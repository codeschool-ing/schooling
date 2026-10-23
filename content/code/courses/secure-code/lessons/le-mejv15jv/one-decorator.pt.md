---
title: Um decorador, e o papel vindo do servidor
version: 1
---

A primeira versão verificava o acesso de dois jeitos diferentes, e os dois no lugar errado. O
`signed_in()` perguntava só se *alguém* estava logado, e cada rota que precisava de mais tinha que
lembrar de perguntar. O `add_note` perguntava ao **formulário** se quem enviava era fisioterapeuta, e
o formulário dizia o que quem enviava queria que dissesse.

A correção põe a pergunta num **lugar só** e faz cada rota declarar sua resposta onde é declarada:

```schooling-example
{"language": "python", "parts": [{"code": "def requires(*roles):\n    def decorate(view):\n        @wraps(view)\n        def checked(*args, **kwargs):", "note": "Um decorador que recebe os papéis que uma rota aceita. O `wraps` mantém o nome da view, que o Flask usa para distinguir as rotas."}, {"code": "            name = session.get(\"staff\")\n            if name not in STAFF:\n                abort(401)", "note": "Quem pergunta vem da sessão. Um nome que o servidor não conhece, ou nenhum, é `401`."}, {"code": "            if STAFF[name] not in roles:\n                abort(403)\n            return view(*args, **kwargs)\n", "note": "O que podem fazer vem do `STAFF`, a tabela do servidor, nunca da requisição. O papel errado é `403`, antes de a view rodar uma linha."}, {"code": "        checked.allowed_roles = roles\n        return checked\n\n    return decorate", "note": "Os papéis também ficam escritos na função, para um teste perguntar a cada rota o que ela permite."}]}
```

Leia o `requires` como as três regras em uma dúzia de linhas. Ele roda **no servidor, a cada
requisição** à rota. Lê o nome na sessão e o papel no `STAFF`, **a tabela do próprio servidor**: nada
na requisição é consultado. E distingue as duas recusas, **`401`** para ninguém logado e **`403`**
para alguém logado sem o papel.

Mais duas linhas da mudança importam. O **campo oculto sumiu** da página, porque nada o lê mais, e
um campo que ninguém lê é um que alguém um dia volta a ler. E o `add_note` perdeu a verificação
própria: o decorador é a única verificação, então há um lugar só para ler, testar e mudar.

### A correção

A ana faz primeiro a mudança óbvia: as duas rotas que os testes nomearam.

```
(.venv) ana@vm:~/sc/console$ git diff
diff --git a/app.py b/app.py
index dcf1f07..a1e2720 100644
--- a/app.py
+++ b/app.py
@@ -1,5 +1,6 @@
 # app.py
 import secrets
+from functools import wraps
 
 from flask import Flask, abort, jsonify, render_template_string, request, session
 
@@ -19,7 +20,6 @@ PAGE = """<h1>Vereda console</h1>
 </ul>
 {% if role == "physio" %}
 <form method="post" action="/patients/lucia/notes">
-  <input type="hidden" name="role" value="physio">
   <textarea name="text"></textarea>
   <button>Add note</button>
 </form>
@@ -34,6 +34,23 @@ def signed_in():
     return name
 
 
+def requires(*roles):
+    def decorate(view):
+        @wraps(view)
+        def checked(*args, **kwargs):
+            name = session.get("staff")
+            if name not in STAFF:
+                abort(401)
+            if STAFF[name] not in roles:
+                abort(403)
+            return view(*args, **kwargs)
+
+        checked.allowed_roles = roles
+        return checked
+
+    return decorate
+
+
 @app.get("/console")
 def console():
     name = signed_in()
@@ -47,16 +64,14 @@ def agenda():
 
 
 @app.get("/patients/<name>/notes")
+@requires("physio")
 def read_notes(name):
-    signed_in()
     return jsonify(NOTES.get(name, []))
 
 
 @app.post("/patients/<name>/notes")
+@requires("physio")
 def add_note(name):
-    signed_in()
-    if request.form.get("role") != "physio":
-        abort(403)
     NOTES.setdefault(name, []).append(request.form["text"])
     return jsonify(NOTES[name]), 201
 
```

```
(.venv) ana@vm:~/sc/console$ pytest -q --tb=no
....FF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_nobody_signed_in_gets_the_export - AssertionError: a...
FAILED test_app.py::test_every_route_says_who_may_use_it - AssertionError: no...
2 failed, 4 passed in 0.12s
(.venv) ana@vm:~/sc/console$ git commit -qam "Check the role on the server for clinical notes"
```

**O recepcionista é recusado, e a alegação do formulário é ignorada.** Restam duas falhas, e são as
interessantes: a exportação de que ninguém lembrou, e o teste que está prestes a explicar por quê.
