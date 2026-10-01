---
title: Loopback, a máquina falando com ela mesma
version: 1
---

Toda máquina tem uma interface sem cabo atrás. Ela se chama `lo`, de **loopback**, e um pacote
mandado para ela nunca sai da máquina: o kernel o devolve direto para si mesmo. A do pc1:

```
ana@pc1:~$ ip addr show lo
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
```

O endereço é `127.0.0.1`, com máscara `/8`. **O bloco `127.0.0.0/8` inteiro é loopback**, todos os
16.777.216 endereços dele, e não só o que todo mundo digita. `scope host` diz que o endereço só
significa algo dentro desta máquina, e `mtu 65536` é um indício de que não há Ethernet no caminho:
uma interface virtual move pacotes muito maiores que os 1500 bytes de um cabo. A linha
`inet6 ::1/128` é o loopback do IPv6, que é um endereço só, e não um bloco.

Pingue o endereço que todo mundo conhece, e depois um que ninguém configurou:

```
ana@pc1:~$ ping -c 1 127.0.0.1
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=9.14 ms

--- 127.0.0.1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 9.143/9.143/9.143/0.000 ms
ana@pc1:~$ ping -c 1 127.45.6.7
PING 127.45.6.7 (127.45.6.7) 56(84) bytes of data.
64 bytes from 127.45.6.7: icmp_seq=1 ttl=64 time=0.813 ms

--- 127.45.6.7 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.813/0.813/0.813/0.000 ms
```

Os dois responderam. Ninguém deu `127.45.6.7` ao pc1, mas o `/8` do `lo` o cobre, então o kernel
responde por ele como responde por `127.0.0.1`. Os dois tempos, 9.14 ms e 0.813 ms, medem a máquina
virtual deste laboratório e não dizem nada sobre loopback em geral. E o ipcalc concorda sobre o que
é a faixa:

```
ana@pc1:~$ ipcalc -b 127.0.0.1
Address:   127.0.0.1            
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   127.0.0.0/24         
HostMin:   127.0.0.1            
HostMax:   127.0.0.254          
Broadcast: 127.0.0.255          
Hosts/Net: 254                   Class A, Loopback

```

Como em todo endereço desta aula, o `/24` e os seus 254 hosts são suposição do ipcalc, e não a
faixa. O rótulo no fim, `Loopback`, é a parte certa.

**Um programa que escuta em `127.0.0.1` só aceita conexões da própria máquina.** É assim que um banco
de dados num servidor web fica longe da rede: ele escuta no loopback, a aplicação web na mesma
máquina se conecta a ele ali, e nada de fora alcança a porta. O nome `localhost` aponta para
`127.0.0.1` pelo `/etc/hosts` da máquina, então os dois são a mesma coisa escrita de jeitos
diferentes.

A ideia errada que vale nomear aqui é que pingar `127.0.0.1` testa a placa de rede. Não testa placa
nenhuma. Uma resposta prova que o software de TCP/IP da máquina está rodando, e nada sobre o cabo, o
switch ou a rede. **Uma máquina com o cabo desconectado continua respondendo a um ping para
`127.0.0.1`**, o que faz dele um mau primeiro teste quando a queixa é que a rede caiu: ele só sabe
dizer sim.

O loopback também explica uma confusão que aparece em chamados de suporte. Quando alguém diz que um
serviço "funciona no servidor mas não da minha máquina", muitas vezes o serviço escuta só em
`127.0.0.1`. Testado no servidor, responde; testado de qualquer outro lugar, a conexão é recusada,
porque nada escuta no endereço de verdade do servidor. A última seção desta aula mostra, com `ss`, os endereços em que o servidor deste escritório escuta.
