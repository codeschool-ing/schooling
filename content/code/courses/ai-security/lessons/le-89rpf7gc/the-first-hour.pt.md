---
title: A primeira hora de um incidente
version: 1
---

Um incidente, escrito pelo curso, que junta cinco aulas anteriores. Na sexta-feira, 9 de outubro, às
13:52, o assistente respondeu à conta `ac-5F2R` com uma resposta que citava o próprio prompt de
sistema. O prompt de sistema inclui o `prompts/support.txt`, o arquivo em que a aula 17 encontrou a
chave de pagamentos escrita. Às 14:03 a regra do canário da aula 22 acordou a Ana, que estava de
plantão.

## Conter, depois entender

As primeiras linhas do runbook do canário mandam a Ana para o `guard trace`, que nomeia o prompt e a
versão dele, e para o próprio prompt, que guarda a chave. **Nesse ponto ela já sabe o bastante para
agir**, e a ordem importa: uma credencial vazada é revogada primeiro e investigada depois. Cada minuto
gasto descobrindo exatamente como o prompt vazou é um minuto em que a chave continua funcionando para
quem a tem.

O que a revogação vai quebrar é a pergunta que o runbook responde com o `guard blast`. Ele lê o
inventário da aula 17 e o log de acesso do serviço de pagamentos. O log é escrito pelo curso, com os
servidores da Tarefa em endereços que começam com `10.0.4.`; cole:

```sh
cat > ~/guard/data/access-payments.jsonl <<'EOF'
{"at": "2026-10-09 11:40", "from": "10.0.4.12", "action": "refund", "record": "job 4471", "result": "ok"}
{"at": "2026-10-09 13:20", "from": "10.0.4.12", "action": "refund", "record": "job 3987", "result": "ok"}
{"at": "2026-10-09 14:10", "from": "10.0.4.12", "action": "refund", "record": "job 5120", "result": "ok"}
{"at": "2026-10-09 14:22", "from": "203.0.113.45", "action": "read", "record": "payment 88213", "result": "ok"}
{"at": "2026-10-09 14:25", "from": "203.0.113.45", "action": "read", "record": "payment 88214", "result": "ok"}
{"at": "2026-10-09 14:38", "from": "203.0.113.45", "action": "payout", "record": "payout 1192", "result": "refused, key revoked"}
EOF
```

Salve o programa como `~/guard/tools/blast.py`:

```python
# blast.py: what a leaked key opens, what revoking it breaks, and who used it.
#
#   guard blast KEY --leaked "YYYY-MM-DD HH:MM" --ours PREFIX
#
# It reads the key from data/keys.json: what it may do, and which components
# use it, which are what stops working the moment it is revoked. Then it reads
# the service's access log, data/access-KEY.jsonl, and lists every use since
# the leak that did not come from an address starting with PREFIX, which is
# where Tarefa's own servers are. Those are the uses somebody else made.
import argparse
import json
import os

p = argparse.ArgumentParser(prog="guard blast")
p.add_argument("key")
p.add_argument("--leaked", required=True)
p.add_argument("--ours", required=True)
a = p.parse_args()

home = os.path.expanduser("~/guard/data")
with open(os.path.join(home, "keys.json"), encoding="utf-8") as f:
    inv = json.load(f)
key = next((k for k in inv["keys"] if k["name"] == a.key), None)
if key is None:
    raise SystemExit("blast: no key named %s in data/keys.json" % a.key)

needed = set()
for user in key["used_by"]:
    needed |= set(inv["needs"].get(user, []))
print("key       %s, kept in %s" % (key["name"], key["kept_in"]))
print("may do    %s" % ", ".join(key["scope"]))
print("needed    %s" % ", ".join(sorted(needed)))
print("revoking  stops %s" % ", ".join(key["used_by"]))

with open(os.path.join(home, "access-%s.jsonl" % a.key), encoding="utf-8") as f:
    uses = [json.loads(line) for line in f]
since = [u for u in uses if u["at"] >= a.leaked]
foreign = [u for u in since if not u["from"].startswith(a.ours)]
print("since     %s: %d use(s), %d from outside %s" % (a.leaked, len(since), len(foreign), a.ours))
for u in foreign:
    print("  %s  %-13s %-7s %-14s %s" % (u["at"], u["from"], u["action"], u["record"], u["result"]))
```

Rodado agora, depois do incidente, ele mostra tudo:

```
ana@lab:~/guard$ guard blast payments --leaked "2026-10-09 13:52" --ours 10.0.4.
key       payments, kept in source code
may do    refund, payout, read
needed    refund
revoking  stops issue_refund
since     2026-10-09 13:52: 4 use(s), 3 from outside 10.0.4.
  2026-10-09 14:22  203.0.113.45  read    payment 88213  ok
  2026-10-09 14:25  203.0.113.45  read    payment 88214  ok
  2026-10-09 14:38  203.0.113.45  payout  payout 1192    refused, key revoked
```

Quatro linhas decidem a próxima hora:

- **a chave pode três coisas e o assistente precisa de uma.** O achado SCOPE da aula 17, parte do
  chamado que a suíte da aula 23 relatou vencido naquela mesma manhã, é o motivo de um vazamento que
  deveria expor reembolsos ter exposto também registros de pagamento e repasses;
- **revogar interrompe o `issue_refund`**, e nada mais. Clientes esperando reembolso esperam mais
  enquanto uma chave nova é emitida. É um custo que o runbook já aceitou;
- **duas leituras de um endereço que não é da Tarefa**, às 14:22 e às 14:25. Um `read` devolve um
  registro de pagamento: o nome de um cliente, o CPF e o valor. Isso faz deste um incidente com dados
  pessoais;
- **o repasse das 14:38 foi recusado**, porque a chave tinha sido revogada às 14:31. A contenção
  funcionou, e o log é a prova.

## A linha do tempo, escrita enquanto acontece

Tudo o que a Ana e o Bruno fizeram foi para o arquivo do próprio incidente, uma linha por passo, com
a hora em que aconteceu e não a hora em que alguém se lembrou. Esta é a primeira hora deles; cole:

```sh
mkdir -p ~/guard/data/incidents
cat > ~/guard/data/incidents/INC-7.jsonl <<'EOF'
{"at": "2026-10-09 14:03", "kind": "detected", "by": "ana.lima", "text": "canary alert paged: the canary is in reply rq-5530"}
{"at": "2026-10-09 13:52", "kind": "started", "by": "ana.lima", "text": "rq-5530 to account ac-5F2R quoted the system prompt"}
{"at": "2026-10-09 14:12", "kind": "note", "by": "ana.lima", "text": "trace: the prompt includes prompts/support.txt, with the payments key"}
{"at": "2026-10-09 14:19", "kind": "note", "by": "ana.lima", "text": "blast: two reads from 203.0.113.45 since 13:52"}
{"at": "2026-10-09 14:31", "kind": "contained", "by": "bruno.alves", "text": "payments key revoked; issue_refund down"}
{"at": "2026-10-09 14:44", "kind": "note", "by": "bruno.alves", "text": "new key, refund only, in the secret store; issue_refund back"}
{"at": "2026-10-09 15:10", "kind": "note", "by": "bruno.alves", "text": "key removed from support.txt; approved by ana.lima"}
EOF
```

A primeira linha do arquivo é o alerta. A segunda foi acrescentada quando o trace mostrou qual
resposta vazou, e diz que o incidente *começou* às 13:52, onze minutos antes. O arquivo só recebe
acréscimos: um erro é corrigido por uma nota posterior, nunca editando uma linha anterior. Salve o
programa como `~/guard/tools/incident.py`:

```python
# incident.py: one incident's timeline, written as it happens.
#
#   guard incident add ID --at "YYYY-MM-DD HH:MM" --kind KIND --by NAME TEXT
#   guard incident show ID
#
# KIND is one of started, detected, note, contained, resolved. Entries are
# appended to data/incidents/ID.jsonl and never changed: a correction is a
# new note. show prints them in time order, each with the minutes since
# detection, and how long detecting and containing took.
import argparse
import datetime as dt
import json
import os

KINDS = ["started", "detected", "note", "contained", "resolved"]
FMT = "%Y-%m-%d %H:%M"

p = argparse.ArgumentParser(prog="guard incident")
sub = p.add_subparsers(dest="cmd", required=True)
add = sub.add_parser("add")
add.add_argument("id")
add.add_argument("--at", required=True)
add.add_argument("--kind", required=True, choices=KINDS)
add.add_argument("--by", required=True)
add.add_argument("text")
show = sub.add_parser("show")
show.add_argument("id")
a = p.parse_args()

path = os.path.expanduser("~/guard/data/incidents/%s.jsonl" % a.id)
if a.cmd == "add":
    dt.datetime.strptime(a.at, FMT)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps({"at": a.at, "kind": a.kind, "by": a.by, "text": a.text}) + "\n")
    raise SystemExit(0)

with open(path, encoding="utf-8") as f:
    entries = sorted((json.loads(line) for line in f), key=lambda e: e["at"])
first = {}
for e in entries:
    first.setdefault(e["kind"], dt.datetime.strptime(e["at"], FMT))
zero = first.get("detected")
for e in entries:
    t = dt.datetime.strptime(e["at"], FMT)
    rel = "" if zero is None else "%+5dm" % ((t - zero).total_seconds() // 60)
    print("%s %6s  %-9s %-11s %s" % (e["at"], rel, e["kind"], e["by"], e["text"]))
for start, end in [("started", "detected"), ("detected", "contained"), ("detected", "resolved")]:
    if start in first and end in first:
        print("%-9s %d minutes after it %s" % (end, (first[end] - first[start]).total_seconds() // 60,
                                               "started" if start == "started" else "was detected"))
    elif start in first:
        print("%-9s not yet" % end)
```

Às 15:30, com a saída do blast lida, a Ana registra o que muda tudo o que vem depois:

```
ana@lab:~/guard$ guard incident add INC-7 --at "2026-10-09 15:30" --kind note --by ana.lima "personal data affected: two payment records read; encarregado told"
ana@lab:~/guard$ guard incident show INC-7
2026-10-09 13:52   -11m  started   ana.lima    rq-5530 to account ac-5F2R quoted the system prompt
2026-10-09 14:03    +0m  detected  ana.lima    canary alert paged: the canary is in reply rq-5530
2026-10-09 14:12    +9m  note      ana.lima    trace: the prompt includes prompts/support.txt, with the payments key
2026-10-09 14:19   +16m  note      ana.lima    blast: two reads from 203.0.113.45 since 13:52
2026-10-09 14:31   +28m  contained bruno.alves payments key revoked; issue_refund down
2026-10-09 14:44   +41m  note      bruno.alves new key, refund only, in the secret store; issue_refund back
2026-10-09 15:10   +67m  note      bruno.alves key removed from support.txt; approved by ana.lima
2026-10-09 15:30   +87m  note      ana.lima    personal data affected: two payment records read; encarregado told
detected  11 minutes after it started
contained 28 minutes after it was detected
resolved  not yet
```

**Onze minutos para detectar, vinte e oito para conter.** São esses dois números que a revisão depois
do incidente tenta reduzir, e eles só existem porque cada passo foi anotado com a sua hora. O
incidente não está resolvido: a chave foi revogada e substituída, o prompt foi corrigido, e duas
pessoas cujos registros de pagamento foram lidos ainda não sabem. A próxima seção trata de avisá-las,
e de avisar a ANPD.

## O que não fazer na primeira hora

- **apagar a evidência.** O log de chamadas guarda a resposta que vazou, e a limpeza da aula 11 apaga
  o texto bruto depois de 30 dias. O runbook manda pausá-la; as chamadas do incidente ficam guardadas
  enquanto ele estiver aberto, e o motivo vai para a linha do tempo;
- **corrigir em silêncio.** Tirar a chave do `support.txt` sem revogá-la deixa uma chave funcionando
  nas mãos de quem leu a resposta;
- **chutar na linha do tempo.** "Provavelmente vazou perto do almoço" não serve para a revisão. Uma
  hora que o log confirma, ou uma nota dizendo que ainda não se sabe.
