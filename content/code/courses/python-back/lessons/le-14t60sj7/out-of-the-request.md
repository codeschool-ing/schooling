---
title: Work that does not belong in the request
version: 1
---

Somebody registers, and agenda should send them a confirmation by e-mail. The obvious place is the
view, right after the registration is saved. This section does exactly that, to see what it costs.

agenda needs a mail server to talk to. **aiosmtpd** is an SMTP server in Python that accepts every
message and prints it, which is what development wants: nothing reaches a real inbox. Add it as a
development dependency, and run it in a terminal of its own:

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

Django 6.1 configures mail with **`MAILERS`**; `startproject` wrote one that prints messages to the
console. Replace it in `config/settings.py` with one that speaks SMTP to port 1025, and set the
sender:

```python
MAILERS = {
    'default': {
        'BACKEND': 'django.core.mail.backends.smtp.EmailBackend',
        'OPTIONS': {'host': '127.0.0.1', 'port': 1025},
    },
}
DEFAULT_FROM_EMAIL = 'agenda <agenda@example.org>'
```

The message itself, in `events/mail.py`:

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

And the call, in `register_for_event` in `events/api.py`, with `from . import mail` at the top:

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

In the mail server's terminal:

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

## When the mail server is down

Stop the mail server, and register Gil:

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

**500, and Gil is registered anyway.** The row was committed before the mail was tried, so the
failure reached the client as an error about something that had worked. Gil, told it failed, tries
again and is told he is already registered, and never gets a confirmation. Putting the mail inside
the transaction would be worse: a mail server that is down would make registering impossible.

Mail is the clearest case of a general rule. **Anything slow or fallible that the answer does not
depend on belongs outside the request**: sending mail, resizing a photo, calling a partner that
takes seconds, building a report. The request records what has to happen, answers, and something
else does it, retrying until it works. That something is a **task queue**, and in Python the usual
one is **Celery**.
