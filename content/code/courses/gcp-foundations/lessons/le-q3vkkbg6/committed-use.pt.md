---
title: Compromisso de uso: pagar menos por prometer mais
version: 1
---

**Um desconto por compromisso de uso é um contrato: o cliente promete pagar por um nível de uso por um ou
três anos, e o Google cobra menos por isso.** A promessa é paga com o uso acontecendo ou não, e essa é toda a
diferença em relação ao uso contínuo. Nada nesta seção rodou; as porcentagens são as da página de preços,
lida em 30 de outubro de 2026.

## Dois tipos de compromisso

| tipo | o que se promete | o desconto, no máximo |
|---|---|---|
| **baseado em recursos** | um número de vCPUs e de gigabytes de memória, de uma série de máquina, numa região | 37% por um ano; 55% por três, 70% para máquinas otimizadas para memória |
| **flexível**, baseado em gasto | um número de dólares por hora de Compute Engine, qualquer série, qualquer região | menos que o baseado em recursos, em troca da liberdade |

Um compromisso **baseado em recursos** serve a uma carga estável que não vai se mover: os servidores de banco
de dados de produção do planner em São Paulo, que rodam toda hora de todo dia e vão rodar por anos. Um
compromisso **flexível** serve a uma empresa cujo uso total é estável mas cuja forma muda: tipos de máquina
trocados, cargas movidas entre regiões. Os dois são comprados por conta de faturamento e projeto, os dois
aparecem na fatura como uma taxa pelo compromisso e um crédito contra o uso que ele cobre, e **nenhum dos
dois pode ser cancelado**.

## Que desconto se aplica

A página de preços é explícita: **os descontos são mutuamente exclusivos**, e ela dá a ordem em que o Google
os aplica, hora a hora:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l13-discounts\" aria-label=\"Uma hora do uso elegível do Compute Engine do planner em São Paulo, desenhada como uma barra de 48 vCPUs, consumida da esquerda para a direita na ordem em que o Google aplica os descontos. As primeiras 32 vCPUs são cobertas por um compromisso baseado em recursos. A parte seguinte é coberta por um compromisso flexível, até onde os dólares por hora dele alcançam. O que sobra é cobrado pelo preço sob demanda, e só essa parte pode depois ganhar o desconto por uso contínuo. Nenhuma vCPU recebe dois descontos.\"><defs><marker id=\"l13-discounts-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma hora, 48 vCPUs de uso elegível</text><rect x=\"40.0\" y=\"50.0\" width=\"426.7\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"253.3\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">1. baseado em recursos</text><text x=\"253.3\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">32 vCPUs comprometidas</text><rect x=\"466.7\" y=\"50.0\" width=\"106.7\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"520.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2. flexível</text><text x=\"520.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">seus dólares por hora</text><rect x=\"573.3\" y=\"50.0\" width=\"106.7\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><text x=\"626.7\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. sob demanda</text><text x=\"626.7\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pode ganhar uso contínuo</text><text x=\"40.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"466.7\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">32</text><text x=\"573.3\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"680.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">48</text><path d=\"M40.0 190.0 L680.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-discounts-af-ah-paper-dim)\"></path><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cada camada cobre o que a anterior deixou</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhuma vCPU recebe dois descontos</text></svg>", "caption": "Os descontos são aplicados em sequência, nunca somados."}
```

1. compromissos baseados em recursos cobrem o uso elegível que correspondem;
2. compromissos flexíveis cobrem o que sobra do uso elegível sob demanda;
3. tudo que ainda está descoberto é cobrado pelo preço sob demanda, **e pode então ganhar uso contínuo**.

Máquinas Spot, que o Google pode parar a qualquer momento, têm preços próprios, até 91% abaixo do sob demanda
na página de preços, e não ganham nenhum outro desconto.

## A decisão

A aritmética de um compromisso é a pergunta de quanto do uso prometido vai acontecer. **Um compromisso de um
ano com 37% de desconto se paga se o uso que ele cobre rodar mais que uns 63% do tempo que teria custado sob
demanda**; abaixo disso, uso contínuo e sob demanda saíam mais baratos. Três anos com 55% são uma economia
maior e uma aposta maior. A prática comum é comprometer só o piso de uso que está estável há meses, medido
pela exportação de faturamento da lição 14, e deixar tudo acima dele com sob demanda e uso contínuo.

**O compromisso não liga para que máquinas o usam.** Um compromisso baseado em recursos de 32 vCPUs N2 em São
Paulo cobre quaisquer 32 vCPUs N2 rodando nessa região nos projetos a que se aplica, sejam de que máquinas
forem. Uma equipe que troca N2 por uma série mais nova fica com o compromisso cobrando e nada para ele cobrir,
até expirar: a fatura que chegou errada da primeira seção, item 4, pelo outro lado.
