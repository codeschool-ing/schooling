---
title: Chamado: "o servidor some e volta"
version: 1
---

Uma impressora nova foi instalada hoje de manhã, e desde então o servidor do escritório fica
inalcançável às vezes. A impressora recebeu um endereço digitado à mão, e é o do servidor:

```
ana@laptop:~$ sudo ip neigh flush dev eth0; ping -c 1 192.168.10.10 >/dev/null; ip neigh show 192.168.10.10
192.168.10.10 dev eth0 lladdr 52:54:00:99:00:01 REACHABLE 
ana@laptop:~$ sudo timeout 4 tcpdump -i eth0 -n -e -l arp 2>/dev/null
16:00:38.092218 52:54:00:a8:0a:14 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 42: Request who-has 192.168.10.10 tell 192.168.10.20, length 28
16:00:38.092262 52:54:00:99:00:01 > 52:54:00:a8:0a:14, ethertype ARP (0x0806), length 42: Reply 192.168.10.10 is-at 52:54:00:99:00:01, length 28
16:00:38.092264 52:54:00:a8:0a:0a > 52:54:00:a8:0a:14, ethertype ARP (0x0806), length 42: Reply 192.168.10.10 is-at 52:54:00:a8:0a:0a, length 28

ana@laptop:~$ nc -zv -w 3 192.168.10.10 22
nc: connect to 192.168.10.10 port 22 (tcp) failed: Connection refused
```

O laptop esqueceu os vizinhos e fez ping em `192.168.10.10`, e a tabela ficou com `52:54:00:99:00:01`,
um endereço MAC que o servidor não tem. O tcpdump mostra por quê: um pedido ARP,
`who-has 192.168.10.10`, e **duas respostas**, de duas máquinas diferentes. A da impressora chegou
primeiro, e o laptop acreditou nela. Então a conexão seguinte destinada ao servidor foi para a
impressora, que não tem nada na porta 22 e a recusou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um endereço duplicado. O laptop manda por broadcast um pedido ARP: quem tem 192.168.10.10? Duas máquinas respondem. A impressora, recém-ligada, responde primeiro, com 52:54:00:99:00:01; o servidor responde com 52:54:00:a8:0a:0a. O laptop ficou com a resposta da impressora, então as conexões dele destinadas ao servidor foram para a impressora, que as recusou.\"><defs><marker id=\"dp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"32\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"560\" y=\"20\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">impressora, recém-ligada</text><text x=\"572\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.10</text><rect x=\"560\" y=\"150\" width=\"150\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"572\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><text x=\"572\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.10.10</text><path d=\"M140 108 L558 48\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\" stroke-dasharray=\"4 4\"></path><path d=\"M140 118 L558 172\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\" stroke-dasharray=\"4 4\"></path><text x=\"150\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quem tem 192.168.10.10?</text><path d=\"M558 62 L142 124\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\"></path><text x=\"360\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">is-at 52:54:00:99:00:01</text><path d=\"M558 186 L142 132\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\"></path><text x=\"300\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">is-at 52:54:00:a8:0a:0a</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o laptop ficou com a resposta da impressora</text></svg>", "caption": "Dois aparelhos com um endereço respondem os dois ao ARP, e cada cliente acredita em quem ouviu. Qual é pode mudar de um minuto para o outro, e é por isso que um endereço duplicado parece um defeito que vai e volta."}
```

Em outro momento, ou em outro PC, o servidor pode ser ouvido primeiro, e é por isso que a reclamação é
de que as coisas somem e voltam. **Duas respostas para um pedido ARP são a prova**. O MAC da resposta
errada leva ao aparelho: a tabela do switch diz em que porta ele está, e a primeira metade de um MAC diz
o fabricante. O conserto é um endereço fora da faixa que o DHCP distribui, ou uma reserva no DHCP, para
que nenhum endereço seja dado duas vezes.
