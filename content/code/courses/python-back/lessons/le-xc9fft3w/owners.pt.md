---
title: Quem organiza o quê
version: 1
---

**Uma permissão diz que tipo de coisa um usuário pode fazer, e nada sobre qual linha.** O grupo
Organisers da aula 5 deu ao Bruno `events.change_event`, então o admin o deixa mudar todo evento; a
regra do agenda é que um organizador muda **os seus**. Linhas precisam de dono. Acrescente um ao
`Event`, em `events/models.py`:

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

`settings.AUTH_USER_MODEL` em vez do próprio `User`, para que um projeto com um model de usuário
próprio não precise mudar nada aqui. **`null=True`**, porque os três eventos já existem e ninguém os
organiza ainda, e **`on_delete=models.PROTECT`**, porque apagar um usuário que organiza eventos deve
ser recusado, em vez de apagar os eventos junto ou deixá-los órfãos em silêncio:

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

Depois os donos, e o que cada pessoa pode fazer segundo as permissões do Django. O `owners.py`:

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

A lista é `add`, `change`, `delete`. **A Ana é superusuária** e tem as três; **o Bruno tem só
`change`**, pelo grupo; **a Carla não tem nenhuma**. O Bruno organiza dois dos três eventos, e a
permissão dele não sabe disso:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 234\" role=\"img\" aria-label=\"Uma grade para o Bruno. O grupo Organisers dá a ele events.change_event nos três eventos. Ele é o organizador do django-night e do testing-dojo, não do async-workshop. Então um PATCH responde 200 no django-night e no testing-dojo e 403 no async-workshop.\"> <text x=\"20\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Bruno, em cada evento</text> <text x=\"250\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">grupo Organisers</text> <text x=\"250\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">events.change_event</text> <text x=\"410\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">organizador =</text> <text x=\"410\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bruno?</text> <text x=\"570\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PATCH</text> <text x=\"570\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resposta</text> <text x=\"150\" y=\"102\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">django-night</text> <rect x=\"200\" y=\"82\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sim</text> <rect x=\"360\" y=\"82\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sim</text> <rect x=\"520\" y=\"82\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"570\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200</text> <text x=\"150\" y=\"142\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">async-workshop</text> <rect x=\"200\" y=\"122\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sim</text> <rect x=\"360\" y=\"122\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"410\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não</text> <rect x=\"520\" y=\"122\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"570\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">403</text> <text x=\"150\" y=\"182\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">testing-dojo</text> <rect x=\"200\" y=\"162\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sim</text> <rect x=\"360\" y=\"162\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sim</text> <rect x=\"520\" y=\"162\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"570\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">O grupo diz que tipo de coisa ele pode fazer; a linha diz onde.</text> </svg>", "caption": "A permissão do Bruno vale em todo evento; a posse a estreita a dois. O doors.py mediu a última coluna.", "same": ["PATCH"]}
```
