---
title: Trabalhando com os times: Conway, tipos de time e um fórum
version: 1
---

A imagem de um arquiteto que desenha e times que implementam é uma passagem de bastão, e ela falha por
um motivo que nada tem a ver com a competência de ninguém: **a estrutura dos times molda o sistema
pelo menos tanto quanto qualquer diagrama.** Um arquiteto que trabalha só no sistema, e nunca em como os
times em volta dele estão organizados e conversam, está desenhando a metade que perde quando as duas
discordam.

## A lei de Conway, usada em vez de citada

A aula 1 apresentou a lei de Conway. O artigo de Melvin Conway de 1968 dizia mais ou menos isto: uma
organização que desenha um sistema produz um desenho cuja estrutura copia a estrutura de comunicação da
organização. A leitura de costume é um aviso. A leitura útil é uma ferramenta.

A Carreto tinha o aviso no registro de incidentes. O módulo de faturamento do monólito era alterado por
dois times. Shipper mexia nele quando as telas do embarcador precisavam de algo novo; Payments mexia
quando os repasses precisavam de algo novo. Nenhum dos dois era dono, os dois faziam deploy dele, e
cada um fazia suposições sobre ele que o outro não conhecia. Dos nove incidentes no faturamento no ano
anterior, **seis começaram com a mudança de um time quebrando uma suposição sobre a qual o outro tinha
construído.** O código era compartilhado porque a responsabilidade era, e a responsabilidade era
compartilhada porque ninguém tinha decidido outra coisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Dois painéis. Antes: o time Shipper e o time Payments têm setas para um mesmo módulo de faturamento; os dois times o alteram, e seis de nove incidentes começaram entre os dois. Depois: Payments tem uma seta para o módulo de faturamento, e Shipper tem uma seta para uma pequena caixa api em cima dele; Payments é dono, Shipper pede pelo api, um time altera e um time fica de plantão.\"><defs><marker id=\"conway-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"conway-ok\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">antes</text><text x=\"540\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">depois</text><rect x=\"10\" y=\"30\" width=\"340\" height=\"280\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"370\" y=\"30\" width=\"340\" height=\"280\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"30\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Shipper</text><rect x=\"200\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Payments</text><rect x=\"95\" y=\"200\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">faturamento</text><path d=\"M95 102 L140 198\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#conway-ah)\"></path><path d=\"M265 102 L220 198\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#conway-ah)\"></path><text x=\"180\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os dois times o alteram</text><text x=\"180\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seis de nove incidentes começaram entre os dois</text><rect x=\"390\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Shipper</text><rect x=\"560\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Payments</text><rect x=\"545\" y=\"200\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">faturamento</text><rect x=\"550\" y=\"170\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">api</text><path d=\"M660 102 L660 198\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#conway-ok)\"></path><path d=\"M455 102 L578 168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#conway-ah)\"></path><text x=\"540\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Payments é dono; Shipper pede pelo api</text><text x=\"540\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um time altera, um time fica de plantão</text></svg>", "caption": "A manobra inversa de Conway na Carreto. Dono compartilhado produziu um módulo compartilhado e incidentes na emenda; dar o faturamento a um time pôs a emenda numa interface.", "same": ["Shipper", "Payments"]}
```

A **manobra inversa de Conway** vira a lei ao contrário: decida a estrutura que você quer, depois
organize os times de modo que a comunicação normal deles a produza. A proposta da Renata era que
Payments fosse dono do faturamento inteiro, atrás de uma interface, e que Shipper pedisse o que precisa
por essa interface como pediria a qualquer outro time. O código seguiria a propriedade: um time
mudando, um time de plantão, e um lugar onde uma mudança na interface é discutida.

Essa proposta não cabia à Renata executar. **Mudar trabalho de um time para outro é uma decisão sobre
pessoas, e pertence a quem as gerencia.** Ela levou a contagem de incidentes e a proposta ao Tomás e aos
dois gerentes de engenharia, que passaram o trabalho de faturamento de dois desenvolvedores de Shipper
para Payments e deram a Payments um trimestre para assumi-lo. A parte da arquiteta foi o argumento e a
interface; a parte dos gerentes foi a organização.

## Quatro tipos de time

Matthew Skelton e Manuel Pais deram vocabulário a esse arranjo em *Team Topologies* (2019). O livro
nomeia quatro tipos de time e três modos de os times trabalharem juntos, e os sete times da Carreto
cabem nele sem forçar:

| tipo | o que faz | na Carreto |
|---|---|---|
| **alinhado ao fluxo** (*stream-aligned*) | é dono de um fluxo de trabalho para um cliente ou usuário, de ponta a ponta | Shipper, Driver, Matching, Payments, Tracking |
| **plataforma** | oferece serviços internos que outros times usam sem precisar pedir | Platform |
| **subsistema complicado** | é dono de uma parte que exige conhecimento especializado que a maioria não tem | Pricing: preço de frete e o piso da ANTT |
| **habilitador** (*enabling*) | ajuda outro time a adquirir uma capacidade, e depois se afasta | ninguém, até a Renata |

Os três modos de interação são **colaboração** (dois times trabalhando juntos de perto por um tempo em
algo novo), **X como serviço** (um time consome o que outro oferece, por uma interface, com pouca
conversa) e **facilitação** (um time ajuda outro a aprender). A mudança do faturamento levou Shipper e
Payments de uma colaboração acidental e permanente para X como serviço, que é o modo barato quando a
interface está clara.

A outra ideia do livro é a **carga cognitiva**: um time só consegue guardar uma certa quantidade na
cabeça, e um time dono de coisa demais deixa de ser dono de qualquer uma direito. Shipper era dono das
suas telas, de metade do faturamento e da etapa do CT-e no fluxo do embarcador. Tirar o faturamento foi
também um jeito de devolver a Shipper a atenção que o próprio trabalho dele precisava.

## O arquiteto como time habilitador de uma pessoa

Uma arquiteta sem time próprio cabe no tipo habilitador melhor do que em qualquer outro: ela entra num
time por um tempo para ajudá-lo com algo que ele ainda não faz sozinho, e o trabalho termina quando eles
não precisam mais dela.

Na primavera o time Driver precisou fazer o app funcionar nas zonas sem sinal das estradas para o porto
de Paranaguá, onde um motorista fica quarenta minutos sem conexão. O time do Diego nunca tinha desenhado
sincronização offline. Renata passou três semanas trabalhando com eles: duas sessões de desenho, um
spike que ela fez em par com um dos desenvolvedores do Diego, e uma revisão do ADR que o time escreveu.
Ela não escreveu o desenho por eles. Na quarta semana o time já tomava as decisões sem ela.

**A medida do trabalho habilitador é ele deixar de ser necessário.** Uma arquiteta que fica num time, ou
cuja aprovação o time espera, transformou facilitação em dependência. A aula 11 trata do aconselhamento
em si, e a aula 17 do porteiro em que ele vira quando a dependência se instala.

## Um fórum, não um comitê

Sete times tomam toda semana decisões que cruzam suas fronteiras. Renata precisava de um lugar onde essas
decisões fossem vistas antes de serem tomadas, sem criar um comitê pelo qual todo mundo tivesse de
passar.

O **fórum de arquitetura** da Carreto se reúne às quintas por 45 minutos e é aberto a qualquer pessoa.
As regras cabem num cartão:

1. Uma proposta é um rascunho de ADR, publicado até terça. Uma proposta que chega depois espera uma
   semana.
2. Nada de slides. As pessoas leem o rascunho antes da reunião e o tempo é para perguntas.
3. O fórum dá conselho. Não aprova. Quem propõe decide, depois de ouvir, como no processo de
   aconselhamento da aula 3.
4. O conselho recebido, e o que quem propôs fez com ele, vai para o ADR.

A terceira regra é a que mantém o fórum um fórum, e não um comitê de revisão. Um comitê que aprova vira
fila, e os times aprendem a trazer decisões já tomadas. Um fórum que aconselha recebe propostas cedo,
porque cedo é quando o conselho é mais útil. Nos primeiros seis meses o fórum ouviu **23 propostas**, e 4
delas mudaram bastante por causa do que foi dito na sala; o desenho da sincronização offline foi uma.

Presença não é a medida. Umas doze pessoas aparecem numa quinta comum. O que Renata acompanha é quais
times trazem propostas. No terceiro mês todos os times já tinham trazido pelo menos uma. O time de
Pricing, que não tinha trazido nenhuma nos dois primeiros, trouxe duas seguidas quando o tech lead viu
que o fórum mudava propostas sem bloqueá-las.

As habilidades de que um fórum assim vive, escutar a objeção real debaixo da declarada e mediar quando
dois times discordam, são as aulas 6 e 9 de `architect-communication`. O que esta aula precisa delas é a
estrutura dentro da qual elas trabalham: times organizados para que o sistema que produzem seja o
pretendido, uma arquiteta que habilita em vez de aprovar, e um lugar onde as decisões que cruzam
fronteiras são ouvidas antes de serem tomadas.
