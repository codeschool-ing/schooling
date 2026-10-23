---
title: Panorama de sistemas, diagramas dinâmicos e de implantação
version: 1
---

**Os quatro níveis descrevem a estrutura estática de um sistema. O C4 acrescenta três diagramas
suplementares para o que essa estrutura deixa de fora: o conjunto inteiro de sistemas, o
comportamento ao longo do tempo e onde as coisas rodam.** Cada um reaproveita as mesmas cinco
palavras, e é isso que os mantém consistentes com os quatro níveis.

## Panorama de sistemas

Um **diagrama de panorama de sistemas** é um diagrama de contexto sem sistema no meio: todos os
sistemas de software que a organização opera, as pessoas que os usam e as relações entre eles. Na
Carcará ele tem sete sistemas, da venda de passagens e da Frota à folha de pagamento e ao pacote
financeiro. É o desenho de partida do arquiteto corporativo, e as aulas 8 a 10 voltam a esse nível.

## Diagramas dinâmicos

Um **diagrama dinâmico** mostra como os elementos colaboram para executar um cenário,
**numerando as relações** na ordem em que acontecem. Ele usa as caixas de um diagrama de containers
ou de componentes e acrescenta os números, então se lê como um diagrama de sequência disposto como
um mapa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-dynamic\" aria-label=\"Um diagrama dinâmico da compra sobre as caixas de containers, com relações numeradas: 1, o app móvel cria a reserva na API de passagens; 2, a API bloqueia o assento no store; 3, grava a reserva pendente no banco de reservas; 4, o app paga; 5, a API cobra no gateway de pagamento; 6, marca a reserva como paga; 7, publica passagem vendida no broker; 8, o worker de notificação envia a passagem.\"><defs><marker id=\"l03-dynamic-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"25.0\" y=\"38.0\" width=\"150.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">App móvel</text><text x=\"100.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"275.0\" y=\"38.0\" width=\"170.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">API de passagens</text><text x=\"360.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container]</text><rect x=\"545.0\" y=\"38.0\" width=\"150.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"620.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Gateway</text><text x=\"620.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Sistema]</text><path d=\"M165.0 177.0 L165.0 223.0 A65.0 7 0 0 0 295.0 223.0 L295.0 177.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"var(--panel)\"></path><ellipse cx=\"230.0\" cy=\"177.0\" rx=\"65.0\" ry=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></ellipse><text x=\"230.0\" y=\"198.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">Bloqueios</text><text x=\"230.0\" y=\"209.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"7.5\" fill=\"var(--paper-dim)\">[Redis]</text><path d=\"M335.0 177.0 L335.0 223.0 A65.0 7 0 0 0 465.0 223.0 L465.0 177.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"var(--panel)\"></path><ellipse cx=\"400.0\" cy=\"177.0\" rx=\"65.0\" ry=\"7\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></ellipse><text x=\"400.0\" y=\"198.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">Banco de reservas</text><text x=\"400.0\" y=\"209.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"7.5\" fill=\"var(--paper-dim)\">[PostgreSQL]</text><rect x=\"530.0\" y=\"168.0\" width=\"140.0\" height=\"44.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"183.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Broker</text><text x=\"600.0\" y=\"196.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[RabbitMQ]</text><rect x=\"525.0\" y=\"250.0\" width=\"150.0\" height=\"40.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"264.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">Worker</text><text x=\"600.0\" y=\"275.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"7.5\" fill=\"var(--paper-dim)\">[Container]</text><path d=\"M175.0 52.0 L275.0 52.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-dynamic-am-fill-paper)\"></path><text x=\"225.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">1 cria reserva</text><path d=\"M175.0 70.0 L275.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-dynamic-am-fill-paper)\"></path><text x=\"225.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">4 paga</text><path d=\"M320.0 82.0 L250.0 168.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-dynamic-am-fill-paper)\"></path><text x=\"274.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">2 bloqueia</text><path d=\"M370.0 82.0 L395.0 168.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-dynamic-am-fill-paper)\"></path><text x=\"390.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">3 pendente · 6 paga</text><path d=\"M445.0 60.0 L545.0 60.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-dynamic-am-fill-paper)\"></path><text x=\"495.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">5 cobra</text><path d=\"M430.0 82.0 L560.0 168.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l03-dynamic-am-fill-paper)\"></path><text x=\"512.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">7 vendida</text><path d=\"M600.0 212.0 L600.0 250.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-dynamic-am-fill-paper)\"></path><text x=\"608.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">8 consome, envia</text></svg>", "caption": "A mesma história do diagrama de sequência da aula 2, contada sobre caixas que o leitor já conhece. Os números carregam a ordem; a disposição carrega a estrutura.", "same": ["[Container]", "[PostgreSQL]", "[RabbitMQ]", "[Redis]"]}
```

Qual usar é uma questão de quem lê. **Um diagrama de sequência é melhor quando a ordem e as esperas
importam**, porque o tempo é uma dimensão da página. **Um diagrama dinâmico é melhor quando a
disposição importa**: quem lê já conhece o diagrama de containers, e os números em caixas
conhecidas contam a história mais rápido do que um desenho novo com linhas de vida.

## Diagramas de implantação

Um **diagrama de implantação** do C4 mostra como os containers se distribuem pela infraestrutura:
nós de implantação, que podem se aninhar (uma região de nuvem, um cluster, um pool de nós), e as
instâncias de container dentro deles. É a mesma ideia do diagrama de implantação da UML da aula 2,
com as palavras do C4: uma instância do container da API de passagens roda dentro de um nó de
implantação, três vezes.

É também o lugar certo para tudo o que o diagrama de containers deixou de fora de propósito:
**balanceadores de carga, firewalls, regiões, réplicas e quantidades**. Um diagrama de containers
com um balanceador de carga está misturando dois tipos de desenho.

## Um modelo, muitos diagramas

Por trás dos sete diagramas há uma ideia que vale nomear agora, porque a aula 12 parte dela. Se os
elementos e as relações existem uma vez só, num **modelo**, então cada diagrama é uma **visão**
desse modelo, e os diagramas não podem discordar sobre se a API de passagens fala com o Redis.
Ferramentas de desenho guardam sete desenhos separados; ferramentas de modelagem guardam um modelo e
desenham sete visões. Essa diferença é o ponto de vista e a visão da aula 1, transformados em
software.
