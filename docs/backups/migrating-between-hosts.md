# Migrating domum-core to a New Host

This guide explains how to move your stack to another Raspberry Pi or server.

---

## Step 1 — Backup Secrets

Copy:

    /etc/domum/secrets/

Example:

    scp -r /etc/domum/secrets new-host:/etc/domum/

---

## Step 2 — Backup Config

Copy:

    /etc/domum/domum.conf

---

## Step 3 — Backup Data (Optional)

If you need persistent data:

    rsync -avz /opt/domum-core/data new-host:/opt/domum-core/

---

## Step 4 — Install on New Host

On the new machine:

    curl -fsSL https://raw.githubusercontent.com/solosoyfranco/domum-core/main/install.sh | sudo bash

---

## Step 5 — Create External Networks (If Needed)

If you see network errors:

    sudo docker network create domum-proxy
    sudo docker network create domum-internal

---

## Step 6 — Verify Services

    sudo docker ps

Confirm all expected containers are running.

---

# Migration Summary

Copy secrets → Copy config → Optional data → Run curl → Done.

