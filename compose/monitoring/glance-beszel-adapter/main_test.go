package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestSummaryFetchesAndSanitizesSystems(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/api/collections/users/auth-with-password":
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{"token":"token-value"}`))
		case "/api/collections/systems/records/system-one":
			if r.Header.Get("Authorization") != "Bearer token-value" {
				t.Fatalf("missing auth header")
			}
			w.Header().Set("Content-Type", "application/json")
			_, _ = w.Write([]byte(`{
          "id":"system-one",
          "name":"do-not-return",
          "status":"up",
          "updated":"2026-08-14T10:00:00Z",
          "info":{"cpu_percent":12.5,"memory_percent":40,"disk_percent":55,"temperature_c":48,"interface":"eth0"}
        }`))
		default:
			http.NotFound(w, r)
		}
	}))
	defer server.Close()

	a := &adapter{
		cfg: config{
			baseURL:  server.URL,
			username: "user",
			password: "pass",
			systems:  []systemConfig{{label: "domum-core", id: "system-one"}},
			cacheTTL: 5 * time.Minute,
			staleTTL: 30 * time.Minute,
		},
		client: server.Client(),
	}

	res := a.summary(context.Background(), time.Date(2026, 8, 14, 10, 0, 0, 0, time.UTC))
	if res.Status != "ok" || res.Cache != "fresh" {
		t.Fatalf("unexpected response state: %+v", res)
	}
	if len(res.Systems) != 1 {
		t.Fatalf("expected one system, got %d", len(res.Systems))
	}
	got := res.Systems[0]
	if got.Label != "domum-core" || got.Status != "up" || got.UpdatedAt == "" || got.Stale {
		t.Fatalf("unexpected system summary: %+v", got)
	}
	if got.Metrics == nil || got.Metrics.CPUPercent == nil || *got.Metrics.CPUPercent != 12.5 {
		t.Fatalf("missing sanitized metrics: %+v", got.Metrics)
	}

	rendered, err := json.Marshal(res)
	if err != nil {
		t.Fatal(err)
	}
	text := string(rendered)
	for _, forbidden := range []string{"system-one", "do-not-return", "eth0", "token-value"} {
		if contains(text, forbidden) {
			t.Fatalf("response leaked %q: %s", forbidden, text)
		}
	}
}

func TestMissingConfigurationIsDegraded(t *testing.T) {
	a := &adapter{cfg: config{systems: []systemConfig{{label: "domum-core"}}}}
	res := a.summary(context.Background(), time.Date(2026, 8, 14, 10, 0, 0, 0, time.UTC))
	if res.Status != "degraded" || res.Cache != "none" {
		t.Fatalf("unexpected response: %+v", res)
	}
	if len(res.Errors) == 0 {
		t.Fatalf("expected configuration errors")
	}
}

func TestStaleCacheUsedOnBeszelFailure(t *testing.T) {
	a := &adapter{
		cfg: config{
			baseURL:  "http://127.0.0.1:1",
			username: "user",
			password: "pass",
			systems:  []systemConfig{{label: "domum-core", id: "system-one"}},
			cacheTTL: time.Minute,
			staleTTL: 30 * time.Minute,
		},
		client: &http.Client{Timeout: 10 * time.Millisecond},
		cache: &cachedSummary{
			generatedAt: time.Date(2026, 8, 14, 10, 0, 0, 0, time.UTC),
			systems:     []systemSummary{{Label: "domum-core", Status: "up"}},
			expiresAt:   time.Date(2026, 8, 14, 10, 1, 0, 0, time.UTC),
			staleUntil:  time.Date(2026, 8, 14, 10, 30, 0, 0, time.UTC),
		},
	}

	res := a.summary(context.Background(), time.Date(2026, 8, 14, 10, 2, 0, 0, time.UTC))
	if res.Status != "degraded" || res.Cache != "stale" {
		t.Fatalf("unexpected response: %+v", res)
	}
	if len(res.Systems) != 1 || !res.Systems[0].Stale {
		t.Fatalf("expected stale system summary: %+v", res.Systems)
	}
}

func contains(text, needle string) bool {
	for i := 0; i+len(needle) <= len(text); i++ {
		if text[i:i+len(needle)] == needle {
			return true
		}
	}
	return false
}
