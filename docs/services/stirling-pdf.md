# Stirling PDF

Stirling PDF provides browser-based PDF tools. This deployment uses the
`latest-ultra-lite` image to keep Raspberry Pi CPU, memory, and disk pressure
lower than the standard image.

The container is capped at 768 MiB so the JVM does not size itself against the
whole host. Ultra-lite intentionally disables heavyweight OCR and Office
conversion features; switch images only after checking idle memory and thermals.

## Enable the Service

Stirling PDF is disabled by default:

```bash
sudo install -d -m 0750 /opt/domum-core/compose/productivity/stirling-pdf
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://pdf.${DOMUM_DOMAIN}` through Traefik. Add a
matching DNS CNAME before using it from the LAN.

## Authentication

The app's built-in login is disabled to avoid shipping the upstream default
`admin` / `stirling` account. Access is protected by the shared Traefik basic
auth middleware instead.

## Data and Backups

Runtime state lives under:

```text
compose/productivity/stirling-pdf
```

`domum-core backups run` includes this directory when `BACKUP_STIRLING_PDF=1`.
The most relevant subdirectories are `configs` and `pipeline`; `logs` and
`tessdata` are included because they are small in the ultra-lite deployment and
simplify restore.

## Updates

Stirling PDF participates in the normal container update workflow with
`STIRLING_PDF_AUTO_UPDATE` and `STIRLING_PDF_UPDATE_DELAY_DAYS`. It defaults to
manual updates because document conversion images can change behavior across
releases.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm DNS has `pdf.${DOMUM_DOMAIN}`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs stirling-pdf` or Dozzle.
