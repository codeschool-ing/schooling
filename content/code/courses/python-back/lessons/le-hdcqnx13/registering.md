---
title: Registering a model
version: 1
---

A model appears in the admin when it is **registered**. The shortest registration is one line per
model. Replace `events/admin.py`, which `startapp` left empty:

```python
# events/admin.py
from django.contrib import admin

from .models import Event, Registration

admin.site.register(Event)
admin.site.register(Registration)
```

`runserver` reloads, and the front page has a new section:

```
ana@vm:~/agenda$ page /admin/ | sed -n "/^Site administration/,/^Recent actions/p"
Site administration

      Authentication and Authorization
Model name Add link Change or view list link
  Groups   Add      Change
  Users    Add      Change

                     Events
 Model name   Add link Change or view list link
   Events     Add      Change
Registrations Add      Change

Recent actions
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"One registered model admin produces five pages: the list, add, change, delete and history, each at its own address under /admin/events/event/. Each page checks one permission before it shows anything: view, add, change, delete, and view again for the history.\"> <defs><marker id=\"pg5-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"90\" width=\"170\" height=\"60\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"105\" y=\"115\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">@admin.register(Event)</text> <text x=\"105\" y=\"133\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">class EventAdmin</text> <rect x=\"250\" y=\"20\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"40\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the list</text> <text x=\"540\" y=\"40\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/admin/events/event/</text> <rect x=\"570\" y=\"24\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"40\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.view_event</text> <path d=\"M190 120 L244 36\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <rect x=\"250\" y=\"62\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"82\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">add</text> <text x=\"540\" y=\"82\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…/event/add/</text> <rect x=\"570\" y=\"66\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.add_event</text> <path d=\"M190 120 L244 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <rect x=\"250\" y=\"104\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"124\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">change</text> <text x=\"540\" y=\"124\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…/event/3/change/</text> <rect x=\"570\" y=\"108\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.change_event</text> <path d=\"M190 120 L244 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <rect x=\"250\" y=\"146\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"166\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">delete</text> <text x=\"540\" y=\"166\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…/event/3/delete/</text> <rect x=\"570\" y=\"150\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"166\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.delete_event</text> <path d=\"M190 120 L244 162\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <rect x=\"250\" y=\"188\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"262\" y=\"208\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">history</text> <text x=\"540\" y=\"208\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">…/event/3/history/</text> <rect x=\"570\" y=\"192\" width=\"130\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"635\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">events.view_event</text> <path d=\"M190 120 L244 204\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pg5-a)\"></path> <text x=\"635\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">checked on every request</text> </svg>", "caption": "Registering a model is one decorator; the five pages and their permission checks come with it, which is the back office lesson 1 called free."}
```

The list page works already, with nothing configured:

```
ana@vm:~/agenda$ page /admin/events/event/ | sed -n "/^Select event to change/,/^[0-9]* events/p"
Select event to change

  * Add event

Action: [- Select an option -  ] Run 0 of 3 selected

[ ]         Event
[ ]      Django Night
[ ] Async Python workshop
[ ]      Testing dojo

Pagination events

3 events
```

Each row is the event's `__str__`, the title, which is why lesson 4 wrote one. A model without
`__str__` shows `Event object (1)` here, which is the first sign that one is missing.

## What came with the line

Without another line of code, `admin.site.register(Event)` gave agenda:

- a **list** of every event, paginated, with a checkbox per row and a delete action;
- an **add** form and a **change** form built from the model's fields, with each field's
  validation: a slug that is not a slug, a capacity below zero, a title over 200 characters, all
  refused with a message beside the field;
- a **delete** page that lists what else will be deleted with the row, because the foreign key
  says `CASCADE`, and asks for confirmation;
- a **history** of every change made through the admin, with who made it and when.

That is a back office a team would otherwise spend weeks building, and the reason lesson 1 named
the admin among Django's assumptions. The rest of this lesson configures it, and the last section is
about what it is not for.
