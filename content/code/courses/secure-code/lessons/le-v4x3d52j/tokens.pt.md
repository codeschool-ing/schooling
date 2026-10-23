---
title: Um token que só as páginas do portal conhecem
version: 1
---

A ideia é simples. Quando o portal desenha um formulário, põe nele um valor aleatório ligado à sessão
da paciente. Quando o formulário volta, o portal confere que o valor está lá e é o certo. Uma página de
outro site consegue fazer o navegador mandar uma requisição, mas **não consegue ler as páginas do
portal**, então não conhece o valor, e a requisição dela chega sem ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l09-token\" aria-label=\"O padrão do token sincronizador em três passos. Um: o navegador da lucia pede GET /account; o portal sorteia um token, guarda na sessão dela e escreve num campo oculto de cada formulário. Dois: ela envia o formulário; a requisição leva o token, o portal o compara com o da sessão, eles batem, e a mudança é feita. Três: uma requisição iniciada por uma página de outro site chega com o cookie dela mas sem o token, porque aquela página não consegue ler as páginas do portal; o portal responde 403 e não muda nada.\"><defs><marker id=\"l09-token-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-token-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"30\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><rect x=\"50\" y=\"24\" width=\"220\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">GET /account</text><path d=\"M270 48 L380 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-token-ah-phosphor)\"></path><rect x=\"380\" y=\"24\" width=\"310\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"41.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">token sorteado, guardado na sessão,</text><text x=\"535.0\" y=\"54.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">escrito em cada formulário</text><text x=\"30\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><rect x=\"50\" y=\"100\" width=\"220\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">POST com o token</text><path d=\"M270 124 L380 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-token-ah-phosphor)\"></path><rect x=\"380\" y=\"100\" width=\"310\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bate com o da sessão: 303, mudou</text><text x=\"30\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">3</text><rect x=\"50\" y=\"176\" width=\"220\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">POST de outro site</text><path d=\"M270 200 L380 200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-token-ah-amber)\"></path><rect x=\"380\" y=\"176\" width=\"310\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sem token: 403, nada mudou</text></svg>", "caption": "Outro site consegue fazer o navegador mandar uma requisição; não consegue ler a página do portal, então não conhece o token.", "same": ["GET /account"]}
```

É o **padrão do token sincronizador**, e tem quatro regras, cada uma uma linha da correção:

- **Aleatório, vindo do `secrets`**, como um id de sessão, porque é um: conhecê-lo é o que faz uma
  requisição parecer do próprio portal.
- **Ligado à sessão.** Um token de outra sessão é recusado, senão qualquer um com uma conta poderia
  pegar o próprio token e pô-lo num formulário apontado para outra pessoa. O quarto teste confere isso.
- **Conferido em toda mudança, num lugar só.** O `@app.before_request` roda antes de toda rota, então
  a verificação cobre o formulário do telefone, e o próximo formulário que alguém acrescentar, sem
  ninguém precisar lembrar. É o negar por padrão da aula 12 de novo: uma rota nova fica protegida a
  não ser que alguém faça algo para desprotegê-la.
- **Comparado em tempo constante.** O `secrets.compare_digest` leva o mesmo tempo para um token errado
  no primeiro caractere e para um errado no último, então o tempo da resposta não diz nada sobre quão
  perto um palpite chegou. Ele quer bytes, ou texto só com caracteres ASCII, por isso os dois lados são
  codificados.

Mais uma linha importa tanto quanto as outras: **um token esperado vazio recusa.** Uma sessão que
nunca desenhou um formulário não tem token, e comparar a string vazia que uma requisição manda com a
string vazia que a sessão guarda diria que elas batem.

### A correção

```
(.venv) ana@vm:~/sc/csrf$ git diff
diff --git a/app.py b/app.py
index 57c0930..7f46529 100644
--- a/app.py
+++ b/app.py
@@ -9,10 +9,12 @@ ACCOUNTS = {"lucia": {"email": "lucia@mail.example", "phone": "+55 11 5555-0101"
 
 PAGE = """<h1>Your account</h1>
 <form method="post" action="/account/email">
+  <input type="hidden" name="csrf" value="{{ csrf_token() }}">
   <input name="email" value="{{ account.email }}">
   <button>Change e-mail</button>
 </form>
 <form method="post" action="/account/phone">
+  <input type="hidden" name="csrf" value="{{ csrf_token() }}">
   <input name="phone" value="{{ account.phone }}">
   <button>Change phone</button>
 </form>
@@ -26,6 +28,25 @@ def signed_in():
     return name
 
 
+def csrf_token():
+    if "csrf" not in session:
+        session["csrf"] = secrets.token_urlsafe(32)
+    return session["csrf"]
+
+
+app.jinja_env.globals["csrf_token"] = csrf_token
+
+
+@app.before_request
+def refuse_cross_site_changes():
+    if request.method in ("GET", "HEAD", "OPTIONS"):
+        return
+    expected = session.get("csrf")
+    sent = request.form.get("csrf", "")
+    if not expected or not secrets.compare_digest(sent.encode(), expected.encode()):
+        abort(403)
+
+
 @app.get("/account")
 def account():
     return render_template_string(PAGE, account=ACCOUNTS[signed_in()])
```

```
(.venv) ana@vm:~/sc/csrf$ pytest -q --tb=no
.....FF                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_change_from_another_origin_is_refused - assert 303...
FAILED test_app.py::test_the_session_cookie_is_samesite_lax - AssertionError:...
2 failed, 5 passed in 0.12s
(.venv) ana@vm:~/sc/csrf$ git commit -qam "Refuse a change without the session's token"
```

**Cinco de sete passam.** Todo formulário leva o token, uma mudança sem ele é recusada, e também uma
mudança com o token de outra sessão. As duas falhas que restam são as outras duas defesas.
