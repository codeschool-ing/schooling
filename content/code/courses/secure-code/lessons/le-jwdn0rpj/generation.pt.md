---
title: "Nasce: um id que ninguém calcula, num cookie que script nenhum lê"
version: 1
---

A primeira falha é a mais perigosa, e se esconde atrás de uma função com cara de cuidadosa:

```python
def new_session_id(name):
    return hashlib.md5(f"{name}{now():%Y%m%d%H%M}".encode()).hexdigest()
```

Um hash MD5 parece aleatório: 32 caracteres hexadecimais, diferentes para cada entrada. **Não é
aleatório. É uma função fixa de duas coisas que qualquer um sabe**, o nome do paciente e o minuto
em que ele entrou. Quem calcula o mesmo hash tem a mesma sessão, e o teste mostrou isso do lado de
quem defende: duas pessoas entrando como lucia no mesmo minuto receberam o mesmo id.

A regra é uma chamada. O módulo `secrets` do Python tira do gerador criptograficamente seguro do
sistema operacional, e `secrets.token_urlsafe(32)` devolve 32 bytes aleatórios, 256 bits, escritos
em 43 caracteres seguros num cookie. A OWASP pede pelo menos 64 bits de entropia num id de sessão;
256 deixam uma margem que ninguém nunca vai precisar discutir. O módulo `random` é a ferramenta
errada pelo mesmo motivo que o MD5 era: foi feito para ser repetível, e sua saída pode ser prevista
a partir de valores anteriores suficientes.

### Os três atributos do cookie

O id, então, é tão seguro quanto o cookie que o leva. Três atributos decidem quem mais pode lê-lo ou
fazer o navegador enviá-lo:

| atributo | o que ele impede |
|---|---|
| `HttpOnly` | o JavaScript da página ler o cookie, para que um script injetado no portal não copie o id (aula 7) |
| `Secure` | o navegador enviar o cookie por HTTP sem criptografia, onde qualquer um na mesma rede o lê |
| `SameSite=Lax` | o navegador anexar o cookie a um formulário que outro site envia ao portal (aula 9) |

Nenhum dos três é o padrão do `set_cookie`, e por isso a primeira versão não tinha nenhum. A
correção os põe num auxiliar só, para que nenhuma rota consiga gravar o cookie sem eles. Os
navegadores tratam `127.0.0.1` e `localhost` como origens seguras, então um cookie `Secure`
continua funcionando enquanto você desenvolve na sua máquina.

### A correção

Troque `hashlib` por `secrets`, escreva o id com `token_urlsafe` e grave o cookie só por meio de
`set_sid`. Depois rode os testes e faça o commit:

```
(.venv) ana@vm:~/sc/sessions$ git diff
diff --git a/app.py b/app.py
index 51c9f42..eb14d68 100644
--- a/app.py
+++ b/app.py
@@ -1,5 +1,5 @@
 # app.py
-import hashlib
+import secrets
 from datetime import datetime
 
 from flask import Flask, abort, jsonify, make_response, request
@@ -17,8 +17,12 @@ def check_password(name, password):
     return (name, password) in {("lucia", "lucia-pw"), ("rafael", "rafael-pw")}
 
 
-def new_session_id(name):
-    return hashlib.md5(f"{name}{now():%Y%m%d%H%M}".encode()).hexdigest()
+def new_session_id():
+    return secrets.token_urlsafe(32)
+
+
+def set_sid(response, sid):
+    response.set_cookie("sid", sid, httponly=True, secure=True, samesite="Lax")
 
 
 def current_patient():
@@ -32,9 +36,9 @@ def current_patient():
 def home():
     response = make_response("Vereda patient portal\n")
     if request.cookies.get("sid") not in SESSIONS:
-        sid = new_session_id("visitor")
+        sid = new_session_id()
         SESSIONS[sid] = {"patient": None}
-        response.set_cookie("sid", sid)
+        set_sid(response, sid)
     return response
 
 
@@ -45,10 +49,10 @@ def sign_in():
         abort(401)
     sid = request.cookies.get("sid")
     if sid not in SESSIONS:
-        sid = new_session_id(name)
+        sid = new_session_id()
     SESSIONS[sid] = {"patient": name}
     response = jsonify(patient=name)
-    response.set_cookie("sid", sid)
+    set_sid(response, sid)
     return response
 
 
```

```
(.venv) ana@vm:~/sc/sessions$ pytest -q --tb=no
...FFFF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_signing_in_issues_a_new_id - AssertionError: assert ...
FAILED test_app.py::test_an_idle_session_expires - AssertionError: assert 200...
FAILED test_app.py::test_a_session_has_an_absolute_limit - AssertionError: as...
FAILED test_app.py::test_signing_out_ends_the_session_on_the_server - Asserti...
4 failed, 3 passed in 0.14s
(.venv) ana@vm:~/sc/sessions$ git commit -qam "Draw session ids from secrets, and mark the cookie"
```

**Duas falhas a menos.** O id agora tem 43 caracteres que ninguém calcula, e a resposta que faz o
login diz como o navegador deve guardá-lo. Com o servidor rodando, o `curl` mostra o cabeçalho que
um navegador de verdade recebe:

```
(.venv) ana@vm:~/sc/sessions$ curl -si -d name=lucia -d password=lucia-pw http://127.0.0.1:5000/sign-in
HTTP/1.1 200 OK
Server: Werkzeug/3.1.9 Python/3.13.17
Date: Fri, 23 Oct 2026 15:03:30 GMT
Content-Type: application/json
Content-Length: 20
Set-Cookie: sid=3vZGSodFsBzECJzgVUuXZIFu60Hy3zrvRAymneatEcM; Secure; HttpOnly; Path=/; SameSite=Lax
Connection: close

{"patient":"lucia"}
```

O `Set-Cookie` leva o id e os três atributos; `Path=/` quer dizer que toda página do portal o
recebe. O id daquela resposta não pertence a ninguém além da execução que o imprimiu: rode o mesmo
comando duas vezes e os dois ids não têm nada em comum.
