---
title: Restrições e transações: regras que valem sob carga
version: 1
---

A aula 3 deixou duas regras no Python: uma inscrição por endereço por evento, e não mais inscrições
que lugares. Python sozinho não consegue manter nenhuma das duas quando duas requisições chegam ao
mesmo tempo. Esta seção leva as duas para onde elas valem.

## Uma restrição que o banco garante

O modelo declarou `one_registration_per_email`. Tente quebrá-la pelo shell, criando a mesma
inscrição duas vezes:

```
ana@vm:~/agenda$ uv run python manage.py shell -c "from events.models import Event, Registration; e = Event.objects.get(slug=\"django-night\"); Registration.objects.create(event=e, name=\"Bruno\", email=\"bruno@example.org\"); Registration.objects.create(event=e, name=\"Bruno again\", email=\"bruno@example.org\")" 2>&1 | tail -2
django.db.utils.IntegrityError: duplicate key value violates unique constraint "one_registration_per_email"
DETAIL:  Key (event_id, email)=(1, bruno@example.org) already exists.
```

O segundo insert foi recusado pelo **PostgreSQL**, não pelo Django, e a mensagem diz a restrição e os
valores. Essa recusa acontece seja quem for que grave a linha: o site, o admin, um script, um colega
no `psql`. A descrição da tabela a mostra ao lado da chave primária e da chave estrangeira:

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

## Uma regra que nenhuma restrição expressa

"No máximo `capacity` linhas para este evento" depende de outras linhas, e uma restrição `CHECK` só
vê uma linha. Então a regra fica no Python e vai para uma função própria, `events/services.py`, que
todo mundo que inscreve chama:

```schooling-example
{"language": "python", "file": "events/services.py", "parts": [{"code": "# events/services.py\nfrom django.db import transaction\n\nfrom .models import Event, Registration\n\n\n", "note": "A inscrição vira uma função própria, para a view, o admin e um teste chamarem a mesma regra."}, {"code": "class RegistrationRefused(Exception):\n    pass\n\n\n", "note": "Uma exceção que diz por quê, e que a view transforma em erro de formulário."}, {"code": "def register(event_id, name, email):\n    with transaction.atomic():\n", "note": "**`transaction.atomic()`**: tudo aqui dentro é confirmado junto ou não é, e a trava abaixo dura até ele acabar."}, {"code": "        event = Event.objects.select_for_update().get(pk=event_id)\n", "note": "**O `select_for_update()` trava a linha do evento.** Uma segunda transação que pede a mesma trava espera aqui até a primeira confirmar."}, {"code": "        if event.registrations.count() >= event.capacity:\n            raise RegistrationRefused(\"This event is full.\")\n", "note": "A regra da capacidade, conferida agora por quem tem a trava."}, {"code": "        if event.registrations.filter(email=email).exists():\n            raise RegistrationRefused(\"This address is already registered.\")\n", "note": "Uma recusa amigável para o duplicado; a restrição de unicidade é a garantia se essa conferência um dia for pulada."}, {"code": "        return Registration.objects.create(event=event, name=name, email=email)\n"}]}
```

As views agora buscam os eventos no banco e chamam o `register`. Este é o `events/views.py` inteiro:

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

O `get_object_or_404` é o `Http404` da aula 2 numa linha só. Sem ninguém mais importá-lo, o
`events/data.py` pode sair: `rm events/data.py`.

## Vinte pessoas, doze lugares

A trava faz diferença? O `crowd.py` manda vinte inscrições para o workshop de async **ao mesmo
tempo**, de vinte threads, e conta o que aconteceu. Salve em `~/agenda`:

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

Ele rodou duas vezes. Na primeira, o `services.py` estava sem a trava, `Event.objects.get` em vez de
`Event.objects.select_for_update().get`, que é a lógica da aula 3 em forma de banco:

```
ana@vm:~/agenda$ uv run python manage.py shell < crowd.py
14 objects imported automatically (use -v 2 for details).

20 registered, 0 refused
20 rows for 12 seats
```

**Vinte inscrições para doze lugares**, e nada em lugar nenhum acusou erro. Toda thread contou as
linhas antes de qualquer outra ter inserido, então todas viram espaço. Depois com a trava de volta, e
as vinte linhas apagadas:

```
ana@vm:~/agenda$ grep -n 'select_for_update' events/services.py
13:        event = Event.objects.select_for_update().get(pk=event_id)
ana@vm:~/agenda$ uv run python manage.py shell < crowd.py
14 objects imported automatically (use -v 2 for details).

12 registered, 8 refused
12 rows for 12 seats
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo. Sem trava, a requisição A e a requisição B contam 11 inscrições cada uma e inserem uma cada, então o evento termina com 13 linhas para 12 lugares. Com select_for_update, A trava a linha do evento, conta 11, insere e confirma; B espera a trava o tempo todo, depois conta 12 e é recusada.\"> <defs><marker id=\"rc-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"rc-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"20\" y=\"24\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">sem trava: as duas veem 11, as duas inserem</text> <text x=\"20\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">requisição A</text> <text x=\"20\" y=\"92\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">requisição B</text> <rect x=\"110\" y=\"40\" width=\"150\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"55\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">count → 11</text> <rect x=\"280\" y=\"40\" width=\"150\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"355\" y=\"55\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">insert</text> <rect x=\"110\" y=\"80\" width=\"150\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"185\" y=\"95\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">count → 11</text> <rect x=\"280\" y=\"80\" width=\"150\" height=\"22\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"355\" y=\"95\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">insert</text> <text x=\"560\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">13 linhas, 12 lugares</text> <text x=\"20\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">com select_for_update: B espera a trava de A</text> <text x=\"20\" y=\"176\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">requisição A</text> <text x=\"20\" y=\"216\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">requisição B</text> <rect x=\"110\" y=\"164\" width=\"110\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"165\" y=\"179\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lock event</text> <rect x=\"225\" y=\"164\" width=\"100\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"179\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">count → 11</text> <rect x=\"330\" y=\"164\" width=\"80\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"370\" y=\"179\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">insert</text> <rect x=\"415\" y=\"164\" width=\"70\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"179\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">commit</text> <path d=\"M110 215 L485 215\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" fill=\"none\"></path> <text x=\"297\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esperando a trava</text> <rect x=\"490\" y=\"204\" width=\"110\" height=\"22\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"545\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">count → 12</text> <rect x=\"605\" y=\"204\" width=\"95\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"652\" y=\"219\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">refused</text> </svg>", "caption": "Uma contagem seguida de um insert são dois passos, e nada impede outra requisição de entrar no meio, a não ser uma trava na linha que as duas requisições precisam ler antes."}
```

Doze entram, oito são recusadas, e doze linhas. O `select_for_update()` virou `SELECT … FOR UPDATE`,
que trava a linha do evento até a transação confirmar; cada thread esperou a vez de contar, então a
contagem que viu era sempre verdadeira. **A trava só funciona dentro de `transaction.atomic()`**,
porque uma trava dura o mesmo que a transação dela, e o Django recusa o `select_for_update()` fora de
uma. No SQLite, que não tem travas de linha, a chamada não faz nada, o que é mais um motivo para esta
aula ter ido para o PostgreSQL.

## O site, no banco

Com o `runserver` rodando de novo:

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

A inscrição anterior do Bruno no Django Night é a única linha desse evento. O formulário recusou o
endereço dele uma segunda vez com a mensagem do serviço, o workshop está cheio por causa da multidão,
e um slug desconhecido é um 404 do `get_object_or_404`.
