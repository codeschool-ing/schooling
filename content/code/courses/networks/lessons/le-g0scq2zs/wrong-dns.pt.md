---
title: Chamado: "os sites não abrem"
version: 1
---

Desta vez o laptop alcança endereços e não nomes:

```
ana@laptop:~$ curl -sS -m 30 https://www.example.com/ -o /dev/null
curl: (6) Could not resolve host: www.example.com
ana@laptop:~$ ping -c 2 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
64 bytes from 192.0.2.80: icmp_seq=1 ttl=61 time=0.091 ms
64 bytes from 192.0.2.80: icmp_seq=2 ttl=61 time=0.102 ms

--- 192.0.2.80 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1025ms
rtt min/avg/max/mdev = 0.091/0.096/0.102/0.005 ms
ana@laptop:~$ cat /etc/resolv.conf
nameserver 192.168.10.53
ana@laptop:~$ dig +tries=1 +time=3 www.example.com
;; communications error to 192.168.10.53#53: timed out

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> +tries=1 +time=3 www.example.com
;; global options: +cmd
;; no servers could be reached
ana@laptop:~$ sudo timeout 6 tcpdump -i eth0 -n -l arp or port 53 2>/dev/null
15:58:41.158416 ARP, Request who-has 192.168.10.53 tell 192.168.10.20, length 28
15:58:42.173841 ARP, Request who-has 192.168.10.53 tell 192.168.10.20, length 28
15:58:43.197869 ARP, Request who-has 192.168.10.53 tell 192.168.10.20, length 28

ana@laptop:~$ dig +short @198.51.100.53 www.example.com
192.0.2.80
ana@laptop:~$ echo "nameserver 198.51.100.53" | sudo tee /etc/resolv.conf
nameserver 198.51.100.53
ana@laptop:~$ dig +short www.example.com
192.0.2.80
```

O `ping` para `192.0.2.80` funciona, então os degraus 1 a 3 passam, e o 4 falha: o `dig` não teve
resposta de `192.168.10.53`, o único servidor no `/etc/resolv.conf`. O tcpdump mostra por quê, e não é
nem um pacote DNS. `192.168.10.53` fica na rede do escritório, então antes de mandar a pergunta o laptop
precisa achar essa máquina pelo ARP, e perguntou três vezes, `who-has 192.168.10.53`, sem
ninguém responder. Não existe servidor DNS nesse endereço.

O `dig @198.51.100.53` pergunta direto ao resolvedor de verdade, passando por cima da configuração, e
recebe `192.0.2.80`, o que prova que o problema é a configuração e não o DNS. **O `@servidor` é o teste
mais rápido que existe para uma reclamação de DNS**: a mesma pergunta a dois servidores, e as duas
respostas comparadas. O conserto aqui foi o arquivo; num PC do escritório é o servidor DNS que o DHCP
entrega, ou um digitado nas configurações do adaptador anos atrás.
