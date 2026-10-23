---
title: O que um arquivo é, e de que tamanho pode ser
version: 1
---

Dois testes ainda falham. Um arquivo de texto puro chamado `scan.pdf` é aceito, e um arquivo de seis
megabytes também. Os dois são valores que quem envia escolheu: a extensão não diz nada sobre os bytes,
e uma requisição pode ser tão longa quanto quem a manda quiser, a não ser que o servidor diga outra
coisa.

### Olhe os bytes

Muitos formatos de arquivo começam com uma **assinatura** fixa, uns poucos bytes que dizem qual é o
formato. Todo PDF começa com `%PDF-`. A correção lê esses cinco bytes do fluxo enviado antes de gravar
qualquer coisa, recusa o arquivo com `400` se eles não estiverem lá, e volta o fluxo ao início para o
arquivo ser gravado inteiro.

Uma assinatura é um **mínimo**, não uma prova: um arquivo pode começar com `%PDF-` e estar quebrado, ou
trazer outra coisa depois. Onde o conteúdo importa mais, os próximos passos são interpretar o arquivo
com uma biblioteca que conhece o formato, e convertê-lo ou redesenhá-lo, para que o portal guarde um
arquivo que ele mesmo produziu. Para exames que uma fisioterapeuta abre num computador da clínica,
passar os envios por um antivírus antes de alguém abri-los também é prática comum.

### Limite o tamanho

O `MAX_CONTENT_LENGTH` faz o Flask recusar qualquer corpo de requisição maior que o limite com
`413 Request Entity Too Large`, **antes de a view rodar** e antes de o arquivo ser guardado em qualquer
lugar. Cinco megabytes é generoso para um exame escaneado; o número é uma decisão, escrita onde a
próxima pessoa possa vê-la.

```
(.venv) ana@vm:~/sc/upload$ git diff
diff --git a/app.py b/app.py
index b3a3e6a..17071b6 100644
--- a/app.py
+++ b/app.py
@@ -9,12 +9,16 @@ from flask import Flask, abort, jsonify, request, send_from_directory
 
 app = Flask(__name__)
 app.config["UPLOADS"] = Path("uploads")
+app.config["MAX_CONTENT_LENGTH"] = 5 * 1024 * 1024
 TEXT_SIZES = {"normal", "large"}
 
 
 @app.post("/exams")
 def upload():
     exam = request.files["exam"]
+    if exam.stream.read(5) != b"%PDF-":
+        abort(400)
+    exam.stream.seek(0)
     folder = app.config["UPLOADS"]
     folder.mkdir(parents=True, exist_ok=True)
     exam_id = secrets.token_hex(8)
```

```
(.venv) ana@vm:~/sc/upload$ pytest -q
........                                                                 [100%]
8 passed in 0.15s
```

Oito de oito. Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/upload$ git commit -qam "Accept only PDFs, up to 5 MB"
(.venv) ana@vm:~/sc/upload$ git log --oneline
fc5c71c Accept only PDFs, up to 5 MB
c69cdf0 Store uploads under ids, outside static, and serve them as downloads
be3b310 Keep preferences as validated JSON, not pickle
c3ee918 Exam uploads and text-size preferences
```

### A lista de verificação de envios

O que o portal faz agora, na ordem em que uma requisição encontra, é a lista de verificação para
qualquer envio:

| verificação | neste portal |
|---|---|
| um limite de tamanho, aplicado antes da view | `MAX_CONTENT_LENGTH`, 5 MB |
| o tipo pelos bytes, não pelo nome | a assinatura `%PDF-` |
| um nome que o servidor escolhe | `secrets.token_hex(8)` |
| armazenamento fora de tudo o que o servidor web serve | `uploads/`, não `static/` |
| servido como download, com tipo declarado | `as_attachment`, `mimetype`, `nosniff` |
| o dono conferido no download | aula 13, ainda por acrescentar |
