---
title: Um agente recebe as ferramentas da tarefa, e nada além
version: 2
---

Quando um modelo recebe ferramentas, ele não as chama. **Ele escreve uma proposta de chamada**, um nome
de ferramenta e os argumentos, e a aplicação decide se a executa. Esse momento é a aula inteira. Uma
aplicação que executa toda proposta entregou ao modelo as próprias permissões; uma que confere cada
proposta contra uma lista escrita ficou com elas.

O assistente de suporte da Tarefa é o caso. A lista do que ele pode fazer é o `data/tools.json`, escrito
pelo curso junto com a sessão contra a qual ele é conferido. Cole-o:

```sh
cat > ~/guard/data/tools.json <<'EOF'
{
 "calls_per_conversation": 8,
 "session": {
  "account": "ac-7Q2M",
  "paid_cents": {
   "4471": 120000
  }
 },
 "tools": {
  "lookup_order": {
   "access": "read",
   "scope": "session-account"
  },
  "send_message": {
   "access": "write",
   "recipients": [
    "session-account"
   ]
  },
  "issue_refund": {
   "access": "write",
   "scope": "session-account",
   "max_cents": "what the client paid",
   "confirm": "moves money and cannot be undone"
  }
 }
}
EOF
```

```
ana@lab:~/guard$ cat data/tools.json
{
 "calls_per_conversation": 8,
 "session": {
  "account": "ac-7Q2M",
  "paid_cents": {
   "4471": 120000
  }
 },
 "tools": {
  "lookup_order": {
   "access": "read",
   "scope": "session-account"
  },
  "send_message": {
   "access": "write",
   "recipients": [
    "session-account"
   ]
  },
  "issue_refund": {
   "access": "write",
   "scope": "session-account",
   "max_cents": "what the client paid",
   "confirm": "moves money and cannot be undone"
  }
 }
}
```

Três ferramentas, e a lista é curta de propósito. **Menor privilégio** significa que o agente tem as
ferramentas que a tarefa exige e nenhuma outra, e que cada ferramenta só alcança os dados da conversa
em que está. Uma conversa de suporte precisa ler os pedidos do cliente, escrever para o cliente e às
vezes reembolsá-lo. Não precisa mudar o telefone de um cliente, rodar uma consulta no banco nem escrever
para outra pessoa, então essas ferramentas não existem para ela.

O portão lê uma proposta contra essa lista e responde com a regra que decidiu. Salve-o como
`~/guard/tools/gate.py`:

```python
# gate.py: proposed tool calls against the agent's manifest, before any runs.
#
#   guard gate FILE [--confirm ID --by NAME] [--budget N]
#
# The model decides nothing here. It PROPOSES a call; the gate reads the
# proposal against data/tools.json and answers ALLOW, HOLD (a person must
# confirm) or DENY, with the rule that decided. The scope is checked against
# the session, which the code knows and the model does not get to say: a
# proposal naming another account has not become that client.
import argparse
import json
import os


def decide(call, session, manifest, confirmed):
    tool = manifest["tools"].get(call["tool"])
    if tool is None:
        return "DENY", "tool %s is not granted to this agent" % call["tool"]
    args = call["args"]
    if tool.get("scope") == "session-account" and args.get("account") != session["account"]:
        return "DENY", "account %s is not the session's (%s)" % (args.get("account"), session["account"])
    if "recipients" in tool:
        allowed = [session["account"] if r == "session-account" else r for r in tool["recipients"]]
        if args.get("to") not in allowed:
            return "DENY", "recipient %s is outside the tool's scope" % args.get("to")
    if "max_cents" in tool:
        cents = args.get("cents", 0)
        if not isinstance(cents, int) or isinstance(cents, bool):
            return "DENY", "cents %r is not an integer" % (cents,)
        paid = session["paid_cents"].get(args.get("job"), 0)
        if cents > paid:
            return "DENY", "refund of %d is more than the %d paid for job %s" % (
                cents, paid, args.get("job"))
    if tool.get("confirm"):
        if call["id"] in confirmed:
            return "ALLOW", "confirmed by %s" % confirmed[call["id"]]
        return "HOLD", "%s needs a person to confirm: %s" % (call["tool"], tool["confirm"])
    return "ALLOW", "%s, within scope" % tool["access"]


p = argparse.ArgumentParser(prog="guard gate")
p.add_argument("file")
p.add_argument("--confirm")
p.add_argument("--by")
p.add_argument("--budget", type=int)
a = p.parse_args()
if a.confirm and not a.by:
    p.exit(2, "a confirmation names the person who gave it: add --by NAME\n")

with open(os.path.expanduser("~/guard/data/tools.json")) as f:
    manifest = json.load(f)
budget = a.budget or manifest["calls_per_conversation"]
confirmed = {a.confirm: a.by} if a.confirm else {}
session = manifest["session"]

print("session %s, %d calls allowed" % (session["account"], budget))
with open(a.file, encoding="utf-8") as f:
    for n, call in enumerate(map(json.loads, f), 1):
        if n > budget:
            decision, why = "DENY", "budget of %d calls per conversation is spent" % budget
        else:
            decision, why = decide(call, session, manifest, confirmed)
        print("%-3s %-14s %-5s  %s" % (call["id"], call["tool"], decision, why))
```

Sete propostas, **escritas pelo curso** no lugar do que um agente proporia, cada uma para encontrar uma
regra diferente:

```sh
cat > ~/guard/data/proposed-calls.jsonl <<'EOF'
{"id": "c1", "tool": "lookup_order", "args": {"account": "ac-7Q2M", "order": "4471"}}
{"id": "c2", "tool": "lookup_order", "args": {"account": "ac-0Z5Q", "order": "5120"}}
{"id": "c3", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": 120000}}
{"id": "c4", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": 900000}}
{"id": "c5", "tool": "send_message", "args": {"to": "ac-7Q2M", "text": "Your refund request is with a colleague."}}
{"id": "c6", "tool": "send_message", "args": {"to": "someone@example.net", "text": "Order 4471 details attached."}}
{"id": "c7", "tool": "update_contact", "args": {"account": "ac-7Q2M", "phone": "+55 11 90000-0000"}}
EOF
```

```
ana@lab:~/guard$ cat data/proposed-calls.jsonl
{"id": "c1", "tool": "lookup_order", "args": {"account": "ac-7Q2M", "order": "4471"}}
{"id": "c2", "tool": "lookup_order", "args": {"account": "ac-0Z5Q", "order": "5120"}}
{"id": "c3", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": 120000}}
{"id": "c4", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": 900000}}
{"id": "c5", "tool": "send_message", "args": {"to": "ac-7Q2M", "text": "Your refund request is with a colleague."}}
{"id": "c6", "tool": "send_message", "args": {"to": "someone@example.net", "text": "Order 4471 details attached."}}
{"id": "c7", "tool": "update_contact", "args": {"account": "ac-7Q2M", "phone": "+55 11 90000-0000"}}
ana@lab:~/guard$ guard gate data/proposed-calls.jsonl
session ac-7Q2M, 8 calls allowed
c1  lookup_order   ALLOW  read, within scope
c2  lookup_order   DENY   account ac-0Z5Q is not the session's (ac-7Q2M)
c3  issue_refund   HOLD   issue_refund needs a person to confirm: moves money and cannot be undone
c4  issue_refund   DENY   refund of 900000 is more than the 120000 paid for job 4471
c5  send_message   ALLOW  write, within scope
c6  send_message   DENY   recipient someone@example.net is outside the tool's scope
c7  update_contact DENY   tool update_contact is not granted to this agent
```

## O escopo vem da sessão

A `c2` pede um pedido de `ac-0Z5Q` numa conversa que pertence a `ac-7Q2M`. O portão a recusa, e o
detalhe importante é de onde o portão tirou `ac-7Q2M`: **da sessão, que o código estabeleceu quando o
cliente entrou**, e não de algo que o modelo escreveu. A proposta de um modelo pode conter qualquer id
de conta, por motivos que vão de um erro simples a um texto que ele leu num documento. Uma regra que
confiasse na conta da proposta seria uma regra que o modelo poderia reescrever.

O mesmo raciocínio vale para a `c6`. O `send_message` pode alcançar o cliente da sessão, e o endereço da
proposta é outra pessoa. E a `c7` pede uma ferramenta que o manifesto não nomeia, então não há o que
decidir: uma ferramenta não concedida é recusada digam o que disserem os argumentos.

## Escrevendo a lista

Um manifesto é escrito a partir da tarefa, não do que os sistemas por baixo conseguem fazer. Três
perguntas por ferramenta resolvem quase tudo:

| pergunta | na Tarefa |
|---|---|
| leitura ou escrita? | `lookup_order` lê; `send_message` e `issue_refund` escrevem |
| de quem são os dados, no máximo? | do cliente da sessão, nas três |
| qual o maior efeito que uma chamada pode ter? | um reembolso do valor pago, e não mais |

Uma ferramenta que não consegue responder à terceira pergunta com um limite é uma ferramenta que deve
ser dividida, estreitada ou deixada de fora. Um agente com permissões mais largas que a tarefa pode ser levado a usar a diferença; esta aula é o formato do conserto.

## O que um modelo de verdade propõe

As sete propostas foram escritas para encontrar as regras. Este programa pergunta ao `llama3.2:3b` no
lugar delas: diz ao modelo de quem é a conversa e quais ferramentas existem, dá a ele uma mensagem de
cliente e escreve as chamadas que ele propuser no mesmo formato. Ele não roda nada. Salve-o como
`~/guard/tools/propose.py`:

```python
# propose.py: ask the model which tool calls it would make for one client message.
#
#   guard propose MESSAGE > FILE
#
# The model is told the session's account and the three tools by name and
# argument, and asked for JSON. It proposes; nothing here runs a tool. The
# proposals are written one per line, numbered p1, p2 ..., in the shape of
# data/proposed-calls.jsonl, so that `guard gate` can judge them.
import json
import sys

from ask import ask

SYSTEM = """You are Tarefa's support assistant, talking to the client whose
account is ac-7Q2M. You can propose calls to these tools:

  lookup_order(account, order)          read an order
  send_message(to, text)                message an account
  issue_refund(account, job, cents)     refund a job, in cents of a real

Reply with a JSON object {"calls": [...]}, each call {"tool": NAME, "args": {...}},
in the order you would make them, and nothing else."""

reply = json.loads(ask(sys.argv[1], system=SYSTEM, json_only=True))
for n, call in enumerate(reply.get("calls", []), 1):
    print(json.dumps({"id": "p%d" % n, "tool": call.get("tool"), "args": call.get("args", {})}))
```

```
ana@lab:~/guard$ guard propose "Job 4471 was never delivered. I paid R$ 1.200,00 and I want my money back." > data/real-calls.jsonl
ana@lab:~/guard$ cat data/real-calls.jsonl
{"id": "p1", "tool": "lookup_order", "args": {"account": "ac-7Q2M", "order": "4471"}}
{"id": "p2", "tool": "issue_refund", "args": {"account": "ac-7Q2M", "job": "4471", "cents": "120000"}}
{"id": "p3", "tool": "send_message", "args": {"to": "ac-7Q2M", "text": "Refund of R$ 1.200,00 has been initiated."}}
ana@lab:~/guard$ guard gate data/real-calls.jsonl
session ac-7Q2M, 8 calls allowed
p1  lookup_order   ALLOW  read, within scope
p2  issue_refund   DENY   cents '120000' is not an integer
p3  send_message   ALLOW  write, within scope
ana@lab:~/guard$ guard propose "Where is my order 4471?" | guard gate /dev/stdin
session ac-7Q2M, 8 calls allowed
p1  lookup_order   ALLOW  read, within scope
p2  read_an_order  DENY   tool read_an_order is not granted to this agent
```

Três coisas aconteceram, e nenhuma estava nas sete propostas escritas.

- **A `p2` pediu o reembolso certo no tipo errado.** O modelo escreveu o valor como o texto
  `"120000"`, não como número. O portão a recusa, e essa verificação existe por causa desta execução: a
  primeira versão do portão comparava o texto com um número, e o Python parou com um erro no meio da
  lista. Um portão que quebra numa proposta que não esperava não decidiu nada.
- **A `p3` diz ao cliente que o reembolso foi iniciado.** Está dentro do escopo, uma mensagem para a
  própria conta da sessão, então o portão a permite, enquanto o reembolso que ela anuncia foi recusado.
  **O portão confere o que uma chamada pode alcançar, não se o que ela diz é verdade.** Uma mensagem que
  relata uma ação vem depois da ação, escrita pelo código a partir do resultado, e não proposta pelo
  modelo ao lado dela.
- **A segunda mensagem ganhou uma ferramenta que ninguém concedeu.** Perguntado onde está um pedido, o
  modelo propôs `read_an_order`, um nome que ele fez a partir da descrição do `lookup_order`. Não
  alcançou nada, porque uma ferramenta não concedida é recusada, tenha o nome que tiver.

A sua execução pode propor outras chamadas. O que não muda é que cada uma passa pelo mesmo portão.
