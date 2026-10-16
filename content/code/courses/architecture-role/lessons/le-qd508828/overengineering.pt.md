---
title: Overengineering, e o seu oposto
version: 1
---

**Overengineering é construir para um problema que você não tem.** Parece zelo: mais flexibilidade,
mais capacidade e mais generalidade do que o requisito pedia, tudo defensável peça por peça. A aula
12 contou o que cada peça custa (plantão, atualizações, documentação e o conhecimento das pessoas
que precisam entendê-la), e esse custo é pago todo mês, chegue ou não o futuro para o qual a peça
foi construída.

## Como se parece

Dois casos na Carreto, um de um time e um da arquiteta.

**A capacidade que ninguém mediu.** Um desenho do time de Shipper para um novo serviço de cotação
chega para revisão. Propõe um log de eventos particionado, três grupos de consumidores e autoscaling
em duas regiões, dimensionado para 2.000 pedidos de cotação por segundo. Renata pergunta qual foi o
pico do ano passado. Foi de 6 por segundo. Mesmo contando dez vezes de crescimento, mais do que
qualquer pessoa na Carreto planeja, o desenho está dimensionado para 2.000 diante de uma necessidade
de 60:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Três barras medindo pedidos de cotação por segundo. O pico do ano passado foi 6, uma lasca. Dez vezes isso é 60, uma barra curta. O desenho foi dimensionado para 2.000, uma barra mais de trinta vezes maior que a segunda.\"><text x=\"190\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pico do ano passado</text><rect x=\"200\" y=\"40\" width=\"2\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"212\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"190\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dez vezes isso</text><rect x=\"200\" y=\"90\" width=\"13.2\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"223.2\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">60</text><text x=\"190\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dimensionado para</text><rect x=\"200\" y=\"140\" width=\"440.0\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"650.0\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2.000</text><text x=\"700\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos de cotação por segundo</text></svg>", "caption": "Mesmo contando dez vezes de crescimento, o desenho carrega mais de trinta vezes a capacidade para a qual alguém conseguiria dar um motivo."}
```

**A generalidade que ninguém pediu.** O novo layout do CT-e (aula 13) obriga a Carreto a mudar a
forma como emite o conhecimento de transporte eletrônico. A Renata imaginada desta aula esboça um
*motor de documentos fiscais*: um motor de regras com um plugin por país e por tipo de documento,
para que "quando a Carreto se expandir para a Argentina e o Chile" o mesmo motor emita os documentos
de lá também. A Carreto opera só no Brasil, não tem expansão aprovada e emite um tipo de documento
fiscal de frete. A própria estimativa dela é de 16 a 22 semanas-engenheiro para o motor, contra 5 a 7
para mudar diretamente o módulo de CT-e que existe: **11 a 15 semanas-engenheiro gastas em países
onde a Carreto não opera.**

Os sintomas aparecem nos dois:

- **Requisitos que começam com "quando" ou "se".** *Quando nos expandirmos*, *se tivermos de trocar
  de provedor de nuvem*, *quando tivermos dez vezes mais motoristas*. Nenhum deles tem data, dono ou
  número.
- **Abstrações com uma implementação.** Uma interface com uma classe por trás, um sistema de plugins
  com um plugin, uma opção de configuração com o mesmo valor em todo lugar.
- **Capacidade desenhada sem medição.** O cenário de atributo de qualidade da aula 6 tem uma medida
  de resposta, e aqui ninguém a forneceu, então o desenho forneceu a sua.
- **Tecnologia nova escolhida para o problema que o arquiteto acha interessante.** As fichas de
  inovação da aula 12, gastas na parte do sistema que precisava da resposta mais sem graça.

## Por que acontece

**Flexibilidade parece segurança.** Um arquiteto inseguro sobre o futuro o cobre com opções, e cada
opção parece barata no dia em que é acrescentada.

**O problema geral é mais interessante que o específico.** Um motor de regras para três países é um
quebra-cabeça melhor do que acrescentar quatro campos a um módulo de CT-e, e a aula 2 já nomeou a
versão disso que é sobre currículo e não sobre quebra-cabeça.

**O horizonte do arquiteto é aplicado às decisões erradas.** A aula 16 pôs o arquiteto num horizonte
de anos. Isso é certo para quem é dono de quais dados, e errado para os internos de um módulo que
vai ser reescrito de qualquer jeito quando os requisitos dele mudarem. O overengineering é muitas
vezes um horizonte longo usado numa decisão de horizonte curto.

**Ninguém pôs "não fazer nada" ou "a coisa mais simples" na mesa.** A aula 14 pediu alternativas
incluindo a mais barata; um desenho comparado apenas com versões mais grandiosas de si mesmo sempre
vence.

## Quanto custa

| custo | o motor de documentos fiscais | o serviço de cotação |
|---|---|---|
| para construir | 11 a 15 semanas-engenheiro a mais | três componentes onde um serviço bastaria |
| para operar | mais um serviço no plantão, com as suas atualizações | duas regiões, um log e os seus consumidores para operar |
| para aprender | todo engenheiro novo encontra um sistema de plugins antes do CT-e | um pipeline para entender antes de mudar uma cotação |
| para mudar | a próxima mudança de layout passa por duas camadas em vez de uma | uma mudança no formato da cotação mexe em três consumidores |

E mais um, fácil de não ver: **o futuro para o qual se construiu, se chegar, raramente é o que se
adivinhou.** Uma abstração desenhada com um só caso real por trás tende a estar errada para o
segundo, então a expansão para a Argentina provavelmente teria exigido refazer o motor de qualquer
forma.

## A alternativa

- **Desenhe para o requisito que você tem, e deixe a mudança provável barata em vez de pronta.**
  Mantenha o módulo de CT-e atrás de uma fronteira clara, para que um segundo país, se um dia for
  aprovado, seja um novo módulo ao lado. Uma fronteira não custa quase nada hoje; a maquinaria para o
  segundo caso custa o preço inteiro agora.
- **Peça o número** (aula 7). Quantas cotações por segundo, em que pico, até quando? Desenhe para o
  pico medido com uma margem combinada, e prove com um teste de carga, como ensinou o curso `scale`.
- **Conte as peças** (aula 12). O que este desenho acrescenta à escala de plantão, ao calendário de
  atualizações e à integração do próximo engenheiro?
- **Registre o que você escolheu não construir, e o que faria você construir.** Um registro de
  decisão (aula 5) que diz "se uma expansão para um segundo país for aprovada, rever isto" mantém a
  opção aberta sem pagar por ela.

É o *bom o bastante para o propósito* da aula 13, visto do outro lado.

## O oposto: o arquiteto ausente

O overengineering tem uma imagem espelhada, e ela é igualmente comum: **ninguém desenha nada, e a
arquitetura acontece por acidente.** Cada time toma decisões locais sensatas, e a soma delas é uma
estrutura que ninguém escolheu. A aula 2 avisou que "nenhum desenho" não é a cura para o "grande
desenho antecipado"; o arquiteto ausente é como "nenhum desenho" fica depois de alguns anos.

Os sintomas são o que Brian Foote e Joseph Yoder chamaram de *big ball of mud*, a grande bola de
lama, em 1997: serviços que conversam pelas tabelas uns dos outros porque era o mais rápido naquela
semana, três formas diferentes de publicar um evento, e ninguém capaz de dizer quem é dono de uma
tabela. Parte dos 14 serviços que a aula 12 contou na Carreto veio exatamente disso: peças
acrescentadas uma semana sensata de cada vez, sem que ninguém as pesasse contra o todo.

O custo é que **cada decisão saiu barata e a soma sai cara**, e a soma nunca aparece no plano de
ninguém. A alternativa é o próprio curso: desenho antecipado na medida certa (aula 2), uma tabela de
direitos de decisão que dá um dono a cada decisão entre times (aula 16) e um registro das decisões
que atravessam as fronteiras entre times (aula 5).

## Os cinco, num mapa

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Um mapa com dois eixos. Na horizontal, a distância dos times e do código deles, de perto a longe. Na vertical, quanto o arquiteto decide, de nada a tudo. O porteiro fica perto e decide tudo. A torre de marfim fica longe e decide tudo. O arquiteto de PowerPoint fica longe e no meio. O arquiteto ausente fica longe e não decide nada. Uma caixa tracejada, perto dos times e no meio, guarda o papel que este curso descreve: decide o que atravessa times, após consulta, perto do código.\"><path d=\"M120 330 L700 330\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M120 330 L120 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"130\" y=\"346\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perto</text><text x=\"700\" y=\"346\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">longe</text><text x=\"410\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">distância dos times e do código deles</text><text x=\"112\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tudo</text><text x=\"112\" y=\"320\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada</text><text x=\"120\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">quanto o arquiteto decide</text><rect x=\"150\" y=\"56\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o porteiro</text><rect x=\"520\" y=\"56\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a torre de marfim</text><rect x=\"520\" y=\"156\" width=\"170\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o arquiteto de PowerPoint</text><rect x=\"520\" y=\"266\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o arquiteto ausente</text><rect x=\"170\" y=\"150\" width=\"210\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"275\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decide o que atravessa times,</text><text x=\"275\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">após consulta, perto do código</text></svg>", "caption": "Quatro dos cinco anti-padrões são lugares onde ficar. O papel que o curso descreve fica perto do código e decide só o que atravessa times."}
```

O overengineering não está no mapa, porque é uma propriedade de um desenho e não uma postura: um
porteiro e um arquiteto ausente podem produzir um. Os outros são quatro formas de ficar no lugar
errado. E cada um deles, olhado de perto, é uma das aulas deste curso pulada:

| anti-padrão | as aulas que o evitam |
|---|---|
| o arquiteto de PowerPoint | 2 (um diagrama é uma visão), 8 (documentação viva), 15 (continuar programando) |
| a torre de marfim | 3 (autoridade conquistada, o processo de aconselhamento), 7 (levantar requisitos), 10 (colaborar) |
| o porteiro | 9 (padrões conferidos por máquinas), 11 (aconselhar, não aprovar), 16 (direitos de decisão) |
| o overengineering | 6 (cenários com números), 12 (simplificar), 13 (bom o bastante), 14 (alternativas) |
| o arquiteto ausente | 2 (não é uma fase), 5 (registros de decisão), 16 (de quem é a decisão) |

O exercício que vem a seguir traz situações da Carreto. Para cada uma, a pergunta é a que um
arquiteto precisa fazer sobre a própria semana: qual destes é, e qual teria sido a alternativa?
