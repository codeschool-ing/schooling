---
title: A linguagem de templates: variáveis, filtros e tags
version: 1
---

As views da aula 2 respondiam JSON. Um site para pessoas responde **HTML**, e escrever HTML dentro de
textos Python é o erro que todo framework existe para impedir. A resposta do Django é o **template**:
um arquivo HTML com buracos, que uma view preenche com um dicionário chamado **contexto**.

Primeiro, os eventos ganham datas de verdade. Uma data escrita como texto pode ser impressa, mas não
formatada, comparada ou convertida para outro fuso, então o `events/data.py` agora monta valores
`datetime` no fuso de São Paulo. A lista vazia no fim é onde a aula 3 guarda as inscrições até a aula
4 dar uma tabela a elas:

```python
# events/data.py
from datetime import datetime
from zoneinfo import ZoneInfo

SAO_PAULO = ZoneInfo("America/Sao_Paulo")

EVENTS = [
    {
        "slug": "django-night",
        "title": "Django Night",
        "starts_at": datetime(2026, 11, 12, 19, 0, tzinfo=SAO_PAULO),
        "venue": "Community Centre, room 3",
        "capacity": 40,
    },
    {
        "slug": "async-workshop",
        "title": "Async Python workshop",
        "starts_at": datetime(2026, 11, 19, 14, 0, tzinfo=SAO_PAULO),
        "venue": "Public Library, lab 2",
        "capacity": 12,
    },
    {
        "slug": "testing-dojo",
        "title": "Testing dojo",
        "starts_at": datetime(2026, 11, 26, 19, 0, tzinfo=SAO_PAULO),
        "venue": "Community Centre, room 3",
        "capacity": 20,
    },
]

REGISTRATIONS = []
```

## Um template

O Django procura templates num diretório `templates/` dentro de cada app instalado, porque o
`APP_DIRS` está `True` no `settings.py`. **O nome do app se repete lá dentro**,
`events/templates/events/`, para que `events/event_list.html` não colida com o `event_list.html` de
outro app: o Django procura no diretório de cada app, em ordem, e fica com o primeiro que achar.
Salve isto como `events/templates/events/event_list.html`:

```html
{# events/templates/events/event_list.html #}
{% extends "base.html" %}

{% block title %}What's on · agenda{% endblock %}

{% block content %}
<h1>What's on</h1>
{% if q %}<p>Results for {{ q }}</p>{% endif %}
<ul>
  {% for event in events %}
  <li>
    <a href="{% url 'events:detail' event.slug %}">{{ event.title }}</a>,
    {{ event.starts_at|date:"D j M, H:i" }} at {{ event.venue }}
  </li>
  {% empty %}
  <li>Nothing on yet.</li>
  {% endfor %}
</ul>
<p>{{ events|length }} event{{ events|length|pluralize }}.</p>
{% endblock %}
```

A view que o preenche está duas seções adiante, com o resto do `events/views.py`; a metade dela que
cuida da lista são três linhas:

```python
def event_list(request):
    q = request.GET.get("q", "")
    events = [e for e in EVENTS if q.lower() in e["title"].lower()]
    return render(request, "events/event_list.html", {"events": events, "q": q})
```

Com todos os arquivos desta aula no lugar, a página sai assim:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/



<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>What's on · agenda</title>
  <link rel="stylesheet" href="/static/events/agenda.css">
</head>
<body>
  <header>
    <a href="/events/">agenda</a>
    <a href="/about/">about</a>
  </header>
  <main>
    
<h1>What's on</h1>

<ul>
  
  <li>
    <a href="/events/django-night/">Django Night</a>,
    Thu 12 Nov, 19:00 at Community Centre, room 3
  </li>
  
  <li>
    <a href="/events/async-workshop/">Async Python workshop</a>,
    Thu 19 Nov, 14:00 at Public Library, lab 2
  </li>
  
  <li>
    <a href="/events/testing-dojo/">Testing dojo</a>,
    Thu 26 Nov, 19:00 at Community Centre, room 3
  </li>
  
</ul>
<p>3 events.</p>

  </main>
</body>
</html>
```

## As três coisas de um template

| sintaxe | o que é | neste template |
|---|---|---|
| `{{ … }}` | uma **variável**, impressa | `{{ event.title }}` |
| `{{ …\|… }}` | uma variável passando por um **filtro** | `{{ event.starts_at\|date:"D j M, H:i" }}` |
| `{% … %}` | uma **tag**: lógica, repetição, carregamento | `{% for %}`, `{% if %}`, `{% url %}` |

**O ponto faz todo tipo de busca.** `event.title` tenta primeiro `event["title"]`, depois um
atributo, depois um índice de lista, e é por isso que o mesmo template funciona com estes dicionários
agora e com os objetos de modelo da aula 4 sem mudança.

**Os filtros fazem a formatação.** `date:"D j M, H:i"` imprimiu `Thu 12 Nov, 19:00`, no horário de
São Paulo, porque o `TIME_ZONE` manda. O `length` contou a lista e o `pluralize` acrescentou o `s` de
`events`. O Django traz uns sessenta filtros, e um template que precisa de mais lógica do que um
filtro dá está pedindo que essa lógica vá para a view.

**As tags fazem o controle.** `{% for %}` repete, e o ramo `{% empty %}` diz o que imprimir quando a
lista está vazia, o que poupa um `if` em volta de cada laço. `{% url 'events:detail' event.slug %}` é
o `reverse` da aula 2 dentro de um template: o link é montado a partir do nome do padrão, então nenhum
endereço é escrito duas vezes.

As linhas em branco no topo da página e entre os itens são as linhas onde as tags estavam. O
navegador as ignora, e você também deve ignorar.
