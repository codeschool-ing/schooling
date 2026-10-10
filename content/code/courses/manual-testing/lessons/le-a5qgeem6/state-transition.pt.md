---
title: Estados e transições
version: 1
---

**Algum comportamento depende do que já aconteceu.** O mesmo botão, Refund, deve funcionar num
pedido e ser recusado em outro, e nada digitado num formulário distingue os dois: a diferença é a
história do pedido. As técnicas da aula 4 olham para entradas, e a tabela de decisão da seção 02
desta aula olha para combinações de condições que valem todas num mesmo instante. Nenhuma das duas
enxerga o tempo. O **teste de transição de estados** é a técnica para coisas que atravessam uma
vida, e no boxoffice isso é um pedido.

O jeito comum de testar um pedido é segui-lo pelo caminho que um cliente costuma fazer: reservar,
pagar, usar na porta. Todo passo funciona, e o pedido é dado como testado. Esse caminho é um dos
vários que o requisito permite, e ele nunca faz a pergunta para a qual esta técnica existe: o que
acontece quando alguém faz algo que o estado atual do pedido não permite?

## Estados, eventos, transições

O R6 descreve a vida do pedido em quatro frases, e um modelo dela tem quatro partes:

- um **estado** é uma condição em que o pedido fica até algo acontecer com ele: reservado, pago,
  usado, cancelado, reembolsado. Cinco estados;
- um **evento** é o que acontece: no boxoffice, os quatro botões da página de um pedido, Pay,
  Cancel, Use e Refund;
- uma **transição** é um evento que leva o pedido de um estado a outro. "Um pedido reservado pode
  ser pago" é a transição de reservado para pago, no evento pagar;
- uma **guarda** é uma condição de que a transição precisa além do evento. O reembolso do R6 tem
  uma: "antes de o espetáculo começar".

Um pedido novo começa em reservado, o **estado inicial**. Cancelado, reembolsado e usado não têm
transições de saída, então um pedido que chega a um deles fica ali; esses são **estados finais**. O
diagrama desenha o R6 inteiro numa página, e mais uma coisa: a ação que duas das transições
carregam, devolver os lugares.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l05-order-states\" aria-label=\"Um diagrama de estados de um pedido. Um pedido novo entra em reservado. De reservado, pagar leva a pago e cancelar leva a cancelado, devolvendo os lugares. De pago, usar leva a usado, e reembolsar, com a guarda antes de o espetáculo começar, leva a reembolsado, devolvendo os lugares. Usado, cancelado e reembolsado têm borda dupla: são estados finais, sem saída.\"><defs><marker id=\"mt-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"80.0\" y=\"120.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">reservado</text><rect x=\"320.0\" y=\"120.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">pago</text><rect x=\"566.0\" y=\"26.0\" width=\"138.0\" height=\"48.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"570.0\" y=\"30.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">usado</text><rect x=\"566.0\" y=\"206.0\" width=\"138.0\" height=\"48.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"570.0\" y=\"210.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">reembolsado</text><rect x=\"316.0\" y=\"241.0\" width=\"138.0\" height=\"48.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"320.0\" y=\"245.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"265.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">cancelado</text><circle cx=\"24.0\" cy=\"140.0\" r=\"6\" fill=\"var(--paper)\"></circle><path d=\"M30.0 140.0 L78.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"24.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">novo pedido</text><path d=\"M210.0 140.0 L318.0 140.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper)\"></path><text x=\"264.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pagar</text><path d=\"M145.0 160.0 L316.0 262.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper)\"></path><text x=\"222.0\" y=\"228.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cancelar</text><text x=\"222.0\" y=\"243.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">/ devolve lugares</text><path d=\"M450.0 128.0 L566.0 58.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper)\"></path><text x=\"498.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">usar</text><path d=\"M450.0 152.0 L566.0 222.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper)\"></path><text x=\"500.0\" y=\"196.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">reembolsar</text><text x=\"500.0\" y=\"211.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">/ devolve lugares</text><text x=\"500.0\" y=\"226.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">[antes de o espetáculo começar]</text><rect x=\"560.0\" y=\"281.0\" width=\"22.0\" height=\"14.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"563.0\" y=\"284.0\" width=\"16.0\" height=\"8.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"590.0\" y=\"288.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">borda dupla: estado final</text></svg>", "caption": "O R6 como máquina de estados: cinco estados, quatro transições, uma guarda e a ação que duas das transições carregam. O que o diagrama não desenha, um botão apertado num estado sem seta para ele, é a outra metade do teste."}
```

## A tabela por trás do diagrama

Um diagrama mostra as transições que existem. Ele não mostra as que não existem, e elas são metade
do teste. Uma **tabela de estados** mostra: uma linha por estado, uma coluna por evento, e em cada
célula o estado a que aquele evento leva, ou um traço onde o evento deve ser recusado. Para o R6:

| estado | pagar | cancelar | usar | reembolsar |
|---|---|---|---|---|
| reservado | pago | cancelado | – | – |
| pago | – | – | usado | reembolsado |
| usado | – | – | – | – |
| cancelado | – | – | – | – |
| reembolsado | – | – | – | – |

Cinco estados por quatro eventos dão 20 células. Quatro delas são transições; **dezesseis são
traços**, e cada traço é um caso de teste que o diagrama nunca desenhou: apertar aquele botão num
pedido naquele estado, e esperar uma recusa com uma frase (R7) e o pedido deixado como estava.

## Quantos casos

O mínimo de costume no teste de transição de estados é **fazer cada transição válida acontecer pelo
menos uma vez**. Transições se encadeiam, então isso raramente exige um caso por transição. Para o
R6, três caminhos a partir de um pedido novo cobrem as quatro:

1. reservado, pagar, pago, usar, usado;
2. reservado, cancelar, cancelado;
3. reservado, pagar, pago, reembolsar, reembolsado.

Cada caso confere o estado depois de cada passo, e a ação também, onde a transição tem uma. Cancelar
e reembolsar devolvem os lugares, então esses casos leem os lugares restantes antes e depois. Um
estado que muda certo enquanto os lugares continuam ocupados é um caso que falhou, e o contrário
também.

Os traços são onde entra o julgamento. Dezesseis casos inválidos não são muitos para o boxoffice, e
os dezesseis rodam em poucos minutos. Numa máquina maior pode haver centenas, e a ordem de rodá-los
vem do dano, do mesmo jeito que a aula 1 ordenou riscos: qual movimento proibido custaria mais se
funcionasse? Para um pedido, os movimentos que devolvem dinheiro ou põem lugares de volta à venda vêm
primeiro. Reembolsar um pedido usado é as duas coisas.

A guarda precisa de mais uma coisa. Testar "antes de o espetáculo começar" quer dizer fazer um
reembolso dos dois lados do horário do espetáculo, e isso exige mover o relógio da aplicação, o que
a aula 13 faz com um relógio falso. Esta aula testa as transições sem a guarda, e diz isso: um plano
que deixa uma condição sem teste deve dizer o nome dela, do jeito que o escopo da aula 1 diz o que
deixa de fora.
