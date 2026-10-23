---
title: Relatar primeiro, aplicar depois
version: 1
---

Uma política escrita lendo o código é um palpite sobre o que a página carrega, e um palpite errado
aplicado no primeiro dia quebra o portal para todo paciente. Por isso uma política entra em duas
etapas, e o nome do cabeçalho diz qual:

- **`Content-Security-Policy-Report-Only`**: o navegador confere cada recurso com a política,
  **relata** cada violação, e não bloqueia nada.
- **`Content-Security-Policy`**: o navegador bloqueia cada violação, e a relata.

O primeiro é como você descobre o que a política quebraria, com páginas reais em navegadores reais,
antes de ela quebrar qualquer coisa. Deixe-o rodando por dias num portal de verdade, leia os relatórios
e corrija o que eles nomeiam.

### A correção, primeiro passo

A política entra uma vez, como constante, e uma função `after_request` a acrescenta a **toda** resposta,
para nenhuma rota esquecer. Uma rota nova, `/csp-report`, recebe os relatórios do navegador e escreve
cada um no log do portal, onde valem as regras da aula 15 sobre logs:

```
(.venv) ana@vm:~/sc/csp$ git diff
diff --git a/app.py b/app.py
index b003960..278aa93 100644
--- a/app.py
+++ b/app.py
@@ -1,7 +1,7 @@
 # app.py
 import logging
 
-from flask import Flask, render_template_string
+from flask import Flask, render_template_string, request
 
 app = Flask(__name__)
 log = logging.getLogger("portal")
@@ -20,6 +20,34 @@ PAGE = """<!doctype html>
 </html>
 """
 
+POLICY = "; ".join([
+    "default-src 'self'",
+    "script-src 'self'",
+    "object-src 'none'",
+    "base-uri 'none'",
+    "frame-ancestors 'none'",
+    "form-action 'self'",
+    "report-uri /csp-report",
+])
+
+
+@app.after_request
+def send_the_policy(response):
+    response.headers["Content-Security-Policy-Report-Only"] = POLICY
+    return response
+
+
+@app.post("/csp-report")
+def csp_report():
+    report = request.get_json(force=True, silent=True) or {}
+    details = report.get("csp-report", {})
+    log.warning(
+        "csp violation directive=%r blocked=%r",
+        details.get("violated-directive"),
+        details.get("blocked-uri"),
+    )
+    return "", 204
+
 
 @app.get("/")
 def home():
```

```
(.venv) ana@vm:~/sc/csp$ pytest -q --tb=no
.FFFF.                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_every_page_sends_an_enforced_policy - assert 'Conten...
FAILED test_app.py::test_scripts_come_only_from_the_portal - assert None == "...
FAILED test_app.py::test_no_page_carries_inline_script - assert not <re.Match...
FAILED test_app.py::test_the_script_file_is_served - AssertionError: assert 4...
4 failed, 2 passed in 0.13s
```

**O endpoint de relatório funciona; o resto continua falhando**, como deve: a política ainda não é
aplicada, a página ainda tem código inline, e não há arquivo de script. Faça o commit deste passo:

```
(.venv) ana@vm:~/sc/csp$ git add look.py
(.venv) ana@vm:~/sc/csp$ git commit -qam "Send a report-only policy, and log what it reports"
```

### O que o navegador relata

Reinicie o portal e rode o `look.py` de novo:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
console: Executing inline script violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-nQGnU0QE1FIi/fdNcq76F6u4piPJwMEAzr61AGlkZp0='), or a nonce ('nonce-...') is required to enable inline execution. The policy is report-only, so the violation has been logged but no further action has been taken.
console: Executing inline event handler violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-...'), or a nonce ('nonce-...') is required to enable inline execution. Note that hashes do not apply to event handlers, style attributes and javascript: navigations unless the 'unsafe-hashes' keyword is present. The policy is report-only, so the violation has been logged but no further action has been taken.
title: Vereda: Monday 16 November, 09:00, with carla
larger text: True
```

Duas mensagens no console, uma para cada hábito. A primeira é o `<script>` inline, recusado pelo
`script-src`; a segunda é o atributo `onclick`, recusado no momento em que o botão foi clicado. As duas
terminam com a mesma frase: **a política é só de relatório, então nada foi bloqueado.** O título foi
definido mesmo assim e o texto aumentou.

Cada violação também foi mandada ao `/csp-report`. No terminal onde o portal roda:

```
csp violation directive='script-src-elem' blocked='inline'
csp violation directive='script-src-attr' blocked='inline'
```

É a lista do que precisa mudar de lugar antes de a política poder ser aplicada, escrita pelo navegador.

### E se você aplicasse agora

Para ver por que a ordem importa, troque `Content-Security-Policy-Report-Only` por
`Content-Security-Policy` no `app.py`, reinicie e rode o `look.py`:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
console: Executing inline script violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-nQGnU0QE1FIi/fdNcq76F6u4piPJwMEAzr61AGlkZp0='), or a nonce ('nonce-...') is required to enable inline execution. The action has been blocked.
console: Executing inline event handler violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-...'), or a nonce ('nonce-...') is required to enable inline execution. Note that hashes do not apply to event handlers, style attributes and javascript: navigations unless the 'unsafe-hashes' keyword is present. The action has been blocked.
title: Vereda
larger text: False
```

O título é o `Vereda` puro do HTML, porque o script que o define nunca rodou, e o botão não faz nada.
**É o código do próprio portal, quebrado pela própria política.** Num portal de verdade seria a página
de todo paciente. Volte o nome do cabeçalho antes de seguir.
