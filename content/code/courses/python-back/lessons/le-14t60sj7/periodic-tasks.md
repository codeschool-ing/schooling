---
title: Periodic tasks, and the sweep
version: 1
---

Gil, Ivo, Kai and Lia have no confirmation, and nothing is going to try again. A **periodic task** can: a
sweep that runs every minute, finds registrations that should have had a confirmation by now and
queues them. Add it to `events/tasks.py`:

```schooling-example
{"language": "python", "file": "events/tasks.py", "parts": [{"code": "# events/tasks.py\nfrom datetime import timedelta\n\nfrom celery import shared_task\nfrom django.utils import timezone\n\nfrom . import mail\nfrom .models import Registration\n\n\n@shared_task(autoretry_for=(OSError,), retry_backoff=True, max_retries=10)\ndef send_confirmation(registration_id):\n    registration = Registration.objects.select_related(\"event\").get(pk=registration_id)\n    if registration.confirmation_sent_at is not None:\n        return \"already sent\"\n    mail.confirmation(registration)\n    registration.confirmation_sent_at = timezone.now()\n    registration.save(update_fields=[\"confirmation_sent_at\"])\n    return \"sent\"\n\n\n"}, {"code": "@shared_task\ndef resend_unconfirmed():\n    now = timezone.now()\n    waiting = Registration.objects.filter(\n        confirmation_sent_at=None,\n        created_at__lt=now - timedelta(minutes=2),\n        created_at__gt=now - timedelta(hours=1),\n    )\n", "note": "**The sweep.** Registrations older than two minutes and younger than an hour that have no confirmation yet: a task that was lost, or never queued."}, {"code": "    found = list(waiting.values_list(\"pk\", flat=True))\n    for registration_id in found:\n        send_confirmation.delay(registration_id)\n    return found\n", "note": "It queues them rather than sending itself, so each one gets the retries and the check above."}]}
```

**beat** is Celery's clock: a separate process that sends a task to the queue on a schedule. The
schedule goes at the end of `config/settings.py`:

```python
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    "resend-unconfirmed": {
        "task": "events.tasks.resend_unconfirmed",
        "schedule": crontab(minute="*"),
    },
}
```

`crontab(minute="*")` is every minute, which suits a sweep that costs one indexed query when there
is nothing to do; a daily report would be `crontab(hour=7, minute=0)`. Restart the worker, so that
it knows the new task, and start beat in a terminal of its own. After a few minutes:

```
ana@vm:~/agenda$ sed -n '/^from celery.schedules/,$p' config/settings.py
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    "resend-unconfirmed": {
        "task": "events.tasks.resend_unconfirmed",
        "schedule": crontab(minute="*"),
    },
}
ana@vm:~/agenda$ uv run celery -A config beat -l info
celery beat v5.6.3 (recovery) is starting.
__    -    ... __   -        _
LocalTime -> 2026-10-22 21:20:05
Configuration ->
    . broker -> redis://127.0.0.1:6379/0
    . loader -> celery.loaders.app.AppLoader
    . scheduler -> celery.beat.PersistentScheduler
    . db -> celerybeat-schedule
    . logfile -> [stderr]@%INFO
    . maxinterval -> 5.00 minutes (300s)
[2026-10-22 21:20:05,254: INFO/MainProcess] beat: Starting...
[2026-10-22 21:21:00,002: INFO/MainProcess] Scheduler: Sending due task resend-unconfirmed (events.tasks.resend_unconfirmed)
[2026-10-22 21:22:00,000: INFO/MainProcess] Scheduler: Sending due task resend-unconfirmed (events.tasks.resend_unconfirmed)
[2026-10-22 21:23:00,000: INFO/MainProcess] Scheduler: Sending due task resend-unconfirmed (events.tasks.resend_unconfirmed)
```

And the worker:

```
[2026-10-22 21:21:00,011: INFO/MainProcess] Task events.tasks.resend_unconfirmed[356e53e5-d0ed-40ef-956d-1fafe47254b7] received
[2026-10-22 21:21:00,029: INFO/MainProcess] Task events.tasks.send_confirmation[01ecc9b6-a3fd-40b1-8c86-f454d1e08c80] received
[2026-10-22 21:21:00,030: INFO/MainProcess] Task events.tasks.send_confirmation[b6eeb24a-5448-4e52-a141-d4360847f0b0] received
[2026-10-22 21:21:00,030: INFO/ForkPoolWorker-1] Task events.tasks.resend_unconfirmed[356e53e5-d0ed-40ef-956d-1fafe47254b7] succeeded in 0.01818443899992417s: [39, 40, 41, 42]
[2026-10-22 21:21:00,031: INFO/MainProcess] Task events.tasks.send_confirmation[493af39f-53bc-4d4d-80ec-77025fe4b8f1] received
[2026-10-22 21:21:00,032: INFO/MainProcess] Task events.tasks.send_confirmation[b5f5fa03-2200-4ff7-8c76-9934b4d325c2] received
[2026-10-22 21:21:00,046: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[493af39f-53bc-4d4d-80ec-77025fe4b8f1] succeeded in 0.013574828000855632s: 'sent'
[2026-10-22 21:21:00,053: INFO/ForkPoolWorker-2] Task events.tasks.send_confirmation[b6eeb24a-5448-4e52-a141-d4360847f0b0] succeeded in 0.022361679999448825s: 'sent'
[2026-10-22 21:21:00,054: INFO/ForkPoolWorker-4] Task events.tasks.send_confirmation[01ecc9b6-a3fd-40b1-8c86-f454d1e08c80] succeeded in 0.023829526000554324s: 'sent'
[2026-10-22 21:21:00,054: INFO/ForkPoolWorker-3] Task events.tasks.send_confirmation[b5f5fa03-2200-4ff7-8c76-9934b4d325c2] succeeded in 0.018782993000058923s: 'sent'
[2026-10-22 21:22:00,002: INFO/MainProcess] Task events.tasks.resend_unconfirmed[f404031f-9d3b-4487-9e0e-f73f1860ad81] received
[2026-10-22 21:22:00,010: INFO/MainProcess] Task events.tasks.send_confirmation[c9ba6125-ea37-4e0d-9e0c-8de6a9facc77] received
[2026-10-22 21:22:00,010: INFO/ForkPoolWorker-1] Task events.tasks.resend_unconfirmed[f404031f-9d3b-4487-9e0e-f73f1860ad81] succeeded in 0.007220020000204386s: [44, 45]
[2026-10-22 21:22:00,011: INFO/MainProcess] Task events.tasks.send_confirmation[9163796e-58e3-48b7-815b-25faa2fd1468] received
[2026-10-22 21:22:00,023: INFO/ForkPoolWorker-4] Task events.tasks.send_confirmation[c9ba6125-ea37-4e0d-9e0c-8de6a9facc77] succeeded in 0.011945704000027035s: 'sent'
[2026-10-22 21:22:00,023: INFO/ForkPoolWorker-1] Task events.tasks.send_confirmation[9163796e-58e3-48b7-815b-25faa2fd1468] succeeded in 0.011179700999491615s: 'sent'
[2026-10-22 21:23:00,002: INFO/MainProcess] Task events.tasks.resend_unconfirmed[2b1b634b-5d77-4653-ba9d-c79b878992d9] received
[2026-10-22 21:23:00,008: INFO/ForkPoolWorker-1] Task events.tasks.resend_unconfirmed[2b1b634b-5d77-4653-ba9d-c79b878992d9] succeeded in 0.00562494699988747s: []
```

```
ana@vm:~/agenda$ psql agenda -c "select name, created_at, confirmation_sent_at from events_registration where created_at > now() - interval '1 hour' order by id"
 name  |          created_at           |     confirmation_sent_at      
-------+-------------------------------+-------------------------------
 Fabio | 2026-10-22 21:18:09.236248-03 | 2026-10-22 21:21:00.050508-03
 Gil   | 2026-10-22 21:18:10.940706-03 | 2026-10-22 21:21:00.050433-03
 Hana  | 2026-10-22 21:18:32.144005-03 | 2026-10-22 21:21:00.044222-03
 Ivo   | 2026-10-22 21:18:34.976204-03 | 2026-10-22 21:21:00.051423-03
 Joana | 2026-10-22 21:18:47.982052-03 | 2026-10-22 21:18:56.112136-03
 Kai   | 2026-10-22 21:19:44.040741-03 | 2026-10-22 21:22:00.020646-03
 Lia   | 2026-10-22 21:19:48.061381-03 | 2026-10-22 21:22:00.021-03
(7 rows)
```

**Every registration of the last hour has a confirmation now.** Gil, Ivo, Kai and Lia got theirs from
the sweep. **Fabio and Hana got a second one**: their mails had gone out before the column existed,
so nothing recorded it, and the sweep could not tell. That is the cost of adding the record after the
fact, and the reason to record an effect from the first day.

**Run exactly one beat.** Two would send every scheduled task twice; the workers can be many, the
clock must be one.
