---
title: Verificações como testes unitários
version: 2
---

Um teste unitário chama uma função com uma entrada e afirma uma coisa sobre o que volta. **Cada
verificação do `pl check` é um teste unitário sobre uma resposta**: dado este texto, ele é JSON
válido, tem exatamente os campos, os valores vêm das listas, ele concorda com a pessoa.

```
ana@lab:~/triage$ pl check runs/v3.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     35     5
urgency      28    12
all          28    12

t01    urgency   normal, expected high
t02    urgency   high, expected normal
t07    urgency   high, expected normal
t09    urgency   high, expected normal
t22    category  other, expected billing
t24    urgency   high, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t32    urgency   high, expected normal
t33    category  delivery, expected returns
t37    json      not a JSON object
t39    urgency   low, expected normal
ana@lab:~/triage$ grep -n "^CHECKS" pl.py
17:CHECKS = ["json", "fields", "labels", "category", "urgency"]
```

`CHECKS` é a linha 17 do `pl.py`: as cinco verificações na ordem em que o `judge()` as tenta, que é a
ordem em que o `pl check` conta.

## A ordem é o projeto

As cinco rodam da mais barata e mais certa para a menos. `json`, `fields` e `labels` não precisam de
nada além da resposta e da especificação, então dão o mesmo veredicto em qualquer mensagem e poderiam
rodar em toda resposta em produção. A aula 10 usou `json` exatamente assim, recusando uma resposta
que tinha acrescentado uma política de reembolso inventada. `category` e `urgency` precisam do
rótulo de uma pessoa, então só existem onde existe um conjunto de teste.

**Uma resposta que falha numa verificação não é pontuada nas seguintes.** Isso faz da lista de
falhas uma lista de primeiras causas. O `t37` falhou em `json`, e essa é a história toda: não há
categoria para discutir numa resposta que ninguém consegue ler. O `t22` era JSON válido, tinha os
campos certos e rótulos válidos, e discordou da pessoa sobre a categoria, que é outro problema com
outra correção.

Na ordem inversa, a lista diria que o `t37` tinha a categoria errada, e você iria procurar um
problema de classificação num prompt cujo problema era a forma da resposta.

## O que faz uma verificação valer a pena

- **Dá o mesmo veredicto toda vez.** Toda verificação aqui são algumas linhas de comparação, sem
  modelo nenhum dentro. Uma verificação que pode mudar de ideia é mais uma coisa a medir, e a aula
  13 mede uma.
- **Afirma uma propriedade só.** `fields` não liga para rótulos; `labels` não liga para a pessoa.
  Quando uma falha, você sabe o que falhou.
- **É tão estrita quanto quem lê a resposta.** `fields` recusa um campo a mais, que é como a aula 1
  pegou o número do pedido copiado. Uma verificação mais frouxa que o programa seguinte aprova
  respostas que o programa vai recusar.
- **A falha diz o que ela viu.** *urgency high, expected normal* é um item de tarefa; um *fail* seco
  é um motivo para abrir o arquivo.

::: track ai
As verificações são o `judge()` do `pl.py`, algumas linhas cada, e acrescentar uma é mais algumas.
Uma verificação que reprova um resumo com mais de uma frase, por exemplo, vai depois de `labels` e
antes de `category`, porque precisa de uma resposta já lida e de nenhum rótulo: ponha o nome dela em
`CHECKS` e devolva-a do `judge()`. Escreva-a como escreveria qualquer teste: ache uma resposta que
deveria falhar nela e veja-a falhar nessa resposta antes de confiar que ela aprova o resto.
:::

::: track *
Você usa as cinco verificações como vêm. O que importa é lê-las como testes: cada uma afirma uma
coisa, e quando você quer saber se uma propriedade nova vale, a pergunta útil é qual verificação
falharia se ela não valesse. A aula 12 acrescenta regras de tom construídas exatamente assim.
:::
