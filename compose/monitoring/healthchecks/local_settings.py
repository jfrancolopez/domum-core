import os
from urllib.parse import urlparse

site_root = os.environ["SITE_ROOT"].rstrip("/")
site_host = urlparse(site_root).hostname
base_domain = ".".join(site_host.split(".")[-2:]) if site_host else ""

CSRF_TRUSTED_ORIGINS = [
    site_root,
    f"https://{site_host}",
    f"http://{site_host}",
]
if base_domain:
    CSRF_TRUSTED_ORIGINS.append(f"https://*.{base_domain}")

CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True
