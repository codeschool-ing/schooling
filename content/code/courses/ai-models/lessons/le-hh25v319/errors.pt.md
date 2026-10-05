---
title: Lendo as falhas
version: 1
---

Uma nota diz quantas. As falhas dizem **de que tipo**, e o tipo decide o que fazer em seguida. O
`evalkit errors` lista toda resposta que não estava estritamente certa:

```
ana@desk:~/desk$ python lab/evalkit.py errors runs/triage.jsonl
standin-large  c20 wrong     expected order-status    got 'address-change'
standin-large  c38 wrong     expected product-question got 'other'
standin-small  c02 loose ok  expected refund          got 'Refund'
standin-small  c12 loose ok  expected refund          got 'refund.'
standin-small  c20 wrong     expected order-status    got 'address-change'
standin-small  c22 wrong     expected address-change  got 'other'
standin-small  c26 wrong     expected refund          got 'product-question'
standin-small  c31 wrong     expected refund          got 'order-status'
standin-small  c37 wrong     expected address-change  got 'other'
standin-small  c38 wrong     expected product-question got 'other'
standin-local  c06 wrong     expected order-status    got 'refund'
standin-local  c20 wrong     expected order-status    got 'address-change'
standin-local  c22 wrong     expected address-change  got 'order-status'
standin-local  c26 wrong     expected refund          got 'product-question'
standin-local  c30 wrong     expected order-status    got 'refund'
standin-local  c31 wrong     expected refund          got 'order-status'
standin-local  c34 wrong     expected other           got 'order-status'
standin-local  c38 wrong     expected product-question got 'other'
```

Dezoito linhas, e elas caem em quatro grupos.

**Desarrumada mas certa.** O `Refund` do standin-small para o c02 e o `refund.` para o c12, marcados
`loose ok`. O conserto está no programa ou no prompt (seção 04), não na escolha do modelo.

**Uma fronteira que o modelo traça em outro lugar.** O c22 pede para retirar um pedido no depósito; a
loja chama isso de `address-change`, o standin-small de `other`, o standin-local de `order-status`. O
c26 quer um reembolso parcial por uma edição errada, e dois modelos leem a edição e respondem
`product-question`. Esses são os casos que a aula 1 seção 07 manda para **exemplos no prompt**: o
modelo entende a tarefa e traça uma linha em outro lugar, e alguns casos de fronteira rotulados mudam
a linha de lugar.

**Um erro puro.** O `refund` do standin-local para o c06, um pacote marcado como entregue que nunca
chegou, e para o c30, um pacote que a transportadora diz nunca ter recebido. Nenhum dos dois e-mails
pede dinheiro. Um modelo que ouve "problema com o meu pedido" e responde `refund` não está traçando
uma linha fina; está lendo sem cuidado. Erros desse tipo são o que um modelo menor ou mais fraco troca
pelo preço.

**Todos os modelos errados, do mesmo jeito.** O c20 e o c38 estão errados para os três, e errados de
forma idêntica: `address-change` para o vizinho, `other` para Portugal. Quando todo candidato discorda
do rótulo na mesma direção, **desconfie do rótulo antes dos modelos**. São os dois casos em que a ana
hesitou na seção 03.

## O que fazer com um rótulo suspeito

Não mudá-lo em silêncio. A ana leva o c20 e o c38 de volta para a pessoa que rotulou com ela, e as
duas decidem de novo, desta vez com as respostas dos modelos na frente:

- c20, o vizinho: o cliente está perguntando para onde o pacote deve ir. Elas concordam que as filas
  da própria loja mandariam isso para quem cuida de endereços, e **rotulam de novo como
  `address-change`**.
- c38, Portugal: destinos de entrega são respondidos na mesma página das perguntas sobre produtos na
  Lantern Books, então **`product-question` fica**, e elas acrescentam uma linha às regras de
  rotulagem dizendo isso.

As duas decisões entram no histórico do projeto com o motivo. **Um rótulo mudado porque um modelo
discordou, sem um motivo que uma pessoa aceitaria, é a avaliação dando nota a si mesma.** E depois de
qualquer mudança no conjunto, todo candidato roda de novo na versão nova, porque notas em duas versões
de um conjunto não são comparáveis. As execuções do resto desta aula foram feitas antes da mudança,
no conjunto como a seção 03 o deixou, então os números delas podem ser lidos contra os da seção 06.
