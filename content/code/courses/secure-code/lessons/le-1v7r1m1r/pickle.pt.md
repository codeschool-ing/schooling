---
title: Preferências num formato que só guarda dados
version: 1
---

O cookie de preferências é escrito com `pickle.dumps` e lido de volta com `pickle.loads`. Rode sozinho o
teste que manda um cookie em pickle:

```
(.venv) ana@vm:~/sc/upload$ pytest -q --tb=short -k pickled
F                                                                        [100%]
=================================== FAILURES ===================================
_______________________ test_a_pickled_cookie_is_refused _______________________
/home/ana/sc/upload/test_app.py:64: in test_a_pickled_cookie_is_refused
    assert client.get("/preferences").status_code == 400
E   AssertionError: assert 200 == 400
E    +  where 200 = <WrapperTestResponse streamed [200 OK]>.status_code
E    +    where <WrapperTestResponse streamed [200 OK]> = get('/preferences')
E    +      where get = <FlaskClient <Flask 'app'>>.get
=========================== short test summary info ============================
FAILED test_app.py::test_a_pickled_cookie_is_refused - AssertionError: assert...
1 failed, 7 deselected in 0.12s
```

`assert 200 == 400`: **o portal desfez o pickle do cookie e respondeu normalmente.** Faria isso com
qualquer cookie, de qualquer navegador, montado por qualquer pessoa, e a primeira seção disse o que isso
quer dizer no caso do `pickle`. O outro teste de preferências que falha mostra a mesma coisa pelo outro
lado: o cookie que o portal escreve não pode ser lido como nada além de pickle.

A correção muda três coisas, e a primeira é a que importa:

- **JSON em vez de pickle.** O `json.loads` constrói strings, números, listas e dicionários, e nada
  mais, sejam quais forem os bytes. O cookie vai em base64 para as aspas e chaves viajarem com
  segurança num cabeçalho de cookie.
- **Validação do que voltou**, a lista de permissão da aula 2: o valor precisa ser um dicionário cujo
  `text_size` é um dos tamanhos que o portal oferece. Um cookie que não é base64, não é JSON ou não tem
  esse formato é `400`.
- **Validação na entrada também**, para o portal nunca escrever um tamanho que se recusaria a ler.

```
(.venv) ana@vm:~/sc/upload$ git diff
diff --git a/app.py b/app.py
index 9806374..e80510c 100644
--- a/app.py
+++ b/app.py
@@ -1,12 +1,14 @@
 # app.py
 import base64
-import pickle
+import binascii
+import json
 from pathlib import Path
 
-from flask import Flask, jsonify, request, send_from_directory
+from flask import Flask, abort, jsonify, request, send_from_directory
 
 app = Flask(__name__)
 app.config["UPLOADS"] = Path("static/uploads")
+TEXT_SIZES = {"normal", "large"}
 
 
 @app.post("/exams")
@@ -26,13 +28,22 @@ def download(name):
 @app.post("/preferences")
 def save_preferences():
     prefs = {"text_size": request.form.get("text_size", "normal")}
+    if prefs["text_size"] not in TEXT_SIZES:
+        abort(400)
     response = jsonify(prefs)
-    response.set_cookie("prefs", base64.b64encode(pickle.dumps(prefs)).decode())
+    response.set_cookie("prefs", base64.urlsafe_b64encode(json.dumps(prefs).encode()).decode())
     return response
 
 
 @app.get("/preferences")
 def read_preferences():
     raw = request.cookies.get("prefs")
-    prefs = pickle.loads(base64.b64decode(raw)) if raw else {"text_size": "normal"}
-    return jsonify(prefs)
+    if raw is None:
+        return jsonify(text_size="normal")
+    try:
+        prefs = json.loads(base64.urlsafe_b64decode(raw))
+    except (binascii.Error, ValueError):
+        abort(400)
+    if not isinstance(prefs, dict) or prefs.get("text_size") not in TEXT_SIZES:
+        abort(400)
+    return jsonify(text_size=prefs["text_size"])
```

```
(.venv) ana@vm:~/sc/upload$ pytest -q --tb=no
.FFFF...                                                                 [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_name_cannot_leave_the_upload_folder - AssertionErr...
FAILED test_app.py::test_a_file_that_is_not_a_pdf_is_refused - AssertionError...
FAILED test_app.py::test_a_large_file_is_refused - AssertionError: assert 201...
FAILED test_app.py::test_a_download_is_an_attachment - AssertionError: assert...
4 failed, 4 passed in 0.16s
```

**Os dois testes de preferências passam**, e quatro testes de envio continuam falhando. Faça o commit:

```
(.venv) ana@vm:~/sc/upload$ git commit -qam "Keep preferences as validated JSON, not pickle"
```

### Quando o valor não pode ser alterado

O tamanho do texto pode ser o que o paciente quiser, então nada se perde se alguém editar o cookie.
Quando um valor não pode ser editável pelo cliente, um preço, um papel, o id de um paciente, há duas
respostas. Guardá-lo **no servidor**, na tabela de sessões da aula 10, que é a melhor. Ou **assiná-lo**,
como o próprio cookie de sessão do Flask faz com o `itsdangerous`: o servidor consegue então saber se os
bytes são os que ele escreveu. Assinar protege a integridade e mais nada; o formato lá dentro ainda
precisa ser de dados, porque um pickle assinado é tão seguro quanto a chave que o assinou.
