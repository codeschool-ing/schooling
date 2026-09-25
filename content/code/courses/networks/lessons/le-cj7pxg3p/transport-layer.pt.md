---
title: Camada 4: uma porta, e se alguém está escutando
version: 1
---

A camada 3 traz um pacote até a máquina. **A camada 4 o leva a um programa**, e o programa é
identificado por uma **porta**, um número de 1 a 65535. Um programa servidor *escuta* numa porta; o
`ss -tln` lista as portas TCP em que algo está escutando:

```
ana@www:~$ ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      128       192.0.2.80:22        0.0.0.0:*          
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*          
LISTEN 0      511          0.0.0.0:443       0.0.0.0:*          
ana@laptop:~$ nc -zv 192.0.2.80 443
Connection to 192.0.2.80 443 port [tcp/https] succeeded!
ana@laptop:~$ nc -zv 192.0.2.80 8080
nc: connect to 192.0.2.80 port 8080 (tcp) failed: Connection refused
```

O servidor web escuta em três: 22 para SSH, 80 para HTTP e 443 para HTTPS. `0.0.0.0` quer dizer
todos os endereços da máquina; `192.0.2.80:22` quer dizer só aquele endereço. Esses números são
convenções, listadas em `/etc/services`, e nada impede um programa de escutar em outra porta, e é por
isso que um endereço web às vezes traz `:8080`.

Do laptop, o `nc -zv` tenta abrir uma conexão e conta como foi. A porta 443 respondeu. **A porta 8080
foi *recusada*: a máquina está lá, e disse não.** Nada escuta na 8080, então o sistema do servidor
respondeu à tentativa com uma recusa na hora. Isso é diferente de nenhuma resposta, um *timeout*, que
em geral quer dizer que um firewall descartou a tentativa em algum ponto do caminho. A aula 3 separa
as duas.

Uma recusa é boa notícia, de certo modo. O enlace, o endereço e a rota funcionaram, porque a recusa
voltou por eles. A falha está na camada 4 ou acima, naquela máquina.
