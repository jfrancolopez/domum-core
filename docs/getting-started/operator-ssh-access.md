# Operator SSH access

Operator SSH access is normal Linux OpenSSH access to the host. It is separate
from service secrets in `/etc/domum-core/secrets/` and separate from Tailscale
SSH.

Set this up before depending on remote maintenance. A rebuilt host does not know
your laptop's SSH key until its public key is installed for the host user.

## Assumptions

- Host user: `jfranco`
- Hostname: `domum-core`
- Tailscale IP: `100.x.y.z`

Adjust the commands if the rebuilt system uses a different operator user.

## 1. Confirm the operator user

Run on the Pi console, or from a login method that still works:

```bash
id jfranco
groups jfranco
```

The user should exist and should be in `sudo` and `docker` after install. If the
user is missing from a group:

```bash
sudo usermod -aG sudo,docker jfranco
```

Log out and back in before relying on the new group membership.

## 2. Install the public key

On the machine you SSH from, print the public key you want this host to trust:

```bash
cat ~/.ssh/id_ed25519.pub
```

If your dotfiles manage SSH config or keys, use the public key from that setup.
Never copy a private key to the Pi just to make login work.

On the Pi, create `authorized_keys` for the operator user:

```bash
sudo install -d -o jfranco -g jfranco -m 700 /home/jfranco/.ssh
sudo install -o jfranco -g jfranco -m 600 /dev/null /home/jfranco/.ssh/authorized_keys
sudo nano /home/jfranco/.ssh/authorized_keys
```

Paste the public key as a single line, save, then verify permissions:

```bash
sudo chown -R jfranco:jfranco /home/jfranco/.ssh
sudo chmod 700 /home/jfranco/.ssh
sudo chmod 600 /home/jfranco/.ssh/authorized_keys
```

## 3. Test before locking down SSH

From the machine you SSH from, test a new login while keeping the console or old
session open:

```bash
ssh -v jfranco@domum-core
```

If the host is reachable only through Tailscale, test the Tailscale IP as well:

```bash
ssh -v jfranco@100.x.y.z
```

Success here proves the host accepted your public key. Do not disable password
login until key login works from a new terminal.

## 4. Lock down sshd

Edit sshd config:

```bash
sudo nano /etc/ssh/sshd_config
```

Use:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Validate and restart SSH:

```bash
sudo sshd -t
sudo systemctl restart ssh
```

Open a fresh terminal and test again:

```bash
ssh jfranco@domum-core
```

If that works, remote maintenance is ready.

## Tailscale note

`ssh jfranco@100.x.y.z` is still normal OpenSSH when Tailscale SSH is disabled.
That is the default for domum-core: `TAILSCALE_SSH=0` and
`sudo tailscale up --accept-dns=false --ssh=false`.

In that mode, Tailscale provides the network path only. The Linux host still
checks `/home/jfranco/.ssh/authorized_keys`.

Only enable Tailscale SSH intentionally, and document that decision in
`config/domum.conf` with `TAILSCALE_SSH=1`.

## Troubleshooting

`Permission denied (publickey,password)` means the SSH server did not accept a
key for that user, and password auth was unavailable or rejected.

Check the common causes on the Pi:

```bash
sudo ls -ld /home/jfranco /home/jfranco/.ssh
sudo ls -l /home/jfranco/.ssh/authorized_keys
sudo sshd -T | grep -E '^(pubkeyauthentication|passwordauthentication|permitrootlogin)'
```

Expected permissions:

- `/home/jfranco/.ssh` is owned by `jfranco:jfranco` and mode `700`.
- `/home/jfranco/.ssh/authorized_keys` is owned by `jfranco:jfranco` and mode
  `600`.
- The public key line in `authorized_keys` matches the private key offered by
  the client.

From the client, `ssh -v` should show which key is offered. If your dotfiles use
a non-default key, either pass it explicitly:

```bash
ssh -i ~/.ssh/domum_core_ed25519 jfranco@domum-core
```

or configure the client side in your dotfiles:

```text
Host domum-core
  HostName domum-core
  User jfranco
  IdentityFile ~/.ssh/domum_core_ed25519
  IdentitiesOnly yes
```
