---
title: Herança de templates, para a página ser escrita uma vez
version: 1
---

Toda página de um site compartilha a maior parte do HTML: o head, a folha de estilo, o cabeçalho com
os links. Copiar isso em cada template significa mudar em cada template. **A herança escreve uma
vez.** Um template base tem a página inteira com **blocos** com nome deixados abertos, e todo outro
template o **estende** e preenche só os blocos.

Templates que não pertencem a nenhum app, como a base de toda página, vão num diretório `templates/`
do projeto. O Django só procura nele quando ele aparece no `DIRS`, em `config/settings.py`:

```python
        'DIRS': [BASE_DIR / 'templates'],
```

```
ana@vm:~/agenda$ grep -n "'DIRS'" config/settings.py
59:        'DIRS': [BASE_DIR / 'templates'],
ana@vm:~/agenda$ find templates events/templates events/static -type f | sort
events/static/events/agenda.css
events/templates/events/event_detail.html
events/templates/events/event_list.html
templates/about.html
templates/base.html
```

A base, `templates/base.html`:

```html
{# templates/base.html #}
{% load static %}
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{% block title %}agenda{% endblock %}</title>
  <link rel="stylesheet" href="{% static 'events/agenda.css' %}">
</head>
<body>
  <header>
    <a href="{% url 'events:list' %}">agenda</a>
    <a href="{% url 'about' %}">about</a>
  </header>
  <main>
    {% block content %}{% endblock %}
  </main>
</body>
</html>
```

**O `{% block %}` declara um buraco com um padrão.** O `title` tem `agenda` como padrão, então uma
página que não o preenche ainda tem título; o `content` tem padrão vazio. O `{% load static %}` deixa
a tag `{% static %}` disponível neste arquivo, e a última seção desta aula é sobre o que ela produz.

O template da lista da seção anterior começava com `{% extends "base.html" %}` e preenchia `title` e
`content`, e é por isso que a página que ele produziu tinha um cabeçalho que ele nunca escreveu. Uma
segunda página mostra o formato sem mais nada no caminho. `templates/about.html`:

```html
{# templates/about.html #}
{% extends "base.html" %}

{% block title %}About · agenda{% endblock %}

{% block content %}
<h1>About agenda</h1>
<p>Community events, with a limited number of seats each.</p>
{% endblock %}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"O templates/base.html tem a página inteira com dois blocos vazios, title e content. O about.html o estende e preenche só esses dois blocos. A página enviada ao navegador é o base com o texto do filho nos blocos.\"> <defs><marker id=\"in-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"30\" width=\"220\" height=\"200\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"130\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">templates/base.html</text> <text x=\"130\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;html&gt; &lt;head&gt;</text> <rect x=\"40\" y=\"88\" width=\"180\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{% block title %}</text> <text x=\"130\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;header&gt; links &lt;/header&gt;</text> <rect x=\"40\" y=\"146\" width=\"180\" height=\"52\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{% block content %}</text> <text x=\"130\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;/html&gt;</text> <rect x=\"270\" y=\"30\" width=\"190\" height=\"200\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"365\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">templates/about.html</text> <text x=\"365\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{% extends \"base.html\" %}</text> <rect x=\"285\" y=\"88\" width=\"160\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"365\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">About · agenda</text> <rect x=\"285\" y=\"146\" width=\"160\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"365\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;h1&gt;About agenda&lt;/h1&gt;</text> <text x=\"365\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;p&gt;Community…&lt;/p&gt;</text> <rect x=\"500\" y=\"30\" width=\"200\" height=\"200\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"600\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a página enviada</text> <text x=\"600\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;html&gt; &lt;head&gt;</text> <rect x=\"515\" y=\"88\" width=\"170\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"600\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">About · agenda</text> <text x=\"600\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;header&gt; links &lt;/header&gt;</text> <rect x=\"515\" y=\"146\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"600\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;h1&gt;About agenda&lt;/h1&gt;</text> <text x=\"600\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;p&gt;Community…&lt;/p&gt;</text> <text x=\"600\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;/html&gt;</text> <path d=\"M445 101 L509 101\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#in-a)\"></path> <path d=\"M445 172 L509 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#in-a)\"></path> <text x=\"360\" y=\"256\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">O filho preenche os blocos do pai e não escreve nada fora deles.</text> </svg>", "caption": "Toda página do agenda é o base.html com blocos diferentes preenchidos, então uma mudança no cabeçalho é uma edição num arquivo só."}
```

Uma página simples assim não precisa de view própria. A aula 2 prometeu o `TemplateView`, e este é o
trabalho dele: uma view baseada em classe que renderiza um template. Aponte uma URL para ele no
`config/urls.py`:

```python
# config/urls.py
from django.contrib import admin
from django.urls import include, path
from django.views.generic import TemplateView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("about/", TemplateView.as_view(template_name="about.html"), name="about"),
    path("events/", include("events.urls")),
]
```

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/about/ | grep -E "<title>|<h1>"
  <title>About · agenda</title>
<h1>About agenda</h1>
```

## Três regras que poupam uma tarde

- **O `{% extends %}` é a primeira tag.** Outra tag antes dele, mesmo um `{% load %}`, para o template
  com `{% extends "base.html" %} must be the first tag in the template.` Texto e comentários antes
  dele são permitidos, e jogados fora.
- **Um filho não escreve nada fora dos blocos.** Texto ali não é erro; é jogado fora em silêncio, o
  que é pior. As duas coisas foram testadas nos templates desta aula antes de serem escritas aqui.
- **`{{ block.super }}`** dentro de um bloco imprime a versão do pai, para um filho que quer
  acrescentar a um bloco em vez de substituí-lo.
