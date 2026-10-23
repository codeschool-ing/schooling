---
title: "Diagramas de componentes: o que cada parte oferece e de que precisa"
version: 1
---

**Um diagrama de componentes mostra as partes substituíveis de um sistema e as interfaces pelas
quais elas se ligam: o que cada parte oferece às outras, e o que exige delas.** É o diagrama para
perguntas sobre dependência e substituição: *o que quebra se Pricing mudar?*, *dá para trocar de
provedor de pagamento sem mexer na venda de passagens?*

## A notação

- Um **componente** é um retângulo com a palavra-chave `«component»` ou um pequeno ícone de
  componente no canto. É uma parte modular com uma interface bem definida: um serviço, uma
  biblioteca, um módulo de um programa maior.
- Uma **interface oferecida** é desenhada como um pequeno círculo numa haste, a **bola**, ou
  pirulito: *este componente oferece isto*.
- Uma **interface exigida** é um meio círculo numa haste, o **soquete**: *este componente precisa
  disto de alguém*.
- Um **conector de montagem** é uma bola encaixada num soquete: a necessidade de um componente é
  atendida pela oferta de outro.
- Uma **porta**, um quadradinho na borda do componente, agrupa interfaces num ponto de interação. É
  opcional e muitas vezes fica de fora.
- Uma **dependência**, a seta tracejada aberta do diagrama de classes, pode ligar componentes
  diretamente quando a interface não importa para a pergunta.

## Os componentes de vendas da Carcará

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-component\" aria-label=\"Um diagrama de componentes das vendas da Carcará. Quatro componentes: app do passageiro, ticketing, pricing e adaptador de pagamento, e o gateway de pagamento, de fora, tracejado. Ticketing oferece a interface Bookings, uma bola, que o app do passageiro exige, com um soquete encaixado em volta. Pricing oferece FareQuote, que ticketing exige. O adaptador de pagamento oferece PaymentPort, que ticketing exige. O gateway oferece a própria API, que o adaptador exige.\"><rect x=\"20.0\" y=\"120.0\" width=\"160.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"158.0\" y=\"128.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"154.0\" y=\"131.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"154.0\" y=\"137.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"30.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"94.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">App do passageiro</text><rect x=\"280.0\" y=\"120.0\" width=\"160.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"418.0\" y=\"128.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"414.0\" y=\"131.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"414.0\" y=\"137.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"290.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"354.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing</text><rect x=\"280.0\" y=\"18.0\" width=\"160.0\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"418.0\" y=\"26.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"414.0\" y=\"29.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"414.0\" y=\"35.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"290.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"354.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Pricing</text><rect x=\"540.0\" y=\"120.0\" width=\"160.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"678.0\" y=\"128.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"674.0\" y=\"131.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"674.0\" y=\"137.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"550.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"614.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Adaptador</text><rect x=\"540.0\" y=\"222.0\" width=\"160.0\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><rect x=\"678.0\" y=\"230.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"674.0\" y=\"233.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"674.0\" y=\"239.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"550.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"614.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Gateway</text><path d=\"M280.0 150.0 L243.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"236.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M180.0 150.0 L225.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M233.6 139.3 A11 11 0 0 1 233.6 160.7\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"236.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Bookings</text><path d=\"M360.0 74.0 L360.0 89.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"360.0\" cy=\"96.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M360.0 120.0 L360.0 107.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M349.3 98.4 A11 11 0 0 1 370.7 98.4\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"376.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">FareQuote</text><path d=\"M540.0 150.0 L499.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"492.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M440.0 150.0 L481.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M489.6 139.3 A11 11 0 0 1 489.6 160.7\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"492.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">PaymentPort</text><path d=\"M620.0 222.0 L620.0 209.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"620.0\" cy=\"202.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M620.0 180.0 L620.0 191.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M630.7 199.6 A11 11 0 0 1 609.3 199.6\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"636.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Gateway API</text><text x=\"20.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bola: oferecida</text><text x=\"20.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">soquete: exigida</text></svg>", "caption": "Ticketing encontra o resto só em três interfaces com nome. As tarifas de uma empresa parceira seriam um segundo fornecedor de FareQuote, e nada dentro de Ticketing mudaria.", "same": ["Pricing", "Ticketing"]}
```

A figura responde à pergunta que Otávio fez numa reunião de planejamento: *daria para vender
passagens de uma empresa de ônibus parceira pelo nosso site?* Ela mostra que **Ticketing** exige
duas interfaces, `FareQuote` e `PaymentPort`, e oferece uma, `Bookings`. Pricing oferece as
tarifas; o **adaptador de pagamento** oferece `PaymentPort` e, por sua vez, exige a API do gateway.

Então a resposta se lê nos soquetes: as viagens de um parceiro precisam de um segundo provedor de
`FareQuote`, e nada mais muda em Ticketing. Se Ticketing consultasse direto as tabelas de Pricing, o
diagrama mostraria uma seta de dependência entrando no banco de dados, e a resposta honesta seria
*teríamos que mudar Ticketing também*.

## Por que as interfaces são o essencial

**Um diagrama de componentes sem interfaces é um diagrama de caixas com uma palavra-chave em
cima.** As bolas e os soquetes são o que o fazem dizer algo que um diagrama de caixas não diz: que
duas partes só se encontram num contrato estreito e com nome, e que qualquer coisa que ofereça o
mesmo contrato poderia tomar o lugar de um dos lados. É o princípio da inversão de dependência da
aula 4 de `design-patterns`, desenhado.

Os erros mais comuns vêm de esquecer isso:

- **todo componente ligado a todos os outros**, com setas de dependência e nenhuma interface, o que
  mostra o acoplamento mas não onde ele poderia ser cortado;
- **soquetes sem bola**, uma exigência que ninguém atende, que é uma lacuna no diagrama ou uma
  lacuna no sistema, e vale descobrir qual das duas;
- **componentes que são classes**, o que transforma o diagrama num diagrama de classes com menos
  detalhes.

## Componentes, containers e implantação

Um componente é uma parte **lógica**. Ele não diz nada sobre onde roda: Ticketing e Pricing podem
ser dois serviços ou dois módulos de um mesmo programa. Onde eles rodam é a pergunta do diagrama de
implantação, na próxima seção. A aula 3 acrescenta a palavra do C4, **container**, para *uma coisa
que roda separada*, que fica entre as duas, e essa palavra causa mais confusão do que qualquer ponta
de seta.
