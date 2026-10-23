---
title: Tokens para programas
version: 1
---

Uma sessão serve a um navegador. Um script, um app de celular ou outro servidor prefere mandar um
cabeçalho e pular o formulário e o token de CSRF. A **autenticação por token do DRF** é isso: uma
chave aleatória por usuário, guardada numa tabela, mandada como `Authorization: Token <chave>`. Ela vem
com o DRF como um app próprio. Acrescente `'rest_framework.authtoken'` ao `INSTALLED_APPS` depois de
`'rest_framework'`, e nomeie os jeitos que a API aceita em `config/settings.py`:

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

**A autenticação Basic saiu da lista**, que é o que a aula 6 prometeu: uma senha em toda requisição é
justamente o que um token existe para evitar. Depois, um endereço que distribui tokens, em
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

O app trouxe uma tabela, `authtoken_token`. Peça de forma anônima, e com Basic, agora que nenhum dos
dois é aceito:

```
ana@vm:~/agenda$ curl -si -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{"capacity": 24}' | grep -iE '^(HTTP|www-authenticate)|detail'
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Token
{"detail":"Authentication credentials were not provided."}
ana@vm:~/agenda$ curl -s -u bruno:m4-orchard-copper-17 -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{"capacity": 24}'; echo
{"detail":"Authentication credentials were not provided."}
```

**401 e `WWW-Authenticate: Token`**, onde a aula 6 recebeu um 403: com a `TokenAuthentication` em
primeiro na lista, o DRF consegue dizer ao cliente que esquema usar, e um 401 com esse cabeçalho é
como o HTTP diz isso. A aula 12 trata da diferença entre os dois códigos. Agora pegue um token, duas
vezes, e use:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17; echo
{"token":"e4ef8afb8619db69d28f589aba704adb6c190d28"}
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17; echo
{"token":"e4ef8afb8619db69d28f589aba704adb6c190d28"}
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/token/ -d username=bruno -d password=m4-orchard-copper-17 | python3 -c "import json, sys; print(json.load(sys.stdin)['token'])" > drf-token.txt
ana@vm:~/agenda$ curl -s -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H "Authorization: Token $(cat drf-token.txt)" -H 'Content-Type: application/json' -d '{"capacity": 24}'; echo
{"slug":"testing-dojo","title":"Testing dojo","starts_at":"2026-11-26T19:00:00-03:00","venue":"Community Centre, room 3","capacity":24,"description":"","taken":3}
```

**O mesmo token as duas vezes**: um por usuário, criado no primeiro pedido e reaproveitado. Toda
requisição com ele é do Bruno.

## Um token é uma senha que não expira

```
ana@vm:~/agenda$ psql agenda -c "select key, user_id, created from authtoken_token"
                   key                    | user_id |           created            
------------------------------------------+---------+------------------------------
 e4ef8afb8619db69d28f589aba704adb6c190d28 |       2 | 2026-10-22 20:35:22.38716-03
(1 row)
```

**A chave está na tabela do jeito que foi mandada.** Quem ler esta tabela, de um backup ou de um dump
vazado, pode agir como qualquer usuário dela até os tokens mudarem, então ela merece a proteção das
senhas e mais. Bibliotecas como a django-rest-knox guardam só um hash de cada token por esse motivo, e
acrescentam expiração. Tomar um de volta é trocá-lo:

```
ana@vm:~/agenda$ uv run python manage.py drf_create_token -r bruno
Generated token 417c54e83246ee6a1f3d857c41ba1a2d41a32bbd for user bruno
ana@vm:~/agenda$ curl -s -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H "Authorization: Token $(cat drf-token.txt)" -H 'Content-Type: application/json' -d '{"capacity": 24}'; echo
{"detail":"Invalid token."}
```
