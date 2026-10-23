---
title: Listas, donos na requisição, e identificadores
version: 1
---

A rota da lista tinha outra versão da falha. Ela tirava o paciente da sessão, a não ser que a
requisição nomeasse um:

```python
    name = request.args.get("patient", signed_in())
```

Havia um motivo: o console da equipe queria reaproveitar a rota para listar os exames de um paciente
para a fisioterapeuta. Então o `?patient=` foi acrescentado, funcionou para a equipe, e funcionou do
mesmo jeito para todo paciente, porque a rota nunca perguntou quem estava mandando. **Um dono tirado
da requisição é um dono que o cliente escolheu.**

A correção tira o dono da sessão e de nada mais. Se a equipe precisa dos exames de um paciente, isso é
**outra rota**, no console, atrás do `requires` da aula 12, com a regra própria sobre quais pacientes
uma fisioterapeuta pode ver. Uma rota servindo dois públicos é como uma verificação pensada para um
deles acaba não valendo para nenhum.

```
(.venv) ana@vm:~/sc/exams$ git diff
diff --git a/app.py b/app.py
index aa1244d..945fa43 100644
--- a/app.py
+++ b/app.py
@@ -2,7 +2,7 @@
 import secrets
 import sqlite3
 
-from flask import Flask, abort, g, jsonify, request, session
+from flask import Flask, abort, g, jsonify, session
 
 app = Flask(__name__)
 app.secret_key = secrets.token_bytes(32)
@@ -64,8 +64,7 @@ def own_exam(exam_id):
 
 @app.get("/exams")
 def list_exams():
-    name = request.args.get("patient", signed_in())
-    rows = db().execute("SELECT id, title, taken FROM exams WHERE patient = ?", (name,))
+    rows = db().execute("SELECT id, title, taken FROM exams WHERE patient = ?", (signed_in(),))
     return jsonify([dict(row) for row in rows])
 
 
```

```
(.venv) ana@vm:~/sc/exams$ pytest -q
.......                                                                  [100%]
7 passed in 0.17s
```

Sete de sete. Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/exams$ git commit -qam "List only the signed-in patient's exams"
(.venv) ana@vm:~/sc/exams$ git log --oneline
ffa7435 List only the signed-in patient's exams
6ed7268 Read and delete an exam only for its owner
d284baa List, show and delete a patient's exams
```

### Identificadores aleatórios teriam evitado isto?

Em parte, e o "em parte" é a armadilha. Se os exames tivessem ids como `ex-6yyzbgfd` em vez de
`1, 2, 3`, ninguém acharia o exame da marta contando. Vale a pena ter isso, e os registros deste
próprio catálogo usam ids opacos por outros motivos. Mas **um id impossível de adivinhar não é
verificação de acesso**:

- Ids vazam. Aparecem em links compartilhados por e-mail, no histórico do navegador num computador
  compartilhado, em capturas de tela anexadas a chamados de suporte, nos logs de todo proxy entre o
  navegador e o servidor.
- Ids sobrevivem ao próprio segredo. Um id visto uma vez fica conhecido para sempre, e o registro por
  trás dele não muda de lugar quando alguém deveria deixar de vê-lo.
- Ids aleatórios escondem a falha dos testes que a achariam. O teste da grade funciona com quaisquer
  ids; uma conferência manual que tenta `/exams/2` para de funcionar, e a verificação que falta
  continua faltando.

Então identificadores aleatórios são **defesa em profundidade**, uma segunda camada sobre a consulta
com escopo, nunca um substituto para ela. O teste da grade é o que prova que a primeira camada está lá.
