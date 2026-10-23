---
title: A mesma view como classe
version: 1
---

Uma view também pode ser uma classe. O Django chama um método dela com o nome do método HTTP, `get`
para um GET e `post` para um POST, e responde 405 para qualquer método que a classe não defina. Eis o
`event_detail` de novo, como classe, no `events/views.py` inteiro:

```python
# events/views.py
from django.http import Http404, JsonResponse
from django.views import View
from django.views.decorators.http import require_GET

from .data import EVENTS


@require_GET
def event_list(request):
    venue = request.GET.get("venue")
    events = [e for e in EVENTS if venue is None or e["venue"] == venue]
    return JsonResponse({"count": len(events), "events": events})


class EventDetailView(View):
    def get(self, request, slug):
        for event in EVENTS:
            if event["slug"] == slug:
                return JsonResponse(event)
        raise Http404(f"No event called {slug}")
```

A tabela de URLs aponta para a classe por meio do `as_view()`, que monta a função que o Django chama:

```python
# events/urls.py
from django.urls import path

from . import views

app_name = "events"
urlpatterns = [
    path("", views.event_list, name="list"),
    path("<slug:slug>/", views.EventDetailView.as_view(), name="detail"),
]
```

Ela responde exatamente como antes, e o tratamento dos métodos veio de graça:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/; echo
{"slug": "async-workshop", "title": "Async Python workshop", "starts_at": "2026-11-19T14:00", "venue": "Public Library, lab 2", "capacity": 12}
ana@vm:~/agenda$ curl -si -X OPTIONS http://127.0.0.1:8000/events/async-workshop/ | grep -iE "^(HTTP|allow)"
HTTP/1.1 200 OK
Allow: GET, HEAD, OPTIONS
```

**Agora o `OPTIONS` responde 200 com os métodos que a classe define**, onde a função com
`require_GET` respondia 405. A `View` implementa `options()` para toda classe, e lista o `HEAD`
também, porque uma classe com `get` responde ao `HEAD` com os mesmos cabeçalhos e sem corpo.

## Qual escrever

| | uma função | uma classe |
|---|---|---|
| lê-se como | o código, de cima para baixo | os métodos, mais o que a classe base faz |
| métodos | uma função, um `if` por método, ou um decorador | um método por método HTTP |
| reaproveitamento | funções auxiliares | herança e mixins |
| melhor para | uma view que faz uma coisa | uma família de views que diferem num detalhe |

A classe vale a indireção quando **o Django já escreveu a view de que você precisa**. `ListView`,
`DetailView`, `CreateView` e as parentes delas são classes que buscam linhas, renderizam um template
e tratam um formulário, configuradas com alguns atributos em vez de escritas. Elas precisam de modelos
e templates para trabalhar, então a aula 3 usa o `TemplateView` e a aula 4 as que se apoiam no banco.
Para uma view que faz uma coisa específica, uma função continua a escolha mais clara, e a própria
documentação do Django diz isso.
