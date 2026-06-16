# OS Security Patches

Host OS updates are handled separately from container updates.

```bash
sudo domum-core os-updates check
sudo domum-core os-updates security-apply --dry-run
sudo domum-core os-updates security-apply
sudo domum-core os-updates history
```

Defaults:

```bash
ENABLE_SECURITY_PATCHES=1
ENABLE_AUTOREMOVE_OLD_KERNELS=0
SECURITY_PATCH_REBOOT_POLICY="manual"
```

`security-apply` uses Debian unattended-upgrades for security patches only. It never
reboots automatically. If `/var/run/reboot-required` exists after patching, the CLI reports
it and leaves reboot timing to the operator.
