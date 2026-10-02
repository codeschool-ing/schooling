---
title: Palavras que conduzem
version: 1
---

Contexto parece inofensivo. Uma frase que conta ao modelo algo verdadeiro sobre a caixa de entrada
parece o tipo de coisa que quem escreve prompts com cuidado acrescenta. **O modelo lê essa frase
como uma pista sobre cada mensagem**, e age conforme ela no único lugar em que tem espaço: as
mensagens que podiam ir para um lado ou para o outro.

```
ana@lab:~/triage$ diff prompts/v6-escaped.txt prompts/v18-leading.txt
1c1,2
< You sort customer messages for Folio, an online bookshop.
---
> You sort customer messages for Folio, an online bookshop. Most messages we
> get are about delivery.
ana@lab:~/triage$ grep -n "^LEADING_PULL" promptlab/standin.py
88:LEADING_PULL = 1.2      # "most messages are about X" adds this to X
```

A frase pode muito bem ser verdadeira; entregas são uma boa parte da correspondência de qualquer
livraria. No substituto, uma frase do tipo *a maioria das mensagens é sobre X* soma 1,2 a X em
toda mensagem, quase cinco vezes o que valia ser listado primeiro.

```
ana@lab:~/triage$ pl run prompts/v18-leading.txt cases/all.jsonl --out runs/leading.jsonl
70 calls, prompt 3a054c39, written to runs/leading.jsonl
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/leading.jsonl --answers
70 cases, same answer 62, different answer 8
  t19  account -> delivery
  t23  returns -> delivery
  t33  returns -> delivery
  h10  account -> delivery
  h13  other -> delivery
  h16  other -> delivery
  h19  other -> delivery
  h20  other -> delivery
ana@lab:~/triage$ grep -E '"(t19|t23|t33|h10|h13|h16|h19|h20)"' cases/all.jsonl | grep -o '"category": "[a-z]*"'
"category": "account"
"category": "returns"
"category": "returns"
"category": "account"
"category": "returns"
"category": "returns"
"category": "account"
"category": "delivery"
```

Oito respostas mudaram, e **todas foram para delivery**. Ponha cada uma ao lado do que a pessoa
disse. `t19`, `t23`, `t33` e `h10` estavam certas e agora estão erradas. `h13`, `h16` e `h19`
estavam erradas e continuam erradas. Uma foi corrigida:

```
ana@lab:~/triage$ grep h20 cases/all.jsonl
{"id": "h20", "message": "Do you deliver to Portugal, and how much does it cost?", "expect": {"category": "delivery", "urgency": "low"}}
```

Uma pergunta sobre entregar em Portugal é uma pergunta de delivery, e a frase a empurrou para o
lado certo da linha. Uma resposta certa por quatro erradas é a troca que uma frase indutora faz, e
é uma troca ruim mesmo quando a frase é verdadeira.

## O que deu errado

A frase é uma afirmação sobre a população, e **o modelo a aplica a cada mensagem**. Que a maioria
das mensagens seja sobre entrega não torna `t19` uma mensagem de entrega; *"Someone else seems to
have logged into my account and changed the delivery address"* menciona entrega, e trata de uma
conta que alguém invadiu. Avisado do que esperar, o substituto encontrou.

Modelos reais não são feitos de uma constante como `LEADING_PULL`, e ninguém consegue dizer quanto
uma frase específica move um modelo específico. O que quem trabalha com eles relata é a direção: um
prompt que diz o que esperar tende a receber mais disso. É uma afirmação para testar, nunca para
supor, e o teste é o de cima: o prompt com e sem a frase, comparado resposta a resposta.

## Como encontrá-las no seu prompt

Palavras indutoras são fáceis de escrever e difíceis de ver, porque cada uma entrou por um motivo.
Leia o prompt procurando:

- Taxas de base: *most*, *usually*, *nearly all*, *rarely*. No substituto, são essas as
  palavras que disparam a regra.
- Expectativas sobre o cliente: *customers are often confused about*, *people usually want*.
- Exemplos nas instruções: *for instance, a late parcel*. Uma frase que cita um tipo de
  mensagem é candidata como as outras, e se testa do mesmo jeito.

**Um prompt deve dizer o que fazer com cada mensagem**, e deixar os fatos sobre a caixa de entrada
para quem lê o painel. Quando uma frase está lá por um motivo, apague-a e compare as respostas; se
nada mudar, você não perdeu nada, e se respostas mudarem, você descobriu o que ela estava fazendo.
