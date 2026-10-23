---
title: Blocos de construção, o repositório e o continuum
version: 1
---

**O TOGAF descreve uma arquitetura como um conjunto de blocos de construção, guarda esses blocos num
repositório de arquitetura e classifica os reutilizáveis ao longo de um continuum corporativo.** São
três ideias, cada uma mais simples que o nome.

## Blocos de construção

Um **bloco de construção** é um pacote de funcionalidade que atende a uma necessidade do negócio, com
fronteiras e interfaces definidas. O TOGAF separa dois tipos:

- um **bloco de construção de arquitetura (ABB)** diz **qual** capacidade é necessária, sem depender
  de produto: *uma capacidade de validar passagens que funcione off-line*;
- um **bloco de construção de solução (SBB)** diz **como** ela é fornecida, com um produto ou um
  componente: *o app de embarque em celulares Android com um store local em SQLite, sincronizado a
  cada 15 minutos*.

A divisão é o mesmo movimento do *o quê, não como* da aula 6. Os ABBs são escritos nas fases B a D;
os SBBs aparecem na fase E, onde as soluções são escolhidas. Um ABB pode ser atendido por SBBs
diferentes em lugares diferentes, e é assim que uma empresa com dois tipos de celular mantém uma
arquitetura só.

## O repositório de arquitetura

O **repositório** é onde moram as saídas da arquitetura: princípios, modelos, padrões, registros de
decisão, os blocos de construção, o material de referência e o log de governança. O padrão descreve
as partes dele em detalhe. Na Carcará, o repositório de arquitetura é um repositório Git com uma
pasta para cada uma dessas coisas, o mesmo lugar onde a aula 5 pôs os registros de decisão, e a aula
11 trata de mantê-lo vivo.

## O continuum corporativo

O **continuum corporativo** é um jeito de classificar ativos de arquitetura pelo quanto são
genéricos, do universal ao específico de uma organização:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l08-continuum\" aria-label=\"O continuum corporativo como uma seta do genérico, à esquerda, ao específico, à direita, com quatro tipos de arquitetura ao longo dela: arquiteturas de fundação, arquiteturas de sistemas comuns, arquiteturas da indústria e arquiteturas específicas da organização. Reutilizar é olhar mais para a esquerda antes de desenhar.\"><defs><marker id=\"l08-continuum-am-fill-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30.0 110.0 L690.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l08-continuum-am-fill-paper-dim)\"></path><text x=\"30.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">genérico</text><text x=\"690.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">específico</text><rect x=\"35.0\" y=\"32.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Fundação</text><text x=\"110.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">vale para quase todos</text><circle cx=\"110.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><rect x=\"202.0\" y=\"32.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"277.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Sistemas comuns</text><text x=\"277.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">identidade, pagamentos</text><circle cx=\"277.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><rect x=\"369.0\" y=\"32.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"444.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Indústria</text><text x=\"444.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">bilhetagem de transporte</text><circle cx=\"444.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><rect x=\"536.0\" y=\"32.0\" width=\"150.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"611.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Organização</text><text x=\"611.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">a da Carcará</text><circle cx=\"611.0\" cy=\"110.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"360.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">antes de desenhar, olhe mais para a esquerda</text></svg>", "caption": "A Carcará não inventou a validação de passagem sem rede: havia um desenho de referência da indústria, e lê-lo poupou semanas."}
```

- **arquiteturas de fundação**: genéricas, valem para quase qualquer empresa, como um modelo de
  referência de serviços de tecnologia comuns;
- **arquiteturas de sistemas comuns**: padrões reutilizados em muitos domínios, como um jeito padrão
  de fazer identidade ou pagamentos;
- **arquiteturas da indústria**: compartilhadas dentro de um setor, como um modelo de referência para
  bilhetagem de transporte;
- **arquiteturas específicas da organização**: as da própria Carcará.

O sentido do continuum é o **reúso**: antes de desenhar alguma coisa, olhe mais para a esquerda para
ver se uma arquitetura mais genérica já resolve. A Carcará não inventou a validação off-line de
passagens; operadoras de transporte têm desenhos de referência para isso, e ler um deles poupou
semanas na fase C.

## Princípios de arquitetura

A fase Preliminar escreve **princípios**, regras curtas que orientam decisões. O TOGAF dá a eles uma
forma fixa: um **nome**, uma **declaração**, uma **justificativa** e as **implicações**. Dois dos oito
da Carcará:

> **O embarque funciona sem rede.** *Declaração:* nenhuma capacidade necessária para embarcar num
> ônibus pode depender de uma conexão ativa. *Justificativa:* 40% das partidas saem de pontos com
> sinal ruim. *Implicações:* toda funcionalidade de embarque precisa de um desenho off-line e de uma
> regra de sincronização.

> **Um registro só de cada passagem.** *Declaração:* o ticketing é o único sistema que cria ou altera
> uma passagem. *Justificativa:* dois registros da mesma passagem discordam. *Implicações:* as vendas
> de balcão passam pelo ticketing; a tabela de passagens própria do back office é aposentada.

Um princípio sem implicações é um slogan. São as implicações que deixam um revisor usá-lo.
