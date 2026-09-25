---
title: Um pacote, dois enlaces
version: 1
---

A aula 1 disse que um roteador monta um quadro novo para o próximo enlace. Aqui está um ping,
capturado dos dois lados do roteador do escritório no mesmo momento: no enlace do laptop e no enlace
do roteador com o provedor.

```
ana@laptop:~$ ping -c 1 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=61 time=0.630 ms

--- 192.0.2.80 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.630/0.630/0.630/0.000 ms
```

Do lado do escritório:

```
ana@laptop:~$ sudo tcpdump -n -e -v -c 2 -i eth0 icmp
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:09.168188 52:54:00:a8:0a:14 > 52:54:00:a8:0a:01, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 16622, offset 0, flags [DF], proto ICMP (1), length 84)
    192.168.10.20 > 192.0.2.80: ICMP echo request, id 60133, seq 1, length 64
13:16:09.168650 52:54:00:a8:0a:01 > 52:54:00:a8:0a:14, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 61, id 54088, offset 0, flags [none], proto ICMP (1), length 84)
    192.0.2.80 > 192.168.10.20: ICMP echo reply, id 60133, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

Do lado do provedor, uma fração de milissegundo depois:

```
ana@router:~$ sudo tcpdump -n -e -v -c 2 -i eth1 icmp
tcpdump: listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:16:09.168440 52:54:00:00:71:02 > 52:54:00:00:71:01, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 63, id 16622, offset 0, flags [DF], proto ICMP (1), length 84)
    203.0.113.2 > 192.0.2.80: ICMP echo request, id 60133, seq 1, length 64
13:16:09.168646 52:54:00:00:71:01 > 52:54:00:00:71:02, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 62, id 54088, offset 0, flags [none], proto ICMP (1), length 84)
    192.0.2.80 > 203.0.113.2: ICMP echo reply, id 60133, seq 1, length 64
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

O `-v` acrescenta os campos do cabeçalho IP entre parênteses, e, lado a lado, eles mostram exatamente
o que o roteador fez:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Um echo request capturado dos dois lados do roteador do escritório. Na LAN do escritório: MAC de 52:54:00:a8:0a:14 para 52:54:00:a8:0a:01, IP de 192.168.10.20 para 192.0.2.80, TTL 64, id do IP 16622. No enlace do ISP: MAC de 52:54:00:00:71:02 para 52:54:00:00:71:01, IP de 203.0.113.2 para 192.0.2.80, TTL 63, id do IP 16622. Os MACs são novos a cada enlace, o endereço de origem foi reescrito pelo NAT, o TTL é um a menos por roteador, e o id igual mostra que é o mesmo pacote.\"><defs><marker id=\"hp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">antes do roteador, na LAN do escritório</text><text x=\"420\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depois do roteador, no enlace do ISP</text><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">MAC de → para</text><rect x=\"170\" y=\"46\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">52:54:00:a8:0a:14 → …:0a:01</text><rect x=\"420\" y=\"46\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">52:54:00:00:71:02 → …:71:01</text><text x=\"420\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">novo a cada enlace</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">IP de → para</text><rect x=\"170\" y=\"98\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.168.10.20 → 192.0.2.80</text><rect x=\"420\" y=\"98\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.2 → 192.0.2.80</text><text x=\"420\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">origem reescrita pelo NAT</text><text x=\"20\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">TTL</text><rect x=\"170\" y=\"150\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">64</text><rect x=\"420\" y=\"150\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">63</text><text x=\"420\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">um a menos por roteador</text><text x=\"20\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">id do IP</text><rect x=\"170\" y=\"202\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16622</text><rect x=\"420\" y=\"202\" width=\"232\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16622</text><text x=\"420\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o mesmo pacote</text></svg>", "caption": "O que um roteador muda e o que mantém. O endereço de destino e o id sobrevivem; os MACs, o TTL e, aqui, o endereço de origem, não.", "same": ["TTL"]}
```

- **Os endereços MAC são todos novos.** No enlace do escritório, o quadro ia do laptop para o
  roteador; no enlace do provedor, vai da outra placa do roteador, `52:54:00:00:71:02`, para o
  roteador do provedor. Cada enlace tem o seu par.
- **O TTL foi de 64 para 63**, a única subtração do roteador. A resposta mostra o mesmo no outro
  sentido: 62 no enlace do provedor, 61 quando chegou ao laptop.
- O `id` do IP é **16622 dos dois lados**. É o número que o remetente deu a este pacote, e é a prova de
  que se trata de um pacote encaminhado, e não de um novo.
- **O endereço de origem mudou**, de `192.168.10.20` para `203.0.113.2`. Um roteador normalmente não
  faz isso. Este faz, e a próxima seção explica por quê.
