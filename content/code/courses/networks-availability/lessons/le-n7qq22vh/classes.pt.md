---
title: Classes, filas e um escalonador
version: 1
---

Um roteador que respeita uma marcação precisa de três coisas, e no Linux cada uma é uma linha separada de
`tc`. **Um classificador decide a que classe um pacote pertence, cada classe ganha uma fila própria, e um
escalonador decide qual fila envia a seguir.** A configuração de fila única é removida antes, fora da tela,
e esta é montada no lugar:

```
ana@hq:~$ sudo tc qdisc add dev eth1 root handle 1: htb default 20 && sudo tc class add dev eth1 parent 1: classid 1:1 htb rate 5mbit
ana@hq:~$ sudo tc class add dev eth1 parent 1:1 classid 1:10 htb rate 1mbit ceil 5mbit prio 0 && sudo tc class add dev eth1 parent 1:1 classid 1:20 htb rate 4mbit ceil 5mbit prio 1
ana@hq:~$ sudo tc qdisc add dev eth1 parent 1:10 pfifo limit 100 && sudo tc qdisc add dev eth1 parent 1:20 pfifo limit 100
ana@hq:~$ sudo tc filter add dev eth1 parent 1: protocol ip prio 1 u32 match ip dsfield 0xb8 0xfc flowid 1:10
```

Quatro comandos, lidos na ordem em que um pacote os encontra:

| peça | o que diz |
|---|---|
| `u32 match ip dsfield 0xb8 0xfc flowid 1:10` | um pacote cujo DSCP é EF vai para a classe `1:10`; a máscara `0xfc` compara os seis bits de DSCP e ignora os dois de ECN |
| `htb default 20` | um pacote que nenhum filtro pega vai para `1:20` |
| `pfifo limit 100`, duas vezes | cada classe tem uma fila própria de 100 pacotes |
| `1:1 htb rate 5mbit` | o enlace inteiro, 5 Mbit/s, dividido entre as duas classes abaixo dele |
| `1:10 ... rate 1mbit ceil 5mbit prio 0` | voz: 1 Mbit/s garantido, pode pegar emprestado até o enlace inteiro, recebe a oferta primeiro |
| `1:20 ... rate 4mbit ceil 5mbit prio 1` | todo o resto: 4 Mbit/s garantidos, pode pegar emprestado o que a voz deixar |

O HTB, hierarchical token bucket, é o escalonador. Cada classe recebe primeiro a sua `rate`; o que sobra é
emprestado às classes que querem mais, até o `ceil` delas, e **a classe com o número de `prio` menor
recebe a oferta primeiro e é atendida primeiro**. Então um pacote em `1:10` nunca espera na fila de `1:20`.
Ele só espera atrás de outros pacotes de voz, e há muito poucos deles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 850 244\" role=\"img\" aria-label=\"O HTB montado na eth1 de hq. Os pacotes do escritório passam por um classificador, um filtro u32 no campo DSCP. EF vai para a classe 1:10, voz, rate 1mbit ceil 5mbit prio 0; o resto vai para a classe 1:20, todo o resto, rate 4mbit ceil 5mbit prio 1. Cada classe tem a própria fila, pfifo limit 100: a fila de voz tem um pacote, a outra está cheia. As duas alimentam a classe 1:1, o enlace a rate 5mbit, que envia de 1:10 primeiro.\"><defs><marker id=\"t18-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pacotes do escritório</text><path d=\"M80 30 L80 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><rect x=\"20\" y=\"100\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">classificador</text><text x=\"85.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">u32 dsfield</text><path d=\"M150 116 C 180 116, 180 68, 206 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><path d=\"M150 140 C 180 140, 180 192, 206 192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><text x=\"170\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">EF</text><text x=\"166\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o resto</text><rect x=\"208\" y=\"40\" width=\"240\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"328.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">voz: 1:10</text><text x=\"328.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rate 1mbit ceil 5mbit prio 0</text><rect x=\"208\" y=\"164\" width=\"240\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"328.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">todo o resto: 1:20</text><text x=\"328.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rate 4mbit ceil 5mbit prio 1</text><path d=\"M448 68 L470 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><rect x=\"472\" y=\"48\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"617\" y=\"54\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M448 192 L470 192\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><rect x=\"472\" y=\"172\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"617\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"600\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"583\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"566\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"549\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"532\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"515\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"498\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"481\" y=\"178\" width=\"13\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"557\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pfifo limit 100</text><text x=\"557\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pfifo limit 100</text><path d=\"M642 68 C 668 68, 668 118, 690 124\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><path d=\"M642 192 C 668 192, 668 144, 690 138\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t18-ah)\"></path><rect x=\"692\" y=\"104\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"762.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o enlace: 1:1</text><text x=\"762.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">rate 5mbit</text><text x=\"762\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">envia de 1:10 primeiro</text></svg>", "caption": "Classificar, enfileirar, escalonar: os três passos desta seção como o tc os montou. O upload enche a própria fila e não fica mais na frente dos pacotes de voz."}
```

## Os mesmos dois pings, de novo

O mesmo upload roda, e os mesmos dois pings vêm em seguida, um sem marcação e outro marcado como EF:

```
ana@laptop:~$ ping -c 5 -q 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 21.792/62.909/221.092/79.098 ms
ana@laptop:~$ ping -c 5 -q -Q 0xb8 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 0.053/0.065/0.092/0.014 ms
```

O ping sem marcação está onde estava, até **221 ms**, porque divide a classe `1:20` com o upload. O
marcado voltou em **0,065 ms** em média, o mesmo que num enlace ocioso. O enlace está tão cheio quanto
antes; os pacotes de voz só não estão mais na fila dele.

O `tc -s` conta o que foi para onde, e as contas batem:

```
ana@hq:~$ tc -s class show dev eth1 | grep -A 1 -E "^class htb 1:(10|20)"
class htb 1:10 parent 1:1 leaf 8010: prio 0 rate 1Mbit ceil 5Mbit burst 1600b cburst 1600b 
 Sent 490 bytes 5 pkt (dropped 0, overlimits 0 requeues 0) 
--
class htb 1:20 parent 1:1 leaf 8011: prio 1 rate 4Mbit ceil 5Mbit burst 1600b cburst 1600b 
 Sent 6279565 bytes 4171 pkt (dropped 163, overlimits 4158 requeues 0) 
```

A classe `1:10` enviou **5 pacotes, 490 bytes**: os cinco pings marcados, 98 bytes cada no fio, 84 de IP e
14 de Ethernet. Não descartou nada e nunca passou do limite. A classe `1:20` levou o upload, 4171 pacotes,
e **descartou 163**. Os descartes não sumiram; ficaram onde está o tráfego pesado, que é o único lugar para
onde podem ir num enlace cheio.

## Prioridade não é inanição

Por que dar uma rate à classe de voz, se ela podia simplesmente ir primeiro? Porque uma classe que sempre
vai primeiro e não tem limite pode tomar o enlace inteiro. Se todo pacote do escritório fosse marcado como
EF, uma fila de prioridade estrita não enviaria mais nada, nunca. Aqui as garantias impedem isso: `1:20`
tem **4 Mbit/s prometidos, aconteça o que acontecer em `1:10`**, então o pior que uma enxurrada de EF
consegue fazer é pegar o megabit garantido dela e o que `1:20` não estiver usando. Roteadores de outros fabricantes chegam ao mesmo resultado por outro caminho. O low-latency queueing da Cisco, por exemplo, aplica um policiamento à fila de prioridade numa taxa fixa; isso não foi executado aqui. De um jeito ou
de outro, **a classe de prioridade é mantida pequena de propósito**, dimensionada para as ligações que o
escritório faz de verdade.
