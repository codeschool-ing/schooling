---
title: Marcadores para valores, lista de permissão para o resto
version: 1
---

A correção tem duas metades, porque a consulta tinha dois buracos.

**O sobrenome é um valor**, então vai por um marcador. O texto do SQL diz `LIKE ?`, e o padrão viaja
na tupla ao lado: `(f"%{term}%",)`. Montar o padrão `%D'Ávila%` em Python é seguro, porque continua
sendo um valor só; o que importa é que ele nunca vire parte do texto do SQL.

**A ordenação não é um valor.** `ORDER BY ?` ordenaria por uma string constante, a mesma em toda
linha, o que não ordena nada. Um nome de coluna precisa ser escrito no SQL, então a requisição não
pode fornecê-lo. Ela escolhe uma **chave** de `SORTS`, e o SQL recebe o texto que o código escreveu
para essa chave. Uma chave desconhecida é `400 Bad Request`, que é o que uma ordenação que ninguém
ofereceu é.

```
(.venv) ana@vm:~/sc/search$ git diff
diff --git a/app.py b/app.py
index 121204c..d768bf2 100644
--- a/app.py
+++ b/app.py
@@ -20,6 +20,7 @@ SAMPLE = [
     ("Marta", "Avelar", "Pinheiros"),
     ("Bruno", "O'Neill", "Santana"),
 ]
+SORTS = {"surname": "surname", "clinic": "clinic, surname"}
 
 
 def db():
@@ -49,10 +50,13 @@ def init_db():
 @app.get("/patients")
 def search():
     term = request.args.get("surname", "")
-    order = request.args.get("sort", "surname")
+    order = SORTS.get(request.args.get("sort", "surname"))
+    if order is None:
+        abort(400)
     rows = db().execute(
-        f"SELECT first_name, surname, clinic FROM patients "
-        f"WHERE surname LIKE '%{term}%' ORDER BY {order}"
+        "SELECT first_name, surname, clinic FROM patients "
+        f"WHERE surname LIKE ? ORDER BY {order}",
+        (f"%{term}%",),
     )
     return jsonify([dict(row) for row in rows])
 
```

```
(.venv) ana@vm:~/sc/search$ pytest -q --tb=no
....F                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_percent_and_underscore_are_searched_for_literally - ...
1 failed, 4 passed in 0.22s
```

**Quatro de cinco.** O teste do apóstrofo passa com a lucia encontrada, e `sort=age` é recusado
antes de qualquer SQL ser montado. O `f` em `f"WHERE surname LIKE ? ORDER BY {order}"` continua lá, e
é seguro por um motivo que um revisor confere numa linha: `order` só pode ser uma das duas strings
de `SORTS`.

Faça o commit deste passo:

```
(.venv) ana@vm:~/sc/search$ git commit -qam "Pass the surname as a parameter, and allowlist the sort"
```

### O que o marcador fez

O `sqlite3` mandou duas coisas ao banco: o texto `SELECT … WHERE surname LIKE ? ORDER BY surname`, e
o valor `%D'Ávila%`. O banco preparou o texto primeiro, com um buraco onde estava o `?`, e depois
comparou cada sobrenome com o valor. **Nenhum caractere do valor foi interpretado como SQL**, então
não há caractere para ninguém escapar, remover ou temer. É por isso que a correção não precisa de
lista de caracteres perigosos, e por isso funciona igual em todo banco e toda linguagem que tem um
driver com marcadores, ou seja, todas.

Cada driver escreve o marcador do seu jeito: `?` no `sqlite3`, `%s` no `psycopg` para PostgreSQL,
`:name` no `text()` do SQLAlchemy, `$1` no `pgx` do Go. O `%s` merece um aviso próprio: no `psycopg`
ele é um marcador, passado ao `execute` com os valores ao lado, e **os mesmos dois caracteres com o
operador `%` do Python são formatação de string**, que é a falha de novo.
