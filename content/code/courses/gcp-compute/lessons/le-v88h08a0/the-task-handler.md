---
title: The handler, and the duplicate it must survive
version: 1
---

A handler for Cloud Tasks is an ordinary HTTP endpoint with two obligations. **It answers 2xx only
when the work is done, and it does the work at most once however many times it is called.** The
first is how the queue knows to stop; the second is because the queue promises at least one
delivery, exactly as Pub/Sub did in lesson 18.

## The mailer

The shop's mailer receives the order, sends the confirmation, and remembers the task's name so that
a second delivery sends nothing. **Create `~/gcp/mailer` and save this as `main.py` in it:**

```schooling-example
{"language": "python", "file": "main.py", "parts": [{"code": "import sqlite3\n\nfrom flask import Flask, request\n\napp = Flask(__name__)\ndb = sqlite3.connect('sent.db', check_same_thread=False)\ndb.execute('create table if not exists sent (task text primary key)')\n\n\n", "note": "A Flask application and a small SQLite database beside it, holding one table: the names of the tasks already done. On Google Cloud that table would live in a real database, because an instance's disk does not outlive the instance."}, {"code": "@app.post('/send')\ndef send():\n    task = request.headers.get('X-CloudTasks-TaskName', '')\n    retry = request.headers.get('X-CloudTasks-TaskRetryCount', '0')\n    order = request.get_json()\n", "note": "Cloud Tasks names each task and counts its retries, and sends both as headers. The body is whatever the task was created with; here, the order."}, {"code": "    if not task:\n        return 'not a Cloud Tasks request\\n', 400\n", "note": "A request with no task name did not come from a queue, and is refused. On Google Cloud the stronger check is the identity token the queue can attach, verified before anything else."}, {"code": "    if db.execute('select 1 from sent where task = ?', (task,)).fetchone():\n        return f'task {task} already done, nothing sent\\n', 200\n", "note": "The idempotence check. A task already in the table is answered with success and nothing is sent, so a duplicate delivery costs nothing."}, {"code": "    if order['email'].endswith('@down.example'):\n        return f'mail provider unavailable, attempt {int(retry) + 1}\\n', 503\n", "note": "A failure worth retrying: the mail provider is down. A 503 tells the queue to try again later, and the retry count shows which attempt this was."}, {"code": "    print(f'confirmation for order {order[\"order\"]} to {order[\"email\"]}', flush=True)\n    with db:\n        db.execute('insert into sent values (?)', (task,))\n    return f'task {task} done\\n', 200\n", "note": "The work, then the record of it. Between the two there is still a window where a crash would send the email twice, which is why the table is checked before sending and written straight after."}]}
```

It prints the confirmation instead of sending it; a real one would call a mail provider there.
Start it in the second terminal with gunicorn, as in lesson 19:

```
ana@laptop:~/gcp/mailer$ gunicorn -b :8082 main:app
[2026-10-30 15:42:19 -0300] [11242] [INFO] Starting gunicorn 26.2.0
[2026-10-30 15:42:19 -0300] [11242] [INFO] Listening at: http://0.0.0.0:8082 (11242)
[2026-10-30 15:42:19 -0300] [11242] [INFO] Using worker: sync
[2026-10-30 15:42:19 -0300] [11246] [INFO] Booting worker with pid: 11246
[2026-10-30 15:42:19 -0300] [11242] [INFO] Control socket listening at /home/ana/.gunicorn/gunicorn.ctl
```

## curl in the queue's place

Nothing on your laptop dispatches Cloud Tasks, so **curl plays the queue**: it sends the request a
task would make, with the headers Google documents that Cloud Tasks adds to every dispatch. It is
curl, not Cloud Tasks; the names and the order are made up for the shop. The first delivery of a
task, then the same task again, as a retry after a lost answer would bring it:

```
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1042-confirmation' -H 'X-CloudTasks-TaskRetryCount: 0' -H 'content-type: application/json' -d '{"order": 1042, "email": "ana@example.com"}'
task order-1042-confirmation done
200
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1042-confirmation' -H 'X-CloudTasks-TaskRetryCount: 1' -H 'content-type: application/json' -d '{"order": 1042, "email": "ana@example.com"}'
task order-1042-confirmation already done, nothing sent
200
```

The second call was answered with success and **sent nothing**, which is exactly what the queue
needs: a 2xx stops the retries, and the table stopped the duplicate. Below its start-up lines,
the mailer's terminal shows one confirmation, not two:

```
confirmation for order 1042 to ana@example.com
```

Then a task whose provider is down, delivered twice with the retry count rising, and a request with
no task name at all:

```
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1043-confirmation' -H 'X-CloudTasks-TaskRetryCount: 0' -H 'content-type: application/json' -d '{"order": 1043, "email": "bo@down.example"}'
mail provider unavailable, attempt 1
503
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1043-confirmation' -H 'X-CloudTasks-TaskRetryCount: 1' -H 'content-type: application/json' -d '{"order": 1043, "email": "bo@down.example"}'
mail provider unavailable, attempt 2
503
ana@laptop:~/gcp/mailer$ curl -s -w '%{http_code}\n' localhost:8082/send -H 'content-type: application/json' -d '{"order": 1044, "email": "cy@example.com"}'
not a Cloud Tasks request
400
```

**The 503s are failures the queue will retry**, with the waits section 04 computes; the attempt
number comes from the header the queue sets. The 400 is a refusal of something that did not come
from a queue, and deployed you would check the identity token instead of a header anybody can type.

Stop gunicorn with Ctrl+C when you are done.
