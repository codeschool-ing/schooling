---
title: Trabalho que não pertence à requisição
version: 1
---

Alguém se inscreve, e o agenda deve mandar uma confirmação por e-mail. O lugar óbvio é a view, logo
depois de a inscrição ser salva. Esta seção faz exatamente isso, para ver quanto custa.

O agenda precisa de um servidor de e-mail com quem falar. O **aiosmtpd** é um servidor SMTP em Python
que aceita toda mensagem e a imprime, que é o que o desenvolvimento quer: nada chega a uma caixa de
entrada de verdade. Acrescente-o como dependência de desenvolvimento, e rode-o num terminal próprio:

```
ana@vm:~/agenda$ uv add --dev aiosmtpd
Resolved 20 packages in 222ms
Prepared 3 packages in 27ms
Installed 3 packages in 3ms
 + aiosmtpd==1.4.6
 + atpublic==9.0.0
 + attrs==26.1.0
```

```sh
uv run python -m aiosmtpd -n -l 127.0.0.1:1025
```

O Django 6.1 configura e-mail com **`MAILERS`**; o `startproject` escreveu um que imprime as mensagens
no console. Troque-o no `config/settings.py` por um que fala SMTP com a porta 1025, e defina o
remetente:

```python
MAILERS = {
    'default': {
        'BACKEND': 'django.core.mail.backends.smtp.EmailBackend',
        'OPTIONS': {'host': '127.0.0.1', 'port': 1025},
    },
}
DEFAULT_FROM_EMAIL = 'agenda <agenda@example.org>'
```

A própria mensagem, em `events/mail.py`:

```python
# events/mail.py
from django.core.mail import send_mail
from django.utils import timezone


def confirmation(registration):
    event = registration.event
    starts = timezone.localtime(event.starts_at)
    send_mail(
        subject=f"You are registered for {event.title}",
        message=f"Hello {registration.name},\n\nsee you on {starts:%d %B at %H:%M}, at {event.venue}.\n",
        from_email=None,
        recipient_list=[registration.email],
    )
```

E a chamada, no `register_for_event` em `events/api.py`, com `from . import mail` no topo:

```python
    try:
        registration = register(event.pk, **serializer.validated_data)
    except RegistrationRefused as refusal:
        return Response({"detail": str(refusal)}, status=status.HTTP_409_CONFLICT)
    mail.confirmation(registration)
    return Response(RegistrationSerializer(registration).data, status=status.HTTP_201_CREATED)
```

```
ana@vm:~/agenda$ sed -n '/^MAILERS/,/^DEFAULT_FROM_EMAIL/p' config/settings.py
MAILERS = {
    'default': {
        'BACKEND': 'django.core.mail.backends.smtp.EmailBackend',
        'OPTIONS': {'host': '127.0.0.1', 'port': 1025},
    },
}
DEFAULT_FROM_EMAIL = 'agenda <agenda@example.org>'
ana@vm:~/agenda$ grep -n 'mail' events/api.py
9:from . import mail
42:    mail.confirmation(registration)
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Fabio", "email": "fabio@example.org"}'; echo
{"name":"Fabio","email":"fabio@example.org","created_at":"2026-10-22T21:18:09.236248-03:00"}
```

No terminal do servidor de e-mail:

```
---------- MESSAGE FOLLOWS ----------
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0
Subject: You are registered for Testing dojo
From: agenda <agenda@example.org>
To: fabio@example.org
Date: Fri, 23 Oct 2026 00:18:09 +0000
Message-ID: <179271468925.298.12302701677398498050@vm>
X-Peer: ('127.0.0.1', 52588)

Hello Fabio,

see you on 26 November at 19:00, at Community Centre, room 3.
------------ END MESSAGE ------------
```

## Quando o servidor de e-mail está fora do ar

Pare o servidor de e-mail, e inscreva o Gil:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Gil", "email": "gil@example.org"}' -o /dev/null -w '%{http_code}\n'
500
ana@vm:~/agenda$ psql agenda -c "select name, email, created_at from events_registration where name = 'Gil'"
 name |      email      |          created_at           
------+-----------------+-------------------------------
 Gil  | gil@example.org | 2026-10-22 21:18:10.940706-03
(1 row)

ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Gil", "email": "gil@example.org"}'; echo
{"detail":"This address is already registered."}
```

**500, e o Gil está inscrito mesmo assim.** A linha teve commit antes de o e-mail ser tentado, então a
falha chegou ao cliente como um erro sobre algo que tinha funcionado. O Gil, avisado de que falhou,
tenta de novo e ouve que já está inscrito, e nunca recebe confirmação. Pôr o e-mail dentro da transação
seria pior: um servidor de e-mail fora do ar tornaria impossível se inscrever.

O e-mail é o caso mais claro de uma regra geral. **Tudo o que é lento ou pode falhar, e de que a
resposta não depende, fica fora da requisição**: mandar e-mail, redimensionar uma foto, chamar um
parceiro que leva segundos, montar um relatório. A requisição registra o que precisa acontecer,
responde, e outra coisa faz o trabalho, tentando de novo até dar certo. Essa outra coisa é uma **fila
de tarefas**, e em Python a mais comum é o **Celery**.
