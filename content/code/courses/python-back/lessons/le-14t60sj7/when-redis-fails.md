---
title: When Redis fails
version: 1
---

The task queue took the mail server out of the request and **put Redis in it**. Stop Redis, as a
crash would:

```
ana@vm:~/agenda$ sudo systemctl stop redis-server
```

The last lines of the worker's terminal:

```
Trying again in 2.00 seconds... (1/100)

[2026-10-22 21:19:40,890: ERROR/MainProcess] consumer: Cannot connect to redis://127.0.0.1:6379/0: Error 111 connecting to 127.0.0.1:6379. Connection refused..
Trying again in 4.00 seconds... (2/100)
```

**The worker survives** and reconnects with growing pauses, up to a hundred attempts. The web side is
less patient. Register Kai:

```
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Kai", "email": "kai@example.org"}' -o /dev/null -w '%{http_code}\n'
500
ana@vm:~/agenda$ psql agenda -c "select name, confirmation_sent_at from events_registration where name = 'Kai'"
 name | confirmation_sent_at 
------+----------------------
 Kai  | 
(1 row)
```

**This lesson's first failure, again**: Kai is committed, the answer is 500, and no task was queued.
`on_commit` runs its function after the commit, and an exception there escapes to the request. Django
can contain it: **`robust=True`** logs the exception instead of raising it.

```
ana@vm:~/agenda$ grep -n 'on_commit' events/services.py
20:        transaction.on_commit(lambda: send_confirmation.delay(registration.pk), robust=True)
ana@vm:~/agenda$ curl -s http://127.0.0.1:8000/api/events/testing-dojo/registrations/ -H 'Content-Type: application/json' -d '{"name": "Lia", "email": "lia@example.org"}' -w ' %{http_code}\n'
{"name":"Lia","email":"lia@example.org","created_at":"2026-10-22T21:19:48.061381-03:00"} 201
```

**201 for Lia**, and the first line of what the development server printed:

```
Error calling register.<locals>.<lambda> in on_commit() during transaction (Error 111 connecting to 127.0.0.1:6379. Connection refused.).
```

Lia is registered and her task was never queued. Start Redis again, and the worker reconnects:

```
ana@vm:~/agenda$ sudo systemctl start redis-server
[2026-10-22 21:19:50,896: INFO/MainProcess] Connected to redis://127.0.0.1:6379/0
[2026-10-22 21:19:50,898: INFO/MainProcess] mingle: searching for neighbors
[2026-10-22 21:19:51,903: INFO/MainProcess] mingle: all alone
```

## The failures you will meet

| symptom | cause | fix |
|---|---|---|
| `Cannot connect to redis://...: Connection refused` in the worker | Redis is not running | `sudo systemctl start redis-server`; the worker reconnects by itself |
| a 500 from a view that queues a task | Redis was down when `.delay()` ran | `robust=True`, and a sweep for what was missed (next section) |
| `Received unregistered task of type 'events.tasks...'` | the worker started before the task existed, or does not import the module | restart the worker; check the `[tasks]` list in its banner |
| `Object of type Registration is not JSON serializable` | a model instance passed to `.delay()` | pass the id |
| the task does nothing new after an edit | the worker runs the code it started with | restart the worker |

The first two are this section's. The last three were not produced for this course; the messages are
the ones Celery and kombu print for those causes.
