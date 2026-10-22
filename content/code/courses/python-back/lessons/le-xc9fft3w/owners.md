---
title: Who organises what
version: 1
---

**A permission says what kind of thing a user may do, and nothing about which row.** Lesson 5's
Organisers group gave Bruno `events.change_event`, so the admin lets him change every event; agenda's
rule is that an organiser changes **their own**. Rows need an owner. Add one to `Event`, in
`events/models.py`:

```python
# events/models.py
from django.conf import settings
from django.db import models


class Event(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    starts_at = models.DateTimeField()
    venue = models.CharField(max_length=200)
    capacity = models.PositiveIntegerField()
    description = models.TextField(blank=True)
    organiser = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="organised_events",
    )

    class Meta:
        ordering = ["starts_at"]

    def __str__(self):
        return self.title


class Registration(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name="registrations")
    name = models.CharField(max_length=100)
    email = models.EmailField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["event", "email"], name="one_registration_per_email"),
        ]

    def __str__(self):
        return f"{self.name} for {self.event}"
```

`settings.AUTH_USER_MODEL` rather than `User` itself, so that a project with its own user model
needs no change here. **`null=True`**, because the three events exist already and nobody organises
them yet, and **`on_delete=models.PROTECT`**, because deleting a user who organises events should
be refused rather than delete the events with them or leave them orphaned silently:

```
ana@vm:~/agenda$ uv run python manage.py makemigrations events
Migrations for 'events':
  events/migrations/0003_event_organiser.py
    + Add field organiser to event
ana@vm:~/agenda$ uv run python manage.py migrate events
Operations to perform:
  Apply all migrations: events
Running migrations:
  Applying events.0003_event_organiser... OK
```

Then the owners, and what each person may do according to Django's permissions. `owners.py`:

```python
# owners.py
from django.contrib.auth.models import User

from events.models import Event

ana = User.objects.get(username="ana")
bruno = User.objects.get(username="bruno")
carla = User.objects.get(username="carla")

Event.objects.filter(slug__in=["django-night", "testing-dojo"]).update(organiser=bruno)
Event.objects.filter(slug="async-workshop").update(organiser=ana)

for event in Event.objects.select_related("organiser"):
    print(event.slug, "organised by", event.organiser)
for user in (ana, bruno, carla):
    print(user.username, [user.has_perm(f"events.{action}_event") for action in ("add", "change", "delete")])
```

```
ana@vm:~/agenda$ uv run python manage.py shell -v 0 < owners.py
django-night organised by bruno
async-workshop organised by ana
testing-dojo organised by bruno
ana [True, True, True]
bruno [False, True, False]
carla [False, False, False]
```

The list is `add`, `change`, `delete`. **Ana is a superuser** and has all three; **Bruno has
`change` only**, from his group; **Carla has none**. Bruno organises two of the three events, and
his permission does not know that:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 234\" role=\"img\" aria-label=\"A grid for Bruno. His Organisers group gives him events.change_event on all three events. He is the organiser of django-night and testing-dojo, not of async-workshop. So a PATCH answers 200 on django-night and testing-dojo and 403 on async-workshop.\"> <text x=\"20\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Bruno, on each event</text> <text x=\"250\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Organisers group</text> <text x=\"250\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">events.change_event</text> <text x=\"410\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">organiser =</text> <text x=\"410\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bruno?</text> <text x=\"570\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PATCH</text> <text x=\"570\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">answer</text> <text x=\"150\" y=\"102\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">django-night</text> <rect x=\"200\" y=\"82\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">yes</text> <rect x=\"360\" y=\"82\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">yes</text> <rect x=\"520\" y=\"82\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"570\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200</text> <text x=\"150\" y=\"142\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">async-workshop</text> <rect x=\"200\" y=\"122\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">yes</text> <rect x=\"360\" y=\"122\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"410\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no</text> <rect x=\"520\" y=\"122\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"570\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">403</text> <text x=\"150\" y=\"182\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">testing-dojo</text> <rect x=\"200\" y=\"162\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">yes</text> <rect x=\"360\" y=\"162\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">yes</text> <rect x=\"520\" y=\"162\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"570\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The group says what kind of thing he may do; the row says where.</text> </svg>", "caption": "Bruno's permission holds on every event; ownership narrows it to two. doors.py measured the last column."}
```
