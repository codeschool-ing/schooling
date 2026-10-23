---
title: A pull request to review
version: 1
---

A review starts from a diff, not from a file. The question is what **this change** does to the
system, and the diff is the exact answer. This lesson's folder holds a small feature of the
portal, patients writing messages to their clinic, and one change somebody has asked you to
review. Make the folder and its repository as in earlier lessons, and save the code as it is on
`main` as `app.py`:

```python
# app.py
import secrets

from flask import Flask, abort, render_template_string, session

app = Flask(__name__)
app.secret_key = secrets.token_bytes(32)
MESSAGES = {
    1: {"patient": "lucia", "text": "Can I move Thursday's session?"},
    2: {"patient": "rafael", "text": "The receipt for October, please."},
}

PAGE = """<h1>Your messages</h1>
{% for m in messages %}<p>{{ m.text }}</p>{% endfor %}"""


def patient():
    if "patient" not in session:
        abort(401)
    return session["patient"]


@app.get("/messages")
def list_messages():
    me = patient()
    mine = [m for m in MESSAGES.values() if m["patient"] == me]
    return render_template_string(PAGE, messages=mine)
```

And its dependencies, as `requirements.txt`:

```
# requirements.txt
flask==3.1.3
```

Commit both on `main`. Then the change arrives on a branch called `messages`: a patient can now
send a message and open one by its number. Here it is as the reviewer sees it:

```
(.venv) ana@vm:~/sc/review$ git diff main messages
diff --git a/app.py b/app.py
index 4456458..f6344dc 100644
--- a/app.py
+++ b/app.py
@@ -1,17 +1,15 @@
 # app.py
-import secrets
-
-from flask import Flask, abort, render_template_string, session
+from flask import Flask, abort, redirect, render_template_string, request, session
 
 app = Flask(__name__)
-app.secret_key = secrets.token_bytes(32)
+app.secret_key = "vereda-dev"
 MESSAGES = {
     1: {"patient": "lucia", "text": "Can I move Thursday's session?"},
     2: {"patient": "rafael", "text": "The receipt for October, please."},
 }
 
 PAGE = """<h1>Your messages</h1>
-{% for m in messages %}<p>{{ m.text }}</p>{% endfor %}"""
+{% for m in messages %}<p>{{ m.text|replace('\n', '<br>')|safe }}</p>{% endfor %}"""
 
 
 def patient():
@@ -25,3 +23,17 @@ def list_messages():
     me = patient()
     mine = [m for m in MESSAGES.values() if m["patient"] == me]
     return render_template_string(PAGE, messages=mine)
+
+
+@app.post("/messages")
+def send_message():
+    message = dict(request.form)
+    message["patient"] = message.get("patient", patient())
+    MESSAGES[max(MESSAGES) + 1] = message
+    return redirect("/messages")
+
+
+@app.get("/messages/<int:number>")
+def read_message(number):
+    patient()
+    return render_template_string(PAGE, messages=[MESSAGES[number]])
diff --git a/requirements.txt b/requirements.txt
index 1a33470..0840ec5 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -1,2 +1,2 @@
 # requirements.txt
-flask==3.1.3
+flask>=3.0
```

The description on the pull request says *"Patients can send messages. Kept line breaks in the
page. Simplified the secret key and the Flask pin."* Every sentence of it is true. Before reading
on, go through the diff yourself and write down what you would ask about, and in what order. The
next two sections are one reviewer's answer.
