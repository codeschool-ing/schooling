---
title: Uma consulta que não consegue devolver a linha errada
version: 1
---

A correção não é uma verificação acrescentada depois da consulta: *busque o exame, depois compare o
dono com a sessão.* Isso funciona, e deixa a decisão de acesso a um `if` esquecido de distância de
toda rota que busca um exame. **O formato mais seguro põe o dono dentro da consulta**, para o banco
nunca devolver uma linha que o paciente não pode ver:

```sql
SELECT id, title, taken FROM exams WHERE id = ? AND patient = ?
```

Com o dono vindo da sessão, essa consulta só tem dois resultados para a lucia: o exame dela, ou nada.
Não consegue devolver a linha da marta, seja qual for o número que chegue no endereço.

A correção põe essa consulta numa função, `own_exam`, e toda rota que age sobre um exame só passa por
ela. Ler e apagar usam a função, então **apagar só consegue apagar uma linha de que o paciente é
dono**, porque apaga pelo id da linha que `own_exam` devolveu.

```
(.venv) ana@vm:~/sc/exams$ git diff
diff --git a/app.py b/app.py
index 8995e3a..aa1244d 100644
--- a/app.py
+++ b/app.py
@@ -52,6 +52,16 @@ def signed_in():
     return name
 
 
+def own_exam(exam_id):
+    row = db().execute(
+        "SELECT id, title, taken FROM exams WHERE id = ? AND patient = ?",
+        (exam_id, signed_in()),
+    ).fetchone()
+    if row is None:
+        abort(404)
+    return row
+
+
 @app.get("/exams")
 def list_exams():
     name = request.args.get("patient", signed_in())
@@ -61,16 +71,12 @@ def list_exams():
 
 @app.get("/exams/<int:exam_id>")
 def read_exam(exam_id):
-    signed_in()
-    row = db().execute("SELECT id, title, taken FROM exams WHERE id = ?", (exam_id,)).fetchone()
-    if row is None:
-        abort(404)
-    return jsonify(dict(row))
+    return jsonify(dict(own_exam(exam_id)))
 
 
 @app.delete("/exams/<int:exam_id>")
 def delete_exam(exam_id):
-    signed_in()
-    db().execute("DELETE FROM exams WHERE id = ?", (exam_id,))
+    exam = own_exam(exam_id)
+    db().execute("DELETE FROM exams WHERE id = ?", (exam["id"],))
     db().commit()
     return "", 204
```

```
(.venv) ana@vm:~/sc/exams$ pytest -q --tb=no
...F...                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_list_shows_only_her_own_exams - AssertionError: ...
1 failed, 6 passed in 0.16s
(.venv) ana@vm:~/sc/exams$ git commit -qam "Read and delete an exam only for its owner"
```

**Cinco falhas somem de uma vez**: a leitura, a exclusão e as três linhas da grade. Resta uma, e é
outro formato da mesma falha, na próxima seção.

### 404, não 403

`own_exam` responde `404 Not Found` para um exame que existe e é de outra pessoa, a mesma resposta de
um exame que não existe. A aula 1 fez a mesma escolha para os agendamentos, e prometeu que esta aula
diria por quê.

Um `403 Forbidden` seria exato, e diria à lucia que o exame 2 **existe**. Contar os números e anotar
quais respondem `403` e quais `404` então diz a ela quantos exames o portal guarda e quais ids estão
em uso, e em alguns portais que uma certa pessoa tem um. **A resposta segura não diz nada que um
estranho já não soubesse.** O teste garante isso com exatidão: o status *e* o corpo das duas respostas
precisam ser iguais.

`403` é o certo onde a existência da coisa não é segredo e a pessoa precisa saber que não tem
permissão: o console da equipe da aula 12, onde o bruno sabe que notas clínicas existem e precisa
saber que não pode lê-las.
