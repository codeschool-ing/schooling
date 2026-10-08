---
title: Lendo com tcpdump
version: 1
---

O `tcpdump -r` lê um arquivo de captura de volta. `-nn` mantém endereços e portas como números, então o tcpdump não
tenta resolver nomes, o que num laboratório isolado só o deixaria lento e num incidente de verdade poderia mandar
uma consulta DNS para o outro lado:

```
ana@soc:~$ tcpdump -nn -r web.pcap 2>/dev/null | head -4
21:10:25.863410 IP 192.168.20.10.50542 > 203.0.113.200.8080: Flags [S], seq 1351909861, win 64240, options [mss 1460,sackOK,TS val 4155148826 ecr 0,nop,wscale 10], length 0
21:10:25.863522 IP 203.0.113.200.8080 > 192.168.20.10.50542: Flags [S.], seq 1005923498, ack 1351909862, win 65160, options [mss 1460,sackOK,TS val 1052539430 ecr 4155148826,nop,wscale 10], length 0
21:10:25.863537 IP 192.168.20.10.50542 > 203.0.113.200.8080: Flags [.], ack 1, win 63, options [nop,nop,TS val 4155148826 ecr 1052539430], length 0
21:10:25.863614 IP 192.168.20.10.50542 > 203.0.113.200.8080: Flags [P.], seq 1:96, ack 1, win 63, options [nop,nop,TS val 4155148826 ecr 1052539430], length 95: HTTP: GET /price-list.csv HTTP/1.1
ana@soc:~$ tcpdump -nn -r web.pcap 2>/dev/null | wc -l
20
```

Quatro linhas são o começo de toda conversa TCP. Leia as `Flags`:

1. `[S]`, **SYN**: o `files`, da porta 50542, pede a `203.0.113.200` porta 8080 para abrir uma conexão.
2. `[S.]`, **SYN-ACK**: o servidor concorda. O ponto é um ACK.
3. `[.]`, **ACK**: o `files` confirma. A conexão está aberta: o **three-way handshake**.
4. `[P.]`, **PUSH**: os primeiros dados, `length 95`, e o tcpdump os reconhece: `HTTP: GET /price-list.csv`.

Vinte linhas ao todo, uma por pacote. Uma linha por pacote serve para vinte e não serve para vinte mil, e por isso
existe a próxima ferramenta. A porta de origem e os números de sequência na sua captura são outros: são escolhidos
ao acaso para cada conexão.
