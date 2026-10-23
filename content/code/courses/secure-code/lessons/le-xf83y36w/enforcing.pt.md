---
title: Aplicando
version: 1
---

Os relatórios silenciaram, então a política está pronta para ser aplicada. É uma palavra no nome do
cabeçalho:

```
(.venv) ana@vm:~/sc/csp$ git diff
diff --git a/app.py b/app.py
index 59e3fbf..a042943 100644
--- a/app.py
+++ b/app.py
@@ -31,7 +31,7 @@ POLICY = "; ".join([
 
 @app.after_request
 def send_the_policy(response):
-    response.headers["Content-Security-Policy-Report-Only"] = POLICY
+    response.headers["Content-Security-Policy"] = POLICY
     return response
 
 
```

```
(.venv) ana@vm:~/sc/csp$ pytest -q
......                                                                   [100%]
6 passed in 0.13s
```

Seis de seis. O navegador agora bloqueia o que a política recusa, e a página continua funcionando:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
title: Vereda: Monday 16 November, 09:00, with carla
larger text: True
```

O cabeçalho que toda resposta leva agora, como qualquer cliente o vê:

```
(.venv) ana@vm:~/sc/csp$ curl -sI http://127.0.0.1:5000/
HTTP/1.1 200 OK
Server: Werkzeug/3.1.9 Python/3.13.17
Date: Fri, 23 Oct 2026 15:51:55 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 277
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'; report-uri /csp-report
Connection: close
```

Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/csp$ git commit -qam "Enforce the policy"
(.venv) ana@vm:~/sc/csp$ git log --oneline
6cc65c4 Enforce the policy
b599870 Move the page's scripts into a file
029839b Send a report-only policy, and log what it reports
ad26f87 Greet the patient with her next session
```

### Mantendo

Uma política se degrada como as regras de acesso, uma exceção de cada vez. Três hábitos a mantêm
honesta:

- **Continue recebendo os relatórios.** Uma política aplicada continua relatando. Um relatório depois
  de uma versão nova quer dizer que uma página passou a carregar algo novo; uma rajada de uma página só
  pode querer dizer que alguém achou um escape esquecido, e a política o barrou. Os alertas da aula 15
  valem aqui.
- **Trate uma origem nova como revisão.** Acrescentar um host ao `script-src` deixa todo script desse
  host rodar no portal com a sessão do paciente. Pergunte que host é, quem controla o que ele serve, e
  se uma cópia em `static` não resolveria.
- **Teste o cabeçalho, não a intenção.** Os testes desta aula falham se um `'unsafe-inline'` entrar
  no `script-src` ou se uma página ganhar um `onclick` de novo, que é a mudança que uma correção
  apressada faz.

O endpoint de relatório aceita qualquer coisa que alguém mande, então é um lugar para escrever no log de
graça. Mantenha curto o que ele registra, como o `csp_report` faz ao registrar dois campos com `%r`, e dê
a ele um limite de taxa num portal de verdade.

Os navegadores estão trocando o `report-uri` pela **Reporting API**, com uma diretiva `report-to` e um
cabeçalho `Reporting-Endpoints`. Hoje o `report-uri` ainda funciona em todo navegador importante, e uma
política pode levar os dois.
