---
title: "Quatro mensagens: discover, offer, request, acknowledge"
version: 1
---

Um PC sem endereço recebe um em quatro mensagens, conhecidas pelas iniciais como **DORA**:
*discover* (descobrir), *offer* (oferecer), *request* (pedir) e *acknowledge* (confirmar). O cliente
não consegue endereçar o servidor, porque não sabe nem o endereço do servidor nem o seu, então
começa perguntando a todo mundo. A conversa corre sobre UDP, da porta 68 no cliente para a porta 67
no servidor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"As quatro mensagens DHCP entre o pc1, o cliente, e o srv, o servidor DHCP, como o tcpdump do srv as imprimiu. Uma: DHCPDISCOVER de 0.0.0.0 porta 68 para 255.255.255.255 porta 67, um broadcast perguntando por qualquer servidor. Duas: DHCPOFFER de 10.20.10.10 porta 67 para 10.20.10.100 porta 68, uma oferta enviada ao endereço de hardware do pc1. Três: DHCPREQUEST, de novo de 0.0.0.0 para 255.255.255.255, um broadcast dizendo qual oferta foi aceita. Quatro: DHCPACK de 10.20.10.10 para 10.20.10.100, a confirmação com as opções. Depois disso o pc1 tem 10.20.10.100/24, uma rota padrão e um servidor de nomes.\"><defs><marker id=\"dd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"105\" y=\"12\" width=\"170\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"190\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cliente</text><line x1=\"190\" y1=\"56\" x2=\"190\" y2=\"276\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 4\"></line><rect x=\"445\" y=\"12\" width=\"170\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv  10.20.10.10</text><text x=\"530\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">servidor</text><line x1=\"530\" y1=\"56\" x2=\"530\" y2=\"276\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 4\"></line><line x1=\"192\" y1=\"92\" x2=\"526\" y2=\"92\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dd-ah)\"></line><text x=\"360\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DHCPDISCOVER</text><text x=\"360\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0.0.0.68 &gt; 255.255.255.255.67</text><text x=\"14\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"546\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">broadcast: algum servidor?</text><line x1=\"528\" y1=\"144\" x2=\"194\" y2=\"144\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#dd-ah)\"></line><text x=\"360\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DHCPOFFER</text><text x=\"360\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.10.67 &gt; 10.20.10.100.68</text><text x=\"14\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"546\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">oferta, para o MAC do pc1</text><line x1=\"192\" y1=\"196\" x2=\"526\" y2=\"196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dd-ah)\"></line><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DHCPREQUEST</text><text x=\"360\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0.0.0.68 &gt; 255.255.255.255.67</text><text x=\"14\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"546\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">broadcast: fico com esta</text><line x1=\"528\" y1=\"248\" x2=\"194\" y2=\"248\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#dd-ah)\"></line><text x=\"360\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DHCPACK</text><text x=\"360\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.10.10.67 &gt; 10.20.10.100.68</text><text x=\"14\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"546\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">confirmado, com opções</text><text x=\"360\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o pc1 assume 10.20.10.100/24, uma rota padrão e um servidor de nomes</text></svg>", "caption": "O DORA como o tcpdump do srv o viu: as duas mensagens do cliente são broadcasts de 0.0.0.0, e as duas do servidor vão para o endereço oferecido."}
```

Aqui está o pc1 pedindo, com o cliente da ISC, o `dhclient`, e `-v` para que ele imprima cada passo:

```
ana@pc1:~$ sudo dhclient -v eth0
Internet Systems Consortium DHCP Client 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/

Listening on LPF/eth0/02:25:70:bc:29:c6
Sending on   LPF/eth0/02:25:70:bc:29:c6
Sending on   Socket/fallback
xid: warning: no netdev with useable HWADDR found for seed's uniqueness enforcement
xid: rand init seed (0x6ac49ffe) built using gethostid
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 3 (xid=0xe264ec04)
DHCPOFFER of 10.20.10.100 from 10.20.10.10
DHCPREQUEST for 10.20.10.100 on eth0 to 255.255.255.255 port 67 (xid=0x4ec64e2)
DHCPACK of 10.20.10.100 from 10.20.10.10 (xid=0xe264ec04)
bound to 10.20.10.100 -- renewal in 291 seconds.
```

O cabeçalho e as duas linhas `xid:` são o cliente iniciando e semeando o número de transação
aleatório que ele usa para reconhecer as respostas destinadas a ele. Depois vêm as quatro linhas que
importam:

- `DHCPDISCOVER on eth0 to 255.255.255.255 port 67`: para o endereço de broadcast, de modo que toda
  máquina da sub-rede o recebe.
- `DHCPOFFER of 10.20.10.100 from 10.20.10.10`: um servidor propõe um endereço.
- `DHCPREQUEST for 10.20.10.100 on eth0 to 255.255.255.255`: o cliente pede aquele endereço, de novo
  para todo mundo.
- `DHCPACK of 10.20.10.100 from 10.20.10.10`: o servidor confirma, e o cliente assume o endereço,
  `bound to 10.20.10.100 -- renewal in 291 seconds`.

**O pedido vai para todo mundo, embora o cliente já saiba qual servidor respondeu.** Se dois
servidores fizeram ofertas, o pedido diz qual foi escolhido, e o broadcast avisa os outros para
devolverem seus endereços. O número de transação amarra as quatro: o DISCOVER e o ACK carregam
`xid=0xe264ec04`. A linha do REQUEST imprime `0x4ec64e2`, que são os mesmos quatro bytes na ordem
inversa (`e2 64 ec 04` contra `04 ec 64 e2`), uma peculiaridade de como este cliente imprime aquela
linha.

Enquanto isso, no srv, um `tcpdump` iniciado num segundo terminal imprimiu os quatro pacotes como o
servidor os viu. Ele aparece depois do comando do pc1 porque imprimiu quando terminou:

```
root@srv:~# timeout 15 tcpdump -n -i eth0 -c 4 port 67 or port 68
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:20:31.505285 IP 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 02:25:70:bc:29:c6, length 300
08:20:32.541960 IP 10.20.10.10.67 > 10.20.10.100.68: BOOTP/DHCP, Reply, length 300
08:20:32.552098 IP 0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 02:25:70:bc:29:c6, length 300
08:20:32.558801 IP 10.20.10.10.67 > 10.20.10.100.68: BOOTP/DHCP, Reply, length 300
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

As duas mensagens do cliente saem de `0.0.0.0.68`: **um endereço todo de zeros, porque o cliente
ainda não tem nenhum**, para `255.255.255.255.67`. As duas respostas do servidor vão para
`10.20.10.100.68`, o endereço oferecido, que o pc1 ainda não tem. O servidor não pode perguntar por
ARP quem tem um endereço que ninguém tem, então manda o quadro para o endereço de hardware que veio
no pedido: `Request from 02:25:70:bc:29:c6` está nos dois pedidos exatamente por isso.

Quando o ACK chegou, o pc1 estava assim:

```
ana@pc1:~$ ip -br addr show eth0
eth0@if123       UP             10.20.10.100/24 fe80::25:70ff:febc:29c6/64 
ana@pc1:~$ ip route
default via 10.20.10.1 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.100 
ana@pc1:~$ cat /etc/resolv.conf
nameserver 10.20.10.10
```

Três coisas chegaram naquela troca, não uma. O endereço, `10.20.10.100/24`, e com a máscara dele a
rota para a própria sub-rede. Uma rota padrão via 10.20.10.1, o roteador. E um servidor de nomes,
10.20.10.10, escrito em `/etc/resolv.conf`. **O DHCP entrega uma configuração inteira, e o endereço é
só a primeira linha dela.** Cada item além do endereço é uma *opção* na resposta, e o arquivo do
servidor decide quais opções são enviadas, que é o assunto da próxima seção.
