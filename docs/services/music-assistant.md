# Music Assistant

Music Assistant is optional but often used with Home Assistant dashboards.

Canonical names:

- Config/service key: `musicassistant`
- Compose service: `musicassistant`
- Container: `musicassistant`
- Display name: Music Assistant

Enable it in `config/domum.conf`:

```bash
ENABLE_MA=1
MUSICASSISTANT_AUTO_UPDATE=0
MUSICASSISTANT_UPDATE_DELAY_DAYS=7
```

Health checks should use the canonical service mapping. A running
`musicassistant` container must not be reported as missing under
`music-assistant`.
