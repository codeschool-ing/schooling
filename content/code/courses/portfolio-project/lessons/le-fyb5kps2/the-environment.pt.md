---
title: Lendo do ambiente
version: 1
---

O lugar padrão para um valor que muda de uma máquina para outra, segredo ou não, é uma **variável de
ambiente**. O código a lê, e usa um padrão quando o valor não é segredo e um padrão faz sentido. O passo 14
do loanbook fez isso para as suas duas configurações:

```
ana@laptop:~/loanbook$ git show --format=%s HEAD -- app.py .gitignore
Read the database path and port from the environment

diff --git a/.gitignore b/.gitignore
index a707f54..4384d7d 100644
--- a/.gitignore
+++ b/.gitignore
@@ -1,2 +1,3 @@
 *.db
+.env
 __pycache__/
diff --git a/app.py b/app.py
index e48521f..7ff706c 100644
--- a/app.py
+++ b/app.py
@@ -1,5 +1,6 @@
 """loanbook: who has which piece of equipment, and until when."""
 import json
+import os
 import re
 import sqlite3
 import sys
@@ -10,8 +11,8 @@ from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
 from pathlib import Path
 
 HERE = Path(__file__).parent
-DB = str(HERE / "loanbook.db")
-PORT = 8000
+DB = os.environ.get("LOANBOOK_DB", str(HERE / "loanbook.db"))
+PORT = int(os.environ.get("LOANBOOK_PORT", "8000"))
 LOAN_DAYS = 7
 
 SCHEMA = """
```

`os.environ.get("LOANBOOK_DB", …)` lê a variável se estiver definida e usa o arquivo ao lado do código se
não estiver. O mesmo commit acrescentou `.env` ao `.gitignore`, porque o jeito comum de definir essas
variáveis na sua máquina é um arquivo chamado `.env`, e esse arquivo é exatamente onde um segredo iria
parar. Aqui está o efeito, com as duas variáveis definidas para uma execução:

```
ana@laptop:~/loanbook$ LOANBOOK_DB=/tmp/other.db LOANBOOK_PORT=8001 timeout 2 python3 app.py
loanbook on http://127.0.0.1:8001
ana@laptop:~/loanbook$ ls *.db /tmp/other.db
/tmp/other.db
loanbook.db
```

O servidor escutou na 8001 e criou o banco em `/tmp`, e o `loanbook.db` padrão ao lado do código ficou
intacto. No servidor, aula 15, o container define `LOANBOOK_DB` para um volume, e nada no código muda.

Para um segredo de verdade o padrão é o mesmo com uma diferença: **sem valor padrão.**
`os.environ["SMTP_PASSWORD"]`, com colchetes, falha na hora se a variável faltar. É isso que você quer: um
programa que sobe sem a senha e falha no primeiro e-mail é mais difícil de diagnosticar do que um que se
recusa a subir. E o repositório ganha um arquivo chamado `.env.example`, com commit, que lista toda variável
de que o projeto precisa com um valor falso, para a próxima pessoa saber o que definir.
