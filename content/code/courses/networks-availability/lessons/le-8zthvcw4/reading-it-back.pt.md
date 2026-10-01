---
title: Lendo o arquivo de volta
version: 1
---

`-r` lê um arquivo em vez de uma interface, e **ler não exige privilégio**: o arquivo é de `ana`,
então nada de `sudo` na frente.

```
ana@web1:~$ tcpdump -n -r web1.pcap | head -n 6
reading from file web1.pcap, link-type EN10MB (Ethernet), snapshot length 262144
18:10:03.429832 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [S], seq 781299498, win 64240, options [mss 1460,sackOK,TS val 1879519515 ecr 0,nop,wscale 10], length 0
18:10:03.429866 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [S.], seq 3577260322, ack 781299499, win 65160, options [mss 1460,sackOK,TS val 3771413204 ecr 1879519515,nop,wscale 10], length 0
18:10:03.429895 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [.], ack 1, win 63, options [nop,nop,TS val 1879519515 ecr 3771413204], length 0
18:10:03.429954 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [P.], seq 1:74, ack 1, win 63, options [nop,nop,TS val 1879519515 ecr 3771413204], length 73: HTTP: GET / HTTP/1.1
18:10:03.429957 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [.], ack 74, win 64, options [nop,nop,TS val 3771413204 ecr 1879519515], length 0
18:10:03.430184 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [P.], seq 1:244, ack 74, win 64, options [nop,nop,TS val 3771413204 ecr 1879519515], length 243: HTTP: HTTP/1.1 200 OK
```

A primeira conexão, pacote a pacote: SYN, SYN-ACK, ACK, a requisição de 73 bytes, a confirmação do
servidor e o início da resposta, 243 bytes que dizem `HTTP/1.1 200 OK`. O arquivo guarda os horários
originais, então uma captura feita à noite é lida de manhã com o relógio da noite.

Um filtro passado com `-r` é BPF, como um filtro de captura, e ele seleciona dentro do arquivo. O BPF
também sabe olhar bits: `tcp[tcpflags]` é o byte das flags TCP, e `& tcp-syn != 0` fica com os pacotes
que têm o bit SYN ligado.

```
ana@web1:~$ tcpdump -n -r web1.pcap "tcp[tcpflags] & tcp-syn != 0"
reading from file web1.pcap, link-type EN10MB (Ethernet), snapshot length 262144
18:10:03.429832 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [S], seq 781299498, win 64240, options [mss 1460,sackOK,TS val 1879519515 ecr 0,nop,wscale 10], length 0
18:10:03.429866 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [S.], seq 3577260322, ack 781299499, win 65160, options [mss 1460,sackOK,TS val 3771413204 ecr 1879519515,nop,wscale 10], length 0
18:10:03.436113 IP 203.0.113.2.58006 > 192.0.2.21.80: Flags [S], seq 819435649, win 64240, options [mss 1460,sackOK,TS val 1554105456 ecr 0,nop,wscale 10], length 0
18:10:03.436121 IP 192.0.2.21.80 > 203.0.113.2.58006: Flags [S.], seq 2611216251, ack 819435650, win 65160, options [mss 1460,sackOK,TS val 1942754168 ecr 1554105456,nop,wscale 10], length 0
18:10:03.442388 IP 203.0.113.2.58022 > 192.0.2.21.80: Flags [S], seq 2112191451, win 64240, options [mss 1460,sackOK,TS val 113813396 ecr 0,nop,wscale 10], length 0
18:10:03.442397 IP 192.0.2.21.80 > 203.0.113.2.58022: Flags [S.], seq 1868065903, ack 2112191452, win 65160, options [mss 1460,sackOK,TS val 2339123235 ecr 113813396,nop,wscale 10], length 0
18:10:03.448333 IP 203.0.113.2.58026 > 192.0.2.21.80: Flags [S], seq 111897154, win 64240, options [mss 1460,sackOK,TS val 2610192501 ecr 0,nop,wscale 10], length 0
18:10:03.448342 IP 192.0.2.21.80 > 203.0.113.2.58026: Flags [S.], seq 2309079825, ack 111897155, win 65160, options [mss 1460,sackOK,TS val 1982204633 ecr 2610192501,nop,wscale 10], length 0
```

**Oito linhas, duas por conexão: quatro conexões**, uma por requisição, cada uma com um SYN e o seu
SYN-ACK. Contar SYNs é o jeito mais rápido de responder "quantas vezes os clientes se conectaram", e
num servidor sob ataque ou sob uma tempestade de novas tentativas é o número que dispara primeiro.

`-A` imprime os bytes de cada pacote como ASCII, e com a flag push e um `grep` vira uma lista de
requisições e respostas:

```
ana@web1:~$ tcpdump -n -A -r web1.pcap "tcp[tcpflags] & tcp-push != 0" | grep -E "GET|HTTP/1.1 [0-9]"
reading from file web1.pcap, link-type EN10MB (Ethernet), snapshot length 262144
18:10:03.429954 IP 203.0.113.2.57998 > 192.0.2.21.80: Flags [P.], seq 781299499:781299572, ack 3577260323, win 63, options [nop,nop,TS val 1879519515 ecr 3771413204], length 73: HTTP: GET / HTTP/1.1
p.1...2.GET / HTTP/1.1
18:10:03.430184 IP 192.0.2.21.80 > 203.0.113.2.57998: Flags [P.], seq 1:244, ack 73, win 64, options [nop,nop,TS val 3771413204 ecr 1879519515], length 243: HTTP: HTTP/1.1 200 OK
..2.p.1.HTTP/1.1 200 OK
18:10:03.436191 IP 203.0.113.2.58006 > 192.0.2.21.80: Flags [P.], seq 819435650:819435723, ack 2611216252, win 63, options [nop,nop,TS val 1554105456 ecr 1942754168], length 73: HTTP: GET / HTTP/1.1
\..ps..xGET / HTTP/1.1
18:10:03.436302 IP 192.0.2.21.80 > 203.0.113.2.58006: Flags [P.], seq 1:244, ack 73, win 64, options [nop,nop,TS val 1942754168 ecr 1554105456], length 243: HTTP: HTTP/1.1 200 OK
s..x\..pHTTP/1.1 200 OK
18:10:03.442465 IP 203.0.113.2.58022 > 192.0.2.21.80: Flags [P.], seq 2112191452:2112191525, ack 1868065904, win 63, options [nop,nop,TS val 113813396 ecr 2339123235], length 73: HTTP: GET / HTTP/1.1
.....l0#GET / HTTP/1.1
18:10:03.442630 IP 192.0.2.21.80 > 203.0.113.2.58022: Flags [P.], seq 1:244, ack 73, win 64, options [nop,nop,TS val 2339123236 ecr 113813396], length 243: HTTP: HTTP/1.1 200 OK
.l0$....HTTP/1.1 200 OK
18:10:03.448411 IP 203.0.113.2.58026 > 192.0.2.21.80: Flags [P.], seq 111897155:111897235, ack 2309079826, win 63, options [nop,nop,TS val 2610192501 ecr 1982204633], length 80: HTTP: GET /missing HTTP/1.1
.GET /missing HTTP/1.1
18:10:03.448552 IP 192.0.2.21.80 > 203.0.113.2.58026: Flags [P.], seq 1:295, ack 80, win 64, options [nop,nop,TS val 1982204633 ecr 2610192501], length 294: HTTP: HTTP/1.1 404 Not Found
...`uHTTP/1.1 404 Not Found
```

Três `200 OK` e um `404 Not Found`, para `/missing`. Os poucos caracteres antes de `GET` e de `HTTP`
são bytes do cabeçalho TCP, impressos como caracteres como todo o resto.

**Olhe os números de sequência**, porque eles mudaram. A primeira linha diz `seq
781299499:781299572`, números brutos, onde a leitura completa acima dizia `seq 1:74`; e a resposta
confirma `73`, onde dizia `74`. O `tcpdump` conta números relativos a partir do primeiro pacote que vê
de cada conexão, e este filtro escondeu o handshake, então ele começou a contar pela requisição. **O
erro de um vem do filtro, não da rede**, e é o tipo de coisa que manda alguém procurar um byte perdido
que nunca se perdeu. Quando os números importam, leia com o handshake à vista, ou peça números brutos
em tudo com `-S`, que não foi rodado aqui.
