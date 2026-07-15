# MQTT

Mosquitto is the message bus used by Home Assistant and Zigbee2MQTT. The broker
publishes port `1883` on the host, so it must require credentials; Docker-published
ports are not reliably protected by host `ufw` rules.

## Credentials

The password file lives outside git:

```bash
sudo install -d -m 0700 /etc/domum-core/secrets
sudo docker run --rm -u root -v /etc/domum-core/secrets:/secrets \
  docker.io/library/eclipse-mosquitto:2 \
  mosquitto_passwd -c -b /secrets/mosquitto_passwd ha '<ha-password>'
sudo docker run --rm -u root -v /etc/domum-core/secrets:/secrets \
  docker.io/library/eclipse-mosquitto:2 \
  mosquitto_passwd -b /secrets/mosquitto_passwd z2m '<z2m-password>'
sudo chmod 0644 /etc/domum-core/secrets/mosquitto_passwd
```

Mode `0644` is intentional: Mosquitto runs as a non-root user inside the
container and must be able to read the bind-mounted password file. The file
contains Mosquitto password hashes, not cleartext passwords, but the cleartext
passwords still belong in your password manager.

## Stage Consumers Before Apply

Update Zigbee2MQTT's ignored secret file before applying the broker change:

```yaml
# /opt/domum-core/compose/automation/zigbee2mqtt/secret.yaml
mqtt_user: z2m
mqtt_pass: <z2m-password>
```

Update Home Assistant's MQTT integration in the UI before applying:

```text
Settings -> Devices & services -> MQTT -> Configure/Reconfigure
Broker: mqtt
Port: 1883
Username: ha
Password: <ha-password>
```

If any LAN sensors or ESPHome devices use raw MQTT, create a separate account
for them and update those devices before applying.

## Apply And Verify

Run the change during a maintenance window:

```bash
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
- `docker logs mqtt` has no repeated authorization failures

## Rollback

Rollback is to temporarily set `allow_anonymous true` in
`compose/automation/mqtt/config/mosquitto.conf`, run `sudo domum-core apply`,
and then fix missed clients before re-enabling authentication.
