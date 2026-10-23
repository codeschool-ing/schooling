---
title: Template inheritance, so the page is written once
version: 1
---

Every page of a site shares most of its HTML: the head, the stylesheet, the header with its links.
Copying that into each template means changing it in each template. **Inheritance writes it once.**
A base template holds the whole page with named **blocks** left open, and every other template
**extends** it and fills only the blocks.

Templates that belong to no app, like the base of every page, go in a project-level `templates/`
directory. Django only searches it when it is listed in `DIRS`, in `config/settings.py`:

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

The base, `templates/base.html`:

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

**`{% block %}` declares a hole with a default.** `title` defaults to `agenda`, so a page that does
not fill it still has a title; `content` defaults to nothing. `{% load static %}` makes the
`{% static %}` tag available in this file, and the last section of this lesson is about what it
produces.

The list template of the previous section began with `{% extends "base.html" %}` and filled
`title` and `content`, which is why the page it produced had a header it never wrote. A second
page shows the shape with nothing else in the way. `templates/about.html`:

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
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"templates/base.html holds the whole page with two empty blocks, title and content. about.html extends it and fills only those two blocks. The page sent to the browser is the base with the child's text in the blocks.\"> <defs><marker id=\"in-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"30\" width=\"220\" height=\"200\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"130\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">templates/base.html</text> <text x=\"130\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;html&gt; &lt;head&gt;</text> <rect x=\"40\" y=\"88\" width=\"180\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{% block title %}</text> <text x=\"130\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;header&gt; links &lt;/header&gt;</text> <rect x=\"40\" y=\"146\" width=\"180\" height=\"52\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"130\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{% block content %}</text> <text x=\"130\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;/html&gt;</text> <rect x=\"270\" y=\"30\" width=\"190\" height=\"200\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"365\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">templates/about.html</text> <text x=\"365\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{% extends \"base.html\" %}</text> <rect x=\"285\" y=\"88\" width=\"160\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"365\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">About · agenda</text> <rect x=\"285\" y=\"146\" width=\"160\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"365\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;h1&gt;About agenda&lt;/h1&gt;</text> <text x=\"365\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;p&gt;Community…&lt;/p&gt;</text> <rect x=\"500\" y=\"30\" width=\"200\" height=\"200\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"600\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the page sent</text> <text x=\"600\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;html&gt; &lt;head&gt;</text> <rect x=\"515\" y=\"88\" width=\"170\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"600\" y=\"105\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">About · agenda</text> <text x=\"600\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;header&gt; links &lt;/header&gt;</text> <rect x=\"515\" y=\"146\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"600\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;h1&gt;About agenda&lt;/h1&gt;</text> <text x=\"600\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;p&gt;Community…&lt;/p&gt;</text> <text x=\"600\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">&lt;/html&gt;</text> <path d=\"M445 101 L509 101\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#in-a)\"></path> <path d=\"M445 172 L509 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#in-a)\"></path> <text x=\"360\" y=\"256\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The child fills the parent's blocks and writes nothing outside them.</text> </svg>", "caption": "Every page of agenda is base.html with different blocks filled, so a change to the header is one edit in one file."}
```

A page this simple needs no view of its own. Lesson 2 promised `TemplateView`, and this is its
job: a class-based view that renders one template. Point a URL at it in `config/urls.py`:

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

## Three rules that save an afternoon

- **`{% extends %}` is the first tag.** Another tag before it, even `{% load %}`, stops the
  template with `{% extends "base.html" %} must be the first tag in the template.` Text and
  comments before it are allowed, and thrown away.
- **A child writes nothing outside its blocks.** Text there is not an error; it is silently thrown
  away, which is worse. Both were tried on this lesson's templates before being written here.
- **`{{ block.super }}`** inside a block prints the parent's version of it, for a child that wants
  to add to a block rather than replace it.
