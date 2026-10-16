---
title: A form, its token, and the redirect after it
version: 1
---

Registering for an event is a **form**: a name, an email address, a button. Django's `Form` class
describes the fields once and does three jobs with that description: it writes the HTML inputs, it
validates what comes back, and it converts it to Python values. Save this as `events/forms.py`:

```python
# events/forms.py
from django import forms


class RegistrationForm(forms.Form):
    name = forms.CharField(max_length=100)
    email = forms.EmailField()
```

`EmailField` is a `CharField` with an email validator. Each field is **required** unless it says
otherwise, and the validation runs on the server, whatever the browser did.

## The view, answering both methods

The detail view now shows the form on a GET and processes it on a POST. This is the whole of
`events/views.py`, with the list view of the template section:

```schooling-example
{"language": "python", "file": "events/views.py", "parts": [{"code": "# events/views.py\nfrom django.http import Http404\nfrom django.shortcuts import redirect, render\n\nfrom .data import EVENTS, REGISTRATIONS\nfrom .forms import RegistrationForm\n\n\n", "note": "Two imports are new: `render` builds a response from a template, and `redirect` answers 302."}, {"code": "def find_event(slug):\n    for event in EVENTS:\n        if event[\"slug\"] == slug:\n            return event\n    raise Http404(f\"No event called {slug}\")\n\n\n", "note": "**Looking an event up moved into a function**, because both views need it."}, {"code": "def event_list(request):\n    q = request.GET.get(\"q\", \"\")\n    events = [e for e in EVENTS if q.lower() in e[\"title\"].lower()]\n    return render(request, \"events/event_list.html\", {\"events\": events, \"q\": q})\n\n\n", "note": "`render(request, template, context)` fills the template with the dictionary and returns an `HttpResponse`."}, {"code": "def event_detail(request, slug):\n    event = find_event(slug)\n    taken = sum(1 for r in REGISTRATIONS if r[\"slug\"] == slug)\n", "note": "The same URL answers both methods: GET shows the form, POST submits it."}, {"code": "    if request.method == \"POST\":\n        form = RegistrationForm(request.POST)\n", "note": "**A bound form**, built from `request.POST`. `is_valid()` runs every field's checks and fills `cleaned_data`."}, {"code": "        if form.is_valid() and taken >= event[\"capacity\"]:\n            form.add_error(None, \"This event is full.\")\n", "note": "A rule no field knows about, added as an error of the whole form. After `add_error`, `is_valid()` is false."}, {"code": "        if form.is_valid():\n            REGISTRATIONS.append({\"slug\": slug, **form.cleaned_data})\n            return redirect(\"events:detail\", slug=slug)\n", "note": "**Success redirects** instead of rendering, so a reload cannot post twice."}, {"code": "    else:\n        form = RegistrationForm()\n    context = {\"event\": event, \"form\": form, \"taken\": taken}\n    return render(request, \"events/event_detail.html\", context)\n", "note": "An unbound form for a GET, and both cases fall through to the same `render`."}]}
```

The detail URL points at a function again rather than lesson 2's class, in `events/urls.py`:

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

And the detail template, `events/templates/events/event_detail.html`:

```html
{# events/templates/events/event_detail.html #}
{% extends "base.html" %}

{% block title %}{{ event.title }} · agenda{% endblock %}

{% block content %}
<h1>{{ event.title }}</h1>
<p>{{ event.starts_at|date:"l j F Y, H:i" }}, {{ event.venue }}</p>
<p>{{ taken }} of {{ event.capacity }} seats taken.</p>

<form method="post">
  {% csrf_token %}
  {{ form.as_p }}
  <button type="submit">Register</button>
</form>
{% endblock %}
```

`{{ form.as_p }}` writes each field as a paragraph with its label, its input and its errors.
`{% csrf_token %}` writes the hidden field this whole section depends on. Here is the result:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/ | sed -n "/<main>/,/<\/main>/p"
  <main>
    
<h1>Async Python workshop</h1>
<p>Thursday 19 November 2026, 14:00, Public Library, lab 2</p>
<p>0 of 12 seats taken.</p>

<form method="post">
  <input type="hidden" name="csrfmiddlewaretoken" value="MYBHQiLxmaEdu2q7VrHz55wlCzEd6kcDTv3vqts8ZlevCwy0tdsrqYLkHOMYDVsc">
  <p>
    <label for="id_name">Name:</label>
    <input type="text" name="name" maxlength="100" required id="id_name">
    
    
  </p>

  
  <p>
    <label for="id_email">Email:</label>
    <input type="email" name="email" maxlength="320" required id="id_email">
    
    
      
    
  </p>
  <button type="submit">Register</button>
</form>

  </main>
```

`required`, `maxlength` and `type="email"` came from the field definitions, so the browser checks
them before sending. **That is a convenience for the person, not a check for the server**: anything
that does not use the page, curl for one, sends whatever it likes.

## The token

The hidden `csrfmiddlewaretoken` is the answer to lesson 2's 403. A POST without it is refused,
exactly as before:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" -d "name=Bruno&email=bruno@example.org" http://127.0.0.1:8000/events/async-workshop/
403
```

The GET that served the page also set a cookie, `csrftoken`, and the hidden field carries a value
derived from the same secret. **A POST is accepted only when the two match.** A page on another
site can make your browser post to agenda, and the browser will even attach agenda's cookies, but
that page cannot read agenda's HTML to learn the token, so its POST fails. This is cross-site
request forgery, CSRF, and the middleware and the template tag are the whole defence.

curl can do what a browser does: keep the cookie, and send the token back.

```
ana@vm:~/agenda$ curl -s -c cookies.txt -o /dev/null http://127.0.0.1:8000/events/async-workshop/ && grep -o "csrftoken.*" cookies.txt | cut -c1-24
csrftoken	koSxdqUYgJvQ44
ana@vm:~/agenda$ TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -si -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Bruno&email=bruno@example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /events/async-workshop/
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/ | grep seats
<p>1 of 12 seats taken.</p>
```

The registration was accepted, and the answer was not a page but **302 Found**, back to the same
address. That is the **Post/Redirect/Get** pattern: after a POST that changed something, redirect,
so the page the person ends up on came from a GET. Reloading it repeats the GET, and nobody gets
registered twice by pressing F5.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"A sequence between the browser and agenda. The browser gets the page, which sets a csrftoken cookie and carries the same secret in a hidden field. It posts the form with the cookie and the token, and agenda saves the registration and answers 302 to the same address. The browser follows it with a GET and sees the updated count. A form posted from another site carries no token and is refused with 403.\"> <defs><marker id=\"pg-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"pg-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"110\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the browser</text> <text x=\"560\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">agenda</text> <path d=\"M110 36 L110 300\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M560 36 L560 300\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M114 60 L554 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"54\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /events/async-workshop/</text> <path d=\"M556 90 L116 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200: the form, a hidden token</text> <text x=\"335\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Set-Cookie: csrftoken=…</text> <path d=\"M114 140 L554 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST: cookie + token + name, email</text> <path d=\"M556 170 L116 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">302 Location: /events/async-workshop/</text> <text x=\"335\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">saved; now send the browser away</text> <path d=\"M114 220 L554 220\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /events/async-workshop/</text> <path d=\"M556 250 L116 250\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg-a)\"></path> <text x=\"335\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200: 1 of 12 seats taken</text> <text x=\"335\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reloading this page repeats a GET, not the POST</text> <path d=\"M300 288 L554 288\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#pg-b)\"></path> <text x=\"296\" y=\"292\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a form on another site: no token, 403</text> </svg>", "caption": "Two defences in one exchange: the token proves the form came from this site, and the redirect after a successful POST means reloading the page can never register somebody twice."}
```

## When the form is wrong

An address without an `@`:

```
ana@vm:~/agenda$ TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -s -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Carla&email=carla.example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -B1 -A1 errorlist

  <ul class="errorlist" id="id_email_error"><li>Enter a valid email address.</li></ul>
  <p>
```

`is_valid()` was false, so the view fell through to `render` with the **bound** form, and the
template printed the error beside the field, with what the person typed still in it. The message,
`Enter a valid email address.`, is the validator's own.

## A rule no field knows

Twelve seats. Eleven more registrations fill them:

```
ana@vm:~/agenda$ TOKEN=$(grep csrftoken cookies.txt | cut -f7); for i in $(seq 2 12); do curl -s -o /dev/null -w "%{http_code} " -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Person $i&email=p$i@example.org" http://127.0.0.1:8000/events/async-workshop/; done; echo
302 302 302 302 302 302 302 302 302 302 302 
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/ | grep seats
<p>12 of 12 seats taken.</p>
ana@vm:~/agenda$ TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -s -w "%{http_code}\n" -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Davi&email=davi@example.org" http://127.0.0.1:8000/events/async-workshop/ | grep -E "errorlist|^[0-9]{3}$"
  <ul class="errorlist nonfield"><li>This event is full.</li></ul>
200
```

The thirteenth got the form back with `This event is full.` and a 200, because nothing was saved and
there is nowhere to redirect to. The error belongs to the whole form, not to a field, which is why
the view added it with `add_error(None, …)` and the template printed it above the fields.

**Two warnings about this rule as it stands.** The registrations live in a Python list, so they
vanish when `runserver` restarts, and the check is a count followed by an append: two requests
arriving together can both see eleven and both append. Lesson 4 moves registrations into
PostgreSQL and makes the database enforce both the uniqueness of an email per event and the
capacity, which is where a rule that must hold under load belongs.
