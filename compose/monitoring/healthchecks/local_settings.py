import os
import sys
from urllib.parse import urlparse

from django.views.csrf import csrf_failure as default_csrf_failure

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
CSRF_FAILURE_VIEW = "hc.local_settings.csrf_failure"


class NullOriginMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if (
            request.META.get("HTTP_ORIGIN") == "null"
            and request.get_host() == site_host
        ):
            request.META["HTTP_ORIGIN"] = site_root
        return self.get_response(request)


MIDDLEWARE = [
    "hc.local_settings.NullOriginMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "hc.accounts.middleware.CustomHeaderMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "hc.accounts.middleware.TeamAccessMiddleware",
]


def csrf_failure(request, reason=""):
    print(
        (
            "CSRF failure: reason=%r host=%r origin=%r referer=%r "
            "cookie_present=%s path=%r"
        )
        % (
            reason,
            request.get_host(),
            request.META.get("HTTP_ORIGIN"),
            request.META.get("HTTP_REFERER"),
            "CSRF_COOKIE" in request.META,
            request.path,
        ),
        file=sys.stderr,
        flush=True,
    )
    return default_csrf_failure(request, reason=reason)
