---
title: A lei de Little, nas palavras de um time
version: 1
---

A crença mais comum sobre um time ocupado é que **começar mais trabalho faz mais trabalho ficar pronto**. Se cinco itens andam devagar, comece um sexto, e pelo menos algo novo está andando. A lei de Little diz por que isso está errado, e diz com aritmética em vez de opinião.

John Little publicou a prova em 1961, sobre filas de qualquer tipo: clientes num banco, peças numa fábrica, pacotes num roteador. A forma usual tem três letras, **L = λW**. **L** é o número médio de coisas dentro do sistema, **λ** (lambda) é o ritmo médio em que elas saem, e **W** é o tempo médio que cada uma passa dentro. Nas palavras de um time com um quadro, fica assim:

```localised
trabalho em andamento médio = vazão × tempo de ciclo médio
```

e, reorganizada, na forma que uma tech lead mais usa:

```localised
tempo de ciclo médio = trabalho em andamento médio ÷ vazão
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" data-fig=\"l01-box\" aria-label=\"Uma caixa que representa o time, com seis cartões dentro. Cartões chegam pela esquerda, e os terminados saem pela direita. O número de cartões dentro é o trabalho em andamento, L; o ritmo em que saem é a vazão, lambda; o tempo que cada cartão passa dentro, de entrar a sair, é o tempo de ciclo, W.\"><defs><marker id=\"dm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"dm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190.0\" y=\"40.0\" width=\"300.0\" height=\"130.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"340.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o time</text><rect x=\"214.0\" y=\"78.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"306.0\" y=\"78.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"78.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"214.0\" y=\"120.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"306.0\" y=\"120.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"398.0\" y=\"120.0\" width=\"70.0\" height=\"28.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"24.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"68.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"112.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M160.0 118.0 L186.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dm-ah-paper-dim)\"></path><path d=\"M494.0 118.0 L520.0 118.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dm-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"574.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"618.0\" y=\"104.0\" width=\"34.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos chegam</text><text x=\"596.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">itens terminam</text><path d=\"M190.0 196.0 L490.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dm-ah-amber)\"></path><path d=\"M190.0 188.0 L190.0 204.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"340.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">W: os dias que cada item passa dentro (tempo de ciclo)</text><text x=\"340.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">L: os itens dentro a cada momento (trabalho em andamento)</text><text x=\"596.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">λ: itens que saem por dia</text><text x=\"596.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">(vazão)</text><text x=\"340.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">L = λ × W</text></svg>", "caption": "Qualquer sistema por onde o trabalho entra e sai. Conhecidos dois dos três números, a lei dá o terceiro.", "same": ["L = λ × W"]}
```

## Um exemplo resolvido

Um time termina **cinco itens por semana** e tem, num dia comum, **quinze itens** começados e não terminados. Então um item leva, em média, 15 ÷ 5 = **três semanas** do início ao fim. Ninguém precisou cronometrar um único item para saber disso.

Agora o time começa mais. Mantém vinte itens abertos e, como são as mesmas pessoas fazendo o mesmo trabalho, continua terminando uns cinco por semana. A lei dá 20 ÷ 5 = **quatro semanas**. Cada item agora leva uma semana a mais, e os cinco itens extras não fizeram nada chegar antes. Esse é todo o argumento para limitar o trabalho em andamento, que a aula 4 faz na prática: **com a vazão fixa, mais trabalho aberto só quer dizer trabalho mais velho**.

O movimento oposto é o útil. Mantenha dez itens abertos e os mesmos cinco por semana dão duas semanas por item. O time não ficou mais rápido; cada item passou menos tempo esperando alguém voltar a ele.

## O que a lei precisa

A lei de Little é um teorema, não uma regra prática, mas é um teorema sobre **médias num período em que o sistema está estável**. No quadro de um time, isso quer dizer quatro coisas valendo no período medido:

- **o que começa, termina.** Um item abandonado no meio, ou apagado do quadro, desequilibra as contas;
- **chegadas e saídas mais ou menos batem.** Se o time começa muito mais do que termina, o trabalho em andamento sobe sem parar e nenhuma média o descreve;
- **o trabalho em andamento é parecido nas duas pontas do período.** Um período que começa com o quadro vazio e termina cheio está medindo uma rampa, não um sistema;
- **as unidades concordam.** Vazão por dia combina com tempo de ciclo em dias, e os dois contam o mesmo calendário: se o trabalho em andamento é contado aos sábados, o tempo de ciclo também conta os sábados.

Quando isso vale, os dois lados concordam, e você pode usar a lei para tirar o número que não tem dos dois que tem. Quando não vale, os dois lados discordam, e **a discordância é informação**: diz que o sistema mudou durante o período. A última seção desta aula mede os dois casos no quadro do time de Billing.

## O que a lei não diz

Não diz que cortar trabalho em andamento sempre encurta o tempo de ciclo. Se o corte também derruba a vazão, porque agora há gente parada esperando algo para começar, a razão pode ficar igual. Na prática, a vazão quase não se mexe quando um time com trabalho aberto demais o corta, porque o trabalho estava esperando, não sendo feito. A aula 4 mostra isso no time de Billing, e a aula 12 mostra a outra ponta: um time tão pouco carregado que tirar mais trabalho só tiraria entrega.

Também não diz nada sobre um item. Um tempo de ciclo médio de duas semanas é compatível com um item que levou dois meses. A aula 2 é sobre a dispersão em volta da média, que é onde mora o item que levou dois meses.
