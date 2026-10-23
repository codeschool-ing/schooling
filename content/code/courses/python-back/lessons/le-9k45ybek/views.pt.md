---
title: Views, as funções que respondem
version: 1
---

Uma **view** é uma função que recebe um `HttpRequest` e devolve um `HttpResponse`. Todo o resto do
Django existe para levar uma requisição até a view certa e trazer a resposta de volta. Troque o
`events/views.py` por isto:

```schooling-example
{"language": "python", "file": "events/views.py", "parts": [{"code": "from django.http import Http404, JsonResponse\nfrom django.views.decorators.http import require_GET\n\nfrom .data import EVENTS\n\n\n", "note": "**Uma view é uma função que recebe uma requisição e devolve uma resposta.** Estas duas devolvem JSON; a aula 3 as faz devolver páginas."}, {"code": "@require_GET\ndef event_list(request):\n", "note": "O `require_GET` responde a qualquer outro método com **405 Method Not Allowed** antes de a função rodar."}, {"code": "    venue = request.GET.get(\"venue\")\n", "note": "`request.GET` é a query string, como dicionário. O `.get` devolve `None` quando o parâmetro não veio."}, {"code": "    events = [e for e in EVENTS if venue is None or e[\"venue\"] == venue]\n    return JsonResponse({\"count\": len(events), \"events\": events})\n\n\n", "note": "O `JsonResponse` serializa o dicionário e põe `Content-Type: application/json`."}, {"code": "@require_GET\ndef event_detail(request, slug):\n", "note": "O `slug` chega como argumento porque o padrão de URL dá esse nome a ele: `<slug:slug>`."}, {"code": "    for event in EVENTS:\n        if event[\"slug\"] == slug:\n            return JsonResponse(event)\n    raise Http404(f\"No event called {slug}\")\n", "note": "**Levantar `Http404` é como uma view diz \"isso não existe\".** O Django transforma em uma resposta 404."}]}
```

O `runserver` recarrega sozinho quando um arquivo muda, então, com ele ainda rodando no primeiro
terminal, pergunte do segundo:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/; echo
{"count": 3, "events": [{"slug": "django-night", "title": "Django Night", "starts_at": "2026-11-12T19:00", "venue": "Community Centre, room 3", "capacity": 40}, {"slug": "async-workshop", "title": "Async Python workshop", "starts_at": "2026-11-19T14:00", "venue": "Public Library, lab 2", "capacity": 12}, {"slug": "testing-dojo", "title": "Testing dojo", "starts_at": "2026-11-26T19:00", "venue": "Community Centre, room 3", "capacity": 20}]}
ana@vm:~/agenda$ curl -s "http://127.0.0.1:8000/events/?venue=Public%20Library,%20lab%202"; echo
{"count": 1, "events": [{"slug": "async-workshop", "title": "Async Python workshop", "starts_at": "2026-11-19T14:00", "venue": "Public Library, lab 2", "capacity": 12}]}
```

A segunda chamada filtrou com `?venue=`, que o curl teve de mandar com os espaços escritos como `%20`.
**A query string chega já decodificada** no `request.GET`: a view comparou texto puro.

## Um evento, e um que não existe

```
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/events/django-night/; echo
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:37:18 GMT
Server: WSGIServer/0.2 CPython/3.12.3
Content-Type: application/json
X-Frame-Options: DENY
Content-Length: 135
X-Content-Type-Options: nosniff
Referrer-Policy: same-origin
Cross-Origin-Opener-Policy: same-origin

{"slug": "django-night", "title": "Django Night", "starts_at": "2026-11-12T19:00", "venue": "Community Centre, room 3", "capacity": 40}
```

Os mesmos quatro cabeçalhos de segurança da aula 1 estão ali, em toda resposta, porque vêm de
middleware e não da view. E quando o slug não bate com nenhum evento:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/no-such-event/
404
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/a%20space/
404
```

Dois 404 por dois motivos diferentes. O `no-such-event` casou com o padrão, chegou à view, e a view
levantou `Http404`. O `a%20space` é um caminho com um espaço, que o conversor `slug` não aceita, então
nenhum padrão casou e **a view nem rodou**. Com o `DEBUG` ligado, as duas páginas de 404 listam os
padrões que o Django tentou, que é o jeito mais rápido de achar um erro de digitação no `urls.py`, e a
primeira também diz qual view levantou o erro e com que mensagem, `No event called no-such-event`.

## Um método que a view não aceita

```
ana@vm:~/agenda$ curl -si -X OPTIONS http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|allow)"
HTTP/1.1 405 Method Not Allowed
Allow: GET
```

O `require_GET` respondeu antes de o corpo da view rodar, com **405 Method Not Allowed** e um
cabeçalho `Allow` com o método que ele aceita. `OPTIONS` é o método que um cliente manda para fazer
exatamente essa pergunta.

## O que uma requisição carrega

| atributo | o que é |
|---|---|
| `request.method` | `"GET"`, `"POST"`, … |
| `request.GET` | a query string, como dicionário de listas |
| `request.POST` | um formulário enviado (aula 3) |
| `request.body` | os bytes crus do corpo, para JSON |
| `request.headers` | os cabeçalhos, sem diferença de maiúsculas: `request.headers["Accept"]` |
| `request.user` | quem está logado, acrescentado por middleware (aula 11) |

O `request.user` é o interessante: **nada na requisição trouxe um usuário**. Um middleware leu um
cookie e anexou um antes de a view ser chamada, e a próxima seção é sobre essa camada.
