---
title: "O gateway padrão: o endereço de um roteador"
version: 1
---

"Gateway" soa como um equipamento. Na configuração de um host é um **endereço**: **o gateway padrão
é o endereço do roteador para o qual um host manda todo pacote cujo destino não está na sua própria
rede.** A tabela de rotas do pc1 diz isso em duas linhas:

```
ana@pc1:~$ ip route
default via 10.20.10.1 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.21 
ana@pc1:~$ ip neigh
10.20.10.10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
```

`10.20.10.0/24 dev eth0` diz que a rede do escritório está diretamente na `eth0`; um pacote para
qualquer endereço dela vai direto ao dono. `default via 10.20.10.1` diz que todo o resto vai para
10.20.10.1, o endereço do r1 no escritório. A tabela de vizinhos tem uma entrada, a do servidor,
que sobrou da seção da placa de rede.

Agora o pc1 pinga uma máquina do outro lado do roteador, enquanto o tcpdump no próprio pc1 observa a
placa. O tcpdump foi iniciado antes e imprimiu quando completou os dois pacotes, por isso a saída
dele vem depois do ping:

```
ana@pc1:~$ ping -c 1 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=62 time=13.8 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 13.754/13.754/13.754/0.000 ms
root@pc1:~# timeout 5 tcpdump -n -e -c 2 -i eth0 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:13:11.759016 02:25:70:bc:29:c6 > 02:1f:23:e7:e9:d5, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 192.0.2.80: ICMP echo request, id 23, seq 1, length 64
15:13:11.770325 02:1f:23:e7:e9:d5 > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 192.0.2.80 > 10.20.10.21: ICMP echo reply, id 23, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
ana@pc1:~$ ip neigh
10.20.10.1 dev eth0 lladdr 02:1f:23:e7:e9:d5 REACHABLE 
10.20.10.10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
root@r1:~# ip -br link show eth0
eth0@if85        UP             02:1f:23:e7:e9:d5 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

Leia o primeiro quadro capturado da esquerda para a direita. **O quadro é endereçado a
`02:1f:23:e7:e9:d5`, enquanto o pacote dentro dele é endereçado a `192.0.2.80`.** O último comando
mostra de quem é esse MAC: da `eth0` do r1. O pc1 nunca perguntou o MAC de 192.0.2.80, e nem
poderia: o ARP só alcança máquinas do mesmo enlace, e 192.0.2.80 está a duas redes de distância.
Ele perguntou o MAC do gateway, e é por isso que a tabela de vizinhos agora tem uma segunda linha,
`10.20.10.1 ... 02:1f:23:e7:e9:d5`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O quadro que o pc1 enviou ao pingar 192.0.2.80, como o tcpdump o capturou, desenhado como duas caixas aninhadas. A caixa de fora é o quadro Ethernet: MAC de destino 02:1f:23:e7:e9:d5, que é o r1, o gateway, e MAC de origem 02:25:70:bc:29:c6, o pc1. Dentro dele está o pacote IP: origem 10.20.10.21 e destino 192.0.2.80, o servidor distante. O quadro só atravessa o enlace do escritório e é trocado no r1; os endereços do pacote viajam o caminho todo.\"><defs><marker id=\"l2-frame-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"692\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">quadro Ethernet: vale só no enlace do escritório</text><rect x=\"26\" y=\"62\" width=\"190\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">MAC de destino</text><text x=\"36\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">02:1f:23:e7:e9:d5</text><text x=\"36\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">r1, o gateway</text><rect x=\"226\" y=\"62\" width=\"190\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"236\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">MAC de origem</text><text x=\"236\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">02:25:70:bc:29:c6</text><text x=\"236\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pc1</text><rect x=\"426\" y=\"62\" width=\"268\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"436\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pacote IP: mantido até o fim</text><text x=\"436\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.10.21 &gt; 192.0.2.80</text><text x=\"436\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">do pc1 ao servidor distante</text><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no r1 o quadro é trocado; o pacote segue dentro de um novo</text></svg>", "caption": "Um quadro da captura do pc1: dois endereços para o próximo equipamento, dois para as pontas da viagem."}
```

**Dois pares de endereços, com dois alcances diferentes.** Os endereços IP nomeiam as duas pontas
da viagem e ficam no pacote o caminho todo; os endereços MAC nomeiam quem envia e quem recebe neste
enlace e são jogados fora no r1, que embrulha o mesmo pacote num quadro novo para o enlace do
provedor. A resposta voltou com `ttl=62`, os dois roteadores da aula 1, e pelo mesmo gateway: o
quadro dela é de `02:1f:23:e7:e9:d5` para o pc1.

A ida e volta, 13.8 ms, é o computador virtual deste laboratório trabalhando, e não uma medida de
rede alguma.

## Por que "padrão"

Um host pode ter mais de uma rota, e a aula 14 lê tabelas com muitas. A rota padrão é a usada
quando nenhuma outra linha casa, o que num PC de escritório comum é todo endereço fora da sua
própria rede. Um host, uma rede, uma saída: é isso que faz um único endereço de gateway bastar para
a maioria das máquinas.

**O gateway tem de estar na rede do próprio host**, porque o host o alcança por ARP e por um quadro,
e não por roteamento. O gateway do pc1, 10.20.10.1, está dentro de 10.20.10.0/24, a rede da `eth0`.
Um gateway fora dessa faixa seria uma rota que precisa de uma rota para ser alcançada.

## O outro sentido da palavra

Fora de uma tabela de rotas, "gateway" ainda nomeia um equipamento: **um que traduz entre dois
sistemas diferentes**, e não apenas encaminha o mesmo protocolo de uma rede para outra. Um gateway
de VoIP transforma uma linha telefônica em chamadas sobre IP; um gateway de e-mail passa mensagens
entre dois sistemas de correio; um gateway numa fábrica ou numa casa inteligente transforma uma rede
de sensores que não fala IP numa que fala. Textos antigos e alguns sistemas operacionais chamam
qualquer roteador de gateway, porque os primeiros roteadores eram exatamente isso, a porta de
entrada para outra rede. Quando ler a palavra, pergunte se ela é um endereço numa configuração ou
uma caixa que muda a língua do tráfego.
