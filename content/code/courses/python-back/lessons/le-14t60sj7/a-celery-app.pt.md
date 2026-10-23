---
title: Um app Celery e a primeira tarefa
version: 1
---

O Celery precisa de um objeto **app**, que conhece o broker e acha as tarefas. Num projeto Django ele
mora ao lado das configurações, em `config/celery.py`:

```python
# config/celery.py
import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

app = Celery("agenda")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
```

O `config_from_object` lê toda configuração que começa com `CELERY_`, então o broker vai no
`settings.py` com o resto; o `autodiscover_tasks` importa o `tasks.py` de todo app instalado. O app
precisa ser carregado quando o Django sobe, para que os decoradores `@shared_task` o encontrem; é para
isso que serve o `config/__init__.py`:

```python
# config/__init__.py
from .celery import app as celery_app

__all__ = ("celery_app",)
```

Acrescente o endereço do broker ao fim do `config/settings.py`, e tire de novo a chamada de e-mail e o
import dela do `events/api.py`:

```
ana@vm:~/agenda$ tail -1 config/settings.py
CELERY_BROKER_URL = "redis://127.0.0.1:6379/0"
ana@vm:~/agenda$ grep -c 'mail' events/api.py
0
```

Uma **tarefa** é uma função que um worker roda. O `events/tasks.py`:

```python
# events/tasks.py
from celery import shared_task

from . import mail
from .models import Registration


@shared_task
def send_confirmation(registration_id):
    registration = Registration.objects.select_related("event").get(pk=registration_id)
    mail.confirmation(registration)
```

**Ela recebe um id, não uma inscrição.** Os argumentos viajam pelo Redis como JSON, e uma instância de
model não é JSON; o id é, e o worker lê a linha como ela está quando a tarefa roda. O `register` a
dispara, em `events/services.py`:

```schooling-example
{"language": "python", "file": "events/services.py", "parts": [{"code": "# events/services.py\nfrom django.db import transaction\n\nfrom .models import Event, Registration\nfrom .tasks import send_confirmation\n\n\nclass RegistrationRefused(Exception):\n    pass\n\n\n", "note": "O `services.py` agora importa a tarefa que dispara."}, {"code": "def register(event_id, name, email):\n    with transaction.atomic():\n        event = Event.objects.select_for_update().get(pk=event_id)\n        if event.registrations.count() >= event.capacity:\n            raise RegistrationRefused(\"This event is full.\")\n        if event.registrations.filter(email=email).exists():\n            raise RegistrationRefused(\"This address is already registered.\")\n        registration = Registration.objects.create(event=event, name=name, email=email)\n", "note": "A mesma transação com lock da aula 4."}, {"code": "        transaction.on_commit(lambda: send_confirmation.delay(registration.pk))\n        return registration\n", "note": "**O `on_commit` espera o commit.** Uma tarefa posta na fila dentro da transação poderia chegar a um worker rápido antes de a linha existir, ou para uma linha que um rollback depois remove."}]}
```

O `.delay(...)` manda a mensagem e volta na hora; a função roda em outro processo.

## O worker

Suba de novo o servidor de e-mail, depois o worker, num terminal próprio:

```
ana@vm:~/agenda$ uv run celery -A config worker -l info
 
 -------------- celery@vm v5.6.3 (recovery)
--- ***** ----- 
-- ******* ---- Linux-6.18.44-fc-v153-x86_64-with-glibc2.39 2026-10-22 21:18:20
- *** --- * --- 
- ** ---------- [config]
- ** ---------- .> app:         agenda:0x7fa349fcd5b0
- ** ---------- .> transport:   redis://127.0.0.1:6379/0
- ** ---------- .> results:     disabled://
- *** --- * --- .> concurrency: 4 (prefork)
-- ******* ---- .> task events: OFF (enable -E to monitor tasks in this worker)
--- ***** ----- 
 -------------- [queues]
                .> celery           exchange=celery(direct) key=celery
                

[tasks]
  . events.tasks.send_confirmation

[2026-10-22 21:18:21,053: INFO/MainProcess] Connected to redis://127.0.0.1:6379/0
[2026-10-22 21:18:21,055: INFO/MainProcess] mingle: searching for neighbors
[2026-10-22 21:18:22,060: INFO/MainProcess] mingle: all alone
[2026-10-22 21:18:22,070: INFO/MainProcess] celery@vm ready.
```

A faixa de abertura nomeia o broker, quatro processos worker (um por processador desta máquina), e a
única tarefa que ele achou. Agora inscreva a Hana:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Hana", "email": "hana@example.org"}' -w ' %{http_code}\n'
{"name":"Hana","email":"hana@example.org","created_at":"2026-10-22T21:18:32.144005-03:00"} 201
```

No terminal do worker:

```
[2026-10-22 21:18:32,191: INFO/MainProcess] Task events.tasks.send_confirmation[c745f2f3-5316-4f19-9032-749415ba5d7b] received
[2026-10-22 21:18:32,219: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[c745f2f3-5316-4f19-9032-749415ba5d7b] succeeded in 0.02728721299990866s: None
```

E no do servidor de e-mail:

```
---------- MESSAGE FOLLOWS ----------
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0
Subject: You are registered for Testing dojo
From: agenda <agenda@example.org>
To: hana@example.org
Date: Fri, 23 Oct 2026 00:18:32 +0000
Message-ID: <179271471221.547.7531978724815521150@vm>
X-Peer: ('127.0.0.1', 54156)

Hello Hana,

see you on 26 November at 19:00, at Community Centre, room 3.
------------ END MESSAGE ------------
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"O register() dá commit na inscrição. O on_commit então chama delay com o id da inscrição, o que põe uma mensagem na lista do Redis chamada celery, e a API responde 201 ao cliente. Um worker com quatro processos pega a mensagem no Redis e fala com o servidor de e-mail.\"> <defs><marker id=\"q-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"50\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"95\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">register()</text> <text x=\"95\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a linha, com commit</text> <rect x=\"190\" y=\"50\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"265\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">on_commit</text> <text x=\"265\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">.delay(registration.pk)</text> <rect x=\"360\" y=\"50\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"435\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Redis</text> <text x=\"435\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a lista chamada celery</text> <rect x=\"530\" y=\"50\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"605\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">worker</text> <text x=\"605\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 processos</text> <path d=\"M170 75 L186 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#q-a)\"></path> <path d=\"M340 75 L356 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#q-a)\"></path> <path d=\"M510 75 L526 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#q-a)\"></path> <rect x=\"530\" y=\"140\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"605\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">servidor de e-mail</text> <path d=\"M605 100 L605 136\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#q-a)\"></path> <path d=\"M265 100 L265 150 L120 150\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#q-a)\"></path> <text x=\"110\" y=\"165\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">201 ao cliente</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A requisição termina quando a mensagem está no Redis; o e-mail é problema do worker.</text> </svg>", "caption": "Para onde a confirmação vai depois da aula 13. A requisição espera o Redis, não o servidor de e-mail.", "same": ["Redis", "worker"]}
```

## Uma tarefa que falha some

Pare o servidor de e-mail de novo, e inscreva o Ivo:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Ivo", "email": "ivo@example.org"}' -w ' %{http_code}\n'
{"name":"Ivo","email":"ivo@example.org","created_at":"2026-10-22T21:18:34.976204-03:00"} 201
```

**201**: a inscrição não depende mais do servidor de e-mail, que era o objetivo. As duas primeiras
linhas no terminal do worker, antes do traceback:

```
[2026-10-22 21:18:34,987: INFO/MainProcess] Task events.tasks.send_confirmation[52b878e9-8e01-462e-ac46-bdb8edb7314e] received
[2026-10-22 21:18:34,999: ERROR/ForkPoolWorker-1] Task events.tasks.send_confirmation[52b878e9-8e01-462e-ac46-bdb8edb7314e] raised unexpected: ConnectionRefusedError(111, 'Connection refused')
```

**A tarefa levantou uma exceção, e acabou ali.** O Ivo está inscrito, não tem confirmação, e nada vai
tentar de novo. A próxima seção conserta isso.
