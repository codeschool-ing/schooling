---
title: "Renovada e expirada: um id novo no login, e dois relógios"
version: 1
---

Veja como a primeira versão fazia o login de um paciente:

```python
    sid = request.cookies.get("sid")
    if sid not in SESSIONS:
        sid = new_session_id()
    SESSIONS[sid] = {"patient": name}
```

Se o navegador já tinha uma sessão, aquela que todo visitante recebe na página inicial, o login
**mantinha o mesmo id e gravava o paciente nele.** O id que era anônimo um segundo antes passa a
querer dizer lucia. Isso se chama **fixação de sessão**, e é uma falha porque o id anônimo é o que
tem mais chance de ter sido visto: foi emitido antes de alguém provar quem era, num computador
compartilhado na recepção da clínica, ou definido por alguém que mandou um link ao paciente. Quem
conhecia o id antes do login conhece depois.

**A regra é que o id muda sempre que o privilégio por trás dele muda.** No login, a sessão antiga é
apagada e um id novo é emitido. O mesmo vale para qualquer subida posterior: um segundo fator, um
papel de equipe ativado. O teste confere as duas metades: o cookie é outro, e o id antigo sumiu da
tabela do servidor.

### Dois relógios

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l10-clocks\" aria-label=\"Dois limites num dia de trabalho, das 09:00 às 17:30. A primeira linha, o limite de inatividade de 15 minutos: requisições chegam a cada poucos minutos, depois um intervalo de 16 minutos sem requisição, e a sessão termina no fim do intervalo. A segunda linha, o limite absoluto de 8 horas: requisições chegam a cada dez minutos o dia todo, sem nunca ficar inativa, e mesmo assim a sessão termina às 17:00, oito horas depois do login.\"><defs><marker id=\"l10-clocks-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"120.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><text x=\"388.2\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13:00</text><text x=\"656.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17:00</text><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">inatividade, 15 min</text><path d=\"M120 80 L690 80\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 72 L120.0 88\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M126.7 72 L126.7 88\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M133.4 72 L133.4 88\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M140.1 72 L140.1 88\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M146.8 72 L146.8 88\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M153.5 72 L153.5 88\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M153.5 100 L171.4 100\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-clocks-ah-amber)\" marker-start=\"url(#l10-clocks-ah-amber)\"></path><text x=\"230.2\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">16 min sem requisição</text><rect x=\"169.4\" y=\"66\" width=\"4\" height=\"28\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"177.4\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">termina</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">limite absoluto, 8 h</text><path d=\"M120 170 L690 170\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 164 L120.0 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M131.2 164 L131.2 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M142.4 164 L142.4 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M153.5 164 L153.5 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M164.7 164 L164.7 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M175.9 164 L175.9 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M187.1 164 L187.1 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M198.2 164 L198.2 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M209.4 164 L209.4 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M220.6 164 L220.6 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M231.8 164 L231.8 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M242.9 164 L242.9 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M254.1 164 L254.1 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M265.3 164 L265.3 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M276.5 164 L276.5 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M287.6 164 L287.6 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M298.8 164 L298.8 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M310.0 164 L310.0 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M321.2 164 L321.2 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M332.4 164 L332.4 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M343.5 164 L343.5 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M354.7 164 L354.7 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M365.9 164 L365.9 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M377.1 164 L377.1 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M388.2 164 L388.2 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M399.4 164 L399.4 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M410.6 164 L410.6 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M421.8 164 L421.8 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M432.9 164 L432.9 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M444.1 164 L444.1 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M455.3 164 L455.3 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M466.5 164 L466.5 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M477.6 164 L477.6 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M488.8 164 L488.8 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M500.0 164 L500.0 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M511.2 164 L511.2 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M522.4 164 L522.4 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M533.5 164 L533.5 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M544.7 164 L544.7 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M555.9 164 L555.9 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M567.1 164 L567.1 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M578.2 164 L578.2 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M589.4 164 L589.4 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M600.6 164 L600.6 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M611.8 164 L611.8 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M622.9 164 L622.9 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M634.1 164 L634.1 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M645.3 164 L645.3 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M656.5 164 L656.5 176\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"654.5\" y=\"156\" width=\"4\" height=\"28\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"650.5\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">termina, mesmo em uso</text><text x=\"124.0\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">login 09:00</text></svg>", "caption": "O limite de inatividade encerra a sessão que ninguém usa; o absoluto encerra a que alguém usa por tempo demais."}
```

Uma sessão sem fim dura tanto quanto o navegador do paciente, o que pode ser semanas. Dois limites a
encerram, e cada um responde a um risco diferente.

- **O limite de inatividade** encerra a sessão que ninguém está usando: o paciente que saiu de perto
  do computador da recepção com o portal aberto. Cada requisição o reinicia. O portal guarda dados
  de saúde, então ele é curto: **15 minutos**.
- **O limite absoluto** encerra a sessão por mais que ela esteja em uso, para que um id copiado não
  seja mantido vivo para sempre por um script que pede uma página a cada poucos minutos. Requisições
  não o reiniciam. Aqui são **8 horas**, um dia de trabalho.

A Session Management Cheat Sheet da OWASP dá faixas em vez de números: um limite de inatividade de
poucos minutos para aplicações de alto valor e de 15 a 30 para as de risco menor, e um limite
absoluto definido por quanto tempo as pessoas usam de fato a aplicação. Os dois números são
decisões; escreva-os onde a próxima pessoa os encontre, o que aqui quer dizer duas constantes com
nome no topo do `app.py`.

A expiração é conferida **no servidor, a cada requisição**. O `Expires` ou o `Max-Age` do próprio
cookie só dizem a um navegador honesto quando parar de enviá-lo; uma cópia do id não obedece.

### A correção

```
(.venv) ana@vm:~/sc/sessions$ git diff
diff --git a/app.py b/app.py
index eb14d68..653aece 100644
--- a/app.py
+++ b/app.py
@@ -1,11 +1,13 @@
 # app.py
 import secrets
-from datetime import datetime
+from datetime import datetime, timedelta
 
 from flask import Flask, abort, jsonify, make_response, request
 
 app = Flask(__name__)
 SESSIONS = {}
+IDLE = timedelta(minutes=15)
+ABSOLUTE = timedelta(hours=8)
 
 
 def now():
@@ -26,9 +28,14 @@ def set_sid(response, sid):
 
 
 def current_patient():
-    record = SESSIONS.get(request.cookies.get("sid"))
+    sid = request.cookies.get("sid")
+    record = SESSIONS.get(sid)
     if record is None or record["patient"] is None:
         abort(401)
+    if now() - record["seen"] > IDLE or now() - record["created"] > ABSOLUTE:
+        del SESSIONS[sid]
+        abort(401)
+    record["seen"] = now()
     return record["patient"]
 
 
@@ -47,10 +54,9 @@ def sign_in():
     name = request.form.get("name", "")
     if not check_password(name, request.form.get("password", "")):
         abort(401)
-    sid = request.cookies.get("sid")
-    if sid not in SESSIONS:
-        sid = new_session_id()
-    SESSIONS[sid] = {"patient": name}
+    SESSIONS.pop(request.cookies.get("sid"), None)
+    sid = new_session_id()
+    SESSIONS[sid] = {"patient": name, "created": now(), "seen": now()}
     response = jsonify(patient=name)
     set_sid(response, sid)
     return response
```

O `sign_in` descarta o id que chegou, seja qual for, e sempre emite um novo, marcado com quando foi
criado e quando foi usado pela última vez. O `current_patient` recusa uma sessão que passou de
qualquer dos limites, apaga-a para que não volte e, se não passou, avança o `seen`. Rode os testes e
faça o commit:

```
(.venv) ana@vm:~/sc/sessions$ pytest -q --tb=no
......F                                                                  [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_signing_out_ends_the_session_on_the_server - Asserti...
1 failed, 6 passed in 0.12s
(.venv) ana@vm:~/sc/sessions$ git commit -qam "Issue a new id at sign-in, and expire idle and old sessions"
```

**Mais três passam.** O teste de inatividade esperou dezesseis minutos; o do limite absoluto mandou
uma requisição a cada dez minutos, sem nunca ficar inativo, e foi recusado assim que oito horas se
passaram.
