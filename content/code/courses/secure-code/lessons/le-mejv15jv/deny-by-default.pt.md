---
title: Negar por padrão, garantido por um teste
version: 1
---

A correção óbvia corrigiu o que os testes nomearam. A exportação nunca foi nomeada por ninguém: foi
escrita numa tarde para um relatório, funcionou, e não tinha verificação porque nada lembrou a
ninguém que precisava de uma. **É assim que o controle de acesso falha na prática**: não uma
verificação errada, mas uma rota sem nenhuma.

Um decorador não ajuda uma rota em que nunca foi aplicado. O que ajuda é inverter a pergunta: em vez
de achar as rotas que precisam de proteção, **recusar entregar qualquer rota que não tenha dito quem
pode usá-la.** O último teste faz isso. Percorre toda rota que o Flask conhece,
`app.url_map.iter_rules()`, e pergunta a cada função de view se o `requires` a marcou com
`allowed_roles`. Rode só ele:

```
(.venv) ana@vm:~/sc/console$ pytest -q --tb=short -k every_route
F                                                                        [100%]
=================================== FAILURES ===================================
_____________________ test_every_route_says_who_may_use_it _____________________
test_app.py:52: in test_every_route_says_who_may_use_it
    assert not open_routes, f"no rule says who may use {open_routes}"
E   AssertionError: no rule says who may use ['/console', '/agenda', '/export']
E   assert not ['/console', '/agenda', '/export']
=========================== short test summary info ============================
FAILED test_app.py::test_every_route_says_who_may_use_it - AssertionError: no...
1 failed, 5 deselected in 0.14s
```

A mensagem nomeia três rotas. `/export` é o vazamento. `/console` e `/agenda` na prática só abrem
para a equipe, por causa do `signed_in()`, mas **nada nelas diz qual equipe**, e a próxima pessoa a
editá-las precisa adivinhar. O teste não se importa se uma rota é perigosa. Pede que toda rota
responda a uma pergunta por escrito.

### A correção

Toda rota que restava diz quem pode usá-la, e o `signed_in()` sai, para não sobrar nada que verifique
menos do que o `requires` verifica:

```
(.venv) ana@vm:~/sc/console$ git diff
diff --git a/app.py b/app.py
index a1e2720..17bc2b8 100644
--- a/app.py
+++ b/app.py
@@ -27,13 +27,6 @@ PAGE = """<h1>Vereda console</h1>
 """
 
 
-def signed_in():
-    name = session.get("staff")
-    if name is None:
-        abort(401)
-    return name
-
-
 def requires(*roles):
     def decorate(view):
         @wraps(view)
@@ -52,14 +45,15 @@ def requires(*roles):
 
 
 @app.get("/console")
+@requires("reception", "physio", "admin")
 def console():
-    name = signed_in()
-    return render_template_string(PAGE, name=name, role=STAFF.get(name))
+    name = session["staff"]
+    return render_template_string(PAGE, name=name, role=STAFF[name])
 
 
 @app.get("/agenda")
+@requires("reception", "physio", "admin")
 def agenda():
-    signed_in()
     return jsonify(AGENDA)
 
 
@@ -77,6 +71,7 @@ def add_note(name):
 
 
 @app.get("/export")
+@requires("admin")
 def export():
     rows = [f"{patient},{len(notes)}" for patient, notes in NOTES.items()]
     return "\n".join(["patient,notes", *rows]) + "\n", {"Content-Type": "text/csv"}
```

```
(.venv) ana@vm:~/sc/console$ pytest -q
......                                                                   [100%]
6 passed in 0.16s
```

Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/console$ git commit -qam "Every route says who may use it"
(.venv) ana@vm:~/sc/console$ git log --oneline
6488c2e Every route says who may use it
38ad6af Check the role on the server for clinical notes
663e1eb Staff console: agenda, clinical notes and the export
```

### A mesma requisição, de novo

```
(.venv) ana@vm:~/sc/console$ curl -si http://127.0.0.1:5000/export
HTTP/1.1 401 UNAUTHORIZED
Server: Werkzeug/3.1.9 Python/3.13.17
Date: Fri, 23 Oct 2026 15:23:14 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 317
Vary: Cookie
Connection: close

<!doctype html>
<html lang=en>
<title>401 Unauthorized</title>
<h1>Unauthorized</h1>
<p>The server could not verify that you are authorized to access the URL requested. You either supplied the wrong credentials (e.g. a bad password), or your browser doesn&#39;t understand how to supply the credentials required.</p>
```

`401 UNAUTHORIZED`. A requisição é a mesma que listou todo paciente com notas no começo da aula.

### A regra por escrito

Com toda rota declarando seus papéis, as regras de acesso do console podem ser lidas no código, e
cabem numa tabela que alguém consegue revisar:

| rota | recepção | fisio | admin |
|---|---|---|---|
| `GET /console` | sim | sim | sim |
| `GET /agenda` | sim | sim | sim |
| `GET /patients/<name>/notes` | não | sim | não |
| `POST /patients/<name>/notes` | não | sim | não |
| `GET /export` | não | não | sim |

Repare que a administradora não lê notas clínicas. É uma decisão, não um descuido: a ana mantém o
sistema e não tem motivo clínico para ler as notas de um paciente. **Menor privilégio** quer dizer
que um papel recebe o que o trabalho dele exige, não tudo o que está abaixo dele. Uma hierarquia em
que admin implica todos os outros é prática e dá à conta mais atacada o maior volume de dados.
