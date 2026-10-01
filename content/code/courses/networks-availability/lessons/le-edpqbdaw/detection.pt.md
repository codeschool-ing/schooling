---
title: Failover é perceber, depois trocar
version: 1
---

A imagem que quase todo mundo tem de um failover é uma chave que vira no instante em que algo quebra.
**Nada sabe que uma máquina falhou.** Uma máquina morta não manda mensagem avisando; as outras precisam
perceber que ela parou de dizer alguma coisa. Então todo failover se apoia num **heartbeat**, uma
mensagem pequena mandada a intervalos fixos, e numa regra de quantas podem faltar antes de quem manda ser
declarado morto.

O tempo entre a falha e a volta do serviço é, portanto, feito de pedaços, um depois do outro, e cada um
tem a sua causa:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um eixo de tempo de 0 a 6 segundos. Os heartbeats chegam em 0, 1 e 2 segundos. O master falha por volta de 2,4 segundos, e os heartbeats esperados em 3, 4 e 5 segundos nunca chegam. O backup assume por volta de 5,6 segundos, três intervalos mais um skew depois do último heartbeat que ouviu, e o tráfego volta um instante depois. Uma chave da falha até esse momento marca o que o cliente sente.\"><defs><marker id=\"ha-tl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40 120 L700 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ha-tl-ah)\"></path><text x=\"700\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><text x=\"50\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"140\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">1 s</text><text x=\"230\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2 s</text><text x=\"320\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">3 s</text><text x=\"410\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">4 s</text><text x=\"500\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">5 s</text><text x=\"590\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">6 s</text><circle cx=\"50\" cy=\"120\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"140\" cy=\"120\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"230\" cy=\"120\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><circle cx=\"320\" cy=\"120\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 2\"></circle><circle cx=\"410\" cy=\"120\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 2\"></circle><circle cx=\"500\" cy=\"120\" r=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 2\"></circle><path d=\"M266.0 50 L266.0 112\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"266.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o master falha</text><path d=\"M554.9000000000001 50 L554.9000000000001 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"554.9000000000001\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o backup assume</text><path d=\"M590.0 72 L590.0 112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"596.0\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tráfego de novo</text><path d=\"M230 160 L230 166 L554.9000000000001 166 L554.9000000000001 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"392.45000000000005\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">silêncio suficiente: 3 intervalos mais um skew</text><path d=\"M266.0 200 L266.0 206 L590.0 206 L590.0 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"428.0\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o que o cliente sente</text><circle cx=\"26\" cy=\"250\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.6\"></circle><text x=\"38\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">heartbeat ouvido</text><circle cx=\"206\" cy=\"250\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 2\"></circle><text x=\"218\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">heartbeat que nunca chega</text></svg>", "caption": "Um failover num relógio, com um heartbeat por segundo como no VRRP. O backup conta a partir do último heartbeat que ouviu, não a partir da falha, então os mesmos timers dão uma queda mais curta ou mais longa conforme o ponto do intervalo em que o master morreu."}
```

| pedaço | o que define a duração | na aula 15 |
|---|---|---|
| detecção | o intervalo do heartbeat vezes as faltas permitidas | um anúncio por segundo, três perdidos e mais uma fração |
| decisão | uma eleição, uma votação, um script | ganha o backup de maior prioridade |
| troca | mover um endereço e anunciar para onde ele foi | o roteador novo passa a responder por `192.168.10.1` |
| os clientes se atualizam | caches, retransmissões TCP, reconexões | a entrada ARP do laptop muda para o roteador novo |

A aula 15 mediu os quatro juntos com um ping a cada 0,2 segundo: **15 respostas faltando, 3,26 segundos
da última resposta antes da falha até a primeira depois dela**. A aula 16 mediu 2,694 segundos para um
balanceador cujo próprio health check falhou. Nenhum dos dois números é o tempo de consertar alguma coisa.
Os dois são o tempo que as máquinas levaram para concordar que algo estava quebrado.

## Mais rápido não sai de graça

Timers mais curtos acham uma falha mais cedo. Também acham falhas que não existem. **Um heartbeat perdido
por um processador ocupado ou um enlace congestionado é idêntico a uma máquina morta**, e um backup que
assume depois de um único pacote perdido vai assumir numa tarde comum sem motivo nenhum. A mesma regra
afobada devolve o controle quando o próximo heartbeat chega, e o par fica **oscilando** (o famoso
flapping): o serviço vai e volta, e cada mudança custa alguns segundos da própria queda que devia evitar.

A defesa é a histerese: pedir mais evidência para mudar de estado do que para ficar nele. Os checks de
servidor do HAProxy na aula 16 estão escritos `check inter 1s fall 2 rise 2`, o que quer dizer um check
por segundo, duas falhas seguidas para marcar um servidor como fora e dois sucessos seguidos para trazê-lo
de volta. **Um check que falha não muda nada.** Muitos sistemas também
esperam antes de devolver o controle a uma máquina que acabou de se recuperar, ou nunca o devolvem
sozinhos; a aula 15 mostra essa escolha, chamada preempção.

Os números a escolher são uma troca entre dois custos. Uma detecção de três segundos é inofensiva para um
roteador e uma eternidade para uma bolsa de valores. Uma detecção de 100 milissegundos é certa num enlace
dedicado e tranquilo e uma fonte de alarmes falsos num enlace compartilhado e cheio. **Ajuste os timers
pelo enlace que leva os heartbeats, não pela rapidez que você gostaria que o failover tivesse.**
