---
title: O LIKE tem curingas próprios
version: 1
---

Um teste ainda falha, e é outro tipo de problema. O marcador garantiu que o valor é dado. Mas o valor
é um **padrão de `LIKE`**, e dentro de um padrão dois caracteres têm significado próprio: `%`
corresponde a qualquer sequência de caracteres e `_` a um caractere qualquer. Busque por `%`, e o
padrão `%%%` corresponde a todo paciente do portal:

```
(.venv) ana@vm:~/sc/search$ curl -s -G --data-urlencode 'surname=%' http://127.0.0.1:5000/patients
[{"clinic":"Pinheiros","first_name":"Marta","surname":"Avelar"},{"clinic":"Pinheiros","first_name":"Lucia","surname":"D'\u00c1vila"},{"clinic":"Santana","first_name":"Bruno","surname":"O'Neill"},{"clinic":"Moema","first_name":"Rafael","surname":"Souza"}]
```

Nenhum SQL foi injetado; a consulta fez o que um `LIKE` com esse padrão faz. Mesmo assim, a
recepcionista digitou um caractere e recebeu a lista inteira de pacientes, e uma busca por `S_uza`
acha `Souza` sem que ninguém tenha digitado um `o`. Numa tabela grande, um padrão cheio de curingas
também é lento. **O que um valor quer dizer dentro do programa que o lê é o código que decide, não
quem digita.**

A correção escapa os dois curingas, e o próprio caractere de escape, e diz ao SQLite qual caractere
escapa com `ESCAPE '\'`:

```
(.venv) ana@vm:~/sc/search$ git diff
diff --git a/app.py b/app.py
index d768bf2..6b6c640 100644
--- a/app.py
+++ b/app.py
@@ -47,6 +47,11 @@ def init_db():
         db().commit()
 
 
+def like_pattern(term):
+    escaped = term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
+    return f"%{escaped}%"
+
+
 @app.get("/patients")
 def search():
     term = request.args.get("surname", "")
@@ -55,8 +60,8 @@ def search():
         abort(400)
     rows = db().execute(
         "SELECT first_name, surname, clinic FROM patients "
-        f"WHERE surname LIKE ? ORDER BY {order}",
-        (f"%{term}%",),
+        f"WHERE surname LIKE ? ESCAPE '\\' ORDER BY {order}",
+        (like_pattern(term),),
     )
     return jsonify([dict(row) for row in rows])
 
```

```
(.venv) ana@vm:~/sc/search$ pytest -q
.....                                                                    [100%]
5 passed in 0.13s
```

**Cinco de cinco.** Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/search$ git commit -qam "Search for % and _ literally"
(.venv) ana@vm:~/sc/search$ git log --oneline
e44568f Search for % and _ literally
61f929c Pass the surname as a parameter, and allowlist the sort
ef40cab Search patients by surname, sorted
```

### Onde mais um valor é um pequeno programa

O `LIKE` é o caso desta aula; o hábito é mais amplo. Um valor posto numa expressão regular precisa de
`re.escape`; um valor posto num comando de shell é a aula 6; um valor posto numa página é a aula 4.
Toda vez, pergunte o que lê o valor em seguida e o que esse leitor trata como especial.
