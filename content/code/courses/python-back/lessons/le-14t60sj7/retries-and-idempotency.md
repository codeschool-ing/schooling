---
title: Retries, and running twice safely
version: 1
---

A task that talks to another server should retry, and a task that retries must be safe to run more
than once, because it will be. Both start with the row recording whether the confirmation went out.
Add a field to `Registration` in `events/models.py`, below `created_at`:

```python
    confirmation_sent_at = models.DateTimeField(null=True, blank=True)
```

```
ana@vm:~/agenda$ grep -n 'confirmation_sent_at' events/models.py
33:    confirmation_sent_at = models.DateTimeField(null=True, blank=True)
ana@vm:~/agenda$ uv run python manage.py makemigrations events
Migrations for 'events':
  events/migrations/0004_registration_confirmation_sent_at.py
    + Add field confirmation_sent_at to registration
ana@vm:~/agenda$ uv run python manage.py migrate events
Operations to perform:
  Apply all migrations: events
Running migrations:
  Applying events.0004_registration_confirmation_sent_at... OK
```

Then the task, rewritten in `events/tasks.py`:

```schooling-example
{"language": "python", "file": "events/tasks.py", "parts": [{"code": "# events/tasks.py\nfrom celery import shared_task\nfrom django.utils import timezone\n\nfrom . import mail\nfrom .models import Registration\n\n\n"}, {"code": "@shared_task(autoretry_for=(OSError,), retry_backoff=True, max_retries=10)\ndef send_confirmation(registration_id):\n    registration = Registration.objects.select_related(\"event\").get(pk=registration_id)\n", "note": "**`autoretry_for`** turns those exceptions into retries; `ConnectionRefusedError` is an `OSError`. **`retry_backoff`** doubles the wait each time, with random jitter, up to ten tries."}, {"code": "    if registration.confirmation_sent_at is not None:\n        return \"already sent\"\n    mail.confirmation(registration)\n", "note": "**The check that makes a second run harmless.** A task can run twice: a retry after a send that worked but timed out, or a worker killed between the send and the save."}, {"code": "    registration.confirmation_sent_at = timezone.now()\n    registration.save(update_fields=[\"confirmation_sent_at\"])\n    return \"sent\"\n", "note": "Record that it happened, in the same row the next run reads."}]}
```

A worker loads its code when it starts, so **restart the worker** after changing a task; the
development server reloads itself, the worker does not. With the mail server still stopped, register
Joana, then start the mail server again a few seconds later. The worker's terminal:

```
[2026-10-22 21:18:48,031: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:48,059: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:48,061: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] retry: Retry in 0s: ConnectionRefusedError(111, 'Connection refused')
[2026-10-22 21:18:48,079: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:48,081: INFO/ForkPoolWorker-4] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] retry: Retry in 2s: ConnectionRefusedError(111, 'Connection refused')
[2026-10-22 21:18:50,084: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:50,085: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] retry: Retry in 3s: ConnectionRefusedError(111, 'Connection refused')
[2026-10-22 21:18:53,093: INFO/MainProcess] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] received
[2026-10-22 21:18:53,093: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] retry: Retry in 3s: ConnectionRefusedError(111, 'Connection refused')
[2026-10-22 21:18:56,118: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[0363cbd1-7594-4da3-b60b-63cf9c83fb8f] succeeded in 0.02377533399976528s: 'sent'
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A timeline of Joana's confirmation: 4 attempts refused by the stopped mail server, at growing intervals, then one that succeeded 8.1 seconds after the first, once the mail server was back.\"> <path d=\"M60 110 L660 110\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path> <circle cx=\"60.0\" cy=\"110\" r=\"7\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></circle> <text x=\"60.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0 s</text> <circle cx=\"61.5\" cy=\"110\" r=\"7\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></circle> <text x=\"61.5\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0 s</text> <circle cx=\"210.7\" cy=\"110\" r=\"7\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></circle> <text x=\"210.7\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.0 s</text> <circle cx=\"434.7\" cy=\"110\" r=\"7\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></circle> <text x=\"434.7\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5.0 s</text> <circle cx=\"660.0\" cy=\"110\" r=\"7\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\"></circle> <text x=\"660.0\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8.1 s</text> <text x=\"60\" y=\"70\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused: retry later</text> <text x=\"660\" y=\"70\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sent</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Each attempt of Joana's confirmation, in seconds after the first, read from the worker's log.</text> </svg>", "caption": "retry_backoff spaces the attempts out, with random jitter, so a server that is down is not hammered while it comes back."}
```

Every attempt is the same task, its id unchanged, sent back to Redis to wait its turn; the last one
found the mail server up. Without the backoff, ten attempts would have been spent in a second.

## Running it twice

Call the task's function directly, as a second delivery would:

```
ana@vm:~/agenda$ uv run python manage.py shell -v 0 -c "from events.models import Registration; from events.tasks import send_confirmation; joana = Registration.objects.get(name='Joana'); print(joana.confirmation_sent_at); print(send_confirmation(joana.pk))"
2026-10-23 00:18:56.112136+00:00
already sent
```

**`already sent`**: the second run read the row and stopped. That is **idempotency**, an operation
that can be repeated without repeating its effect, and it is what makes retrying safe. Celery
promises that a task runs **at least once**, not exactly once, so every task with an effect outside
the database needs a check like this one.

It is not perfect: a worker killed after the mail left and before `save()` still sends twice. Closing
that gap entirely needs the other side to deduplicate, as payment gateways do with an idempotency key.
For a confirmation e-mail, a rare duplicate is a fair price.
