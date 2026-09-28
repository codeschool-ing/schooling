---
title: Por que os escritórios não se falam
version: 1
---

O laboratório tem dois escritórios. Na matriz, `laptop` fica em `192.168.10.0/24`, atrás do roteador
`hq`. Na filial, um caixa, `till`, fica em `192.168.20.0/24`, atrás do roteador `branch`. Cada roteador
tem um endereço público, e entre eles há um provedor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 180\" role=\"img\" aria-label=\"Cinco máquinas em fila: laptop em 192.168.10.20 na LAN do escritório, o roteador do escritório hq em 203.0.113.2, o roteador do provedor em 203.0.113.1, o roteador da filial em 198.51.100.2 e o caixa, till, em 192.168.20.30 na LAN da filial. Uma linha tracejada liga hq e branch por cima do provedor: o túnel, tun0, de 10.0.0.1 até 10.0.0.2. O provedor só roteia endereços públicos, então 192.168.x.x não tem para onde ir sem ele.\"><defs><marker id=\"topo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">laptop</text><text x=\"75.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"170\" y=\"40\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"230.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"330\" y=\"40\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"385.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">isp</text><text x=\"385.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.1</text><rect x=\"480\" y=\"40\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">branch</text><text x=\"540.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.2</text><rect x=\"640\" y=\"40\" width=\"100\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"690.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">till</text><text x=\"690.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M130 62 L170 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M290 62 L330 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M440 62 L480 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M600 62 L640 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"75\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">LAN do escritório</text><text x=\"385\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a internet</text><text x=\"690\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">LAN da filial</text><path d=\"M230 84 C 250 140, 520 140, 540 84\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#topo-ah)\"></path><text x=\"385\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">tun0: 10.0.0.1 até 10.0.0.2</text><text x=\"385\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o provedor só roteia endereços públicos: 192.168.x.x não tem para onde ir</text></svg>", "caption": "Os dois escritórios do laboratório. Todo túnel das aulas 1 a 5 é traçado entre hq e branch, ou de um laptop em casa até hq."}
```

Cada escritório chega à internet por NAT, assunto da aula 11 de `networks-addressing`: `hq` reescreve a
origem de tudo que sai com o próprio endereço público. Isso funciona para uma conversa que começa do lado
de dentro. Não resolve nada numa conversa de uma rede privada para outra, e um ping do laptop para o caixa
mostra isso:

```
ana@laptop:~$ ping -c 2 -W 1 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1015ms

ana@laptop:~$ traceroute -n -w 1 -q 1 -m 4 192.168.20.30
traceroute to 192.168.20.30 (192.168.20.30), 4 hops max, 60 byte packets
 1  192.168.10.1  0.054 ms
 2  *
 3  *
 4  *
```

O primeiro salto, `hq`, responde. Depois disso vem o silêncio, e a tabela de rotas do provedor diz por
quê:

```
ana@isp:~$ ip route
192.0.2.0/24 dev eth2 proto kernel scope link src 192.0.2.1 
198.51.100.0/24 dev eth1 proto kernel scope link src 198.51.100.1 
203.0.113.0/24 dev eth0 proto kernel scope link src 203.0.113.1 
```

**O provedor conhece três redes públicas e nenhuma privada.** Um pacote para `192.168.20.30` não
corresponde a nenhuma das rotas dele, então o provedor o descarta. Não é defeito deste provedor. As faixas da RFC
1918 são privadas porque milhares de empresas usam as mesmas, e nenhum roteador da internet saberia de
qual `192.168.20.30` o pacote está falando.

Os roteadores das duas pontas sabem. `hq` sabe que o caixa está atrás de `branch`, e `branch` sabe que
alcança `hq` em `203.0.113.2`. O que falta é um jeito de passar o pacote de um para o outro através de
uma rede que só leva endereços públicos, e é para isso que serve um túnel.
