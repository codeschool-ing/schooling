---
title: O arquivo que nunca chega
version: 1
---

O caso resolvido é o que a aula 1 prometeu: um buraco negro de PMTU. Os dois escritórios estão ligados
por um túnel WireGuard montado como na aula 4, `wg0` em `hq` e em `branch`. O chamado da filial é do tipo
que ninguém consegue reproduzir por telefone: **a página web do servidor de arquivos abre, e um download
dele nunca termina.** As duas metades são verdade:

```
ana@till:~$ curl -sS -m 5 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/
200 16 bytes
ana@till:~$ curl -sS -m 8 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin
curl: (28) Operation timed out after 8002 milliseconds with 0 bytes received
000 0 bytes
```

A página chega, status 200 e 16 bytes. O download, `big.bin`, recebe **0 bytes em 8002 milissegundos**,
e o curl desiste no limite que recebeu. O nome, a rota, o túnel e o servidor web funcionam, ou a página
pequena também teria falhado. **O que quer que esteja errado depende do tamanho.**

Uma captura no lado do escritório de `hq`, por onde os pacotes do servidor de arquivos passam a caminho
do túnel, mostra a conversa:

```
ana@hq:~$ sudo tcpdump -n -t -i eth0 -c 9 tcp port 80 and host 192.168.20.30
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 192.168.20.30.41212 > 192.168.10.10.80: Flags [S], seq 3890829214, win 64240, options [mss 1460,sackOK,TS val 1270073489 ecr 0,nop,wscale 10], length 0
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [S.], seq 288962322, ack 3890829215, win 65160, options [mss 1460,sackOK,TS val 797129185 ecr 1270073489,nop,wscale 10], length 0
IP 192.168.20.30.41212 > 192.168.10.10.80: Flags [.], ack 1, win 63, options [nop,nop,TS val 1270073490 ecr 797129185], length 0
IP 192.168.20.30.41212 > 192.168.10.10.80: Flags [P.], seq 1:84, ack 1, win 63, options [nop,nop,TS val 1270073490 ecr 797129185], length 83: HTTP: GET /big.bin HTTP/1.1
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 0
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], seq 1:1449, ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 1448: HTTP: HTTP/1.1 200 OK
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], seq 1449:2897, ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 1448: HTTP
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], seq 2897:4345, ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 1448: HTTP
IP 192.168.10.10.80 > 192.168.20.30.41212: Flags [.], seq 4345:5793, ack 84, win 64, options [nop,nop,TS val 797129185 ecr 1270073490], length 1448: HTTP
9 packets captured
17 packets received by filter
0 packets dropped by kernel
```

Leia em três partes. O handshake se completa, `[S]`, `[S.]`, `[.]`, e os dois lados anunciam `mss
1460`, o maior segmento que cada um aceita, dimensionado para uma Ethernet comum de 1500 bytes. O pedido
atravessa, 83 bytes de `GET /big.bin`, e `files` o confirma com `ack 84`. Aí `files` começa a enviar, e
**todo segmento leva 1448 bytes**: 1460 menos 12 bytes da opção de timestamp do TCP, o que, com 32 bytes
de cabeçalho TCP e 20 de IP, dá um pacote de 1500 bytes. A captura parou em nove pacotes, como o `-c 9`
mandou, e nesses nove o caixa nunca confirma um byte de dados.

Um pacote de 1500 bytes está para entrar num túnel, então a hipótese é tamanho, e o ping testa tamanho
diretamente. De `files` para o caixa, com Don't Fragment ligado:

```
ana@files:~$ ping -c 1 -M do -s 1392 192.168.20.30 | tail -n 2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.563/0.563/0.563/0.000 ms
ana@files:~$ ping -c 1 -W 2 -M do -s 1400 192.168.20.30 | tail -n 2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@hq:~$ ip link show wg0 | head -n 1
2: wg0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1420 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 500
```

`-s 1392` gera um pacote de 1420 bytes, e ele atravessa. `-s 1400` gera 1428, e ele se perde. O MTU do
túnel é **1420**, o padrão que o `wg-quick` define, que deixa espaço para os cabeçalhos do próprio
WireGuard num enlace de 1500 bytes. Até aqui é o normal: um pacote grande demais para o próximo enlace,
com Don't Fragment ligado, é descartado. O que não é normal é o silêncio. Na aula 1 o mesmo experimento
pelo túnel IP-in-IP imprimiu `Frag needed and DF set (mtu = 1480)`, e a linha de estatística dizia `+1
errors`. Aqui a linha diz `0 received` e mais nada. **O roteador descartou o pacote, e a mensagem dele
explicando o porquê nunca chegou.**

Uma mensagem que o roteador envia sai pelo caminho de saída dele mesmo, então é lá que se procura:

```
ana@hq:~$ sudo nft list ruleset | grep -B 3 destination-unreachable
table ip hardening {
	chain out {
		type filter hook output priority filter; policy accept;
		icmp type destination-unreachable drop
```

Uma tabela chamada `hardening`, uma chain no hook `output` do roteador e uma regra: descartar todo ICMP
destination unreachable que o próprio `hq` envia. "Fragmentation needed" é um tipo de destination
unreachable, então **a regra descarta exatamente a mensagem de que a descoberta do MTU do caminho
depende**. `files` manda segmentos de 1448 bytes e `hq` descarta cada um na entrada do `wg0`. A explicação
é jogada fora na saída, e `files` continua tentando um tamanho que nunca vai caber até o curl do caixa
desistir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 364\" role=\"img\" aria-label=\"Uma sequência entre três máquinas: till em 192.168.20.30, hq, cujo túnel wg0 tem MTU de 1420, e files em 192.168.10.10. O handshake atravessa: SYN com mss 1460, SYN-ACK com mss 1460, depois GET /big.bin. files manda um segmento de 1448 bytes de dados, um pacote de 1500; ele para em hq, grande demais para o wg0, e é descartado. A mensagem ICMP de hq, fragmentation needed com mtu 1420, é descartada pela regra hardening na saída de hq antes de chegar a files. O próximo segmento de 1448 bytes tem o mesmo destino, e o caixa recebe 0 bytes em 8002 ms.\"><defs><marker id=\"bh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">till</text><text x=\"110.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.20.30</text><rect x=\"300\" y=\"14\" width=\"180\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"390.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">wg0 mtu 1420</text><rect x=\"600\" y=\"14\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"670.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">files</text><text x=\"670.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">192.168.10.10</text><path d=\"M110 54 L110 306\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M390 54 L390 306\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M670 54 L670 306\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M110 80 L664 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"390.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SYN, mss 1460</text><path d=\"M670 110 L116 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"390.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SYN-ACK, mss 1460</text><path d=\"M110 140 L664 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"390.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /big.bin</text><path d=\"M670 180 L402 180\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"530\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1448 bytes de dados: um pacote de 1500</text><path d=\"M386.5 176.5 L393.5 183.5 M386.5 183.5 L393.5 176.5\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"378\" y=\"183\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">grande demais para o wg0: descartado</text><path d=\"M398 230 L560 230\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#bh-ah)\"></path><text x=\"480\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ICMP: fragmentation needed, mtu 1420</text><path d=\"M564.5 226.5 L571.5 233.5 M564.5 233.5 L571.5 226.5\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"480\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">descartado pela regra hardening na saída de hq</text><path d=\"M670 280 L402 280\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#bh-ah)\"></path><text x=\"530\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o próximo segmento de 1448, o mesmo destino</text><path d=\"M386.5 276.5 L393.5 283.5 M386.5 283.5 L393.5 276.5\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><rect x=\"40\" y=\"318\" width=\"170\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"335\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">0 bytes em 8002 ms</text></svg>", "caption": "O buraco negro. Pacotes pequenos atravessam, o primeiro pacote cheio é descartado no túnel, e a mensagem que diria a files para mandar pacotes menores é descartada pelo próprio firewall de hq.", "same": ["ICMP: fragmentation needed, mtu 1420"]}
```

**A página pequena atravessou porque cabia.** Dezesseis bytes de corpo e alguns cabeçalhos formam um
pacote pequeno, bem abaixo de 1420. Tudo o que cabe num pacote pequeno funciona; tudo o que precisa de um
pacote cheio não funciona. Essa é a assinatura para guardar: o login funciona, a primeira tela de uma
página funciona, um e-mail sem anexo funciona, e um download, um upload ou uma página grande trava, sem
erro de ninguém.

Regras como a `hardening` são escritas de boa-fé, para impedir que um roteador conte a estranhos quais
endereços e portas estão fechados. A aula 23 volta a isso: como registrar este caso de modo que o
registro corrija a regra, e não a pessoa que a escreveu.
