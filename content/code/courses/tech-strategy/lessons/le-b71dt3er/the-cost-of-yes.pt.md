---
title: Quanto custa um sim
version: 1
---

Um sim a um pedido custa mais do que as horas da estimativa. Custa também as horas que a estratégia
já tinha dado para outra coisa, e **uma estratégia que não sabe dizer quais eram essas horas vai
perdê-las, um pedido razoável de cada vez.** Esta seção põe um número nisso, usando a sprint de um
time da Coreto.

Numa quinta-feira de maio, Júlia Sato, a head de produto, passa pelo time de Checkout. O maior
cliente de festivais da Coreto quer reservas de grupo para a próxima temporada: um comprador
escolhe um bloco de assentos para um grupo de amigos, os assentos ficam reservados juntos, e cada
amigo paga separado. Mateus Araújo, o tech lead do Checkout, olha o pedido com dois dos seus
engenheiros e estima umas 90 horas. "Isso é um cantinho de uma sprint", diz Júlia. "Dá para
encaixar?"

## A conta que todo mundo faz

A conta na sala é a estimativa. Noventa horas aos R$ 150 da hora de engenharia da Coreto dão
R$ 13.500, e, comparado com o que o festival paga à Coreto em taxas de ingresso, parece barato.
**É a conta certa para a pergunta errada.** Ela precifica a funcionalidade como se o time tivesse
90 horas que ninguém estava usando, e um time no meio de uma estratégia não tem essas horas.

Comece pelo que o time tem de fato. O Checkout tem seis engenheiros, uma sprint tem dez dias úteis,
e a Coreto planeja com seis horas de foco por dia por engenheiro — o resto do dia vai para
revisões, reuniões, perguntas de suporte e as interrupções que todo time tem.

| | Checkout |
|---|---|
| engenheiros | 6 |
| dias úteis numa sprint | 10 |
| horas de foco por dia | 6 |
| **capacidade numa sprint** | **360 h** |

Seis vezes dez vezes seis dá 360 horas. Um pedido de 90 horas é 90 de 360: **um quarto de uma
sprint, 25%.** Visto assim, o pedido deixa de ser um cantinho. Cada engenheiro tem 60 horas numa
sprint, então 90 horas são um engenheiro e meio durante a sprint inteira. A aula 12 de
`delivery-metrics` mostra como medir a capacidade de um time e por que um plano deve deixar folga
nela; esta aula toma as 360 horas como dadas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas barras, cada uma uma sprint de 360 horas do Checkout. Antes: uma barra cheia, as 360 horas planejadas para a mudança do Checkout para a nova interface de reservas. Depois de um sim às reservas de grupo: 270 horas sobrando para o trabalho da estratégia e um bloco tracejado de 90 horas para as reservas de grupo, um quarto da sprint, R$ 13.500.\"><rect x=\"30\" y=\"42\" width=\"660\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"28\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">antes: uma sprint do Checkout, 6 engenheiros × 10 dias × 6 horas de foco</text><text x=\"360\" y=\"69\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">360 h, todas planejadas: a mudança do Checkout para a nova interface de reservas</text><text x=\"30\" y=\"120\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">depois de um sim às reservas de grupo</text><rect x=\"30\" y=\"134\" width=\"495\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"277\" y=\"161\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">270 h sobrando para o trabalho da estratégia</text><rect x=\"528\" y=\"134\" width=\"162\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"609\" y=\"161\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">90 h: reservas de grupo</text><text x=\"690\" y=\"200\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">um quarto da sprint · R$ 13.500</text><text x=\"30\" y=\"232\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o pedido é o bloco tracejado; a estratégia perde as mesmas 90 h do bloco cheio</text></svg>", "caption": "A mesma sprint antes e depois de um sim. Quem pede vê o bloco tracejado; o que encolhe é o trabalho que a estratégia tinha posto em primeiro lugar."}
```

## Toda hora já estava prometida

As 360 horas não estão paradas. A estratégia da Coreto, da aula 1, deu um dono ao módulo de
reservas e pediu ao novo time de Reservas dois trimestres tirando as travas de linha do caminho da
reserva. Esse trabalho precisa que o Checkout mude as próprias funcionalidades para a interface de
reservas que o time de Reservas está construindo, e **é para essa mudança que as sprints do
Checkout neste trimestre foram planejadas.**

Então as 90 horas não saem do nada. Elas saem da mudança, a mudança atrasa a remoção das travas, e
a remoção das travas é a primeira ação de uma estratégia cuja política orientadora é "proteger a
abertura de vendas primeiro". O custo do sim, dito nos termos da própria estratégia, é que aquilo
que a empresa decidiu ser o mais importante chega mais tarde.

Esse atraso tem um preço próprio. A aula 5 precificou a dívida da reserva de assentos em 31 horas
de juros por sprint — R$ 4.650 —, pagas por todo time que mexe no módulo enquanto a dívida existir.
**Se o sim empurrar a remoção das travas em uma sprint, os juros dessa sprint fazem parte do custo
do sim**, além dos R$ 13.500 que todo mundo viu.

## O pedido bate duas vezes

As reservas de grupo têm um segundo problema, e ele não é de horas. Segurar um bloco de assentos
para um grupo significa reservas novas no caminho da reserva, que é exatamente o caminho que a
política orientadora protege: nada entra nele sem evidência de um teste de carga. **O pedido disputa
com a estratégia as mesmas pessoas, e ainda pede para mudar o código que a estratégia cercou.**

Um pedido pode bater de um jeito só. Uma funcionalidade longe do caminho da reserva ainda tira horas
do trabalho da estratégia; uma mudança de duas horas na lógica da reserva quase não ocupa capacidade
e mesmo assim atravessa a política. Confira as duas coisas antes de responder.

## Sins pequenos se somam

Noventa horas parecem um cantinho porque não são comparadas com nada. Compare com a sprint e
quatro pedidos assim são a sprint inteira: 4 × 90 dá 360. Ninguém concorda em perder uma sprint do
trabalho da estratégia. **As pessoas concordam quatro vezes, em quatro conversas, com algo que
parecia pequeno a cada vez**, e no fim do trimestre as datas da estratégia andaram sem que nenhuma
decisão isolada as tenha movido.

A aula 8 de `architect-communication` tratou o custo do sim como um problema de capacidade dentro
de uma conversa, e mostrou como tornar a troca visível para quem pede. Uma estratégia acrescenta a
visão entre conversas. Ela é o único documento que diz para que serviam todas as horas, então é o
único lugar onde o quarto sim pequeno aparece como aquele que custou uma sprint.

## O sim que está certo

Nada disso faz do não a resposta padrão. A estratégia é um teste, e alguns pedidos passam nele. Se
Júlia tivesse pedido uma sala de espera na frente do checkout para as manhãs de abertura, a resposta
certa seria sim, tirando de outro trabalho se preciso, porque isso protege a abertura. **Um pedido
que serve à política orientadora recebe um sim mesmo quando é inconveniente**; um pedido que
compete com ela recebe a resposta que a próxima seção descreve.
