---
title: Verificações como testes unitários
version: 1
---

Um teste unitário chama uma função com uma entrada e afirma uma coisa sobre o que volta. **Cada
verificação do `pl check` é um teste unitário sobre uma resposta**: dado este texto, ele é
JSON válido, tem exatamente os campos, os valores vêm das listas, concorda com a pessoa?

```
ana@lab:~/triage$ pl check runs/v2.jsonl --failures
check      pass  fail
json         27    13
fields       27    13
labels       27    13
category     27    13
urgency      24    16
all          24    16

t03    json      not JSON
t06    json      not JSON
t08    json      not JSON
t09    json      not JSON
t12    json      not JSON
t14    urgency   normal, expected low
t15    json      not JSON
t16    json      not JSON
t20    json      not JSON
t22    json      not JSON
t24    urgency   low, expected normal
t27    json      not JSON
t28    urgency   normal, expected low
t32    json      not JSON
t35    json      not JSON
t39    json      not JSON
ana@lab:~/triage$ grep -n "^CHECKS" promptlab/cli.py
204:CHECKS = ["json", "fields", "labels", "category", "urgency"]
```

## A ordem é o projeto

As cinco rodam da mais barata e mais certa para a menos. `json`, `fields` e `labels` não precisam de
nada além da resposta e da especificação, então dão o mesmo veredito em qualquer mensagem e poderiam
rodar em toda resposta em produção. A aula 10 usou `json` exatamente assim, recusando respostas que
uma injeção tinha entortado. `category` e `urgency` precisam do rótulo de uma pessoa, então só
existem onde existe um conjunto de teste.

**Uma resposta que falha numa verificação não é avaliada nas seguintes.** Isso faz da lista de
falhas uma lista de causas primeiras. `t03` falhou em `json`, e essa é a história inteira: não há
categoria para discutir numa resposta que ninguém consegue ler. `t14` era JSON válido, tinha os campos
certos e rótulos permitidos, e discordou da pessoa sobre a urgência, que é outro problema com outra
correção.

Na ordem inversa, a lista diria que `t03` tinha a categoria errada, e você iria procurar um problema
de classificação num prompt cujo problema era um bloco de código.

## O que faz uma verificação valer a pena

- **Ela dá o mesmo veredito sempre.** Toda verificação aqui são poucas linhas de comparação, sem
  modelo nenhum dentro. Uma verificação que pode mudar de ideia é uma segunda coisa a medir.
- **Ela afirma uma propriedade.** `fields` não se importa com rótulos; `labels` não se importa com a
  pessoa. Quando uma falha, você sabe o que falhou.
- **Ela é tão rigorosa quanto quem lê a resposta.** `fields` recusa um campo a mais, e foi assim que a
  aula 1 pegou o número de pedido copiado. Uma verificação mais frouxa que o programa seguinte aprova
  respostas que o programa vai recusar.
- **A falha diz o que viu.** *urgency normal, expected low* é uma tarefa; um *fail* seco é um motivo
  para abrir o arquivo.

::: track ai
As verificações são a `judge_row` em `promptlab/cli.py`, um `elif` cada, e acrescentar uma são poucas
linhas. Uma verificação que reprova um resumo com mais de uma frase, por exemplo, fica depois de
`labels` e antes de `category`, porque precisa de uma resposta que já passou pelo parser e de nenhum rótulo.
Escreva-a como escreveria qualquer teste: encontre uma resposta que deveria reprovar, e veja-a
reprovar essa resposta antes de confiar que ela aprova as outras.
:::

::: track *
Você usa as cinco verificações como vêm. O que importa é lê-las como testes: cada uma afirma uma
coisa, e quando você quer saber se uma propriedade nova vale, a pergunta útil é qual verificação
falharia se ela não valesse. A aula 12 acrescenta regras de tom construídas exatamente assim.
:::
