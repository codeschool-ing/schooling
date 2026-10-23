---
title: Um pull request para revisar
version: 1
---

Uma revisão começa por um diff, não por um arquivo. A pergunta é o que **esta mudança** faz com o
sistema, e o diff é a resposta exata. A pasta desta aula guarda uma pequena funcionalidade do portal,
pacientes escrevendo mensagens para a clínica, e uma mudança que alguém pediu que você revisasse.
Crie a pasta e o repositório como nas aulas anteriores, e salve o código como está no `main` como
`app.py`:

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

E as dependências dele, como `requirements.txt`:

```
# requirements.txt
flask==3.1.3
```

Faça commit dos dois no `main`. Então a mudança chega num branch chamado `messages`: agora um
paciente pode enviar uma mensagem e abrir uma pelo número. Aqui está ela como o revisor a vê:

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

A descrição no pull request diz *"Pacientes podem enviar mensagens. Mantive as quebras de linha na
página. Simplifiquei a chave secreta e a versão do Flask."* Cada frase é verdade. Antes de seguir,
percorra o diff você mesmo e anote o que perguntaria, e em que ordem. As próximas duas seções são a
resposta de um revisor.
