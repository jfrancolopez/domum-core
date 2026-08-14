package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

type config struct {
	listenAddr string
	baseURL    string
	username   string
	password   string
	systems    []systemConfig
	cacheTTL   time.Duration
	staleTTL   time.Duration
	timeout    time.Duration
}

type systemConfig struct {
	label string
	id    string
}

type adapter struct {
	cfg    config
	client *http.Client
	mu     sync.Mutex
	cache  *cachedSummary
}

type cachedSummary struct {
	generatedAt time.Time
	systems     []systemSummary
	expiresAt   time.Time
	staleUntil  time.Time
}

type response struct {
	Status      string          `json:"status"`
	GeneratedAt string          `json:"generated_at"`
	Cache       string          `json:"cache"`
	Systems     []systemSummary `json:"systems"`
	Errors      []apiError      `json:"errors,omitempty"`
}

type systemSummary struct {
	Label     string   `json:"label"`
	Status    string   `json:"status"`
	UpdatedAt string   `json:"updated_at,omitempty"`
	Stale     bool     `json:"stale"`
	Metrics   *metrics `json:"metrics,omitempty"`
}

type metrics struct {
	CPUPercent    *float64 `json:"cpu_percent,omitempty"`
	Load1         *float64 `json:"load_1,omitempty"`
	MemoryPercent *float64 `json:"memory_percent,omitempty"`
	DiskPercent   *float64 `json:"disk_percent,omitempty"`
	TemperatureC  *float64 `json:"temperature_c,omitempty"`
}

type apiError struct {
	Label string `json:"label,omitempty"`
	Code  string `json:"code"`
}

func main() {
	if len(os.Args) == 2 && os.Args[1] == "--healthcheck" {
		fmt.Println("ok")
		return
	}

	cfg, err := loadConfig(os.Environ())
	if err != nil {
		log.Fatalf("invalid configuration: %v", err)
	}

	a := &adapter{
		cfg:    cfg,
		client: &http.Client{Timeout: cfg.timeout},
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", a.handleHealthz)
	mux.HandleFunc("/summary", a.handleSummary)

	server := &http.Server{
		Addr:              cfg.listenAddr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("starting glance-beszel-adapter on %s", cfg.listenAddr)
	if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatalf("server stopped: %v", err)
	}
}

func loadConfig(env []string) (config, error) {
	values := map[string]string{}
	for _, item := range env {
		key, value, ok := strings.Cut(item, "=")
		if ok {
			values[key] = value
		}
	}

	baseURL := strings.TrimRight(get(values, "GLANCE_BESZEL_BASE_URL", "http://beszel:8090"), "/")
	if _, err := url.ParseRequestURI(baseURL); err != nil {
		return config{}, fmt.Errorf("GLANCE_BESZEL_BASE_URL: %w", err)
	}

	cfg := config{
		listenAddr: get(values, "GLANCE_BESZEL_ADAPTER_LISTEN", ":8080"),
		baseURL:    baseURL,
		username:   values["GLANCE_BESZEL_USERNAME"],
		password:   values["GLANCE_BESZEL_PASSWORD"],
		cacheTTL:   parseDuration(values, "GLANCE_BESZEL_CACHE_TTL", 5*time.Minute),
		staleTTL:   parseDuration(values, "GLANCE_BESZEL_STALE_TTL", 30*time.Minute),
		timeout:    parseDuration(values, "GLANCE_BESZEL_HTTP_TIMEOUT", 10*time.Second),
	}

	for i := 1; i <= 2; i++ {
		label := strings.TrimSpace(values[fmt.Sprintf("GLANCE_BESZEL_SYSTEM_%d_LABEL", i)])
		id := strings.TrimSpace(values[fmt.Sprintf("GLANCE_BESZEL_SYSTEM_%d_ID", i)])
		if label != "" || id != "" {
			cfg.systems = append(cfg.systems, systemConfig{label: label, id: id})
		}
	}

	return cfg, nil
}

func get(values map[string]string, key string, fallback string) string {
	if value := strings.TrimSpace(values[key]); value != "" {
		return value
	}
	return fallback
}

func parseDuration(values map[string]string, key string, fallback time.Duration) time.Duration {
	value := strings.TrimSpace(values[key])
	if value == "" {
		return fallback
	}
	duration, err := time.ParseDuration(value)
	if err != nil {
		return fallback
	}
	return duration
}

func (a *adapter) handleHealthz(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = w.Write([]byte("ok\n"))
}

func (a *adapter) handleSummary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	now := time.Now().UTC()
	res := a.summary(r.Context(), now)
	status := http.StatusOK
	if res.Cache == "none" && res.Status == "degraded" {
		status = http.StatusServiceUnavailable
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(res)
}

func (a *adapter) summary(ctx context.Context, now time.Time) response {
	missing := a.configErrors()
	if len(missing) > 0 {
		return response{
			Status:      "degraded",
			GeneratedAt: now.Format(time.RFC3339),
			Cache:       "none",
			Systems:     configuredSystems(a.cfg.systems, true),
			Errors:      missing,
		}
	}

	a.mu.Lock()
	cache := a.cache
	if cache != nil && now.Before(cache.expiresAt) {
		res := buildResponse("ok", "fresh", cache.generatedAt, cache.systems, nil)
		a.mu.Unlock()
		return res
	}
	a.mu.Unlock()

	systems, errs := a.fetch(ctx)
	if len(errs) == 0 {
		fresh := &cachedSummary{
			generatedAt: now,
			systems:     systems,
			expiresAt:   now.Add(a.cfg.cacheTTL),
			staleUntil:  now.Add(a.cfg.staleTTL),
		}
		a.mu.Lock()
		a.cache = fresh
		a.mu.Unlock()
		return buildResponse("ok", "fresh", now, systems, nil)
	}

	a.mu.Lock()
	cache = a.cache
	if cache != nil && now.Before(cache.staleUntil) {
		staleSystems := markStale(cache.systems)
		res := buildResponse("degraded", "stale", cache.generatedAt, staleSystems, errs)
		a.mu.Unlock()
		return res
	}
	a.mu.Unlock()

	return response{
		Status:      "degraded",
		GeneratedAt: now.Format(time.RFC3339),
		Cache:       "none",
		Systems:     configuredSystems(a.cfg.systems, true),
		Errors:      errs,
	}
}

func (a *adapter) configErrors() []apiError {
	var errs []apiError
	if strings.TrimSpace(a.cfg.username) == "" {
		errs = append(errs, apiError{Code: "missing_username"})
	}
	if strings.TrimSpace(a.cfg.password) == "" {
		errs = append(errs, apiError{Code: "missing_password"})
	}
	if len(a.cfg.systems) == 0 {
		errs = append(errs, apiError{Code: "missing_systems"})
	}
	for _, system := range a.cfg.systems {
		if system.label == "" {
			errs = append(errs, apiError{Code: "missing_label"})
		}
		if system.id == "" {
			errs = append(errs, apiError{Label: system.label, Code: "missing_system_id"})
		}
	}
	return errs
}

func (a *adapter) fetch(ctx context.Context) ([]systemSummary, []apiError) {
	token, err := a.authenticate(ctx)
	if err != nil {
		return configuredSystems(a.cfg.systems, true), []apiError{{Code: "auth_failed"}}
	}

	systems := make([]systemSummary, 0, len(a.cfg.systems))
	var errs []apiError
	for _, configured := range a.cfg.systems {
		summary, err := a.fetchSystem(ctx, token, configured)
		if err != nil {
			errs = append(errs, apiError{Label: configured.label, Code: err.Error()})
			systems = append(systems, systemSummary{Label: configured.label, Status: "unknown", Stale: true})
			continue
		}
		systems = append(systems, summary)
	}

	return systems, errs
}

func (a *adapter) authenticate(ctx context.Context) (string, error) {
	body, _ := json.Marshal(map[string]string{
		"identity": a.cfg.username,
		"password": a.cfg.password,
	})
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, a.cfg.baseURL+"/api/collections/users/auth-with-password", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Accept", "application/json")

	var payload map[string]any
	if err := a.doJSON(request, &payload); err != nil {
		return "", err
	}
	token, _ := payload["token"].(string)
	if token == "" {
		return "", errors.New("missing token")
	}
	return token, nil
}

func (a *adapter) fetchSystem(ctx context.Context, token string, configured systemConfig) (systemSummary, error) {
	endpoint := a.cfg.baseURL + "/api/collections/systems/records/" + url.PathEscape(configured.id)
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return systemSummary{}, err
	}
	request.Header.Set("Accept", "application/json")
	request.Header.Set("Authorization", "Bearer "+token)

	var record map[string]any
	if err := a.doJSON(request, &record); err != nil {
		return systemSummary{}, err
	}

	return sanitizeSystem(configured.label, record), nil
}

func (a *adapter) doJSON(request *http.Request, target any) error {
	response, err := a.client.Do(request)
	if err != nil {
		return errors.New("request_failed")
	}
	defer response.Body.Close()

	if response.StatusCode == http.StatusUnauthorized || response.StatusCode == http.StatusForbidden {
		io.Copy(io.Discard, response.Body)
		return errors.New("unauthorized")
	}
	if response.StatusCode == http.StatusNotFound {
		io.Copy(io.Discard, response.Body)
		return errors.New("missing_system")
	}
	if response.StatusCode < 200 || response.StatusCode > 299 {
		io.Copy(io.Discard, response.Body)
		return errors.New("beszel_error")
	}
	decoder := json.NewDecoder(io.LimitReader(response.Body, 1<<20))
	if err := decoder.Decode(target); err != nil {
		return errors.New("malformed_response")
	}
	return nil
}

func sanitizeSystem(label string, record map[string]any) systemSummary {
	status := firstString(record, "status", "state")
	if status == "" {
		status = "unknown"
	}

	updatedAt := firstString(record, "updated", "updated_at", "last_seen", "lastSeen")
	metricValues := &metrics{
		CPUPercent:    firstNumber(record, "cpu_percent", "cpuPercent", "cpu_usage", "cpuUsage"),
		Load1:         firstNumber(record, "load_1", "load1"),
		MemoryPercent: firstNumber(record, "memory_percent", "memoryPercent", "mem_percent", "memPercent"),
		DiskPercent:   firstNumber(record, "disk_percent", "diskPercent", "disk_usage", "diskUsage"),
		TemperatureC:  firstNumber(record, "temperature_c", "temperatureC", "temp_c", "tempC"),
	}
	if metricValues.CPUPercent == nil && metricValues.Load1 == nil && metricValues.MemoryPercent == nil && metricValues.DiskPercent == nil && metricValues.TemperatureC == nil {
		metricValues = nil
	}

	return systemSummary{
		Label:     label,
		Status:    strings.ToLower(status),
		UpdatedAt: updatedAt,
		Stale:     false,
		Metrics:   metricValues,
	}
}

func firstString(value any, keys ...string) string {
	switch typed := value.(type) {
	case map[string]any:
		for _, key := range keys {
			if raw, ok := typed[key]; ok {
				if text, ok := raw.(string); ok && text != "" {
					return text
				}
			}
		}
		for _, child := range typed {
			if text := firstString(child, keys...); text != "" {
				return text
			}
		}
	case []any:
		for _, child := range typed {
			if text := firstString(child, keys...); text != "" {
				return text
			}
		}
	}
	return ""
}

func firstNumber(value any, keys ...string) *float64 {
	switch typed := value.(type) {
	case map[string]any:
		for _, key := range keys {
			if raw, ok := typed[key]; ok {
				if number, ok := toFloat(raw); ok {
					return &number
				}
			}
		}
		for _, child := range typed {
			if number := firstNumber(child, keys...); number != nil {
				return number
			}
		}
	case []any:
		for _, child := range typed {
			if number := firstNumber(child, keys...); number != nil {
				return number
			}
		}
	}
	return nil
}

func toFloat(value any) (float64, bool) {
	switch typed := value.(type) {
	case float64:
		return typed, true
	case int:
		return float64(typed), true
	case json.Number:
		parsed, err := typed.Float64()
		return parsed, err == nil
	case string:
		parsed, err := strconv.ParseFloat(typed, 64)
		return parsed, err == nil
	default:
		return 0, false
	}
}

func configuredSystems(systems []systemConfig, stale bool) []systemSummary {
	summaries := make([]systemSummary, 0, len(systems))
	for _, system := range systems {
		label := system.label
		if label == "" {
			label = "unconfigured"
		}
		summaries = append(summaries, systemSummary{Label: label, Status: "unknown", Stale: stale})
	}
	return summaries
}

func markStale(systems []systemSummary) []systemSummary {
	stale := make([]systemSummary, len(systems))
	copy(stale, systems)
	for i := range stale {
		stale[i].Stale = true
	}
	return stale
}

func buildResponse(status string, cacheState string, generatedAt time.Time, systems []systemSummary, errs []apiError) response {
	return response{
		Status:      status,
		GeneratedAt: generatedAt.Format(time.RFC3339),
		Cache:       cacheState,
		Systems:     systems,
		Errors:      errs,
	}
}
