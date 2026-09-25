---
title: Sim, não, e nada
version: 1
---

Uma porta TCP pode responder a uma conexão de três jeitos, e um firewall decide qual dos dois últimos
você recebe. O servidor web ganha um firewall com duas regras, uma que **descarta** (*drop*) tentativas
na porta 3306 e outra que as **rejeita** (*reject*) na 5432, mais a regra UDP que a seção 06 usou:

```
ana@www:~$ sudo nft add table inet fw
ana@www:~$ sudo nft add chain inet fw input '{ type filter hook input priority 0; }'
ana@www:~$ sudo nft add rule inet fw input tcp dport 3306 drop
ana@www:~$ sudo nft add rule inet fw input tcp dport 5432 reject with tcp reset
ana@www:~$ sudo nft add rule inet fw input udp dport 9998 drop
```

Depois, três tentativas do laptop: 8080, onde nada escuta; 5432, rejeitada; 3306, descartada.

```
ana@laptop:~$ nc -zv -w 3 192.0.2.80 8080
nc: connect to 192.0.2.80 port 8080 (tcp) failed: Connection refused
ana@laptop:~$ nc -zv -w 3 192.0.2.80 5432
nc: connect to 192.0.2.80 port 5432 (tcp) failed: Connection refused
ana@laptop:~$ time nc -zv -w 3 192.0.2.80 3306
nc: connect to 192.0.2.80 port 3306 (tcp) timed out: Operation now in progress

real    0m3.005s
user    0m0.002s
sys     0m0.000s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Três jeitos de uma porta TCP responder. Nada escutando: o laptop manda SYN, o servidor responde RST, e o nc informa conexão recusada na hora. Uma regra de firewall reject with tcp reset: SYN, depois RST, recusada na hora, igual à primeira. Uma regra de firewall drop: o laptop manda SYN três vezes, nada volta, e o nc informa timeout depois do tempo limite.\"><defs><marker id=\"an-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que há na porta</text><text x=\"290\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o laptop manda</text><text x=\"420\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o www responde</text><text x=\"560\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o nc desiste</text><rect x=\"14\" y=\"40\" width=\"692\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada escuta: recusada</text><text x=\"290\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SYN</text><text x=\"420\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RST</text><text x=\"560\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">na hora</text><rect x=\"14\" y=\"86\" width=\"692\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reject with tcp reset: recusada</text><text x=\"290\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SYN</text><text x=\"420\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RST</text><text x=\"560\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">na hora</text><rect x=\"14\" y=\"132\" width=\"692\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">drop: timeout</text><text x=\"290\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SYN, SYN, SYN</text><text x=\"420\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada</text><text x=\"560\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">depois do timeout</text></svg>", "caption": "Um reset e uma porta fechada parecem iguais de fora. O drop é o único dos três que faz o cliente esperar, e é o que um firewall costuma escolher."}
```

A porta 8080 e a porta 5432 dão a mesma resposta, `Connection refused`, na hora. No fio, é um SYN que
sai e um RST que volta:

```
ana@laptop:~$ sudo tcpdump -n -i eth0 -c 2 tcp port 8080
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:27:24.548279 IP 192.168.10.20.55428 > 192.0.2.80.8080: Flags [S], seq 2740136733, win 64240, options [mss 1460,sackOK,TS val 1967779466 ecr 0,nop,wscale 10], length 0
13:27:24.548594 IP 192.0.2.80.8080 > 192.168.10.20.55428: Flags [R.], seq 0, ack 2740136734, win 0, length 0
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**De fora, um firewall que rejeita é indistinguível de uma porta fechada.** A porta 3306 é a diferente:
o nc esperou os três segundos inteiros que recebeu (`real 0m3.006s`), e o lado do laptop no fio mostra
por quê:

```
ana@laptop:~$ sudo tcpdump -n -i eth0 -c 3 tcp port 3306
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
13:27:17.999289 IP 192.168.10.20.42742 > 192.0.2.80.3306: Flags [S], seq 3033148130, win 64240, options [mss 1460,sackOK,TS val 2247737711 ecr 0,nop,wscale 10], length 0
13:27:19.022502 IP 192.168.10.20.42742 > 192.0.2.80.3306: Flags [S], seq 3033148130, win 64240, options [mss 1460,sackOK,TS val 2247738735 ecr 0,nop,wscale 10], length 0
13:27:20.046492 IP 192.168.10.20.42742 > 192.0.2.80.3306: Flags [S], seq 3033148130, win 64240, options [mss 1460,sackOK,TS val 2247739759 ecr 0,nop,wscale 10], length 0
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

O mesmo SYN, com o mesmo número de sequência, mandado três vezes com cerca de um segundo de intervalo,
e nem um pacote de volta. O kernel do laptop continua tentando porque um SYN perdido é normal. Um
navegador espera mais que o nc, em geral um minuto ou mais, e é por isso que uma porta descartada parece
um programa travado.

As duas escolhas do firewall têm cada uma a sua razão:

- **Drop** não conta nada a um estranho, nem que existe uma máquina ali, e torna lenta uma varredura de
  portas. É a escolha comum do lado da internet.
- **Reject** responde na hora, e um programa legítimo falha rápido, com um erro claro, em vez de
  travar. É a escolha mais gentil dentro de uma rede.

**Para o suporte, o tempo é a pista.** `Connection refused` na hora quer dizer que o caminho funciona e
a porta está fechada, e a pergunta vai para quem cuida do serviço. Um timeout quer dizer que algo entre
você e o serviço está descartando a tentativa em silêncio, e a pergunta vai para quem cuida do
firewall.
