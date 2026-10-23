---
title: SameSite, e de onde a requisição veio
version: 1
---

O token faz uma requisição forjada falhar. Mais duas linhas fazem a maioria das requisições forjadas
**nem chegar com sessão**, e valem a pena porque um token pode ser esquecido numa rota que pula a
verificação, ou vazar numa URL.

### SameSite

`SameSite` é um atributo de cookie que diz ao navegador quando anexá-lo a uma requisição que **outro
site** iniciou:

| valor | o cookie viaja em… de outro site |
|---|---|
| `Strict` | nada: nem um link que o paciente segue até o portal |
| `Lax` | navegações de nível superior com `GET`, como seguir um link; nunca um `POST` |
| `None` | tudo, como antes de o atributo existir; exige `Secure` |

`Lax` é a configuração para a maioria das aplicações: seguir um link de um e-mail para o portal
continua chegando logado, e um formulário que outro site envia chega **sem o cookie de sessão**, então
o portal o responde como a um estranho. `Strict` é mais seguro e faz todo link para o portal chegar
deslogado, o que num portal de pacientes mais ensinaria as pessoas a desconfiar dos links da clínica.

O Chrome e os navegadores construídos sobre ele tratam um cookie sem atributo `SameSite` como `Lax`; o
Firefox e o Safari, não. **Defina mesmo assim**: o padrão é decisão de cada navegador, os navegadores já
o mudaram antes, e o atributo na resposta é uma decisão escrita no código. O cookie de sessão do Flask
é configurado por `SESSION_COOKIE_SAMESITE` e, aproveitando, `SESSION_COOKIE_SECURE`; o `HttpOnly` já é
o padrão do Flask.

### A origem da requisição

Quando um navegador manda um `POST`, acrescenta um cabeçalho `Origin` com o site da página que o
iniciou: `https://portal.vereda.example` para o formulário do próprio portal, outra coisa para uma
página de qualquer outro lugar. A verificação é uma comparação: **se a requisição nomeia uma origem e
ela não é a do portal, recuse.**

Uma requisição sem `Origin` nenhum segue para a verificação do token, que ainda precisa passar. Alguns
clientes legítimos não mandam nenhum, e o token é a defesa que não depende do navegador.

Os navegadores também mandam cabeçalhos de **Fetch Metadata**, como `Sec-Fetch-Site: cross-site`, que
dizem a mesma coisa com mais detalhe, e uma política construída sobre eles é uma alternativa sólida à
verificação de origem.

### A correção

```
(.venv) ana@vm:~/sc/csrf$ git diff
diff --git a/app.py b/app.py
index 7f46529..8751734 100644
--- a/app.py
+++ b/app.py
@@ -5,6 +5,7 @@ from flask import Flask, abort, redirect, render_template_string, request, sessi
 
 app = Flask(__name__)
 app.secret_key = secrets.token_bytes(32)
+app.config.update(SESSION_COOKIE_SAMESITE="Lax", SESSION_COOKIE_SECURE=True)
 ACCOUNTS = {"lucia": {"email": "lucia@mail.example", "phone": "+55 11 5555-0101"}}
 
 PAGE = """<h1>Your account</h1>
@@ -41,6 +42,9 @@ app.jinja_env.globals["csrf_token"] = csrf_token
 def refuse_cross_site_changes():
     if request.method in ("GET", "HEAD", "OPTIONS"):
         return
+    origin = request.headers.get("Origin")
+    if origin is not None and origin != request.host_url.rstrip("/"):
+        abort(403)
     expected = session.get("csrf")
     sent = request.form.get("csrf", "")
     if not expected or not secrets.compare_digest(sent.encode(), expected.encode()):
```

```
(.venv) ana@vm:~/sc/csrf$ pytest -q
.......                                                                  [100%]
7 passed in 0.15s
```

Sete de sete. Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/csrf$ git commit -qam "Keep the session cookie to its own site, and check the origin"
(.venv) ana@vm:~/sc/csrf$ git log --oneline
4bf090a Keep the session cookie to its own site, and check the origin
44aebcc Refuse a change without the session's token
84a1e45 Change the e-mail address and the phone number
```

**Três defesas, cada uma contra uma condição diferente.** O token vale até num navegador que ignora o
`SameSite`; o `SameSite` vale até numa rota que alguém isentou do token; a verificação de origem recusa
uma requisição de outro site antes de qualquer das duas ser consultada.
