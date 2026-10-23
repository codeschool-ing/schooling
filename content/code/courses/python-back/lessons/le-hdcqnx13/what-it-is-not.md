---
title: What the admin is not
version: 1
---

The admin is a back office for a handful of trusted people. Three things follow from that, and the
first is easy to miss because everything looks fine.

## It does not call your rules

Lesson 4 put the capacity rule in `services.register`, and the site's form calls it. The admin's add
form for a registration does not: it builds a `ModelForm` from the model and saves it. The async
workshop has 12 seats, and 12 registrations:

```
ana@vm:~/agenda$ psql agenda -c "SELECT count(*) FROM events_registration WHERE event_id = 2"
 count 
-------
    12
(1 row)

ana@vm:~/agenda$ TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -si -b ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&event=2&name=Elisa&email=elisa@example.org" http://127.0.0.1:8000/admin/events/registration/add/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /admin/events/registration/
ana@vm:~/agenda$ psql agenda -c "SELECT count(*) FROM events_registration WHERE event_id = 2"
 count 
-------
    13
(1 row)
```

**Thirteen registrations for twelve seats**, added by the superuser through the admin, and nothing
refused it. The unique constraint would have stopped a second Elisa, because the database enforces
that whoever writes; the capacity rule lives in a function the admin never calls. The admin's history
recorded it faithfully:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from django.contrib.admin.models import LogEntry; [print(e.action_time.date(), e.user, e) for e in LogEntry.objects.all()]"
14 objects imported automatically (use -v 2 for details).

2026-10-16 ana Added “Elisa for Async Python workshop”.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two ways into the registrations table. The site's form calls services.register, which locks the event, counts and inserts. The admin's add form saves a model form directly into the table, without the count. Both are stopped by the unique constraint on event and email; only the first is stopped by the capacity rule.\"> <defs><marker id=\"dr-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"dr-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <rect x=\"20\" y=\"30\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"55\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the site's form</text> <rect x=\"20\" y=\"120\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"145\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the admin's add form</text> <rect x=\"240\" y=\"30\" width=\"230\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"355\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">services.register()</text> <text x=\"355\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lock, count, insert</text> <rect x=\"540\" y=\"70\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"620\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">events_registration</text> <text x=\"620\" y=\"109\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">unique (event, email)</text> <path d=\"M170 50 L234 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#dr-a)\"></path> <path d=\"M470 50 L534 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#dr-a)\"></path> <path d=\"M170 140 L534 106\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#dr-b)\"></path> <text x=\"352\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a ModelForm, then save(): no count</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Both doors reach the constraint; only one passes the capacity rule.</text> </svg>", "caption": "A rule written in a function holds for the callers of that function. The admin is not one of them unless you make it one, or close its door."}
```

There are two honest fixes. One is to send the admin through the same door: a custom form whose
`clean` calls the rule, or a `save_model` that calls `register`. The other, which agenda takes, is to
**close the door**: registrations are made on the site, by the people registering, and organisers
see them and can cancel them. Two methods do it, one on the inline and one on `RegistrationAdmin`:

```
ana@vm:~/agenda$ grep -n -B1 -A1 'has_add_permission' events/admin.py
16-
17:    def has_add_permission(self, request, obj=None):
18-        return False
--
53-
54:    def has_add_permission(self, request):
55-        return False
```

`has_add_permission` returning `False` removes the *Add* links and the empty inline row, and the add
page itself now answers:

```
ana@vm:~/agenda$ curl -s -b ~/admin-cookies.txt -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/admin/events/registration/add/
403
```

Elisa's thirteenth registration was then deleted from the shell, which brings the workshop back to
its twelve.

## It is not the site

The admin's pages are built for people who know the data model. They show raw field names, accept
any value the model accepts, and assume the person knows what *Delete selected* on four hundred rows
will do. **Visitors never get staff accounts**, however convenient it would be to let them edit their
own registration there; that is a page on the site, with its own view and its own rules.

## It is a door worth guarding

The admin can change every row in the database, so its login is the most valuable one the site has.
It has no second factor of its own; libraries such as `django-otp` add one, and a staff account
without one is a password away from the whole database. Serve it only over HTTPS, which lesson 16
arranges; keep staff accounts few and their groups narrow, as the previous section did; and read the
history, which records every change made through the admin with who made it. Moving it from
`/admin/` to another address only stops automated guessing that looks for the default; it is not a
defence on its own.
