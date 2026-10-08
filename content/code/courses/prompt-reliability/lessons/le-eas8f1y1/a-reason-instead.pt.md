---
title: Um motivo no lugar de uma regra
version: 2
---

A alternativa a uma lista de regras é uma explicação do trabalho. Este prompt pede o mesmo JSON com
os mesmos rótulos, e gasta as palavras dele no **para que** serve cada rótulo. Salve-o como
`prompts/v8-guide.txt`:

```
You sort customer messages for Folio, an online bookshop, so that the right
person answers each one and the urgent ones are answered first.

Answer with only a JSON object with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

What the categories mean, because two people answer them:
- billing goes to the accounts desk: money taken, owed or charged wrongly.
- delivery goes to the warehouse: an order on its way, late or lost.
- returns also goes to the warehouse: a book coming back, or a refund for one.
- account goes to whoever runs the website: signing in, settings, personal data.
- other is for anything that needs neither.

Urgency is about harm, not tone. A customer out of pocket, or unable to
reach their account, is high however politely they ask. A question that
can wait a day is low.

The summary is read instead of the message by somebody choosing what to do
next, so it says what the customer needs, without their name.

<message>
{{message|xml}}
</message>
```

Cada categoria é descrita por quem a atende, porque é isso que a categoria decide: a mesa de
contas, o depósito, quem cuida do site. A urgência ganha uma frase de princípio, *about harm, not
tone*, e duas instâncias dele. O resumo é descrito por quem o lê e pelo que essa pessoa faz em
seguida, e a regra sobre nomes sai daí.

```
ana@lab:~/triage$ python3 lint.py prompts/v8-guide.txt
prompts/v8-guide.txt: nothing found
```

**O linter não acha nada**, e neste caso isso é mais que a ausência de um padrão, porque não há nada
do tipo que ele procura: nenhuma proibição em fila, nenhuma maiúscula, nenhum par de opostos.

## O conflito, resolvido pelo motivo

Leve o `t22` ao guia em vez das regras. É uma pergunta, sobre pagamento, de alguém que ainda não
pagou. Ninguém está no prejuízo, e pode esperar um dia, então o princípio do guia diz low, que é o
que a pessoa que o rotulou disse. O guia não precisou de uma regra sobre perguntas nem de uma regra
sobre dinheiro. **Um princípio cobre os casos para os quais cada uma das duas regras foi escrita, e
aquele em que elas colidem.** Esse é o argumento; a próxima seção o confere contra o modelo.

## Mais longo, e sem enchimento

O guia é mais longo que as regras: 285,3 tokens por chamada contra 231,3, dizem as execuções da
próxima seção. A aula 2 cortou 97 tokens de um prompt e não perdeu nada, e isso não é uma
contradição: o que a aula 2 cortou foram linhas que não decidiam nada, diziam algo duas vezes ou
brigavam entre si. **Cada linha do guia traz um motivo que um leitor consegue aplicar a uma
mensagem**, e o teste de uma linha é se ela muda uma resposta, não o quanto ela é curta. Se estas
linhas mudam respostas é uma medição, e a próxima seção a faz.
