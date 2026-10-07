---
title: Lendo as falhas
version: 1
---

Uma nota diz quantos. As falhas dizem **de que tipo**, e o tipo decide o que fazer em seguida. O
`evalkit errors` lista toda resposta que não estava estritamente certa. As do 1b ficam para o fim;
primeiro os outros dois modelos:

```
ana@desk:~/desk$ python evalkit.py errors runs/triage.jsonl | grep -v "^llama3.2:1b"
llama3.2:3b  c04 wrong     expected product-question got 'order-status, refund, address-change, product-question, other.'
llama3.2:3b  c05 loose ok  expected other           got 'other.'
llama3.2:3b  c07 wrong     expected refund          got 'order-status, refund'
llama3.2:3b  c09 wrong     expected product-question got 'order-status'
llama3.2:3b  c10 wrong     expected other           got 'order-status, refund'
llama3.2:3b  c13 wrong     expected address-change  got 'order-status'
llama3.2:3b  c14 wrong     expected product-question got 'order-status, product-question.'
llama3.2:3b  c15 wrong     expected other           got 'order-status, other.'
llama3.2:3b  c16 wrong     expected order-status    got 'product-question'
llama3.2:3b  c19 wrong     expected product-question got 'order-status'
llama3.2:3b  c21 wrong     expected refund          got 'order-status'
llama3.2:3b  c22 wrong     expected address-change  got 'order-status'
llama3.2:3b  c24 wrong     expected other           got 'order-status, other.'
llama3.2:3b  c26 wrong     expected refund          got 'order-status'
llama3.2:3b  c28 wrong     expected product-question got 'order-status, refund'
llama3.2:3b  c29 wrong     expected other           got 'order-status'
llama3.2:3b  c32 wrong     expected address-change  got 'order-status, refund, address-change, product-question, other.'
llama3.2:3b  c33 wrong     expected product-question got 'order-status'
llama3.2:3b  c34 wrong     expected other           got 'order-status, refund'
llama3.2:3b  c37 wrong     expected address-change  got 'order-status, address-change'
llama3.2:3b  c38 wrong     expected product-question got 'order-status, product-question'
llama3.2:3b  c39 wrong     expected other           got "I can't do that. If you're concerned about your account being deleted or your personal information being held, I can provide general information on data protection and account management. Would that help?"
qwen2.5:3b   c01 wrong     expected order-status    got 'product-question'
qwen2.5:3b   c06 wrong     expected order-status    got 'refund'
qwen2.5:3b   c10 wrong     expected other           got 'order-status'
qwen2.5:3b   c11 wrong     expected order-status    got 'product-question'
qwen2.5:3b   c24 wrong     expected other           got 'product-question'
qwen2.5:3b   c26 wrong     expected refund          got 'product-question'
qwen2.5:3b   c32 wrong     expected address-change  got 'order-status'
qwen2.5:3b   c34 wrong     expected other           got 'product-question'
qwen2.5:3b   c36 wrong     expected refund          got 'product-question'
qwen2.5:3b   c40 wrong     expected order-status    got 'refund'
```

Trinta e duas linhas, e elas caem em quatro grupos.

**Mais de um rótulo.** A falha mais comum do llama3.2:3b é de formato: `order-status, refund`,
`order-status, product-question`, e duas vezes a lista inteira de cinco. O prompt pede exatamente um
rótulo e mais nada, e onze vezes o modelo respondeu com uma lista, às vezes com o rótulo certo em
algum lugar dentro dela. A pontuação frouxa não salva isso, porque uma lista não é um rótulo. O
único `loose ok` dele, `other.` para o c05, é a desarrumação que a seção 04 previu. **O conserto
está no prompt ou num recurso de saída estruturada** (a coluna `S` da aula 4), não na escolha do
modelo.

**Tudo é pedido.** Das 21 respostas erradas do llama3.2:3b, 19 são `order-status` ou começam por
ele, e `order-status` é o primeiro rótulo da lista do prompt. Um modelo que pega a primeira opção
quando está em dúvida tem um viés, e um viés se mede: ponha os rótulos em outra ordem, rode os casos
de novo e veja se as respostas erradas andam junto com a lista.

**Uma recusa.** O c39 pede à loja que apague a conta do cliente e tudo o que ela guarda, e o
llama3.2:3b respondeu *I can't do that*. Ele leu o e-mail como um pedido feito a ele, não como uma
mensagem a classificar, e recusou. Uma recusa no lugar de um rótulo é uma falha que o programa tem
de esperar, porque ela vai voltar de qualquer modelo em algum e-mail.

**Uma fronteira traçada em outro lugar.** Os dez do qwen2.5:3b são todos rótulos únicos e limpos, e
cada um é um julgamento que ele fez diferente da loja. Um pacote marcado como entregue que nunca
chegou (c06) e um pacote devolvido como não entregue (c40) foram `refund` para ele e `order-status`
para a loja; um volume faltando que o cliente quer reembolsado (c36) foi `product-question`. Esses
são os casos que a aula 1 seção 11 manda para **exemplos no prompt**: o modelo entende a tarefa e
traça a linha em outro lugar, e alguns casos de fronteira rotulados mudam a linha.

## Todos os modelos errados

Cinco casos estão errados para os três modelos: c10, c24, c26, c32 e c34. Dois deles são os que a
ana hesitou em rotular na seção 03, o desconto para escola e o reembolso da diferença. **Quando
todos os candidatos discordam de um rótulo, desconfie do rótulo antes dos modelos.** Aqui eles nem
concordam entre si: para o c24, o qwen2.5:3b diz `product-question` e o llama3.2:3b uma lista que
começa com `order-status`, o que é sinal de caso difícil, não de rótulo errado.

E então o 1b, cujos seis primeiros de trinta e seis são típicos:

```
ana@desk:~/desk$ python evalkit.py errors runs/triage.jsonl | grep "^llama3.2:1b" | head -6
llama3.2:1b  c02 wrong     expected refund          got 'order-status\nrefund\naddress-change\nproduct-question\nother'
llama3.2:1b  c03 wrong     expected address-change  got 'order-status, address-change.'
llama3.2:1b  c04 wrong     expected product-question got 'other'
llama3.2:1b  c05 wrong     expected other           got 'No.'
llama3.2:1b  c06 wrong     expected order-status    got 'order-status, refund, address-change, product-question, other.'
llama3.2:1b  c07 wrong     expected refund          got 'order-status\nrefund'
```

A lista inteira de rótulos, em coluna ou numa linha só, e `No.` para uma pergunta sobre visitar uma
loja. **O llama3.2:1b não é um classificador mais fraco, ele não está classificando**: não segue a
instrução de responder com um rótulo. Isso também é uma conclusão, e custa a um modelo uma linha
numa tabela em vez de um mês em produção.

## O que fazer com um rótulo suspeito

Não mudá-lo calado. A ana leva o c24 e o c26 de volta à pessoa que rotulou com ela, e as duas
decidem de novo, desta vez com as respostas dos modelos à frente:

- c24, trinta exemplares para uma escola: preço por quantidade é respondido por quem negocia, não
  pelas páginas de produto, então **`other` fica**, e elas acrescentam uma linha às regras de
  rotulação dizendo isso.
- c26, a capa dura que veio em brochura: o cliente está pedindo dinheiro de volta, então **`refund`
  fica**, seja qual for a edição.

As duas decisões vão para o histórico do projeto com o motivo. **Um rótulo mudado porque um modelo
discordou, sem um motivo que uma pessoa aceitaria, é a avaliação dando nota a si mesma.** E depois
de qualquer mudança no conjunto, todos os candidatos rodam de novo, porque notas em duas versões de
um conjunto não são comparáveis. Aqui os dois rótulos ficaram, os modelos estavam errados, e o
conjunto não mudou.
