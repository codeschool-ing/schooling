---
title: fe80, o endereço que toda interface dá a si mesma
version: 1
---

No IPv4 uma interface não tem endereço até que alguém ou algo lhe dê um. **No IPv6 toda interface dá
a si mesma um endereço link-local no instante em que sobe**, sem servidor e sem configuração.
Endereços link-local ficam em `fe80::/10` (na prática, sempre `fe80::/64`), valem só no próprio
enlace, e nenhum roteador os encaminha. Eles existem para que máquinas do mesmo cabo consigam sempre
conversar entre si, e o IPv6 precisa disso antes de qualquer outra coisa funcionar: as próximas duas
seções mostram um roteador se anunciando e um vizinho sendo encontrado, os dois a partir de endereços
link-local.

A placa do pc1 e o seu endereço link-local:

```
ana@pc1:~$ ip link show eth0
28: eth0@if27: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
ana@pc1:~$ ip -6 addr show eth0 scope link
28: eth0@if27: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns sw1
    inet6 fe80::25:70ff:febc:29c6/64 scope link 
       valid_lft forever preferred_lft forever
```

O endereço MAC é `02:25:70:bc:29:c6` e o endereço link-local é `fe80::25:70ff:febc:29c6`. Os dígitos do
MAC estão ali, quase todos. **O Linux montou o identificador de interface a partir do MAC por uma
regra chamada EUI-64 modificado**:

1. divida os seis bytes do MAC ao meio: `02:25:70` e `bc:29:c6`;
2. ponha `ff:fe` no meio, o que dá oito bytes, 64 bits;
3. inverta o sétimo bit do primeiro byte, o que diz se um MAC foi atribuído por um fabricante ou
   localmente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 252\" role=\"img\" aria-label=\"Como o pc1 montou o seu endereço link-local a partir do endereço MAC, em três passos. Primeiro, o endereço MAC 02:25:70:bc:29:c6, desenhado como seis bytes com um vão no meio. Segundo, ff e fe são inseridos no vão, o que dá oito bytes: 02, 25, 70, ff, fe, bc, 29, c6. Terceiro, o bit 7 do primeiro byte é invertido, então 02, em binário 00000010, vira 00, em binário 00000000, o que dá 00, 25, 70, ff, fe, bc, 29, c6. Esses 64 bits depois de fe80::/64 formam o endereço link-local fe80::25:70ff:febc:29c6.\"><text x=\"20\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o endereço MAC do pc1</text><rect x=\"290\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">02</text><rect x=\"340\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">25</text><rect x=\"390\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">70</text><rect x=\"540\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bc</text><rect x=\"590\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">29</text><rect x=\"640\" y=\"20\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"662\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c6</text><text x=\"20\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">insira ff:fe no meio</text><rect x=\"290\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">02</text><rect x=\"340\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">25</text><rect x=\"390\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">70</text><rect x=\"440\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ff</text><rect x=\"490\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">fe</text><rect x=\"540\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bc</text><rect x=\"590\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">29</text><rect x=\"640\" y=\"78\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"662\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c6</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">inverta o bit 7 do primeiro byte</text><text x=\"20\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">00000010 → 00000000</text><rect x=\"290\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">00</text><rect x=\"340\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">25</text><rect x=\"390\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"412\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">70</text><rect x=\"440\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"462\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ff</text><rect x=\"490\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">fe</text><rect x=\"540\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"562\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bc</text><rect x=\"590\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">29</text><rect x=\"640\" y=\"136\" width=\"44\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"662\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c6</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o endereço link-local</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fe80::/64 + o identificador de 64 bits</text><text x=\"290\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--phosphor)\">fe80::25:70ff:febc:29c6</text></svg>", "caption": "EUI-64 modificado: o MAC dividido ao meio, ff:fe no vão, um bit invertido. Os zeros à esquerda de 0025 caem depois, como em qualquer grupo."}
```

O primeiro byte aqui é `02`, em binário `00000010`, e o sétimo bit é o 1 dele, então invertê-lo dá
`00`. O laboratório dá às suas máquinas MACs que começam com `02`, a marca de um endereço administrado
localmente. Um MAC gravado por um fabricante tem esse bit em 0, e a inversão o põe em 1: uma placa
cujo MAC começa com `00:1a` recebe um identificador que começa com `021a`. **O `ff:fe` no meio é a
impressão digital**: um endereço IPv6 com `ff:fe` no quarto e no quinto bytes do identificador foi
montado a partir de um MAC.

Essa impressão digital também é um problema de privacidade. Um notebook que monta todo endereço a
partir do MAC leva os mesmos 64 bits de rede em rede, e quem vê os seus endereços consegue segui-lo.
Muitos sistemas hoje montam o identificador dos endereços globais a partir de bits aleatórios. Neste
laboratório o Linux usou EUI-64, e é por isso que a aritmética fica visível.

Agora tente alcançar o r1 pelo endereço link-local:

```
root@r1:~# ip -6 addr show eth0 scope link
34: eth0@if33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns sw1
    inet6 fe80::1f:23ff:fee7:e9d5/64 scope link 
       valid_lft forever preferred_lft forever
ana@pc1:~$ ping -c 1 fe80::1f:23ff:fee7:e9d5
ping: Warning: IPv6 link-local address on ICMP datagram socket may require ifname or scope-id => use: address%<ifname|scope-id>
PING fe80::1f:23ff:fee7:e9d5 (fe80::1f:23ff:fee7:e9d5) 56 data bytes

--- fe80::1f:23ff:fee7:e9d5 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@pc1:~$ ping -c 1 fe80::1f:23ff:fee7:e9d5%eth0
PING fe80::1f:23ff:fee7:e9d5%eth0 (fe80::1f:23ff:fee7:e9d5%eth0) 56 data bytes
64 bytes from fe80::1f:23ff:fee7:e9d5%eth0: icmp_seq=1 ttl=64 time=2.44 ms

--- fe80::1f:23ff:fee7:e9d5%eth0 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 2.436/2.436/2.436/0.000 ms
```

O primeiro ping imprimiu um aviso e perdeu o pacote. O segundo acrescentou `%eth0` e teve resposta. A
diferença é a essência de um endereço link-local: **toda interface tem um em `fe80::/64`, então o
endereço sozinho não diz por qual enlace mandar o pacote**. Uma máquina com duas placas tem dois
enlaces que, para o seu roteamento, contêm `fe80::1f:23ff:fee7:e9d5`. O `%eth0` é a **zona**, a
interface a que o endereço pertence, e o aviso que o ping imprimiu diz exatamente isso,
`use: address%<ifname|scope-id>`. Endereços globais nunca precisam de zona; os link-local precisam,
sempre que um programa tem de ser informado de uma.

O próprio endereço link-local do r1, `fe80::1f:23ff:fee7:e9d5`, saiu do MAC `02:1f:23:e7:e9:d5` pelos
mesmos três passos. Guarde-o: na próxima seção ele aparece como gateway padrão de todos os PCs do
escritório.
