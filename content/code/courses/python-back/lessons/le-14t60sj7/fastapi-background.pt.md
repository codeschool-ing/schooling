---
title: As tarefas em segundo plano do FastAPI
version: 1
---

O FastAPI tem algo menor embutido: as **`BackgroundTasks`**, funções que rodam no mesmo processo
depois de a resposta ter sido mandada. O agenda-api manda a confirmação assim. A mensagem, com o
`smtplib` da biblioteca padrão, em `app/mail.py`:

```python
# app/mail.py
import smtplib
from email.message import EmailMessage


def confirmation(name: str, email: str, title: str) -> None:
    message = EmailMessage()
    message["From"] = "agenda API <agenda@example.org>"
    message["To"] = email
    message["Subject"] = f"You are registered for {title}"
    message.set_content(f"Hello {name},\n\nsee you there.\n")
    with smtplib.SMTP("127.0.0.1", 1025) as smtp:
        smtp.send_message(message)
```

No `app/main.py`, importe `BackgroundTasks` do `fastapi` e `mail` do pacote, dê ao `register` um
parâmetro `background: BackgroundTasks`, e acrescente a tarefa logo antes do `return row`:

```python
    background.add_task(mail.confirmation, row.name, row.email, event.title)
```

```
ana@vm:~/agenda-api$ grep -n 'BackgroundTasks\|background\|import mail' app/main.py
2:from fastapi import BackgroundTasks, FastAPI, HTTPException, status
7:from . import mail
72:def register(slug: str, registration: RegistrationIn, session: SessionDep, background: BackgroundTasks):
87:    background.add_task(mail.confirmation, row.name, row.email, event.title)
```

Com o servidor de e-mail rodando, inscreva a Maria:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/testing-dojo/registrations -H 'Content-Type: application/json' -d '{"name": "Maria", "email": "maria@example.org"}' -w ' %{http_code}\n'
{"name":"Maria","email":"maria@example.org","created_at":"2026-10-22T21:23:47.138589-03:00"} 201
```

```
---------- MESSAGE FOLLOWS ----------
From: agenda API <agenda@example.org>
To: maria@example.org
Subject: You are registered for Testing dojo
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0
X-Peer: ('127.0.0.1', 58018)

Hello Maria,

see you there.
------------ END MESSAGE ------------
```

Agora pare o servidor de e-mail e inscreva o Nuno:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events/testing-dojo/registrations -H 'Content-Type: application/json' -d '{"name": "Nuno", "email": "nuno@example.org"}' -w ' %{http_code}\n'
{"name":"Nuno","email":"nuno@example.org","created_at":"2026-10-22T21:23:48.873284-03:00"} 201
```

**201**, e no terminal da API, as primeiras linhas e a última do que veio depois:

```
INFO:     127.0.0.1:36172 - "POST /events/testing-dojo/registrations HTTP/1.1" 201 Created
ERROR:    Exception in ASGI application
Traceback (most recent call last):
ConnectionRefusedError: [Errno 111] Connection refused
```

A resposta já tinha ido quando o e-mail falhou, então o cliente não soube de nada, e **nada vai tentar
de novo**. A exceção está num log, e o Nuno não tem confirmação.

## Qual dos dois

| | `BackgroundTasks` | Celery |
|---|---|---|
| roda | no processo web, depois da resposta | em processos worker, a partir de um broker |
| sobrevive a um reinício do servidor web | **não**: o trabalho pendente se perde | **sim**: ele espera no Redis |
| novas tentativas | escreva você mesmo | `autoretry_for`, `retry_backoff` |
| horários | não | beat |
| custa | nada para instalar | Redis, um worker e um beat para rodar e vigiar |

**As `BackgroundTasks` servem para trabalho cuja perda ninguém notaria**: uma linha de log, uma
métrica, um cache para aquecer. Um e-mail de confirmação não é isso, e o agenda-api também precisaria
do Celery, que funciona com o FastAPI do mesmo jeito: um app Celery, tarefas, um worker, `.delay()` na
rota. Não é o Django que faz o Celery servir; é a necessidade de uma fila que dure mais que a
requisição.
