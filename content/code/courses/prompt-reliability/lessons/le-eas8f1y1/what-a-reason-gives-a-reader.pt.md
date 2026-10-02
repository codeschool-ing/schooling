---
title: O que um motivo dá ao próximo leitor
version: 1
---

A medição não conseguiu separar os dois prompts. O argumento a favor do guia não depende só dela,
porque um prompt tem dois leitores, e o segundo é uma pessoa.

## Um caso que ninguém listou

Esta é uma mensagem do holdout para a qual nenhum dos dois prompts foi escrito:

```
ana@lab:~/triage$ grep h01 cases/all.jsonl
{"id": "h01", "message": "I returned the paperback but you refunded the wrong card.", "expect": {"category": "billing", "urgency": "normal"}}
ana@lab:~/triage$ grep -n refund prompts/v8-rules.txt
16:- Do not mention refunds unless the customer does.
17:- A refund is billing.
18:- A refund for a returned book is returns.
ana@lab:~/triage$ pl check runs/rules.jsonl --failures | grep h01
h01    category  returns, expected billing
```

Lida ao pé da letra, a linha 18 resolve: reembolso de livro devolvido é returns. A pessoa que
rotulou disse billing, porque o reembolso foi para o cartão errado, e só o setor de contas consegue
devolver dinheiro a um cartão. **A lista de regras dá uma resposta errada e confiante** ao primeiro
caso em que os autores não pensaram, e acrescentar uma décima quarta regra para ele só levaria a
borda para o caso seguinte.

O guia também não menciona esse caso. O que ele dá é uma pergunta a fazer a qualquer caso:

```
ana@lab:~/triage$ grep -n "goes to" prompts/v8-guide.txt
10:- billing goes to the accounts desk: money taken, owed or charged wrongly.
11:- delivery goes to the warehouse: an order on its way, late or lost.
12:- returns also goes to the warehouse: a book coming back, or a refund for one.
13:- account goes to whoever runs the website: signing in, settings, personal data.
```

Quem consegue consertar um reembolso pago no cartão errado? O depósito não. A linha 10 diz que
dinheiro cobrado errado vai para o setor de contas. **Uma regra com o seu motivo pode ser aplicada a
um caso que ninguém listou**; uma regra sem motivo só pode ser comparada com os casos que ela nomeia.
No substituto, `h01` volta como returns também com o guia, porque o substituto não lê motivos, que é
o ponto da seção anterior e não um veredito sobre esta.

## Qual regra pode sair

O segundo leitor é quem mantém o prompt. Pegue a linha 19 das regras, *Do not use the word
"customer" in the summary*. Alguém tinha um motivo. Ninguém mais sabe qual, então ninguém se arrisca
a apagar a linha, e o prompt continua crescendo na única direção contra a qual a aula 2 alertou.
**Um motivo escrito ao lado de uma regra é o que deixa a próxima pessoa decidir que ela não vale
mais**, e apagá-la com um teste em vez de um palpite.

A linha do guia sobre nomes traz o motivo junto: o resumo é lido por alguém que escolhe o que fazer
em seguida, e o nome não ajuda nessa escolha. Se um dia a equipe quiser nomes no resumo, o motivo diz
o que mudou e a linha pode sair.

## O que os fornecedores dizem

A documentação de engenharia de prompts da Anthropic para o Claude recomenda exatamente isso: dar ao
modelo o contexto e a motivação por trás de uma instrução, e dizer o que fazer em vez de só o que não
fazer. Ela apresenta isso como orientação, não como um ganho medido, e é a hipótese que a seção
anterior mostrou como testar nos seus próprios casos.

Nem toda linha precisa de motivo. As listas de rótulos e o formato JSON são contratos, como a aula 3
disse, e um contrato se declara, não se argumenta. **Motivos vão onde o leitor precisa usar
julgamento**: qual setor, quão urgente, para que serve o resumo.
