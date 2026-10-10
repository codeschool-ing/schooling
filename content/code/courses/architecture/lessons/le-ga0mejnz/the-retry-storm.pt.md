---
title: A tempestade de retries
version: 1
---

Agora a falha que importa em produção. O checkout chama 60 vezes por segundo, três quartos da capacidade
do serviço, e no sexto segundo o serviço congela por três segundos, como uma pausa longa de coleta de lixo
ou um failover do banco o fariam. Primeiro sem retries:

```
ana@vm:~/lab/resilience$ $C --freeze-at 6
 second      ok  failed   calls
  0-2       120       0     120
  2-4       120       0     120
  4-6       120       0     120
  6-8         3     117     120
  8-10        0     120     120
 10-12        1     119     120
 12-14        3     117     120
 14-16        1     119     120
 16-18       93      27     120
 18-20      120       0     120
 20-22      120       0     120
 22-24      120       0     120
 24-26      120       0     120
 26-28      120       0     120
 28-30      120       0     120
the stock service answered 1800 calls, 619 of them after the caller had given up
```

Durante o congelamento quase tudo falhou, o que era inevitável: nada estava respondendo. Mas veja quanto
tempo levou para se recuperar. O congelamento acabou no segundo 9, e as requisições continuaram falhando
até por volta do segundo 17. **Três segundos de congelamento custaram uns dez segundos de falhas.** Congelado, o
serviço continuou aceitando chamadas na fila; quando acordou, tinha umas 180 requisições esperando e uma
capacidade só 20 por segundo acima do ritmo de chegada, então a fila levou uns nove segundos para
esvaziar. Toda requisição nela esperou mais que o meio segundo do cliente, então o serviço passou esses
segundos respondendo chamadas cujos chamadores já tinham desistido: 619 das 1.800 respostas foram para
ninguém.

Agora o mesmo congelamento, com três retries:

```
ana@vm:~/lab/resilience$ $C --freeze-at 6 --retries 3
 second      ok  failed   calls
  0-2       120       0     120
  2-4       120       0     120
  4-6       120       0     120
  6-8         4     116     291
  8-10        9     111     475
 10-12       10     110     469
 12-14        7     113     474
 14-16        8     112     474
 16-18       12     108     466
 18-20       18     102     469
 20-22        9     111     460
 22-24        9     111     471
 24-26       11     109     462
 26-28       11     109     465
 28-30        8     112     458
 30-32        0       0     173
the stock service answered 5947 calls, 5471 of them after the caller had given up
```

**Ele nunca se recupera.** O congelamento acabou no segundo 9 como antes, e vinte segundos depois o
checkout ainda está falhando nove requisições em cada dez. A última coluna explica: o serviço consegue
responder 160 chamadas em dois segundos, e está recebendo umas 460, porque toda requisição que dá timeout
volta até mais três vezes. A fila dele só pode crescer, toda resposta chega atrasada, toda resposta
atrasada causa um retry, e os retries mantêm a fila cheia. De 5.947 respostas, 5.471 foram para
chamadores que tinham parado de esperar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Um laço de quatro passos. O serviço está lento ou sobrecarregado. Quem chama dá timeout. Quem chama tenta de novo, somando chamadas. As chamadas a mais deixam o serviço mais sobrecarregado, o que leva o laço de volta ao começo. Uma nota diz que o laço continua depois que a causa original foi embora.\"><defs><marker id=\"l11-loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"250\" y=\"30\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">serviço sobrecarregado</text><rect x=\"470\" y=\"110\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quem chama dá timeout</text><rect x=\"250\" y=\"190\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quem chama tenta de novo</text><rect x=\"30\" y=\"110\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">chegam mais chamadas</text><path d=\"M472 50 L580 50 L580 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-loop-ah-amber)\"></path><path d=\"M580 152 L580 210 L472 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-loop-ah-amber)\"></path><path d=\"M248 210 L140 210 L140 152\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-loop-ah-amber)\"></path><path d=\"M140 108 L140 50 L248 50\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-loop-ah-amber)\"></path><text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">continua depois que a causa foi embora</text></svg>", "caption": "A tempestade de retries se alimenta: os retries mantêm o serviço sobrecarregado, e a sobrecarga continua causando retries, muito depois de passar o que a começou."}
```

Isso é uma **tempestade de retries** (*retry storm*), e o perigoso nela está no tempo: **a causa original
tinha ido embora depois de três segundos**, e o sistema continuou fora do ar por causa do jeito como reage
a falhas. Ela só termina quando a carga para, o que em produção quer dizer quando alguém percebe e desliga
as coisas. O nome de uma falha que se sustenta depois de o gatilho ter ido embora é **falha metaestável**,
e os retries são o motor mais comum dela.

Duas coisas a pioraram e merecem nome. **O serviço trabalhou para chamadores que já tinham ido embora**:
ele não tinha como saber que o prazo do chamador tinha passado, então respondeu milhares de requisições
pelas quais ninguém esperava. E **os retries chegaram juntos**: todo chamador que falhou no mesmo
instante tentou de novo no mesmo instante. O resto da aula trata das duas.
