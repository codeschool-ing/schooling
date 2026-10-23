---
title: A viagem que uma requisição faz
version: 1
---

Entre o servidor e a sua view fica uma pilha de **middleware**, a lista chamada `MIDDLEWARE` no
`settings.py`. Cada um é uma camada em volta de tudo o que está abaixo: vê a requisição na ida, pode
pará-la e responder sozinho, e vê a resposta na volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Os middlewares listados na configuração, de cima para baixo, envolvem a view como as camadas de uma cebola. Uma requisição desce por todas as camadas até o resolvedor de URL e a view; a resposta sobe pelas mesmas camadas na ordem inversa. O CsrfViewMiddleware está em destaque: um POST sem token CSRF é recusado ali com um 403, antes de chegar à view.\"> <defs><marker id=\"rc-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"rc-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"170\" y=\"46\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">requisição</text> <text x=\"550\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">resposta</text> <rect x=\"200\" y=\"36\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"51\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TimingMiddleware</text> <rect x=\"200\" y=\"64\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"79\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SecurityMiddleware</text> <rect x=\"200\" y=\"92\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionMiddleware</text> <rect x=\"200\" y=\"120\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"135\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CommonMiddleware</text> <rect x=\"200\" y=\"148\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.25\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"163\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CsrfViewMiddleware</text> <rect x=\"200\" y=\"176\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"191\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AuthenticationMiddleware</text> <rect x=\"200\" y=\"204\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MessageMiddleware</text> <rect x=\"200\" y=\"232\" width=\"320\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"247\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">XFrameOptionsMiddleware</text> <rect x=\"200\" y=\"270\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"291\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">resolvedor de URL, depois a view</text> <path d=\"M180 36 L180 282 L194 282\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rc-a)\"></path> <path d=\"M526 290 L540 290 L540 42\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rc-a)\"></path> <text x=\"556\" y=\"140\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um POST sem</text> <text x=\"556\" y=\"155\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">token para aqui:</text> <text x=\"556\" y=\"170\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">403, e a view</text> <text x=\"556\" y=\"185\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nem roda</text> <path d=\"M552 160 L526 160\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rc-b)\"></path> </svg>", "caption": "Cada middleware vê a requisição na ida e a resposta na volta. O TimingMiddleware é o primeiro da lista, então dispara o cronômetro antes de todas as outras camadas e o para depois de todas elas."}
```

Os quatro cabeçalhos de segurança da aula 1 são acrescentados na volta pelo `SecurityMiddleware` e
pelo `XFrameOptionsMiddleware`. O redirecionamento que acrescentou uma barra veio do
`CommonMiddleware` na ida. E um cookie vira `request.user` no `AuthenticationMiddleware`, antes de
qualquer view ser chamada.

## Um middleware seu

Um middleware é uma classe construída uma vez com a próxima camada, `get_response`, e chamada uma vez
por requisição. Este mede quanto tempo tudo abaixo dele levou e diz isso num cabeçalho padrão,
`Server-Timing`, que os navegadores mostram nas ferramentas de desenvolvimento. Salve como
`events/middleware.py`:

```python
# events/middleware.py
import time


class TimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        started = time.perf_counter()
        response = self.get_response(request)
        elapsed = (time.perf_counter() - started) * 1000
        response["Server-Timing"] = f"app;dur={elapsed:.1f}"
        return response
```

A linha **antes** do `get_response` roda na ida; as linhas **depois** rodam na volta, com a resposta
na mão. Acrescente-o no topo do `MIDDLEWARE`, para ele envolver todas as outras camadas:

```
ana@vm:~/agenda$ sed -n '/^MIDDLEWARE/,/^]/p' config/settings.py
MIDDLEWARE = [
    'events.middleware.TimingMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]
```

Uma mudança no `settings.py` também reinicia o `runserver`. Então:

```
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|server-timing|x-frame)"
HTTP/1.1 200 OK
X-Frame-Options: DENY
Server-Timing: app;dur=1.9
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/events/nope/ | grep -iE "^(HTTP|server-timing)"
HTTP/1.1 404 Not Found
Server-Timing: app;dur=3.6
```

Os milissegundos são a viagem inteira abaixo da camada de tempo, e mudam a cada requisição. O 404
passou pelas mesmas camadas e também foi cronometrado: uma exceção levantada numa view vira resposta
antes de chegar aos middlewares, então toda camada ainda vê uma resposta voltar.

## Uma camada que responde antes da view

```
ana@vm:~/agenda$ curl -si -X POST http://127.0.0.1:8000/events/django-night/ | grep -iE "^(HTTP|server-timing)"
HTTP/1.1 403 Forbidden
Server-Timing: app;dur=3.0
```

Esse POST não ganhou um 405 do `require_GET`, como a requisição `OPTIONS` da seção anterior. Ganhou
**403 Forbidden**, e o log do servidor disse por quê: `Forbidden (CSRF cookie not set.)`. O
`CsrfViewMiddleware` recusa todo POST que não traz um token provando que veio de um formulário que
este site serviu, e **ele roda antes da view**, então a regra da própria view nem foi consultada. A
camada de tempo, acima dele, ainda cronometrou a recusa. A aula 3 põe o token num formulário, que é o
que faz um POST de navegador funcionar, e a aula 6 explica por que uma API autenticada com token, e
não com cookie, não precisa dele.

## Ordem é comportamento

O middleware roda na ordem da lista na ida e na ordem inversa na volta, então mover uma linha muda o
que a aplicação faz. O `SecurityMiddleware` é o primeiro entre os do Django para que o
redirecionamento para HTTPS, em produção, aconteça antes de qualquer trabalho; o
`AuthenticationMiddleware` vem depois do `SessionMiddleware` porque lê a sessão que aquele carrega. A
documentação do Django lista a ordem de que cada middleware dele precisa, e um novo entra onde o
trabalho dele manda, o que para a maioria dos seus é depois dos do Django.
