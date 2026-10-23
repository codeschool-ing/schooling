---
title: URLs, do projeto até o app
version: 1
---

O Django lê o `ROOT_URLCONF`, `config/urls.py`, em toda requisição, e tenta os padrões em ordem até
um casar. **A tabela do projeto deve ficar curta**: ela diz qual app é dono de qual prefixo, e cada
app mantém a própria tabela. Troque o `config/urls.py` por isto, mantendo a linha do admin:

```python
# config/urls.py
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("events/", include("events.urls")),
]
```

O `include("events.urls")` entrega tudo o que está sob `/events/` ao app. Crie a tabela dele como
`events/urls.py`:

```python
# events/urls.py
from django.urls import path

from . import views

app_name = "events"
urlpatterns = [
    path("", views.event_list, name="list"),
    path("<slug:slug>/", views.event_detail, name="detail"),
]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O caminho /events/testing-dojo/ casa em dois passos. O config/urls.py casa o prefixo events/ e entrega o resto ao urls.py do próprio app, que casa &lt;slug:slug&gt;/ com testing-dojo/ e chama event_detail com slug igual a testing-dojo.\"> <defs><marker id=\"ui-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"360\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">GET /events/testing-dojo/</text> <rect x=\"20\" y=\"60\" width=\"210\" height=\"92\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"125\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">config/urls.py</text> <text x=\"125\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">path(\"events/\",</text> <text x=\"125\" y=\"121\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">include(\"events.urls\"))</text> <text x=\"125\" y=\"141\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">casa e retira events/</text> <rect x=\"255\" y=\"60\" width=\"210\" height=\"92\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">events/urls.py</text> <text x=\"360\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">path(\"&lt;slug:slug&gt;/\",</text> <text x=\"360\" y=\"121\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">views.event_detail)</text> <text x=\"360\" y=\"141\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">vê só testing-dojo/</text> <rect x=\"490\" y=\"60\" width=\"210\" height=\"92\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"595\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">event_detail(request,</text> <text x=\"595\" y=\"111\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">slug=\"testing-dojo\")</text> <text x=\"595\" y=\"141\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o conversor fez o argumento</text> <path d=\"M230 106 L249 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ui-a)\"></path> <path d=\"M465 106 L484 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ui-a)\"></path> <text x=\"360\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">O app nunca vê o prefixo, então montá-lo em outro endereço muda uma linha no config/urls.py.</text> </svg>", "caption": "O include() é uma passagem de bastão: o urls.py do projeto é dono do prefixo, o do app é dono de tudo depois dele."}
```

## Conversores, a parte tipada de um caminho

`<slug:slug>` aceita um **slug**, letras, dígitos, hífens e sublinhados, e o passa à view como o
argumento `slug`. Um caminho que não cabe no conversor não casa com nada, e a view nem o vê:

| conversor | aceita | a view recebe |
|---|---|---|
| `str` | qualquer coisa menos barra, e é o padrão | um `str` |
| `int` | dígitos | um `int` |
| `slug` | letras, dígitos, `-` e `_` | um `str` |
| `uuid` | um UUID | um `uuid.UUID` |
| `path` | qualquer coisa, inclusive barras | um `str` |

## Nomes, para nada precisar escrever uma URL duas vezes

`app_name = "events"` e `name="detail"` dão um nome a cada padrão, `events:detail`, e o projeto pode
montar a URL a partir do nome em vez de escrever o texto de novo. O `reverse` monta um caminho, e o
`resolve` faz o contrário, de um caminho até a view:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.urls import reverse; print(reverse(\"events:detail\", args=[\"testing-dojo\"]))"
12 objects imported automatically (use -v 2 for details).

/events/testing-dojo/
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.urls import resolve; m = resolve(\"/events/testing-dojo/\"); print(m.view_name, m.func.__name__, m.kwargs)"
12 objects imported automatically (use -v 2 for details).

events:detail event_detail {'slug': 'testing-dojo'}
```

A linha sobre **12 objects imported automatically** é o shell do Django avisando que importou os
modelos e alguns utilitários comuns para você; ele imprime isso antes de rodar o comando. A aula 3 usa
os mesmos nomes dentro dos templates, e mudar uma URL depois é uma edição no `urls.py`, com todos os
links acompanhando.

## A barra final

Todo padrão aqui termina em `/`, e o Django acrescenta uma quando ela falta:

```
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/events/django-night | head -4
HTTP/1.1 301 Moved Permanently
Date: Fri, 16 Oct 2026 22:37:18 GMT
Server: WSGIServer/0.2 CPython/3.12.3
Content-Type: text/html; charset=utf-8
```

O `CommonMiddleware`, com a configuração `APPEND_SLASH` ligada por padrão, vê que
`/events/django-night` não casa com nada, que `/events/django-night/` casaria, e responde **301**
apontando para lá. Um navegador segue o redirecionamento sem o usuário perceber. Um cliente que faz
POST de JSON no endereço sem a barra não tem o corpo encaminhado, e é por isso que as APIs da aula 6
são chamadas com a barra.
