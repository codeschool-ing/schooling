---
title: Janelas de sessão
version: 1
---

**Uma janela de sessão não tem tamanho fixo: ela dura enquanto os eventos continuam chegando, e fecha
depois de um intervalo sem atividade.** É a janela para perguntas sobre surtos de atividade cuja
duração ninguém sabe de antemão: a visita de um cliente ao site, o período movimentado de um caixa,
a rota de uma van de entrega.

A regra é uma pausa. Com uma pausa de cinco minutos, um evento a menos de cinco minutos do último de
uma sessão entra nela e a estende; um evento a cinco minutos ou mais começa uma sessão nova. A
sessão 1 das dez vendas começa às 09:00:40, e as vendas 2 a 5 chegam cada uma a menos de dois minutos
da anterior. Então vem uma pausa: das 09:06:20 às 09:12:30 são seis minutos e dez segundos, mais que
o intervalo.

```
ubuntu@stream:~/work$ python windows.py session 5
```

O programa imprimiu uma sessão onde o parágrafo acima previa duas, e a linha entre parênteses diz por
quê. **Um evento atrasado pode juntar duas sessões numa só.** Na ordem de chegada, as vendas 1 a 5
formaram uma sessão terminando às 09:06:20; a venda 6, às 09:12:30, veio mais de cinco minutos
depois, então começou uma segunda, que a venda 7 estendeu. Aí chegou a venda 8: ela aconteceu às
09:08:50, dois minutos e meio depois da última venda da primeira sessão e menos de quatro minutos
antes da primeira da segunda. Ela está perto das duas, então pertence às duas, e as duas viram uma
sessão só, das 09:00:40 às 09:14:10, com nove vendas. A venda 10, sete minutos depois, fica sozinha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo de sessões de cinco minutos. Em cima, depois de chegar a venda 7: uma sessão de 09:00:40 a 09:06:20 com cinco vendas e outra de 09:12:30 a 09:13:05 com duas, a mais de cinco minutos uma da outra. Embaixo, depois de chegar a venda 8, que aconteceu às 09:08:50: ela fica a menos de cinco minutos das duas, e as duas sessões viram uma de 09:00:40 a 09:13:05.\" data-fig=\"l10-session-merge\"><text x=\"10\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">depois que chega a venda 7</text><text x=\"690\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">duas sessões</text><circle cx=\"170.4\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"197.0\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"228.0\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"247.1\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"270.8\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"380.0\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"390.3\" cy=\"60\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><rect x=\"164.4\" y=\"48\" width=\"112.4\" height=\"24\" rx=\"6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"374.0\" y=\"48\" width=\"22.30000000000001\" height=\"24\" rx=\"6\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325.4\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pausa de 6 min 10 s</text><text x=\"10\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">depois que chega a venda 8</text><text x=\"690\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma sessão</text><circle cx=\"170.4\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"197.0\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"228.0\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"247.1\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"270.8\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"380.0\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"390.3\" cy=\"150\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"315.0\" cy=\"150\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></circle><rect x=\"164.4\" y=\"138\" width=\"231.9\" height=\"24\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">venda 8, 09:08:50</text><line x1=\"70\" y1=\"210\" x2=\"690\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"70.0\" y1=\"207\" x2=\"70.0\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"70.0\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">08:55</text><line x1=\"158.6\" y1=\"207\" x2=\"158.6\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"158.6\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"247.1\" y1=\"207\" x2=\"247.1\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"247.1\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:05</text><line x1=\"335.7\" y1=\"207\" x2=\"335.7\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"335.7\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:10</text><line x1=\"424.3\" y1=\"207\" x2=\"424.3\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"424.3\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:15</text><line x1=\"512.9\" y1=\"207\" x2=\"512.9\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"512.9\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:20</text><line x1=\"601.4\" y1=\"207\" x2=\"601.4\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"601.4\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:25</text><line x1=\"690.0\" y1=\"207\" x2=\"690.0\" y2=\"213\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"690.0\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">09:30</text></svg>", "caption": "Um evento atrasado pode juntar duas sessões numa só. As bordas delas são feitas pelos eventos, então um evento que chega tarde pode movê-las."}
```

Essa fusão é a dificuldade que define as sessões num stream. As bordas de uma janela tumbling são
conhecidas antes de qualquer evento chegar; as de uma sessão são feitas pelos eventos, e um evento
que chegou tarde pode movê-las. Um motor que já tivesse informado "sessão 2: 09:12:30 às 09:13:05,
duas vendas" precisa retirar isso e informar uma sessão fundida. Flink e Kafka Streams fazem
exatamente isso: cada evento começa como uma sessão própria, e sessões que se sobrepõem são fundidas
conforme são encontradas.

## O que as bordas impressas querem dizer

O programa imprime uma sessão da primeira à última venda, então uma sessão de uma venda só aparece
como `09:21:00-09:21:00`. A janela em si dura mais: nada pode entrar nela depois que passou uma pausa
inteira desde o último evento, então a sessão das 09:21:00 não pode fechar antes das 09:26:00. O Flink
deixa isso explícito e dá a cada sessão a janela do primeiro evento ao último **mais** a pausa; o
Kafka Streams informa o primeiro e o último. De um jeito ou de outro, **o fim de uma sessão só é
conhecido depois que a pausa passou sem nada dentro**, o que num stream quer dizer depois que chegou
algo mostrando que esse tempo passou. É de novo a pergunta da lição 11.

A pausa é o projeto inteiro. Diminua para três minutos e o programa acha três sessões:

```
ubuntu@stream:~/work$ python windows.py session 3
```

A primeira sessão agora para às 09:08:50, porque a venda 8 cobre uma pausa de 2 minutos e 30 segundos
e não a seguinte, de 3 minutos e 40 segundos, e 09:12:30 às 09:14:10 fica por conta própria. Uma pausa
curta demais divide uma visita em muitas; uma longa demais junta desconhecidos. Para um site, o ponto
de partida usual são trinta minutos, uma convenção antiga da análise web, e para caixas ela deveria
vir de quanto tempo uma loja de fato fica quieta entre clientes, medido.
