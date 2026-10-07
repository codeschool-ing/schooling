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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l06-reach-change\" aria-label=\"As cinco entradas do portal posicionadas por quem as alcança sem credencial, na horizontal, e pelo que mudam, na vertical. O webhook de pagamento: qualquer um que saiba o endereço, e muda se um agendamento está pago. Entrar e agendar: qualquer um, e muda os agendamentos do paciente. A página de login da equipe: qualquer um, e não muda nada sozinha, mas guarda todo prontuário. Upload de exame: só pacientes, os exames do paciente. Gerenciar a agenda: só a equipe, todo prontuário.\"><defs><marker id=\"l06-reach-change-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M120.0 240.0 L700.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-reach-change-tm-ah-paper-dim)\"></path><path d=\"M120.0 240.0 L120.0 20.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-reach-change-tm-ah-paper-dim)\"></path><text x=\"210.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">qualquer um</text><text x=\"420.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pacientes</text><text x=\"620.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">equipe</text><text x=\"112.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dado próprio</text><text x=\"112.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dinheiro</text><text x=\"112.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dado de todos</text><circle cx=\"210.0\" cy=\"130.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"222.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">webhook de pagamento</text><circle cx=\"210.0\" cy=\"200.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"222.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">entrar e agendar</text><circle cx=\"210.0\" cy=\"60.0\" r=\"7\" fill=\"var(--amber)\"></circle><text x=\"222.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">login da equipe (guarda)</text><circle cx=\"420.0\" cy=\"200.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"432.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">upload de exame</text><circle cx=\"620.0\" cy=\"60.0\" r=\"7\" fill=\"var(--paper-dim)\"></circle><text x=\"632.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">gerenciar a agenda</text><text x=\"410.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">em cima à esquerda é onde olhar primeiro</text></svg>", "caption": "Duas perguntas ordenam as entradas melhor que a quantidade delas: quem chega sem nada, e o que consegue mudar."}
```
