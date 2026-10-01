---
title: O tag 802.1Q, quatro bytes no cabeçalho
version: 1
---

A marca que um tronco põe num quadro é definida pelo padrão IEEE **802.1Q**, e é pequena o bastante
para ser vista inteira. O sw1 escutou a p24 enquanto o pc1 pingava o pc3 e o pc2 pingava o pc4; a
captura terminou depois dos dois pings, então a saída dela vem por último:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 3.085/3.085/3.085/0.000 ms
ana@pc2:~$ ping -c 1 -q 10.20.20.24
PING 10.20.20.24 (10.20.20.24) 56(84) bytes of data.

--- 10.20.20.24 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 1.306/1.306/1.306/0.000 ms
root@sw1:~# timeout 8 tcpdump -n -e -i p24 -c 4 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on p24, link-type EN10MB (Ethernet), snapshot length 262144 bytes
09:00:36.437905 02:25:70:bc:29:c6 > 02:d9:6b:02:17:20, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.20.10.21 > 10.20.10.23: ICMP echo request, id 89, seq 1, length 64
09:00:36.438786 02:d9:6b:02:17:20 > 02:25:70:bc:29:c6, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4 (0x0800), 10.20.10.23 > 10.20.10.21: ICMP echo reply, id 89, seq 1, length 64
09:00:37.346964 02:fd:f2:d2:63:ba > 02:25:46:c1:26:7d, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4 (0x0800), 10.20.20.22 > 10.20.20.24: ICMP echo request, id 90, seq 1, length 64
09:00:37.347183 02:25:46:c1:26:7d > 02:fd:f2:d2:63:ba, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4 (0x0800), 10.20.20.24 > 10.20.20.22: ICMP echo reply, id 90, seq 1, length 64
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

Leia o primeiro quadro da esquerda para a direita. A origem é `02:25:70:bc:29:c6`, o pc1, e o
destino `02:d9:6b:02:17:20`, o pc3. Onde um quadro sem tag diria o que carrega, este diz `ethertype
802.1Q (0x8100)`, depois `vlan 10, p 0`, e só então `ethertype IPv4 (0x0800)` e o pacote IP. O
quadro tem 102 bytes. Os dois quadros do pc2 levam `vlan 20` e também têm 102 bytes.

Agora a mesma conversa onde ela chega, na porta de acesso do pc3:

```
ana@pc1:~$ ping -c 1 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.696/1.696/1.696/0.000 ms
root@pc3:~# timeout 6 tcpdump -n -e -i eth0 -c 2 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
09:00:41.501029 02:25:70:bc:29:c6 > 02:d9:6b:02:17:20, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.23: ICMP echo request, id 91, seq 1, length 64
09:00:41.501768 02:d9:6b:02:17:20 > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 10.20.10.23 > 10.20.10.21: ICMP echo reply, id 91, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

Os mesmos dois endereços MAC, nada de `802.1Q`, nada de `vlan`, e um tamanho de 98. **102 − 98 = 4:
o tag tem quatro bytes, posto pelo sw1 quando o quadro entra no tronco e tirado pelo sw2 antes de o
quadro sair por uma porta de acesso.** O pc1 e o pc3 nunca o veem, e é por isso que nada teve de
mudar em nenhum dos dois PCs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"O mesmo quadro de duas formas, e depois o tag bit a bit. Sem tag, na porta de acesso do pc3, 98 bytes: MAC de destino, 6 bytes; MAC de origem, 6 bytes; EtherType 0x0800 para IPv4, 2 bytes; o pacote IP, 84 bytes. Com tag, no tronco p24, 102 bytes: MAC de destino; MAC de origem; depois o tag de 4 bytes, feito de TPID 0x8100 e TCI, 2 bytes cada; depois EtherType 0x0800 e o pacote IP. O tag, bit a bit: TPID, 16 bits, no lugar onde estaria o EtherType; PCP, 3 bits, prioridade de 0 a 7; DEI, 1 bit, descartar antes sob congestionamento; VID, 12 bits, o número da VLAN de 1 a 4094.\"><defs><marker id=\"v19g-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem tag, na porta de acesso do pc3: 98 bytes</text><rect x=\"20\" y=\"24\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dst MAC</text><text x=\"80.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 bytes</text><rect x=\"140\" y=\"24\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">src MAC</text><text x=\"200.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 bytes</text><rect x=\"260\" y=\"24\" width=\"100\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0x0800</text><text x=\"310.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tipo: IPv4</text><rect x=\"360\" y=\"24\" width=\"340\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pacote IP, 84 bytes</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">com tag, no tronco p24: 102 bytes</text><text x=\"350\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o tag: 4 bytes</text><rect x=\"20\" y=\"100\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dst MAC</text><text x=\"80.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 bytes</text><rect x=\"140\" y=\"100\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">src MAC</text><text x=\"200.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 bytes</text><rect x=\"260\" y=\"100\" width=\"90\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"305.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TPID</text><text x=\"305.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0x8100</text><rect x=\"350\" y=\"100\" width=\"90\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TCI</text><text x=\"395.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 bytes</text><rect x=\"440\" y=\"100\" width=\"100\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"490.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0x0800</text><text x=\"490.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tipo: IPv4</text><rect x=\"540\" y=\"100\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pacote IP, 84 bytes</text><line x1=\"260\" y1=\"138\" x2=\"60\" y2=\"188\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"440\" y1=\"138\" x2=\"660\" y2=\"188\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o tag, bit a bit</text><rect x=\"60\" y=\"188\" width=\"220\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">TPID</text><text x=\"170.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">16 bits</text><rect x=\"280\" y=\"188\" width=\"120\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PCP</text><text x=\"340.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 bits</text><rect x=\"400\" y=\"188\" width=\"100\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DEI</text><text x=\"450.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 bit</text><rect x=\"500\" y=\"188\" width=\"160\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"580.0\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">VID</text><text x=\"580.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">12 bits</text><text x=\"170\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">onde estava o EtherType</text><text x=\"340\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">prioridade 0 a 7</text><text x=\"450\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">descartar antes</text><text x=\"580\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">VLAN 1 a 4094</text></svg>", "caption": "O mesmo quadro do ping numa porta de acesso e no tronco. O switch insere quatro bytes depois do endereço de origem e os retira de novo antes de o quadro chegar a um PC.", "same": ["1 bit", "12 bits", "16 bits", "2 bytes", "3 bits", "6 bytes"]}
```

Os quatro bytes são dois campos de dois bytes cada. O primeiro é o **TPID** (*tag protocol
identifier*, identificador do protocolo do tag), sempre `0x8100`, e ele fica exatamente onde um
quadro sem tag guarda o EtherType. Essa posição é proposital: um host que não sabe nada de VLANs
lê `0x8100` como um protocolo que ele não trata e ignora o quadro, em vez de ler o tag como se fosse
o começo de um pacote IP.

O segundo é o **TCI** (*tag control information*, informação de controle do tag), dezesseis bits
divididos em três:

- PCP (*priority code point*), três bits de prioridade, de 0 a 7. É o `p 0` na linha do tcpdump, e
  é como os quadros de uma VLAN de voz pedem para ser atendidos antes dos de uma transferência de
  arquivo. Todo quadro deste laboratório leva 0, porque nada pediu outra coisa.
- DEI (*drop eligible indicator*), um bit dizendo que o quadro pode ser descartado primeiro quando
  um enlace está congestionado.
- VID (*VLAN identifier*), doze bits com o número da VLAN: o `vlan 10` e o `vlan 20` acima.

**Doze bits dão 4096 valores, e dois são reservados**: 0 quer dizer que o quadro leva uma prioridade
e nenhuma VLAN, e 4095 fica guardado pelo padrão. Sobram 4094 VLANs utilizáveis, numeradas de 1 a
4094, e esse é um teto rígido para qualquer rede construída sobre este tag. Redes que precisam de
mais — um provedor mantendo separadas as VLANs dos clientes, um data center com milhares de
inquilinos — empilham um segundo tag (IEEE 802.1ad, muitas vezes chamado de QinQ) ou levam um número
mais longo em outro cabeçalho, como os 24 bits do VXLAN. Nenhum dos dois roda neste laboratório.

Vale saber duas consequências de acrescentar bytes a um quadro. O maior quadro Ethernet cresceu de
1518 para 1522 bytes para dar lugar ao tag, então um equipamento num tronco tem de aceitar quadros
quatro bytes mais longos do que uma porta de acesso jamais entrega. E a soma de verificação no fim
do quadro cobre todos os bytes, então o switch a recalcula toda vez que põe ou tira um tag; o
tcpdump no Linux não mostra essa soma, e é por isso que os tamanhos acima são 98 e 102 e não quatro
bytes a mais.
