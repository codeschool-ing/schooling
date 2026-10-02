---
title: Um motivo em vez de uma regra
version: 1
---

A alternativa a uma lista de regras é uma explicação do trabalho. O `v8-guide.txt` pede o mesmo JSON
com os mesmos rótulos, e gasta as palavras dizendo **para que** serve cada rótulo:

```
ana@lab:~/triage$ cat -n prompts/v8-guide.txt
     1	You sort customer messages for Folio, an online bookshop, so that the right
     2	person answers each one and the urgent ones are answered first.
     3	
     4	Answer with only a JSON object with three fields:
     5	- "category": one of billing, delivery, returns, account, other
     6	- "urgency": one of low, normal, high
     7	- "summary": one sentence saying what the customer needs
     8	
     9	What the categories mean, because two people answer them:
    10	- billing goes to the accounts desk: money taken, owed or charged wrongly.
    11	- delivery goes to the warehouse: an order on its way, late or lost.
    12	- returns also goes to the warehouse: a book coming back, or a refund for one.
    13	- account goes to whoever runs the website: signing in, settings, personal data.
    14	- other is for anything that needs neither.
    15	
    16	Urgency is about harm, not tone. A customer out of pocket, or unable to
    17	reach their account, is high however politely they ask. A question that
    18	can wait a day is low.
    19	
    20	The summary is read instead of the message by somebody choosing what to do
    21	next, so it says what the customer needs, without their name.
    22	
    23	<message>
    24	{{message|xml}}
    25	</message>
ana@lab:~/triage$ pl lint prompts/v8-guide.txt
prompts/v8-guide.txt: nothing found
246 tokens
```

Cada categoria é descrita por quem a atende, porque é isso que a categoria decide: o setor de
contas, o depósito, quem cuida do site. A urgência ganha uma frase de princípio, *about harm, not
tone*, e dois exemplos dele. O resumo é descrito por quem o lê e pelo que essa pessoa faz em
seguida, e a regra sobre nomes sai disso.

**O linter não encontra nada**, e neste caso isso é mais do que a ausência de um padrão, porque não
há nada do tipo que ele procura: nenhuma fileira de proibições, nenhuma maiúscula, nenhum par de
opostos.

## O conflito, resolvido pelo motivo

Leve `t22` ao guia em vez das regras. É uma pergunta, sobre pagamento, de alguém que ainda não pagou.
Ninguém está no prejuízo, e pode esperar um dia, então o guia diz low, que é o que a pessoa que
rotulou disse. O guia não precisou de uma regra sobre perguntas nem de uma regra sobre dinheiro. **Um
princípio cobre os casos para os quais duas regras foram escritas, e também aquele em que elas
colidem.**

## Mais longo, sem enchimento

```
ana@lab:~/triage$ pl tokens prompts/v8-rules.txt
199 tokens, 152 words, 839 characters
ana@lab:~/triage$ pl tokens prompts/v8-guide.txt
246 tokens, 191 words, 1101 characters
```

O guia tem 47 tokens a mais. A aula 2 cortou 98 tokens de um prompt e não perdeu nada, e isso não é
contradição: o que a aula 2 cortou foram linhas que não decidiam nada, diziam algo duas vezes ou
brigavam entre si. **Cada linha do guia traz um motivo que um leitor consegue aplicar a uma
mensagem**, e o teste de uma linha é se ela muda uma resposta, não o quanto ela é curta. Se estas
linhas mudam respostas é uma medição, e a próxima seção a faz.
