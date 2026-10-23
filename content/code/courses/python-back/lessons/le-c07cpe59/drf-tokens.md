---
title: Tokens for programs
version: 1
---

A session suits a browser. A script, a phone app or another server would rather send one header and
skip the form and the CSRF token. **DRF's token authentication** is that: a random key per user,
kept in a table, sent as `Authorization: Token <key>`. It comes with DRF as an app of its own. Add
`'rest_framework.authtoken'` to `INSTALLED_APPS` after `'rest_framework'`, and name the ways the
API accepts in `config/settings.py`:

```python
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 2,
}
```

**Basic authentication is gone from the list**, which is what lesson 6 promised: a password on
every request is the thing a token exists to avoid. Then an address that hands tokens out, in
`events/api_urls.py`:

```python
# events/api_urls.py
from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token
from rest_framework.routers import DefaultRouter

from . import api

router = DefaultRouter()
router.register("events", api.EventViewSet, basename="event")

urlpatterns = [
    path("token/", obtain_auth_token, name="token"),
    path("events/<slug:slug>/registrations/", api.register_for_event, name="register"),
    *router.urls,
]
```

```
ana@vm:~/agenda$ grep -n 'rest_framework' config/settings.py
40:    'rest_framework',
41:    'rest_framework.authtoken',
135:        "rest_framework.authentication.TokenAuthentication",
136:        "rest_framework.authentication.SessionAuthentication",
139:        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
141:    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
ana@vm:~/agenda$ sed -n '/^REST_FRAMEWORK/,/^}/p' config/settings.py
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 2,
}
ana@vm:~/agenda$ uv run python manage.py migrate
Operations to perform:
  Apply all migrations: admin, auth, authtoken, contenttypes, events, sessions
Running migrations:
  Applying authtoken.0001_initial... OK
  Applying authtoken.0002_auto_20160226_1747... OK
  Applying authtoken.0003_tokenproxy... OK
  Applying authtoken.0004_alter_tokenproxy_options... OK
```

The app brought a table, `authtoken_token`. Ask anonymously, and with Basic, now that neither is
accepted:

```
ana@vm:~/agenda$ curl -si -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{"capacity": 24}' | grep -iE '^(HTTP|www-authenticate)|detail'
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Token
{"detail":"Authentication credentials were not provided."}
ana@vm:~/agenda$ curl -s -u bruno:m4-orchard-copper-17 -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{"capacity": 24}'; echo
{"detail":"Authentication credentials were not provided."}
```

**401 and `WWW-Authenticate: Token`**, where lesson 6 got a 403: with `TokenAuthentication` first in
the list, DRF can tell the client which scheme to use, and a 401 with that header is how HTTP says
so. Lesson 12 is about the difference between the two codes. Now get a token, twice, and use it:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17; echo
{"token":"e4ef8afb8619db69d28f589aba704adb6c190d28"}
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17; echo
{"token":"e4ef8afb8619db69d28f589aba704adb6c190d28"}
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17 | python3 -c "import json, sys; print(json.load(sys.stdin)['token'])" > drf-token.txt
ana@vm:~/agenda$ curl -s -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H "Authorization: Token $(cat drf-token.txt)" -H 'Content-Type: application/json' -d '{"capacity": 24}'; echo
{"slug":"testing-dojo","title":"Testing dojo","starts_at":"2026-11-26T19:00:00-03:00","venue":"Community Centre, room 3","capacity":24,"description":"","taken":3}
```

**The same token both times**: one per user, made on first request and reused. Every request with
it is Bruno's.

## A token is a password with no expiry

```
ana@vm:~/agenda$ psql agenda -c "select key, user_id, created from authtoken_token"
                   key                    | user_id |           created            
------------------------------------------+---------+------------------------------
 e4ef8afb8619db69d28f589aba704adb6c190d28 |       2 | 2026-10-22 20:35:22.38716-03
(1 row)
```

**The key is in the table as it was sent.** Whoever reads this table, from a backup or a leaked
dump, can act as every user in it until the tokens change, so it deserves the protection of the
passwords and more. Libraries such as django-rest-knox keep only a hash of each token for that
reason, and add expiry. Taking one back is changing it:

```
ana@vm:~/agenda$ uv run python manage.py drf_create_token -r bruno
Generated token 417c54e83246ee6a1f3d857c41ba1a2d41a32bbd for user bruno
ana@vm:~/agenda$ curl -s -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H "Authorization: Token $(cat drf-token.txt)" -H 'Content-Type: application/json' -d '{"capacity": 24}'; echo
{"detail":"Invalid token."}
```
