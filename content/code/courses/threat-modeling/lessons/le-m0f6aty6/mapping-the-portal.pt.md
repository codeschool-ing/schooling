---
title: Mapeando o portal
version: 1
---

O mapa não precisa de desenho novo. Todo ponto de entrada e de saída é um fluxo em `model.py` que
cruza a borda do que a Vereda roda, que é a nuvem e a rede privada dentro dela. O `surface.py` lê o
JSON que o pytm escreve e os lista:

```schooling-example
{"language": "python", "file": "surface.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The attack surface of a pytm model: every flow that enters or leaves what Vereda runs.\"\"\"\nimport json\nimport sys\n\nOURS = {\"Vereda cloud\", \"Private network\"}\n", "note": "O que a Vereda roda são duas fronteiras: a nuvem e a rede privada dentro dela. Todo o resto está fora."}, {"code": "model = json.load(open(sys.argv[1]))\nwhere = {e[\"name\"]: e[\"inBoundary\"] for e in model[\"elements\"]}\ninside = lambda name: where[name] in OURS\n", "note": "A fronteira de cada elemento, a partir do JSON do pytm, e um teste para saber se um nome está do lado da Vereda."}, {"code": "entries = [f for f in model[\"flows\"] if not inside(f[\"source\"]) and inside(f[\"sink\"])]\nexits = [f for f in model[\"flows\"] if inside(f[\"source\"]) and not inside(f[\"sink\"])]\n", "note": "Um ponto de entrada chega de fora para dentro; um ponto de saída vai de dentro para fora. Um fluxo de dentro, como o worker lendo o banco, não é nenhum dos dois."}, {"code": "for title, flows in ((\"entry points\", entries), (\"exit points\", exits)):\n    print(f\"{len(flows)} {title}\")\n    for f in flows:\n        print(f\"  {f['name']:26} {f['source']} -> {f['sink']}\")", "note": "Imprime cada lista com a contagem, o nome do fluxo e as duas pontas."}]}
```

```
(.venv) ana@vm:~/tm/portal-model$ python3 model.py --json model.json
(.venv) ana@vm:~/tm/portal-model$ python3 surface.py model.json
4 entry points
  Sign in and book           Patient -> Portal
  Upload exam PDF            Patient -> Portal
  Payment webhook            Payment gateway -> Portal
  Manage the agenda          Clinic staff -> Staff console
3 exit points
  Pages and booking status   Portal -> Patient
  Charge for a session       Portal -> Payment gateway
  Send reminder              Reminder worker -> SMS provider
```

Quatro entradas e três saídas, e todas são fluxos que já estão na figura da aula 2. Para comparar
com o que vem a seguir, a contagem do pytm neste modelo:

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json | grep findings
196 findings on 17 elements
```

### A porta que o desenho deixou de fora

A aula 2 desenhou o console da equipe atrás da rede da clínica, como projetado, e anotou que ele
responde pela internet. A aula 3 escreveu isso como T12. O mapa é o lugar de parar de descrever a
intenção e **desenhar o sistema como ele está**: mais um ator, qualquer um na internet, e mais um
fluxo, para a página de login do console. Em `model.py` são seis linhas:

```
--- a/model.py
+++ b/model.py
@@ -26,6 +26,9 @@
 payments = ExternalEntity("Payment gateway")
 payments.inBoundary = vendors
 payments.protocol = "HTTPS"
+anyone = Actor("Anyone on the internet")
+anyone.inBoundary = internet
+anyone.protocol = "HTTPS"
 
 # Processes: code Vereda runs.
 portal = Server("Portal")
@@ -67,5 +70,8 @@
 Dataflow(worker, db, "Read tomorrow's bookings")
 Dataflow(worker, sms, "Send reminder")
 
+# Drawn in lesson 6: the console answers from the internet, not only the clinics.
+Dataflow(anyone, console, "Staff sign-in page")
+
 if __name__ == "__main__":
     tm.process()
```

E o mapa, rodado de novo:

```
(.venv) ana@vm:~/tm/portal-model$ git diff --stat
 model.py | 6 ++++++
 1 file changed, 6 insertions(+)
(.venv) ana@vm:~/tm/portal-model$ python3 model.py --json model.json
(.venv) ana@vm:~/tm/portal-model$ python3 surface.py model.json
5 entry points
  Sign in and book           Patient -> Portal
  Upload exam PDF            Patient -> Portal
  Payment webhook            Payment gateway -> Portal
  Manage the agenda          Clinic staff -> Staff console
  Staff sign-in page         Anyone on the internet -> Staff console
3 exit points
  Pages and booking status   Portal -> Patient
  Charge for a session       Portal -> Payment gateway
  Send reminder              Reminder worker -> SMS provider
```

**Cinco pontos de entrada.** O novo é a única entrada no lado da equipe da Vereda que qualquer um,
de qualquer lugar, consegue alcançar sem estar na rede de uma clínica. A contagem do pytm subiu
cinco, os achados genéricos que todo fluxo novo recebe:

```
(.venv) ana@vm:~/tm/portal-model$ python3 findings.py model.json | grep findings
201 findings on 18 elements
```

A mudança entra num commit como qualquer outra, para que o histórico mostre quando o modelo começou
a dizer a verdade sobre o console:

```
(.venv) ana@vm:~/tm/portal-model$ git commit -qam 'Draw the console as it is: reachable from the internet'
(.venv) ana@vm:~/tm/portal-model$ git log --oneline -3
23e3e45 Draw the console as it is: reachable from the internet
088ee69 List the entry and exit points
f602de2 Model one goal as an attack tree
```

### O mapa como lista a manter

Cinco entradas e três saídas cabem numa tabela, e a tabela é o documento a manter ao lado do modelo:

| ponto de entrada | quem chega até ele sem credencial | o que ele muda |
|---|---|---|
| entrar e agendar | qualquer um (o formulário de login) | os agendamentos do paciente |
| enviar PDF do exame | ninguém: só pacientes | os exames do paciente, e o armazenamento |
| webhook de pagamento | qualquer um que conheça o endereço | se um agendamento está pago |
| cuidar da agenda | ninguém: só a equipe | o prontuário de todos os pacientes |
| página de login da equipe | qualquer um | nada sozinha; ela guarda o prontuário de todos os pacientes |

Três linhas dizem "qualquer um", e duas delas guardam dinheiro ou todos os prontuários. É por elas
que a próxima seção começa.
