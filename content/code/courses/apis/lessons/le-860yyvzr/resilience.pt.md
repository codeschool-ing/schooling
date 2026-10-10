---
title: Resiliência através da fronteira
version: 1
---

**Uma chamada pela rede tem três resultados, não dois: funcionou, falhou, ou você não sabe.** Uma
falha SOAP é o segundo. Um timeout é o terceiro, e o código que o trata como o segundo comete o erro
de que esta seção trata.

Duas seções atrás a ponte desistiu de um pedido depois de dois segundos e respondeu 504. O terminal
dela, o terceiro, registrou essa resposta:

```
127.0.0.1 - - [10/Oct/2026 01:41:06] "POST /orders HTTP/1.1" 504 -
```

O distribuidor não tinha terminado; estava dormindo. As últimas linhas no segundo terminal, onde ele
vem imprimindo, vieram alguns segundos depois:

```
order PO100003: 10 x 9786500000016 for R-2002
127.0.0.1 - - [10/Oct/2026 01:41:09] "POST /distributor HTTP/1.1" 200 -
the caller left before the answer
```

**O pedido foi feito, depois de o shelf já ter dito a quem chamou que ele falhou.** O distribuidor
até percebeu que ninguém esperava a resposta dele, e disse isso; o shelf não soube nada do pedido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 370\" role=\"img\" aria-label=\"Uma sequência no tempo com três linhas de vida: curl, bridge.py e distributor.py. Em 0 segundo o curl envia um pedido com a referência R-2002 e a ponte manda PlaceOrder ao distribuidor, que está dormindo. Em 2 segundos a ponte para de esperar e responde 504 ao curl. Em 5 segundos o distribuidor acorda, faz o pedido PO100003 e responde a quem já foi embora. Depois, o curl envia o mesmo pedido de novo com a mesma referência; o distribuidor encontra R-2002, não faz nada, e responde PO100003 com Repeated verdadeiro, que a ponte repassa como 200.\"><defs><marker id=\"l05-time-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"75\" y=\"14\" width=\"130\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curl</text><line x1=\"140\" y1=\"42\" x2=\"140\" y2=\"358\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"305\" y=\"14\" width=\"130\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bridge.py</text><line x1=\"370\" y1=\"42\" x2=\"370\" y2=\"358\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"535\" y=\"14\" width=\"130\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">distributor.py</text><line x1=\"600\" y1=\"42\" x2=\"600\" y2=\"358\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"30\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 s</text><text x=\"30\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 s</text><line x1=\"140\" y1=\"62\" x2=\"368\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"254.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">POST /orders R-2002</text><line x1=\"370\" y1=\"70\" x2=\"598\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"484.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PlaceOrder</text><rect x=\"594\" y=\"74\" width=\"12\" height=\"158\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"614\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dormindo: slow</text><line x1=\"370\" y1=\"130\" x2=\"142\" y2=\"130\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"256.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">504, depois de 2 s</text><text x=\"378\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">desiste de esperar</text><text x=\"588\" y=\"234\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">faz o PO100003</text><line x1=\"600\" y1=\"246\" x2=\"440\" y2=\"246\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"520.0\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ninguém escuta</text><text x=\"30\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois</text><line x1=\"140\" y1=\"292\" x2=\"368\" y2=\"292\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"254.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mesmo pedido, R-2002</text><line x1=\"370\" y1=\"300\" x2=\"598\" y2=\"300\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"484.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PlaceOrder</text><line x1=\"600\" y1=\"318\" x2=\"372\" y2=\"318\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"486.0\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PO100003, Repeated</text><line x1=\"370\" y1=\"332\" x2=\"142\" y2=\"332\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l05-time-ah)\"></line><text x=\"256.0\" y=\"344\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">200 PO100003</text></svg>", "caption": "Um timeout não diz a quem chamou nada sobre o que aconteceu do outro lado. O pedido de que a ponte desistiu foi feito três segundos depois, e só a referência torna seguro enviá-lo de novo."}
```

## Repita só o que é idempotente

A reação óbvia a um 504 é tentar de novo, e a aula 1 já disse quando isso é seguro: quando a chamada
é **idempotente**, de modo que duas cópias deixam o lado de lá como uma deixaria. O `GetStock` só lê,
então repeti-lo é sempre seguro. O `PlaceOrder` cria algo, e uma repetição às cegas depois deste 504
teria pedido vinte livros em vez de dez.

O que torna este pedido seguro de repetir é **a referência**. O distribuidor lembra cada
`CustomerRef` que já atendeu, e uma referência que ele já viu recebe o mesmo pedido de volta em vez
de um novo. Apague o arquivo `slow` e mande exatamente a mesma requisição de novo:

```
ana@api:~/shelf$ rm slow
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/orders -H 'Content-Type: application/json' -d '{"isbn": "9786500000016", "quantity": 10, "reference": "R-2002"}'
{"order": "PO100003", "isbn": "9786500000016", "quantity": 10, "reference": "R-2002"}
200
ana@api:~/shelf$ curl -s localhost:8000/stock/9786500000016
{"isbn": "9786500000016", "available": 30, "price_cents": 2150, "next_delivery": "2026-10-12"}
```

**200, não 201, e o mesmo número de pedido.** A ponte repassou o `Repeated` do distribuidor, e o
estoque confirma: o distribuidor tinha 40 cópias de *Dom Casmurro* e tem 30, então dez foram
pedidas, uma vez.

Essa deduplicação tem de acontecer **do lado de lá**, porque só o lado de lá sabe se a primeira
requisição chegou. O shelf não consegue descobrir lembrando o que mandou: o que ele mandou é
exatamente aquilo de que não tem certeza. Quando o contrato de um parceiro não tem um campo como
`CustomerRef`, o procedimento seguro depois de um timeout é perguntar antes de reenviar, consultando
os pedidos do parceiro se ele permitir, e passar o caso a uma pessoa se não permitir. A aula 2 mostra
o cabeçalho HTTP que faz o mesmo trabalho numa API REST.

## As outras regras

**Toda chamada que atravessa a fronteira ganha um timeout.** A ponte espera dois segundos pelo
distribuidor; quem chama a ponte tem de esperar mais que isso, ou desiste antes e a resposta da ponte
não vai para lugar nenhum. O timeout de cada camada é menor que o da camada de cima.

**As repetições ganham um limite e uma pausa entre elas.** Três tentativas, esperando mais antes de
cada uma, é uma escolha comum. Repetir na hora e sem limite transforma um distribuidor com
dificuldades num distribuidor fora do ar, com o seu tráfego fazendo isso.

**Uma dependência fora do ar deveria falhar rápido.** Pare o distribuidor com `Ctrl+C` no segundo
terminal e peça estoque à ponte:

```
ana@api:~/shelf$ curl -s -w '%{http_code} after %{time_total} s\n' localhost:8000/stock/9786500000016
{"error": "the distributor cannot be reached"}
502 after 0.003271 s
```

Uma conexão recusada falha na hora, como mostra o tempo que o curl imprimiu, então um distribuidor
morto sai barato para o shelf. O que custa é um lento: toda requisição espera os dois segundos
inteiros, segurando uma thread, antes de falhar.

Esse é o problema que um **circuit breaker** resolve, e vale conhecê-lo pelo nome mesmo que a ponte
não tenha um. Ele conta as falhas recentes de uma dependência. Passado um limite, ele **abre**, e por
um tempo toda chamada falha na hora sem ser tentada, o que poupa as threads do shelf e dá um descanso
ao distribuidor. Depois ele deixa uma chamada passar para testar a água, o estado **meio aberto**, e
fecha de novo se ela der certo. Há bibliotecas que o implementam em toda linguagem; o que você decide
é o limite, quanto tempo ele fica aberto e o que o shelf responde enquanto isso, em geral o mesmo 502
ou 504 que responde agora.
