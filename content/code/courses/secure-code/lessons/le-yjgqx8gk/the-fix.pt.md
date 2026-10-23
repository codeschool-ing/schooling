---
title: Uma página curta, um log completo
version: 1
---

A correção mantém todo fato que a equipe de suporte queria e o leva para onde a equipe lê. Eis o
`app.py` novo:

```python
# app.py
import logging
import secrets

from flask import Flask, request
from werkzeug.exceptions import HTTPException
from werkzeug.security import check_password_hash, generate_password_hash

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s %(message)s")
log = logging.getLogger("portal")

app = Flask(__name__)
USERS = {"lucia": generate_password_hash("correct horse battery staple")}
PHONES = {"lucia": "11987654321"}


@app.errorhandler(Exception)
def unexpected(error):
    if isinstance(error, HTTPException):
        return error
    reference = secrets.token_hex(4)
    log.exception("unexpected error ref=%s path=%r", reference, request.path)
    return {"error": "something went wrong on our side", "reference": reference}, 500


@app.post("/login")
def login():
    name = request.form.get("name", "")
    password = request.form.get("password", "")
    if name in USERS and check_password_hash(USERS[name], password):
        log.info("sign-in succeeded name=%r", name)
        return {"signed_in": name}
    log.warning("sign-in failed name=%r", name)
    return {"error": "wrong name or password"}, 401


@app.get("/patients/<name>/phone")
def phone(name):
    return {"phone": PHONES[name]}
```

Três mudanças, cada uma de uma ou duas linhas:

- **A página de erro diz que algo deu errado, e dá uma referência**: oito caracteres hexadecimais
  vindos do `secrets`, diferentes a cada vez. Um paciente que liga para a clínica a lê em voz alta, e a
  equipe acha a falha exata no log.
- **O `log.exception` escreve o traceback no log**, com a mesma referência e o caminho que falhou.
  Tudo o que a página antiga mostrava continua registrado; só não é mostrado a quem perguntou.
- **O login registra o resultado e o nome, e nunca a senha**, e registra o nome com `%r`, que o
  escreve como literal de string do Python, com aspas e quebras de linha escapadas. A seção depois da
  próxima diz por quê.

```
(.venv) ana@vm:~/sc/errors$ pytest -q
....                                                                     [100%]
4 passed in 0.38s
```

As mesmas três requisições contra a versão nova:

```
(.venv) ana@vm:~/sc/errors$ flask --app app run > server.log 2>&1 &
(.venv) ana@vm:~/sc/errors$ curl -s http://127.0.0.1:5000/patients/marta/phone
{"error":"something went wrong on our side","reference":"9e047314"}
(.venv) ana@vm:~/sc/errors$ curl -s -d 'name=lucia&password=correct horse battery staple' http://127.0.0.1:5000/login
{"signed_in":"lucia"}
(.venv) ana@vm:~/sc/errors$ grep -A 8 'portal' server.log
ERROR portal unexpected error ref=9e047314 path='/patients/marta/phone'
Traceback (most recent call last):
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py", line 917, in full_dispatch_request
    rv = self.dispatch_request()
  File "/home/ana/sc/.venv/lib/python3.13/site-packages/flask/app.py", line 902, in dispatch_request
    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)  # type: ignore[no-any-return]
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "/home/ana/sc/errors/app.py", line 39, in phone
    return {"phone": PHONES[name]}
--
INFO portal sign-in succeeded name='lucia'
INFO werkzeug 127.0.0.1 - - [23/Oct/2026 11:28:18] "POST /login HTTP/1.1" 200 -
```

A página diz *"something went wrong on our side"* e dá a referência. O log traz a mesma referência, o
caminho e o traceback até a linha que falhou, que o `grep -A 8` cortou aqui. A linha do login diz quem
entrou e que deu certo, e nada sobre o que foi digitado.

### E o depurador

O modo de depuração do Flask, o B201 da aula 19, transforma todo erro numa página interativa que
mostra o código e consegue rodar Python no servidor. É a página de erro que fala demais, levada ao
extremo. **Ele é para a sua máquina, e é ligado por `--debug` ou `FLASK_DEBUG=1`**, nunca por código
que vai para produção. Nada nas transcrições desta aula o executa.
