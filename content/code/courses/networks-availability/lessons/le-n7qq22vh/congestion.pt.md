---
title: O QoS não faz nada até uma fila se formar
version: 1
---

O QoS costuma ser vendido como um jeito de deixar o tráfego importante mais rápido, ou de reservar banda
para ele. Num enlace ocioso ele não faz nenhuma das duas coisas, porque não há nada em relação a que ser
mais rápido. **A qualidade de serviço só decide quem espera quando os pacotes chegam mais depressa do que
um enlace consegue enviá-los**, e isso acontece num lugar só: a fila na frente do enlace mais lento do
caminho.

O laboratório não tem enlace lento. Todo cabo nele é virtual, num único computador. Um ping do laptop
para `web1`, no datacenter, volta numa fração de milissegundo, o que mede esse computador falando consigo
mesmo e mais nada:

```
ana@laptop:~$ ping -c 5 -q 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 0.077/0.161/0.321/0.085 ms
```

Então a aula cria um. O enlace de `hq` para o provedor, `eth1`, vira um enlace de 5 Mbit/s com uma fila de
100 pacotes na frente, o formato do upload de um escritório pequeno. O primeiro comando o monta com o `tc`,
a ferramenta de controle de tráfego do Linux, e o segundo mostra o que foi montado:

```
ana@hq:~$ sudo tc qdisc add dev eth1 root handle 1: htb default 20 && sudo tc class add dev eth1 parent 1: classid 1:20 htb rate 5mbit && sudo tc qdisc add dev eth1 parent 1:20 pfifo limit 100
ana@hq:~$ tc qdisc show dev eth1; tc class show dev eth1
qdisc htb 1: root refcnt 5 r2q 10 default 0x20 direct_packets_stat 0 direct_qlen 1000
qdisc pfifo 800f: parent 1:20 limit 100p
class htb 1:20 root leaf 800f: prio 0 rate 5Mbit ceil 5Mbit burst 1600b cburst 1600b 
ana@laptop:~$ ping -c 5 -q 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 0.094/0.106/0.129/0.014 ms
```

`rate 5Mbit` é a nova velocidade do enlace e `pfifo ... limit 100p` é a fila: primeiro a entrar, primeiro
a sair, no máximo 100 pacotes. O ping logo depois dá **0,106 ms**, o mesmo de antes. Um enlace de 5 Mbit/s
é lento para um arquivo e rápido para cinco pings, então a fila estava vazia a cada vez e não havia nada
atrás do que esperar.

## Um upload muda tudo

Agora o laptop faz um upload para `web1`, com um `iperf3` iniciado em segundo plano e não mostrado, e dois
segundos depois o mesmo ping roda de novo:

```
ana@laptop:~$ ping -c 5 -q 192.0.2.21 | tail -n 1
rtt min/avg/max/mdev = 23.031/65.122/221.652/78.297 ms
```

A resposta mais rápida levou **23 ms** e a mais lenta **221 ms**, umas duas mil vezes o ping anterior.
Nada no ping mudou. Ele entrou no fim da fila, atrás do que o upload tinha posto lá, e esperou a vez. A
conta diz o quanto uma fila cheia é ruim: 100 pacotes de 1514 bytes, os 1500 do IP mais 14 do Ethernet,
são 1.211.200 bits, e a 5 Mbit/s eles levam **242 ms** para escoar. A resposta de 221 ms encontrou a fila
quase cheia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 230\" role=\"img\" aria-label=\"Uma fila desenhada como uma fileira de posições na frente de um enlace de 5 Mbit/s. As posições estão cheias de pacotes do upload, e um ping espera no fim. Uma fila cheia são 100 pacotes de 1514 bytes, 1.211.200 bits, que levam 0,242 segundo para esvaziar a 5 Mbit/s. Medido durante o upload, cinco pings levaram de 23 a 221 milissegundos.\"><defs><marker id=\"q18-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hq, eth1: uma fila para tudo</text><rect x=\"30\" y=\"44\" width=\"500\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"36\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"56.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"77.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"97.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"118.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"138.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"159.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"179.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"200.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"220.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"241.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"261.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"282.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"302.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"323.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"343.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"364.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"384.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"405.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"425.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"446.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"466.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"487.0\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"507.5\" y=\"50\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><path d=\"M530 66 L578 66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#q18-ah)\"></path><rect x=\"580\" y=\"44\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o enlace: 5 Mbit/s</text><text x=\"36\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o ping, no fim da fila</text><text x=\"524\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o próximo a sair</text><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma fila cheia:</text><text x=\"200\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">100 × 1514 bytes × 8 = 1,211,200 bits</text><text x=\"30\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">para esvaziar a 5 Mbit/s:</text><text x=\"200\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1,211,200 ÷ 5,000,000 = 0.242 s</text><text x=\"30\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">medido, cinco pings durante o upload: de 23 ms a 221 ms</text><rect x=\"30\" y=\"206\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os pacotes do upload (iperf3)</text><rect x=\"260\" y=\"206\" width=\"12\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"278\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um ping</text></svg>", "caption": "Uma fila na frente de um enlace lento. O ping não é lento; ele é o último da fila, e a fila, cheia, tem um quarto de segundo de comprimento."}
```

Por que a fila fica cheia, e não só de vez em quando? Porque é isso que o TCP faz. Ele envia cada vez mais
rápido até um pacote se perder, desacelera e volta a subir, então **um único upload mantém cheia a fila na
frente de um enlace lento enquanto durar.** Um segundo upload, rodado em primeiro plano depois que o
primeiro terminou, mostra as perdas no resumo, 163 retransmissões em cinco segundos:

```
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 5 | tail -n 4
[  5]   0.00-5.00   sec  3.50 MBytes  5.87 Mbits/sec  163             sender
[  5]   0.00-5.03   sec  2.75 MBytes  4.59 Mbits/sec                  receiver

iperf Done.
```

Uma fila que fica cheia e soma um quarto de segundo a tudo o que vem atrás tem nome, **bufferbloat**, e
no uplink de um escritório é o motivo de sempre para uma ligação picotar enquanto alguém envia um arquivo
grande. O enlace não está sem capacidade para a ligação; a ligação está presa atrás do arquivo.

Isso também diz o que o QoS pode e o que não pode fazer. Ele não deixa o enlace mais rápido e não esvazia
a fila para todo mundo. **O que ele pode fazer é manter alguns pacotes fora dessa fila**, e são três
passos: reconhecer quais pacotes importam, dar a eles uma fila própria e enviar dessa fila primeiro. O
resto desta aula monta esses três passos neste enlace.
