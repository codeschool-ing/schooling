---
title: tcpdump para um arquivo, para depois
version: 1
---

O tcpdump apareceu em quase toda aula, imprimindo pacotes conforme passam. Com o `-w` ele os grava num
arquivo, no formato **pcap** que o Wireshark e toda outra ferramenta de pacotes sabem abrir:

```
ana@laptop:~$ sudo ip neigh flush dev eth0
ana@laptop:~$ sudo timeout 5 tcpdump -i eth0 -n -w /tmp/web.pcap host 192.0.2.80
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
22 packets captured
22 packets received by filter
0 packets dropped by kernel
ana@laptop:~$ ls -l /tmp/web.pcap
-rw-r--r-- 1 tcpdump tcpdump 5023 Sep 25 16:00 /tmp/web.pcap
ana@laptop:~$ tcpdump -n -r /tmp/web.pcap "tcp[tcpflags] & (tcp-syn|tcp-fin) != 0" 2>/dev/null
16:00:42.225540 IP 192.168.10.20.51554 > 192.0.2.80.443: Flags [S], seq 3902438229, win 64240, options [mss 1460,sackOK,TS val 779025817 ecr 0,nop,wscale 10], length 0
16:00:42.225963 IP 192.0.2.80.443 > 192.168.10.20.51554: Flags [S.], seq 923909534, ack 3902438230, win 65160, options [mss 1460,sackOK,TS val 3408522847 ecr 779025817,nop,wscale 10], length 0
16:00:42.258253 IP 192.0.2.80.443 > 192.168.10.20.51554: Flags [F.], seq 2379, ack 802, win 64, options [nop,nop,TS val 3408522879 ecr 779025850], length 0
16:00:42.258857 IP 192.168.10.20.51554 > 192.0.2.80.443: Flags [F.], seq 802, ack 2380, win 78, options [nop,nop,TS val 779025851 ecr 3408522879], length 0
```

22 pacotes, uma página buscada por HTTPS, em `/tmp/web.pcap`. O `-r` lê o arquivo de volta, e os
mesmos filtros valem. `host 192.0.2.80` escolheu o que foi capturado, e
`tcp[tcpflags] & (tcp-syn|tcp-fin) != 0` separa só os pacotes que abrem e fecham uma conexão, o
handshake e a despedida da aula 3.

**Um arquivo de captura é como um problema viaja.** Ele pode ser feito na máquina onde está o defeito,
lido depois em outro lugar, e anexado a um chamado para quem conhece o protocolo. Ele também pode conter
senhas e dados privados, tudo que as aulas de FTP e e-mail mostraram às claras, então é tratado como
qualquer outro arquivo sensível. Os filtros que vale saber de cor são poucos: `host`, `port`, `net`,
`and`, `or` e `not`.
