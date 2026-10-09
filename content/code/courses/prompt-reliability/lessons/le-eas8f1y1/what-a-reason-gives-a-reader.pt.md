---
title: O que um motivo dá ao próximo leitor
version: 2
---

A medição não conseguiu separar os dois prompts. O argumento a favor do guia não depende só dela,
porque um prompt tem dois leitores, e o segundo é uma pessoa.

## Um caso que ninguém listou

Aqui está uma mensagem do conjunto guardado para a qual nenhum dos prompts foi escrito:

```
ana@lab:~/triage$ grep h01 cases/all.jsonl
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
ana@lab:~/triage$ grep -n refund prompts/v8-rules.txt
16:- Do not mention refunds unless the customer does.
17:- A refund is billing.
18:- A refund for a returned book is returns.
```

Lida ao pé da letra, a linha 18 resolve: um reembolso de um livro devolvido é returns. A pessoa que
a rotulou disse billing, porque o reembolso foi para o cartão errado, e só a mesa de contas consegue
devolver dinheiro a um cartão. **A lista de regras dá uma resposta errada e confiante** ao primeiro
caso em que os autores não pensaram, e acrescentar uma décima quarta regra para ele só levaria a
borda para o próximo caso.

O guia também não menciona este caso. O que ele dá a um leitor é uma pergunta a fazer a qualquer
caso:

```
ana@lab:~/triage$ grep -n "goes to" prompts/v8-guide.txt
10:- billing goes to the accounts desk: money taken, owed or charged wrongly.
11:- delivery goes to the warehouse: an order on its way, late or lost.
12:- returns also goes to the warehouse: a book coming back, or a refund for one.
13:- account goes to whoever runs the website: signing in, settings, personal data.
```

Quem consegue consertar um reembolso pago no cartão errado? Não o depósito. A linha 10 diz que
dinheiro cobrado errado vai para a mesa de contas. **Uma regra com o seu motivo pode ser aplicada a
um caso que ninguém listou**; uma regra sem motivo só pode ser comparada com os casos que nomeia.

É isso que o motivo dá a uma pessoa. Se o modelo o aplica é outra questão, e aqui ele não aplicou:

```
ana@lab:~/triage$ pl show runs/rules.jsonl h01
│ {"category": "returns", "urgency": "high", "summary": "Refunded the wrong card for returned paperback"}
stop: stop, tokens in 228, out 27, 3.2 s
ana@lab:~/triage$ pl show runs/guide.jsonl h01
│ {"category": "returns", "urgency": "high", "summary": "Refund was made to the wrong card for returned paperback"}
stop: stop, tokens in 282, out 30, 3.9 s
```

`returns` com os dois prompts, e `high` com os dois, onde uma pessoa disse `normal`. O modelo casou
*returned* e *refunded* com a linha de returns e parou ali. Um motivo é algo que um leitor
**consegue** usar, o que não é o mesmo que um leitor usá-lo, e no `llama3.2:3b` este não foi usado.
Um modelo mais forte talvez use; isso é uma execução, não uma suposição.

## Qual regra pode sair

O segundo leitor é quem mantém o prompt. Pegue a linha 19 das regras, *Do not use the word
"customer" in the summary*. Alguém tinha um motivo. Ninguém o sabe mais, então ninguém ousa apagar a
linha, e o prompt continua crescendo na única direção contra a qual a aula 2 alertou. **Um motivo
escrito ao lado de uma regra é o que deixa a próxima pessoa decidir que ela não vale mais**, e
apagá-la com um teste em vez de um palpite.

A linha do guia sobre nomes traz o motivo junto: o resumo é lido por alguém escolhendo o que fazer
em seguida, e o nome não ajuda essa pessoa a escolher. Se um dia a equipe quiser nomes no resumo, o
motivo diz o que mudou e a linha pode sair.

## O que os fornecedores dizem

A documentação de engenharia de prompts da Anthropic para o Claude recomenda exatamente isso: dar ao
modelo o contexto e a motivação por trás de uma instrução, e dizer o que fazer em vez de só o que
não fazer. Ela apresenta isso como orientação, não como um ganho medido, e a seção anterior o mediu
num modelo pequeno e em setenta mensagens sem achar diferença.

Nem toda linha precisa de motivo. As listas de rótulos e a forma do JSON são contratos, como a aula
3 disse, e um contrato se declara, não se argumenta. **Motivos ficam onde o leitor precisa usar
julgamento**: qual mesa, quão urgente, para que serve o resumo.
