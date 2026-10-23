---
title: Um comando, antes de todo commit
version: 1
---

Verificações ajudam quando rodam a cada mudança sem ninguém precisar lembrar. O arranjo mínimo que
faz isso é **um script que roda tudo, e um hook do git que roda o script antes de cada commit**.
Salve isto como `check.sh`:

```sh
# check.sh
# Every automated check of the project, in one command. Stops at the first failure.
set -e
pytest -q
bandit -q -r . -x ./test_app.py -f custom --msg-template '{relpath}:{line}: {test_id} {msg}'
pip-audit -r requirements.txt
```

O `set -e` faz o script parar, e devolver falha, no primeiro comando que falhar, então uma
verificação falhando não passa despercebida rolando a tela. O projeto precisa do seu
`requirements.txt` para o pip-audit, e o git roda o que estiver em `.git/hooks/pre-commit` antes de
registrar um commit, recusando o commit se falhar:

```
(.venv) ana@vm:~/sc/checks$ printf 'flask==3.1.3\n' > requirements.txt
(.venv) ana@vm:~/sc/checks$ printf '#!/bin/sh\nexec sh ./check.sh\n' > .git/hooks/pre-commit
(.venv) ana@vm:~/sc/checks$ chmod +x .git/hooks/pre-commit
```

Agora faça commit da versão apressada:

```
(.venv) ana@vm:~/sc/checks$ git add .
(.venv) ana@vm:~/sc/checks$ git commit -m "Reset codes and receipt ids"
..                                                                       [100%]
2 passed in 0.11s
app.py:8: B105 Possible hardcoded password: 'vereda-dev'
app.py:12: B311 Standard pseudo-random generators are not suitable for security/cryptographic purposes.
app.py:16: B324 Use of weak MD5 hash for security. Consider usedforsecurity=False
app.py:20: B201 A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
```

Os testes passaram, o bandit falhou, e **o git não registrou nada**: não há commit para desfazer,
porque o hook o barrou antes de ele existir. Agora o `app.py` corrigido, com a chave secreta
aleatória de novo como na aula 1, o código de redefinição vindo do `secrets`, o identificador do
recibo declarado como uso que não é de segurança, e a linha do depurador removida (inicie o servidor
com `flask --app app run`):

```python
# app.py
import hashlib
import secrets

from flask import Flask

app = Flask(__name__)
app.secret_key = secrets.token_bytes(32)


def reset_code():
    return "".join(secrets.choice("0123456789") for _ in range(6))


def receipt_id(booking):
    return hashlib.md5(str(booking).encode(), usedforsecurity=False).hexdigest()
```

```
(.venv) ana@vm:~/sc/checks$ git add app.py
(.venv) ana@vm:~/sc/checks$ git commit -m "Reset codes and receipt ids, from secrets and without the debugger"
..                                                                       [100%]
2 passed in 0.09s
No known vulnerabilities found
[main (root-commit) c034774] Reset codes and receipt ids, from secrets and without the debugger
 4 files changed, 35 insertions(+)
 create mode 100644 app.py
 create mode 100644 check.sh
 create mode 100644 requirements.txt
 create mode 100644 test_app.py
```

As três verificações passaram e o commit foi feito. O `root-commit` nas últimas linhas é a prova de
que a tentativa recusada não deixou nada para trás: este é o primeiro commit do repositório.

### O que um hook local é, e o que não é

Um hook mora em `.git/hooks`, que o git nunca inclui num commit, então **cada pessoa o instala na
própria máquina** e qualquer um pode pulá-lo com `git commit --no-verify`. Ele também verifica os
arquivos como estão no disco, não exatamente a versão que está indo para o commit. Isso o torna uma
gentileza consigo mesmo: o aviso mais rápido possível. A verificação em que a equipe confia roda o
mesmo `check.sh` num servidor, para cada mudança, onde ninguém pode pulá-la; é o assunto da próxima
seção.
