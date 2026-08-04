# Excalidraw

Excalidraw is a browser-based whiteboard for sketches, diagrams, and exported
`.excalidraw` drawings. This deployment is stateless; drawings are stored in the
browser or exported by the user, not on the server.

## Enable the Service

Excalidraw is disabled by default:

```bash
sudo domum-core configure
sudo domum-core apply
```

The service is exposed as `https://draw.${DOMUM_DOMAIN}` through Traefik. Add a
matching DNS CNAME before using it from the LAN.

## Data and Backups

There is no server-side data directory and no service backup flag. Export any
important drawings from the browser as `.excalidraw`, PNG, or SVG files.

## Updates

Excalidraw participates in the normal container update workflow with
`EXCALIDRAW_AUTO_UPDATE` and `EXCALIDRAW_UPDATE_DELAY_DAYS`. It defaults to
manual updates.

## Quick Checks

If the page does not load:

- Confirm the service is enabled with `sudo domum-core configure`.
- Confirm DNS has `draw.${DOMUM_DOMAIN}`.
- Re-apply the stack with `sudo domum-core apply`.
- Run `sudo domum-core checkup`.
- Check logs with `sudo docker logs excalidraw` or Dozzle.
