---
title: Um agente recebe as ferramentas da tarefa, e nada além
version: 1
---

Quando um modelo recebe ferramentas, ele não as chama. **Ele escreve uma proposta de chamada**, um nome
de ferramenta e os argumentos, e a aplicação decide se a executa. Esse momento é a aula inteira. Uma
aplicação que executa toda proposta entregou ao modelo as próprias permissões; uma que confere cada
proposta contra uma lista escrita ficou com elas.

O assistente de suporte da Tarefa é o caso. A lista do que ele pode fazer é o `data/tools.json`:

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

As chamadas em `data/proposed-calls.jsonl` **foram escritas pelo curso** no lugar do que um agente
proporia; nenhum modelo as propôs. Cada uma encontra uma regra diferente:

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
ser dividida, estreitada ou deixada de fora. A aula 7 olha o que dá errado quando as permissões de um
agente são mais largas que a tarefa; esta aula é o formato do conserto.
