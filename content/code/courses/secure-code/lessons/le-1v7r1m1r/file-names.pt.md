---
title: Nomes que o portal escolhe, fora da raiz da web
version: 1
---

A primeira versão fazia três coisas com o nome que o navegador mandava. **Usava-o como caminho**, então
`../escape.pdf` subiu para fora da pasta de envios. **Mantinha-o como nome guardado**, então quem envia
escolhe como o arquivo se chama no servidor, inclusive o nome de um arquivo que já está lá. E gravava
em **`static/uploads`**, uma pasta que o Flask serve a qualquer um, com esse nome.

O nome mais seguro é um que quem envia não escolhe. **O portal sorteia um id com o `secrets`, guarda o
arquivo como `<id>.pdf` numa pasta que não é servida, e devolve o id.** O nome de quem enviou nunca toca
o sistema de arquivos, então não há nada a limpar: nenhum `../`, nenhum nome reservado de outro sistema
operacional, nenhum `scan.pdf` de dois pacientes sobrescrevendo um ao outro.

O download muda para combinar. O `send_from_directory` já recusa um caminho que saia da pasta dele, e
por isso é a função certa para servir arquivos. Três argumentos deixam a resposta explícita:

- **`mimetype="application/pdf"`** diz o que o arquivo é, em vez de adivinhar por um nome.
- **`as_attachment=True`** manda `Content-Disposition: attachment`, para o navegador baixar o arquivo
  em vez de desenhá-lo dentro da origem do portal, onde os scripts dele rodariam com os cookies do
  portal se o arquivo fosse HTML.
- **`X-Content-Type-Options: nosniff`** diz ao navegador que acredite no tipo declarado e não adivinhe
  um a partir dos bytes.

```
(.venv) ana@vm:~/sc/upload$ git diff
diff --git a/app.py b/app.py
index e80510c..b3a3e6a 100644
--- a/app.py
+++ b/app.py
@@ -2,12 +2,13 @@
 import base64
 import binascii
 import json
+import secrets
 from pathlib import Path
 
 from flask import Flask, abort, jsonify, request, send_from_directory
 
 app = Flask(__name__)
-app.config["UPLOADS"] = Path("static/uploads")
+app.config["UPLOADS"] = Path("uploads")
 TEXT_SIZES = {"normal", "large"}
 
 
@@ -16,13 +17,22 @@ def upload():
     exam = request.files["exam"]
     folder = app.config["UPLOADS"]
     folder.mkdir(parents=True, exist_ok=True)
-    exam.save(folder / exam.filename)
-    return jsonify(id=exam.filename), 201
-
-
-@app.get("/exams/<name>")
-def download(name):
-    return send_from_directory(app.config["UPLOADS"], name)
+    exam_id = secrets.token_hex(8)
+    exam.save(folder / f"{exam_id}.pdf")
+    return jsonify(id=exam_id), 201
+
+
+@app.get("/exams/<exam_id>")
+def download(exam_id):
+    response = send_from_directory(
+        app.config["UPLOADS"],
+        f"{exam_id}.pdf",
+        mimetype="application/pdf",
+        as_attachment=True,
+        download_name="exam.pdf",
+    )
+    response.headers["X-Content-Type-Options"] = "nosniff"
+    return response
 
 
 @app.post("/preferences")
```

```
(.venv) ana@vm:~/sc/upload$ pytest -q --tb=no
..FF....                                                                 [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_file_that_is_not_a_pdf_is_refused - AssertionError...
FAILED test_app.py::test_a_large_file_is_refused - AssertionError: assert 201...
2 failed, 6 passed in 0.24s
```

**Seis de oito.** Faça o commit:

```
(.venv) ana@vm:~/sc/upload$ git commit -qam "Store uploads under ids, outside static, and serve them as downloads"
```

Duas coisas que esta correção não faz, e um portal de verdade precisa. **De quem é o exame?** Qualquer
paciente com um id consegue baixá-lo; o id é aleatório, e a aula 13 explicou por que ids aleatórios não
são verificação de acesso. O envio registra o dono, e o download o confere. E **como ele se chamava?**
Pacientes gostam de ver os próprios nomes de arquivo. Guarde o nome como texto ao lado do id, passe-o
pelo `werkzeug.utils.secure_filename` se ele for usado num cabeçalho, e nunca como caminho.
