# MariaDB for Home Assistant (Domum)


# Database Configuration

In configuration.yaml:

    recorder:
      db_url: !secret ha_db_url
      purge_keep_days: 30
      commit_interval: 60

In secrets.yaml:

    ha_db_url: "mysql://ha:password@mariadb:3306/homeassistant?charset=utf8mb4"

The hostname must match the service name in docker compose: mariadb.

------------------------------------------------------------------------

# Verify MariaDB is Running

    sudo docker ps | grep mariadb

Check logs:

    sudo docker logs mariadb --tail 100

You should see:

    mariadbd: ready for connections.
    port: 3306

------------------------------------------------------------------------

# Verify Home Assistant is Using MariaDB

## 1) Check database exists

    sudo docker exec -it mariadb sh -lc '
    mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -e "SHOW DATABASES;"
    '

You should see:

    homeassistant
    information_schema

## 2) Check tables exist

    sudo docker exec -it mariadb sh -lc '
    mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -D homeassistant -e "SHOW TABLES;"
    '

Expected tables include:

- events
- states
- statistics
- recorder_runs
- schema_changes

## 3) Check active connections

    sudo docker exec -it mariadb sh -lc '
    mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -e "SHOW PROCESSLIST;"
    '

You should see connections from user ha.

------------------------------------------------------------------------

# Verify Network Connectivity

## From Home Assistant container

Test DNS resolution:

    sudo docker exec -it homeassistant sh -lc 'getent hosts mariadb'

Test TCP connection:

    sudo docker exec -it homeassistant sh -lc 'nc -zv mariadb 3306'

Expected:

    mariadb (172.x.x.x:3306) open

------------------------------------------------------------------------

# Verify Traefik Routing

Test from inside Traefik:

    sudo docker exec -it traefik sh -lc '
    apk add --no-cache curl >/dev/null 2>&1 || true
    curl -sS -D- http://homeassistant:8123/ | head
    '

Expected:

    HTTP/1.1 302 Found

If you get timeout here, networking is broken.

------------------------------------------------------------------------

# Common Problems & Fixes

## 1) 504 Gateway Timeout via Traefik

Symptom:

    curl -I https://ha.domain.com
    HTTP/2 504

Cause: Home Assistant is on multiple networks and Traefik selects the
wrong one.

Fix: Add this label to Home Assistant:

    - traefik.docker.network=domum-proxy

Redeploy:

    sudo domum apply
    sudo docker restart traefik

------------------------------------------------------------------------

## 2) "Can't connect to server on 'mariadb'"

Cause: Wrong hostname in db_url.

Correct format:

    mysql://user:pass@mariadb:3306/homeassistant?charset=utf8mb4

The hostname must equal the docker service name.

------------------------------------------------------------------------

## 3) HA stuck at "Unable to connect, retrying in 60 seconds"

Check:

- Is MariaDB running?
- Does HA resolve mariadb?
- Does nc -zv mariadb 3306 work?
- Are there recorder errors in logs?

Check logs:

    sudo docker logs homeassistant --tail 200 | grep -i recorder

------------------------------------------------------------------------

## 4) Host Cannot Reach 127.0.0.1:8123

This is expected.

HA does NOT expose port 8123 to the host. It is only accessible via
Traefik.

If you need direct host access for debugging:

    ports:
      - "8123:8123"

Remove after debugging.

------------------------------------------------------------------------

# Useful HA Debug Commands

Check config validity:

    sudo docker exec -it homeassistant python -m homeassistant --script check_config

Check logs:

    sudo docker logs homeassistant --tail 200

Restart HA only:

    sudo docker restart homeassistant

------------------------------------------------------------------------

# Backup Strategy

Dump database:

    sudo docker exec mariadb sh -lc '
    mariadb-dump -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" homeassistant
    ' > ha_backup.sql

Restore:

    cat ha_backup.sql | sudo docker exec -i mariadb sh -lc '
    mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" homeassistant
    '

