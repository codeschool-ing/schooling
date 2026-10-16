---
title: Limites de trabalho em andamento, e por que menos faz sair mais
version: 1
---

**Um limite de trabalho em andamento (WIP, do inglês *work in progress*) é o máximo de cartões que uma coluna
pode ter de uma vez.** Quando a coluna está cheia, ninguém pode puxar outro cartão para ela. Parece uma regra
para ir mais devagar, e é o contrário: é a regra que faz o trabalho terminado sair mais rápido.

## A lei de Little

A aritmética por trás disso foi provada por John Little em 1961 para qualquer fila estável ao longo do tempo:

> **tempo médio no sistema = trabalho médio em andamento ÷ vazão média**

No Cine Aurora em março, o quadro tinha em média 9 cartões entre "a fazer" e "pronto", e 3 cartões por semana
chegavam a "pronto". Então um cartão passava, em média, 9 ÷ 3 = **3 semanas** no quadro. A Célia pediu a meia
infantil na placa e a viu três semanas depois, por uma mudança que tomou uma tarde do Rafael.

A lei não diz para que lado andar. Terminar mais por semana é difícil: quer dizer trabalhar mais rápido ou com
mais gente. Ter menos cartões é uma decisão que o time pode tomar amanhã. Com a mesma vazão e 6 cartões em vez de
9, a média cai para 6 ÷ 3 = 2 semanas. Ninguém trabalhou mais rápido; os cartões pararam de esperar.

## Onde o limite aperta

O Rafael constrói mais rápido do que a Lia testa, então no quadro antigo os cartões se empilhavam em "esperando
teste". O time pôs limites no quadro:

| coluna | limite |
|---|---|
| a fazer | 4 |
| construindo | 2 |
| esperando teste | 2 |
| testando | 1 |

Na primeira semana, "esperando teste" encheu até dois e o Rafael terminou um cartão que não podia mover. A regra
diz que ele não pode começar outro. O que ele pode é **ajudar o cartão à frente dele a andar**: fazer par com a
Lia no teste, ou escrever a verificação automatizada do cartão que ela está explorando. O lema da comunidade
Kanban para isso é **pare de começar, comece a terminar**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 180\" role=\"img\" data-fig=\"l13-limits\" aria-label=\"A lei de Little desenhada duas vezes. Em cima, nove cartões no quadro e três por semana chegando ao pronto: cada cartão passa três semanas no quadro. Embaixo, seis cartões e as mesmas três por semana: duas semanas. Ninguém trabalha mais rápido; há menos cartões esperando.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"340.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">tempo no quadro = cartões ÷ vazão</text><rect x=\"10.0\" y=\"44.0\" width=\"400.0\" height=\"50.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"62.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"104.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"146.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"188.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"230.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"272.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"314.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"356.0\" y=\"52.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">9 cartões no quadro</text><path d=\"M412.0 69.0 L470.0 69.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"476.0\" y=\"50.0\" width=\"90.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"521.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3 semanas</text><rect x=\"10.0\" y=\"114.0\" width=\"400.0\" height=\"50.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"62.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"104.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"146.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"188.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"230.0\" y=\"122.0\" width=\"32.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6 cartões no quadro</text><path d=\"M412.0 139.0 L470.0 139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"476.0\" y=\"120.0\" width=\"90.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"521.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2 semanas</text><text x=\"441.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 por semana chegam ao pronto</text></svg>", "caption": "Mesmas pessoas, mesma velocidade, menos cartões em andamento: todo cartão sai mais cedo."}
```

## O que o limite faz com o teste

Três coisas mudaram para a Lia, e nenhuma foi ela trabalhar mais.

- **Os cartões chegavam um ou dois de cada vez**, enquanto o Rafael ainda lembrava deles. Um defeito que ela
  achava era corrigido no mesmo dia, a ponta barata da curva da aula 3.
- **O teste deixou de ser a fila de outra pessoa.** Quando a coluna enchia, o teste virava problema do time
  todo, que é a abordagem do time todo da aula 5 imposta por um número no quadro.
- **O gargalo ficou visível.** Se a coluna está sempre cheia, o teste é onde o sistema é mais lento, e esse é um
  fato sobre o qual o time pode agir: automatizar mais verificações, fazer cartões menores ou dividir o teste.

Um limite é uma política, não uma lei da natureza. Um time escolhe um número, observa o que acontece e o muda.
Um limite tão alto que nunca aperta é enfeite. Um tão baixo que deixa gente parada todo dia é baixo demais, e o
quadro vai mostrar isso também.
