---
title: Segredos pelo ambiente, e recusar sem eles
version: 1
---

O jeito comum de um segredo chegar a um programa em execução é uma **variável de ambiente**. Quem inicia o processo a define: um gerenciador de serviços, uma plataforma de contêineres, um sistema de CI, um cofre de segredos. O programa a lê ao iniciar, e ela nunca é escrita num arquivo que o projeto compartilha.

Os testes dizem três coisas. A aplicação pega os segredos do ambiente. Ela **se recusa a iniciar**
quando falta um. E nenhum segredo está escrito no código. Salve como `test_app.py`:

```python
# test_app.py
import importlib

import pytest

NAMES = ("PORTAL_SECRET_KEY", "SMS_API_KEY")


def load(monkeypatch, **env):
    for name in NAMES:
        monkeypatch.delenv(name, raising=False)
    for name, value in env.items():
        monkeypatch.setenv(name, value)
    import app
    return importlib.reload(app)


def test_secrets_come_from_the_environment(monkeypatch):
    portal = load(monkeypatch, PORTAL_SECRET_KEY="k" * 32, SMS_API_KEY="test-key")
    assert portal.app.secret_key == "k" * 32
    assert portal.SMS_API_KEY == "test-key"


def test_the_app_refuses_to_start_without_them(monkeypatch):
    with pytest.raises(RuntimeError, match="PORTAL_SECRET_KEY"):
        load(monkeypatch)


def test_no_secret_is_written_in_the_code():
    with open("app.py") as source:
        assert "sms_live_" not in source.read()
```

O `load` limpa as duas variáveis, define as que um teste pede e importa o `app.py` de novo, para cada
teste ver o módulo como ele iniciaria naquele ambiente. Contra a primeira versão:

```
(.venv) ana@vm:~/sc/secrets$ pytest -q --tb=no
FFF                                                                      [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_secrets_come_from_the_environment - AssertionError: ...
FAILED test_app.py::test_the_app_refuses_to_start_without_them - Failed: DID ...
FAILED test_app.py::test_no_secret_is_written_in_the_code - assert 'sms_live_...
3 failed in 0.08s
```

Faça commit como está, que é exatamente o erro de que trata a próxima seção:

```
(.venv) ana@vm:~/sc/secrets$ git add app.py test_app.py
(.venv) ana@vm:~/sc/secrets$ git commit -q -m "Send reminders by SMS"
```

### Falhar fechado

Eis o `app.py` novo:

```python
# app.py
import os

from flask import Flask


def required(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"{name} is not set: the application will not start without it")
    return value


app = Flask(__name__)
app.secret_key = required("PORTAL_SECRET_KEY")
SMS_API_KEY = required("SMS_API_KEY")


@app.get("/health")
def health():
    return {"sms": bool(SMS_API_KEY)}
```

```
(.venv) ana@vm:~/sc/secrets$ pytest -q
...                                                                      [100%]
3 passed in 0.27s
```

**O `required` se recusa a iniciar em vez de recorrer a um padrão.** Um programa que usa em silêncio
uma chave padrão quando a variável falta, `os.environ.get("PORTAL_SECRET_KEY", "dev")`, inicia em
produção com uma chave impressa no repositório, e todos os testes passam. Recusar transforma a
variável ausente num erro de inicialização que alguém vê em minutos:

```
(.venv) ana@vm:~/sc/secrets$ python3 -c 'import app'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import app
  File "/home/ana/sc/secrets/app.py", line 15, in <module>
    app.secret_key = required("PORTAL_SECRET_KEY")
                     ~~~~~~~~^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/sc/secrets/app.py", line 10, in required
    raise RuntimeError(f"{name} is not set: the application will not start without it")
RuntimeError: PORTAL_SECRET_KEY is not set: the application will not start without it
```

### Na sua máquina: um arquivo `.env` que o git ignora

Para desenvolvimento, as variáveis moram num arquivo chamado `.env` na pasta do projeto, e **o
`.gitignore` o mantém fora de todo commit**. Gere uma chave de sessão aleatória nele, com um valor
provisório para a chave do SMS, e confira que o git o ignora:

```
(.venv) ana@vm:~/sc/secrets$ printf 'PORTAL_SECRET_KEY=%s\nSMS_API_KEY=%s\n' "$(python3 -c 'import secrets; print(secrets.token_hex(32))')" sms_test_0000 > .env
(.venv) ana@vm:~/sc/secrets$ printf '.env\n__pycache__/\n' > .gitignore
(.venv) ana@vm:~/sc/secrets$ git check-ignore -v .env
.gitignore:1:.env	.env
(.venv) ana@vm:~/sc/secrets$ git status --short
 M app.py
?? .gitignore
```

O `git check-ignore -v` nomeia a regra que ignora o arquivo, e o `git status` nem lista o `.env`. Um
shell o carrega com `set -a`, que exporta toda variável que o arquivo define, e a aplicação as lê:

```
(.venv) ana@vm:~/sc/secrets$ set -a; . ./.env; set +a; python3 -c 'import app; print(app.SMS_API_KEY)'
sms_test_0000
```

O arquivo `.env` continua sendo um segredo no disco. No seu notebook, para uma chave de
desenvolvimento, tudo bem; não é assim que a produção recebe os segredos, e esse é o assunto da última
seção desta aula.
