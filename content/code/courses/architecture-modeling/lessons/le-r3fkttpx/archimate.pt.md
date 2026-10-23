---
title: "ArchiMate: uma notação para todas as camadas"
version: 1
---

**O ArchiMate é a linguagem de modelagem do The Open Group para arquitetura corporativa: uma notação
em que elementos de negócio, de aplicação e de tecnologia, e as relações entre eles, podem ser
desenhados num só diagrama com um sentido preciso.** Ele é para a arquitetura corporativa o que a UML
é para o desenho de software, e é o parceiro natural do TOGAF. A versão atual é a 3.2, de 2023.

## Camadas e aspectos

O núcleo do ArchiMate arruma seus elementos em dois eixos:

- **camadas**: a **camada de negócio**, a **camada de aplicação** e a **camada de tecnologia**, que
  correspondem aos domínios da aula 8;
- **aspectos**: **estrutura ativa** (quem ou o que faz alguma coisa: um ator, um componente, um nó),
  **comportamento** (o que é feito: um processo, uma função, um serviço) e **estrutura passiva**
  (sobre o que é feito: um objeto de negócio, um objeto de dados, um artefato).

Outros elementos cobrem a motivação (objetivos, princípios, requisitos), a estratégia (capacidades) e
a implementação e migração (pacotes de trabalho, platôs), que se alinham às fases A, E e F do TOGAF.

## Uma pequena visão da Carcará

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" data-fig=\"l09-archimate\" aria-label=\"Uma pequena visão ArchiMate da Carcará em três camadas. Camada de negócio: o passageiro, um ator de negócio, atribuído ao processo de negócio comprar passagem. Camada de aplicação: o serviço de aplicação venda de passagens serve o processo; o componente de aplicação sistema de vendas o realiza e acessa o objeto de dados reserva. Camada de tecnologia: o serviço de tecnologia runtime de containers serve o sistema de vendas, e é realizado pelo nó cluster de containers.\"><defs><marker id=\"l09-archimate-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l09-archimate-am-hollow-paper\" viewBox=\"0 0 12 10\" refX=\"11\" refY=\"5\" markerWidth=\"11\" markerHeight=\"10\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M1 1 L11 5 L1 9 z\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.1\"></path></marker><marker id=\"l09-archimate-am-open-paper\" viewBox=\"0 0 10 8\" refX=\"9.5\" refY=\"4\" markerWidth=\"9\" markerHeight=\"8\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0.5 L9.5 4 L0 7.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></path></marker></defs><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"112.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"22.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">Negócio</text><rect x=\"10.0\" y=\"130.0\" width=\"700.0\" height=\"112.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"22.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Aplicação</text><rect x=\"10.0\" y=\"250.0\" width=\"700.0\" height=\"112.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"22.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Tecnologia</text><rect x=\"120.0\" y=\"40.0\" width=\"140.0\" height=\"50.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><circle cx=\"244.0\" cy=\"52.0\" r=\"4\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><path d=\"M244.0 56.0 L244.0 63.0\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M239.0 59.0 L249.0 59.0\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"182.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Passageiro</text><rect x=\"400.0\" y=\"40.0\" width=\"170.0\" height=\"50.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M542 50 L556 50 L562 56 L556 62 L542 62 L548 56 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"470.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Comprar passagem</text><circle cx=\"262.0\" cy=\"65.0\" r=\"3\" fill=\"var(--paper)\"></circle><path d=\"M265.0 65.0 L398.0 65.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-archimate-am-fill-paper)\"></path><text x=\"330.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">atribuição</text><rect x=\"400.0\" y=\"140.0\" width=\"170.0\" height=\"36.0\" rx=\"18\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"485.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Venda de passagens</text><path d=\"M485.0 140.0 L485.0 92.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-archimate-am-open-paper)\"></path><text x=\"478.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">serve</text><rect x=\"400.0\" y=\"206.0\" width=\"170.0\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"552.0\" y=\"210.0\" width=\"12.0\" height=\"9.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></rect><text x=\"476.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Sistema de vendas</text><path d=\"M470.0 206.0 L470.0 178.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-archimate-am-hollow-paper)\"></path><text x=\"462.0\" y=\"192.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">realiza</text><rect x=\"150.0\" y=\"196.0\" width=\"130.0\" height=\"40.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M150.0 208.0 L280.0 208.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"215.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Reserva</text><path d=\"M400.0 221.0 L282.0 221.0\" stroke=\"var(--paper)\" stroke-width=\"1.1\" fill=\"none\" stroke-dasharray=\"2 3\" marker-end=\"url(#l09-archimate-am-open-paper)\"></path><text x=\"340.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">acessa</text><rect x=\"400.0\" y=\"268.0\" width=\"170.0\" height=\"34.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"485.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Runtime de containers</text><path d=\"M485.0 268.0 L485.0 236.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-archimate-am-open-paper)\"></path><text x=\"478.0\" y=\"254.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">serve</text><path d=\"M410.0 322.0 L420.0 312.0 L570.0 312.0 L570.0 338.0 L560.0 348.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--ink)\"></path><path d=\"M560.0 322.0 L570.0 312.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"410.0\" y=\"322.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"485.0\" y=\"335.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Cluster de containers</text><path d=\"M485.0 322.0 L485.0 304.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-archimate-am-hollow-paper)\"></path><text x=\"392.0\" y=\"315.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">realiza</text></svg>", "caption": "Cada forma é um tipo de elemento e cada linha um tipo de relação, ambos definidos pela especificação. Servir e realizar são tão diferentes aqui quanto composição e agregação eram na UML."}
```

Leia de cima para baixo:

- o **passageiro**, um ator de negócio, é atribuído ao processo de negócio **comprar passagem**;
- esse processo é **servido pelo** serviço de aplicação **venda de passagens**;
- o serviço é **realizado pelo** componente de aplicação **sistema de vendas**, o ticketing;
- o sistema de vendas **acessa** o objeto de dados **reserva**;
- o sistema de vendas roda no **cluster de containers**, um nó de tecnologia, cujo serviço de
  tecnologia o serve.

A figura mostra o que faz o ArchiMate diferente de um diagrama de caixas: **cada elemento tem um tipo,
mostrado pela forma, e cada relação tem um tipo, mostrado pela linha**, e os tipos estão definidos na
especificação. *Serve* e *realiza* não são intercambiáveis, assim como não eram a composição e a
agregação da aula 2.

## Algumas relações

| relação | desenhada como | quer dizer |
| --- | --- | --- |
| **serve (serving)** | linha cheia, ponta de seta aberta | um elemento fornece sua funcionalidade a outro |
| **realização** | linha tracejada, triângulo vazado | um elemento faz existir outro, mais abstrato |
| **atribuição** | linha cheia, um ponto na origem e uma ponta de seta | quem ou o que executa um comportamento |
| **acesso** | linha pontilhada, ponta de seta pequena | um comportamento lê ou escreve um elemento passivo |
| **composição** | linha cheia, losango cheio | a parte pertence ao todo |
| **disparo (triggering)** | linha cheia, ponta de seta cheia | um comportamento provoca o seguinte |

## Onde ele se encaixa

Vale aprender ArchiMate quando você trabalha no nível corporativo, principalmente onde o TOGAF está em
uso e os modelos ficam numa ferramenta como o Archi, uma ferramenta de modelagem gratuita, ou num dos
repositórios comerciais. Para um sistema só, **o C4 e a UML dizem o que um time de engenharia precisa
com menos vocabulário**. Os dois convivem: a visão corporativa da Carcará está em ArchiMate, e cada
aplicação nela tem um link para os seus diagramas C4.
