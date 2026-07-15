# MQTT

Mosquitto is the message bus used by Home Assistant and Zigbee2MQTT. The broker
publishes port `1883` on the host, so it must require credentials; Docker-published
ports are not reliably protected by host `ufw` rules.

## Credentials

Use one shared MQTT account for this home stack:

```text
username: domum
password: /etc/domum-core/secrets/mqtt_password
```

Create the missing secrets with:

```bash
sudo domum-core mqtt init-auth
```

The command is idempotent. It never rotates an existing MQTT password:

- `/etc/domum-core/secrets/mqtt_password` — cleartext password for clients
- `/etc/domum-core/secrets/mosquitto_passwd` — root-only source hash file
- `/opt/domum-core/compose/automation/mqtt/config/passwd` — runtime hash copy
  owned by the Mosquitto user from the running container image
- `/opt/domum-core/compose/automation/zigbee2mqtt/secret.yaml` — updates only
  the `mqtt_user` and `mqtt_pass` entries, with a local `.pre-mqtt-init` backup

The runtime `config/passwd` copy is ignored by git and exists only because
Mosquitto runs as a non-root user inside the container. The files under
`/etc/domum-core/secrets` remain root-only.

## Stage Consumers Before Apply

`domum-core mqtt init-auth` stages Zigbee2MQTT automatically. Update Home
Assistant's MQTT integration in the UI before applying:

```text
Settings -> Devices & services -> MQTT -> Configure/Reconfigure
Broker: mqtt
Port: 1883
Username: domum
Password: value from /etc/domum-core/secrets/mqtt_password
```

If any LAN sensors or ESPHome devices use raw MQTT, update them to the same
`domum` account before applying.

## Apply And Verify

Run the change during a maintenance window:

```bash
sudo domum-core mqtt init-auth
sudo domum-core configure --validate
sudo domum-core apply
sudo domum-core checkup
sudo docker logs mqtt --since 10m
```

Expected checks:

- unauthenticated publish to `1883` fails
- authenticated publish succeeds
- Home Assistant MQTT integration is connected
- Zigbee2MQTT devices continue reporting
- `docker logs mqtt` has no permission warnings or repeated authorization failures

## Rollback

Rollback is to temporarily set `allow_anonymous true` in
`compose/automation/mqtt/config/mosquitto.conf`, run `sudo domum-core apply`,
and then fix missed clients before re-enabling authentication.
