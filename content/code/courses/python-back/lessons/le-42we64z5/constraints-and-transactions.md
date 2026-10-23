---
title: Constraints and transactions: rules that hold under load
version: 1
---

Lesson 3 left two rules in Python: one registration per address per event, and no more
registrations than seats. Python alone cannot keep either when two requests arrive at once. This
section moves both to where they hold.

## A constraint the database enforces

The model declared `one_registration_per_email`. Try to break it from the shell, by creating the same
registration twice:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from events.models import Event, Registration; e = Event.objects.get(slug=\"django-night\"); Registration.objects.create(event=e, name=\"Bruno\", email=\"bruno@example.org\"); Registration.objects.create(event=e, name=\"Bruno again\", email=\"bruno@example.org\")" 2>&1 | tail -2
django.db.utils.IntegrityError: duplicate key value violates unique constraint "one_registration_per_email"
DETAIL:  Key (event_id, email)=(1, bruno@example.org) already exists.
```

The second insert was refused by **PostgreSQL**, not by Django, and the message names the constraint
and the values. That refusal happens whoever writes the row: the site, the admin, a script, a
colleague in `psql`. The table's description shows it beside the primary key and the foreign key:

```
ana@vm:~/agenda$ psql agenda -c "\d events_registration" | tail -8
 event_id   | bigint                   |           | not null | 
Indexes:
    "events_registration_pkey" PRIMARY KEY, btree (id)
    "events_registration_event_id_75b6f198" btree (event_id)
    "one_registration_per_email" UNIQUE CONSTRAINT, btree (event_id, email)
Foreign-key constraints:
    "events_registration_event_id_75b6f198_fk_events_event_id" FOREIGN KEY (event_id) REFERENCES events_event(id) DEFERRABLE INITIALLY DEFERRED
```

## A rule no constraint can express

"At most `capacity` rows for this event" depends on other rows, and a `CHECK` constraint only sees
one row. So the rule stays in Python and moves into a function of its own, `events/services.py`,
which every caller uses:

```schooling-example
{"language": "python", "file": "events/services.py", "parts": [{"code": "# events/services.py\nfrom django.db import transaction\n\nfrom .models import Event, Registration\n\n\n", "note": "Registration becomes a function of its own, so the view, the admin and a test can all call the same rule."}, {"code": "class RegistrationRefused(Exception):\n    pass\n\n\n", "note": "An exception that says why, which the view turns into a form error."}, {"code": "def register(event_id, name, email):\n    with transaction.atomic():\n", "note": "**`transaction.atomic()`**: everything inside commits together or not at all, and the lock below lasts until it ends."}, {"code": "        event = Event.objects.select_for_update().get(pk=event_id)\n", "note": "**`select_for_update()` locks the event's row.** A second transaction asking for the same lock waits here until the first commits."}, {"code": "        if event.registrations.count() >= event.capacity:\n            raise RegistrationRefused(\"This event is full.\")\n", "note": "The capacity rule, now checked by whoever holds the lock."}, {"code": "        if event.registrations.filter(email=email).exists():\n            raise RegistrationRefused(\"This address is already registered.\")\n", "note": "A friendly refusal for the duplicate; the unique constraint is the backstop if this check is ever bypassed."}, {"code": "        return Registration.objects.create(event=event, name=name, email=email)\n"}]}
```

The views now look events up in the database and call `register`. This is the whole of
`events/views.py`:

```python
# events/views.py
from django.shortcuts import get_object_or_404, redirect, render

from .forms import RegistrationForm
from .models import Event
from .services import RegistrationRefused, register


def event_list(request):
    q = request.GET.get("q", "")
    events = Event.objects.filter(title__icontains=q)
    return render(request, "events/event_list.html", {"events": events, "q": q})


def event_detail(request, slug):
    event = get_object_or_404(Event, slug=slug)
    if request.method == "POST":
        form = RegistrationForm(request.POST)
        if form.is_valid():
            try:
                register(event.pk, **form.cleaned_data)
            except RegistrationRefused as refusal:
                form.add_error(None, str(refusal))
            else:
                return redirect("events:detail", slug=slug)
    else:
        form = RegistrationForm()
    context = {"event": event, "form": form, "taken": event.registrations.count()}
    return render(request, "events/event_detail.html", context)
```

`get_object_or_404` is lesson 2's `Http404` in one line. With nothing importing it any more,
`events/data.py` can go: `rm events/data.py`.

## Twenty people, twelve seats

Does the lock matter? `crowd.py` sends twenty registrations for the async workshop **at the same
time**, from twenty threads, and counts what happened. Save it in `~/agenda`:

```python
# crowd.py
from concurrent.futures import ThreadPoolExecutor

from django.db import connection

from events.models import Event
from events.services import RegistrationRefused, register

event = Event.objects.get(slug="async-workshop")


def attempt(i):
    try:
        register(event.pk, f"Person {i}", f"p{i}@example.org")
        return "registered"
    except RegistrationRefused:
        return "refused"
    finally:
        connection.close()


with ThreadPoolExecutor(max_workers=20) as pool:
    results = list(pool.map(attempt, range(20)))

print(results.count("registered"), "registered,", results.count("refused"), "refused")
print(event.registrations.count(), "rows for", event.capacity, "seats")
```

It was run twice. The first time, `services.py` had its lock taken out, `Event.objects.get` instead
of `Event.objects.select_for_update().get`, which is lesson 3's logic in database form:

```
ana@vm:~/agenda$ uv run python manage.py shell < crowd.py
14 objects imported automatically (use -v 2 for details).

20 registered, 0 refused
20 rows for 12 seats
```

**Twenty registrations for twelve seats**, and nothing anywhere reported an error. Every thread
counted the rows before any of the others had inserted, so every one of them saw room. Then with the
lock back, after deleting those twenty rows:

```
ana@vm:~/agenda$ grep -n 'select_for_update' events/services.py
13:        event = Event.objects.select_for_update().get(pk=event_id)
ana@vm:~/agenda$ uv run python manage.py shell < crowd.py
14 objects imported automatically (use -v 2 for details).

12 registered, 8 refused
12 rows for 12 seats
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two timelines. Without a lock, request A and request B each count 11 registrations and each insert one, so the event ends with 13 rows for 12 seats. With select_for_update, A locks the event row, counts 11, inserts and commits; B waits for the lock the whole time, then counts 12 and is refused.\"> <defs><marker id=\"rc-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"rc-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"24\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">without a lock: both see 11, both insert</text> <text x=\"20\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request A</text> <text x=\"20\" y=\"92\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request B</text> <rect x=\"110\" y=\"40\" width=\"150\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"55\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">count → 11</text> <rect x=\"280\" y=\"40\" width=\"150\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"355\" y=\"55\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">insert</text> <rect x=\"110\" y=\"80\" width=\"150\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"95\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">count → 11</text> <rect x=\"280\" y=\"80\" width=\"150\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"355\" y=\"95\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">insert</text> <text x=\"560\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">13 rows, 12 seats</text> <text x=\"20\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">with select_for_update: B waits for A's lock</text> <text x=\"20\" y=\"176\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request A</text> <text x=\"20\" y=\"216\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request B</text> <rect x=\"110\" y=\"164\" width=\"110\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"165\" y=\"179\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lock event</text> <rect x=\"225\" y=\"164\" width=\"100\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"179\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">count → 11</text> <rect x=\"330\" y=\"164\" width=\"80\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"370\" y=\"179\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">insert</text> <rect x=\"415\" y=\"164\" width=\"70\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"179\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">commit</text> <path d=\"M110 215 L485 215\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" fill=\"none\"></path> <text x=\"297\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waiting for the lock</text> <rect x=\"490\" y=\"204\" width=\"110\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"545\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">count → 12</text> <rect x=\"605\" y=\"204\" width=\"95\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"652\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">refused</text> </svg>", "caption": "A count followed by an insert is two steps, and nothing stops another request between them, except a lock on the row both requests must read first."}
```

Twelve in, eight refused, and twelve rows. `select_for_update()` became `SELECT … FOR UPDATE`, which
locks the event's row until the transaction commits; each thread waited its turn to count, so the
count it saw was always true. **The lock only works inside `transaction.atomic()`**, because a lock
lasts as long as its transaction, and Django refuses `select_for_update()` outside one. On SQLite,
which has no row locks, the call does nothing, which is one more reason this lesson moved to
PostgreSQL.

## The site, on the database

With `runserver` started again:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/django-night/ | grep seats
<p>1 of 40 seats taken.</p>
ana@vm:~/agenda$ curl -s -c cookies.txt -o /dev/null http://127.0.0.1:8000/events/django-night/; TOKEN=$(grep csrftoken cookies.txt | cut -f7); curl -s -b cookies.txt -d "csrfmiddlewaretoken=$TOKEN&name=Bruno&email=bruno@example.org" http://127.0.0.1:8000/events/django-night/ | grep errorlist
  <ul class="errorlist nonfield"><li>This address is already registered.</li></ul>
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/async-workshop/ | grep seats
<p>12 of 12 seats taken.</p>
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/events/nope/ -o /dev/null -w "%{http_code}\n"
404
```

Bruno's earlier registration for Django Night is the one row on that event. The form refused his
address a second time with the service's message, the workshop is full from the crowd, and an
unknown slug is a 404 from `get_object_or_404`.
