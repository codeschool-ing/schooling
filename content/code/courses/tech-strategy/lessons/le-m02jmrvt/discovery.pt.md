---
title: Descoberta com engenheiros dentro
version: 1
---

Na maioria das empresas, a engenharia encontra uma ideia de produto pela primeira vez como uma
especificação. O produto já conversou com clientes, um designer já desenhou as telas, e o time é
perguntado quanto tempo vai levar. **A essa altura as perguntas mais caras já foram respondidas sem a
engenharia**, e algumas foram respondidas errado. Esta seção trata de levar os engenheiros para o
começo desse trabalho, e do que eles estão lá para encontrar.

## O revezamento que falha

A ideia errada é uma corrida de revezamento. O produto descobre o que construir, passa o bastão para
a engenharia, e ela constrói. Cada lado faz o seu trabalho, e a passagem é um documento.

**O revezamento falha num lugar previsível.** A especificação descreve uma solução, e as pessoas que
sabem o que o sistema consegue ou não fazer só a veem depois que a solução foi escolhida. Quando ela
bate no sistema, a batida é descoberta durante a construção, com uma data já prometida. Nesse ponto
as escolhas são ruins: cortar escopo às pressas, assumir uma dívida que ninguém planejou ou perder a
data. A engenharia leva a culpa pela estimativa. A falha de verdade é que ninguém perguntou a ela
enquanto a ideia ainda era barata de mudar.

## Os quatro riscos de Cagan

Marty Cagan, que escreve sobre times de produto há muitos anos, descreve a descoberta como o trabalho
de testar uma ideia contra quatro riscos antes que alguém se comprometa a construí-la.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 322\" role=\"img\" aria-label=\"Quatro caixas numa grade dois por dois, uma por risco. Valor: os clientes vão escolher isto, ou pagar por isto? Liderado pelo produto. Usabilidade: eles conseguem entender como usar? Liderado pelo design. Viabilidade técnica, em destaque: conseguimos construir, com estas pessoas, este sistema e este prazo? Liderado pela engenharia. Viabilidade de negócio: funciona para finanças, jurídico, vendas e suporte? Liderado pelo produto, com a empresa. Embaixo: a descoberta testa os quatro antes de alguém se comprometer a construir.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Valor</text><text x=\"185\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Os clientes vão escolher isto,</text><text x=\"185\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">ou pagar por isto?</text><text x=\"185\" y=\"120\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">liderado pelo produto</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Usabilidade</text><text x=\"535\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Eles conseguem entender</text><text x=\"535\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">como usar?</text><text x=\"535\" y=\"120\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">liderado pelo design</text><rect x=\"20\" y=\"148\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--amber)\">Viabilidade técnica</text><text x=\"185\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Conseguimos construir, com estas pessoas,</text><text x=\"185\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">este sistema e este prazo?</text><text x=\"185\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">liderado pela engenharia</text><rect x=\"370\" y=\"148\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Viabilidade de negócio</text><text x=\"535\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Funciona para finanças, jurídico,</text><text x=\"535\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vendas e suporte?</text><text x=\"535\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">liderado pelo produto, com a empresa</text><rect x=\"20\" y=\"278\" width=\"680\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"298\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a descoberta testa os quatro antes de alguém se comprometer a construir</text></svg>", "caption": "Os quatro riscos de Cagan. A viabilidade técnica é a única que só a engenharia responde, e é por isso que um engenheiro pertence à descoberta desde o começo, e não à passagem de bastão."}
```

| risco | a pergunta | quem lidera |
|---|---|---|
| valor | Os clientes vão escolher isto, ou pagar por isto? | produto |
| usabilidade | Eles conseguem entender como usar? | design |
| viabilidade técnica | Conseguimos construir, com estas pessoas, este sistema e este prazo? | engenharia |
| viabilidade de negócio | Funciona para o resto da empresa: finanças, jurídico, vendas, suporte? | produto, com a empresa |

**A viabilidade técnica é a única que só a engenharia responde**, e só isso já é motivo para ter um
engenheiro na descoberta. Não é o único motivo. Engenheiros também sabem o que passou a ser possível
há pouco tempo, e uma ideia que ninguém no produto proporia, por não saber que agora ficou barata, é
uma que um engenheiro na sala pode oferecer. O argumento do próprio Cagan é que os engenheiros são,
com frequência, a melhor fonte de ideias novas, se os deixam chegar perto do problema.

A viabilidade técnica também cobre mais que "dá para fazer". Ela pergunta quanto fazer custaria ao
sistema, e é aí que uma estratégia técnica e uma ideia de produto se encontram.

## Mapas de assentos para festivais, com o Mateus na sala

A Coreto vende pista para festivais: o ingresso dá direito a passar pelo portão. Organizadores de
festival disseram ao time de Júlia Sato que queriam vender também áreas reservadas, com um mapa em
que o comprador escolhe um lugar numa arquibancada ou num camarote. O time da Júlia tinha ouvido isso
de vários organizadores, então o risco de valor parecia baixo. Em anos anteriores, isso teria virado
uma especificação e chegado ao Checkout como um projeto com um trimestre reservado.

Desta vez, Mateus Araújo, o tech lead do Checkout, entrou na descoberta na segunda semana. Ele
participou de duas das chamadas com organizadores e leu as notas das outras. Em poucos dias, tinha
achado o risco que importava.

Uma área reservada de festival é um mapa de assentos, e todo assento de um mapa passa pelo caminho
de reserva de assento. A abertura de vendas de um festival grande é exatamente o tipo de grande
abertura em que esse caminho falha hoje. Construir mapas de festival em cima do código atual de
reserva acrescentaria uma abertura nova, e maior, ao único módulo que a estratégia manda proteger
primeiro. **A funcionalidade só era viável depois do ADR-0006**, a decisão da aula 17 de reservar
assentos sem travas de linha, estar em produção.

Isso mudou o plano sem matar a ideia. O time testou os outros três riscos enquanto o time de Reservas
trabalhava:

- Valor: o time da Júlia mostrou aos organizadores um protótipo clicável e perguntou em que eventos
  eles o usariam.
- Usabilidade: o designer pôs o mesmo protótipo diante de compradores no celular, porque um mapa de
  festival é lido numa tela pequena, numa fila.
- Viabilidade de negócio: o time de Otávio Lins conferiu como a taxa por ingresso da Coreto se
  aplicaria a uma área reservada com preço diferente do resto do festival.
- Viabilidade técnica: Mateus fez um spike curto contra o teste de carga da abertura, usando o
  caminho novo de reserva atrás da flag.

A construção começou quando os quatro voltaram limpos. Começou mais tarde do que a Júlia esperava no
início, e o motivo estava por escrito, no roadmap, meses antes de alguém poder perder uma data por
causa dele.

## Quanto custa incluir engenheiros

Descoberta com um engenheiro dentro custa tempo de engenharia, e fingir que não prepara a próxima
discussão. Três escolhas tornam isso viável na Coreto.

**Um engenheiro, não o time.** Um tech lead, ou um engenheiro sênior indicado pelo time, participa
das chamadas e das sessões de protótipo. O resto do time continua construindo, e ouve o que se
aprendeu na reunião de planejamento seguinte.

**O trabalho do engenheiro são os riscos, não a estimativa.** Uma estimativa dada cedo numa reunião
de descoberta vira promessa até o fim da semana. Mateus disse de que os mapas de festival dependiam
e o que precisaria ser verdade antes de a construção começar; não deu data, e ninguém pediu uma.

O tempo conta como trabalho de produto. A Coreto lança a descoberta no lado de produto da capacidade
de cada time, o assunto da próxima seção. Investimento de engenharia é outra coisa, e pôr a
descoberta nele faria a fatia da dívida encolher toda vez que o produto tivesse uma ideia nova.

Discordâncias vão continuar acontecendo. Quando produto e engenharia discordam sobre um risco, a
pergunta útil é que evidência resolveria a questão, e quem vai colhê-la até quando. A aula 22 de
`people-leadership` trata do conflito em si quando a evidência não resolve.
