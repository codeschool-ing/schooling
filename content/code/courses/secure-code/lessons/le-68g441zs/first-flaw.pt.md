---
title: A primeira falha, achada por um teste
version: 1
---

O ciclo deste curso, uma vez, sobre o requisito da primeira seção: *o paciente pode cancelar um
agendamento pela internet até 24 horas antes da sessão.* Aqui está o botão de cancelar como a ana o
escreveu, com só o bastante do portal para rodar. Salve como `~/sc/cancel/app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import secrets\nfrom datetime import datetime, timedelta\n\nfrom flask import Flask, abort, jsonify, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\n", "note": "O Flask assina o cookie de sessão com a `secret_key`. Uma aleatória a cada início basta para um programa que só roda na sua máquina; a aula 16 trata de guardar uma de verdade."}, {"code": "BOOKINGS = {\n    101: {\"patient\": \"lucia\", \"starts\": datetime(2026, 11, 3, 9, 0), \"status\": \"booked\"},\n    102: {\"patient\": \"rafael\", \"starts\": datetime(2026, 11, 3, 10, 0), \"status\": \"booked\"},\n}\n\n", "note": "Dois agendamentos guardados na memória em vez de um banco de dados, para o programa inteiro caber na página. A aula 5 traz o SQLite."}, {"code": "def now():\n    return datetime.now()\n\n\ndef can_cancel(booking, at):\n    return booking[\"starts\"] - at >= timedelta(hours=24)\n\n", "note": "O relógio é uma função separada, para que um teste possa substituí-lo. A regra é o requisito palavra por palavra: pelo menos 24 horas antes da sessão."}, {"code": "@app.post(\"/bookings/<int:booking_id>/cancel\")\ndef cancel(booking_id):\n    if \"patient\" not in session:\n        abort(401)\n    booking = BOOKINGS.get(booking_id)\n    if booking is None:\n        abort(404)\n    if not can_cancel(booking, now()):\n        abort(409)\n    booking[\"status\"] = \"cancelled\"\n    return jsonify(id=booking_id, status=booking[\"status\"])", "note": "Entrou, o agendamento existe, ainda dá tempo: cancela. Cada verificação responde a uma frase do requisito. Leia todas e pergunte qual frase nunca foi escrita."}]}
```

O programa tem três verificações e todas estão corretas. O que falta é uma verificação que ninguém
pediu. **Os testes abaixo enunciam o requisito, e depois a frase que o requisito esqueceu.** Salve-os
ao lado, como `test_app.py`:

```python
# test_app.py
from datetime import datetime

import pytest

import app as portal


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setattr(portal, "now", lambda: datetime(2026, 11, 1, 9, 0))
    for booking in portal.BOOKINGS.values():
        booking["status"] = "booked"
    return portal.app.test_client()


def sign_in(client, patient):
    with client.session_transaction() as session:
        session["patient"] = patient


def test_a_patient_cancels_their_own_booking(client):
    sign_in(client, "lucia")
    assert client.post("/bookings/101/cancel").status_code == 200


def test_too_late_to_cancel(client, monkeypatch):
    monkeypatch.setattr(portal, "now", lambda: datetime(2026, 11, 2, 10, 0))
    sign_in(client, "lucia")
    assert client.post("/bookings/101/cancel").status_code == 409


def test_a_patient_cannot_cancel_somebody_elses_booking(client):
    sign_in(client, "lucia")
    assert client.post("/bookings/102/cancel").status_code == 404
    assert portal.BOOKINGS[102]["status"] == "booked"
```

Quatro coisas nesse arquivo valem saber, porque toda aula usa:

- **`client` é uma fixture**: o pytest a chama e entrega o resultado a todo teste que a menciona. Ela
  fixa o relógio em 1º de novembro de 2026 às 09:00, volta os dois agendamentos para `booked` e
  devolve o **cliente de teste** do Flask, que envia requisições à aplicação sem iniciar servidor.
- **`monkeypatch` troca um nome durante um teste** e o devolve depois. É por isso que `now` era uma
  função separada.
- **`sign_in` escreve a sessão diretamente.** Entrar de verdade é assunto das aulas 10 e 11; aqui só
  atrapalharia.
- **O último teste é a frase que faltava**: lucia, autenticada, tenta cancelar o agendamento de
  rafael, e a resposta tem de ser como se o agendamento não existisse, e ele tem de continuar
  marcado. A aula 13 diz por que 404 e não 403.

### Vermelho

```
(.venv) ana@vm:~/sc/cancel$ pytest
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/cancel
collected 3 items

test_app.py ..F                                                          [100%]

=================================== FAILURES ===================================
_____________ test_a_patient_cannot_cancel_somebody_elses_booking ______________

client = <FlaskClient <Flask 'app'>>

    def test_a_patient_cannot_cancel_somebody_elses_booking(client):
        sign_in(client, "lucia")
>       assert client.post("/bookings/102/cancel").status_code == 404
E       AssertionError: assert 200 == 404
E        +  where 200 = <WrapperTestResponse streamed [200 OK]>.status_code
E        +    where <WrapperTestResponse streamed [200 OK]> = post('/bookings/102/cancel')
E        +      where post = <FlaskClient <Flask 'app'>>.post

test_app.py:35: AssertionError
=========================== short test summary info ============================
FAILED test_app.py::test_a_patient_cannot_cancel_somebody_elses_booking - Ass...
========================= 1 failed, 2 passed in 0.12s ==========================
```

Dois testes passam e o terceiro falha, e o pytest diz exatamente como: a aplicação respondeu `200`
onde o teste esperava `404`. **Essa linha é a falha, mostrada na sua própria aplicação por uma
requisição.** Qualquer paciente autenticado cancela qualquer agendamento cujo número consiga
adivinhar, e os números começam em 101 e sobem um a um.

Faça commit da versão com falha antes de mexer nela, para a correção ser um diff que dá para ler
depois:

```
(.venv) ana@vm:~/sc/cancel$ git add app.py test_app.py
(.venv) ana@vm:~/sc/cancel$ git commit -m "Cancel a booking up to 24 hours before"
[main (root-commit) 556a7f2] Cancel a booking up to 24 hours before
 2 files changed, 69 insertions(+)
 create mode 100644 app.py
 create mode 100644 test_app.py
```

### Correção

A correção é uma condição: um agendamento que não é do paciente autenticado é tratado como um que não
existe. Mude a linha `if booking is None:` do `app.py`, e o `git diff` mostra a mudança inteira:

```
(.venv) ana@vm:~/sc/cancel$ git diff
diff --git a/app.py b/app.py
index 0b47e64..6a47a61 100644
--- a/app.py
+++ b/app.py
@@ -25,7 +25,7 @@ def cancel(booking_id):
     if "patient" not in session:
         abort(401)
     booking = BOOKINGS.get(booking_id)
-    if booking is None:
+    if booking is None or booking["patient"] != session["patient"]:
         abort(404)
     if not can_cancel(booking, now()):
         abort(409)
```

### Verde

```
(.venv) ana@vm:~/sc/cancel$ pytest
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/cancel
collected 3 items

test_app.py ...                                                          [100%]

============================== 3 passed in 0.10s ===============================
```

Faça commit da correção junto com o teste que a prova. A partir de agora a frase que faltava está
escrita, numa forma que falha alto se alguém remover a verificação:

```
(.venv) ana@vm:~/sc/cancel$ git commit -am "Refuse to cancel a booking that is not the patient's"
[main 6cb0f01] Refuse to cancel a booking that is not the patient's
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### E roda

Os testes nunca iniciaram servidor, mas a aplicação é de verdade. `flask --app app run` a inicia na
porta 5000 de `127.0.0.1` e fica em primeiro plano, escrevendo uma linha para cada requisição que
responde; `Ctrl+C` para.

```
(.venv) ana@vm:~/sc/cancel$ flask --app app run
 * Serving Flask app 'app'
 * Debug mode: off
Address already in use
Port 5000 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

O aviso do Flask é exato e vale levar ao pé da letra: o servidor embutido dele é para
desenvolvimento, na sua própria máquina, que é o único lugar onde este curso o usa. De um **segundo
terminal**, uma requisição sem sessão recebe a recusa para a qual a primeira verificação foi escrita:

```
(.venv) ana@vm:~/sc/cancel$ curl -si -X POST http://127.0.0.1:5000/bookings/101/cancel
HTTP/1.1 401 UNAUTHORIZED
Server: Werkzeug/3.1.9 Python/3.13.16
Date: Fri, 23 Oct 2026 03:24:54 GMT
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

`401 UNAUTHORIZED`, e uma página HTML dizendo isso. O cabeçalho `Vary: Cookie` é o Flask avisando que
a resposta depende do cookie de sessão, que esta requisição não enviou.
