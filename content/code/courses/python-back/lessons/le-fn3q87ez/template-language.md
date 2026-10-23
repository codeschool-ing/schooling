---
title: The template language: variables, filters and tags
version: 1
---

Lesson 2's views returned JSON. A site for people returns **HTML**, and writing HTML inside Python
strings is the mistake every framework exists to prevent. Django's answer is the **template**: an
HTML file with holes in it, which a view fills with a dictionary called the **context**.

First, the events get real dates. A date written as a string can be printed but not formatted,
compared or converted to another zone, so `events/data.py` now builds `datetime` values in São
Paulo's zone. The empty list at the bottom is where lesson 3 keeps registrations until lesson 4
gives them a table:

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

## A template

Django looks for templates in a `templates/` directory inside each installed app, because
`APP_DIRS` is `True` in `settings.py`. **The app's name is repeated inside it**,
`events/templates/events/`, so that `events/event_list.html` cannot collide with another app's
`event_list.html`: Django searches every app's directory in order and takes the first match. Save
this as `events/templates/events/event_list.html`:

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

The view that fills it is in the next section but one, with the rest of `events/views.py`; its
list half is three lines:

```python
def event_list(request):
    q = request.GET.get("q", "")
    events = [e for e in EVENTS if q.lower() in e["title"].lower()]
    return render(request, "events/event_list.html", {"events": events, "q": q})
```

With all of this lesson's files in place, the page comes out like this:

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

## The three things in a template

| syntax | what it is | in this template |
|---|---|---|
| `{{ … }}` | a **variable**, printed | `{{ event.title }}` |
| `{{ …\|… }}` | a variable through a **filter** | `{{ event.starts_at\|date:"D j M, H:i" }}` |
| `{% … %}` | a **tag**: logic, loops, loading | `{% for %}`, `{% if %}`, `{% url %}` |

**The dot does every kind of lookup.** `event.title` tries `event["title"]` first, then an
attribute, then a list index, which is why the same template works for these dictionaries now and
for the model objects of lesson 4 without a change.

**Filters do the formatting.** `date:"D j M, H:i"` printed `Thu 12 Nov, 19:00`, in São Paulo time,
because `TIME_ZONE` says so. `length` counted the list and `pluralize` added the `s` of `events`.
Django ships about sixty filters, and a template that needs more logic than a filter gives is asking
for that logic to move into the view.

**Tags do the control.** `{% for %}` loops, and its `{% empty %}` branch says what to print when the
list is empty, which saves an `if` around every loop. `{% url 'events:detail' event.slug %}` is
lesson 2's `reverse` inside a template: the link is built from the name of the pattern, so no
address is written twice.

The blank lines at the top of the page and between the items are the lines the tags stood on. The
browser ignores them, and so should you.
