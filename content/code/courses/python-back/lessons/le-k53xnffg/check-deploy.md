---
title: check --deploy, and DEBUG off
version: 1
---

Django can review its own settings for a deployment:

```
ana@vm:~/agenda$ uv run --env-file .env python manage.py check --deploy
System check identified some issues:

WARNINGS:
?: (security.W004) You have not set a value for the SECURE_HSTS_SECONDS setting. If your entire site is served only over SSL, you may want to consider setting a value and enabling HTTP Strict Transport Security. Be sure to read the documentation first; enabling HSTS carelessly can cause serious, irreversible problems.
?: (security.W008) Your SECURE_SSL_REDIRECT setting is not set to True. Unless your site should be available over both SSL and non-SSL connections, you may want to either set this setting True or configure a load balancer or reverse-proxy server to redirect all connections to HTTPS.
?: (security.W012) SESSION_COOKIE_SECURE is not set to True. Using a secure-only session cookie makes it more difficult for network traffic sniffers to hijack user sessions.
?: (security.W016) You have 'django.middleware.csrf.CsrfViewMiddleware' in your MIDDLEWARE, but you have not set CSRF_COOKIE_SECURE to True. Using a secure-only CSRF cookie makes it more difficult for network traffic sniffers to steal the CSRF token.
?: (security.W018) You should not have DEBUG set to True in deployment.
?: (security.W020) ALLOWED_HOSTS must not be empty in deployment.

System check identified 6 issues (0 silenced).
```

Six warnings, and the last two are this lesson's: **`DEBUG` on**, and **`ALLOWED_HOSTS` empty**. Set
both as a server would, in the shell, where they win over `.env`:

```
ana@vm:~/agenda$ DJANGO_DEBUG=0 DJANGO_ALLOWED_HOSTS=agenda.example.org uv run --env-file .env python manage.py check --deploy
System check identified some issues:

WARNINGS:
?: (security.W004) You have not set a value for the SECURE_HSTS_SECONDS setting. If your entire site is served only over SSL, you may want to consider setting a value and enabling HTTP Strict Transport Security. Be sure to read the documentation first; enabling HSTS carelessly can cause serious, irreversible problems.
?: (security.W008) Your SECURE_SSL_REDIRECT setting is not set to True. Unless your site should be available over both SSL and non-SSL connections, you may want to either set this setting True or configure a load balancer or reverse-proxy server to redirect all connections to HTTPS.
?: (security.W012) SESSION_COOKIE_SECURE is not set to True. Using a secure-only session cookie makes it more difficult for network traffic sniffers to hijack user sessions.
?: (security.W016) You have 'django.middleware.csrf.CsrfViewMiddleware' in your MIDDLEWARE, but you have not set CSRF_COOKIE_SECURE to True. Using a secure-only CSRF cookie makes it more difficult for network traffic sniffers to steal the CSRF token.

System check identified 4 issues (0 silenced).
```

The four left are about **HTTPS**: a redirect to it, cookies that only travel over it, and HSTS, the
header that tells browsers never to try plain HTTP again. They belong to the server that terminates
TLS, which is lesson 16's nginx, and they are set there.

## What ALLOWED_HOSTS does

Run the development server with the same two values, and ask for the list by IP address, then by
name:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/
400
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" -H "Host: agenda.example.org" http://127.0.0.1:8000/events/
200
```

**400 for a host not in the list.** Django compares the request's `Host` header with
`ALLOWED_HOSTS` before anything else. That stops requests aimed at other names from reaching the
application, including the forged ones that would put a stranger's domain into the links of a
password-reset e-mail. With `DEBUG` off, an error is also a plain page:

```
ana@vm:~/agenda$ curl -s -H "Host: agenda.example.org" http://127.0.0.1:8000/events/nope/; echo

<!doctype html>
<html lang="en">
<head>
  <title>Not Found</title>
</head>
<body>
  <h1>Not Found</h1><p>The requested resource was not found on this server.</p>
</body>
</html>
```

No traceback, no list of URL patterns, no settings. That is what a visitor of a site in production
must see, and the reason `DEBUG` defaults to off.
