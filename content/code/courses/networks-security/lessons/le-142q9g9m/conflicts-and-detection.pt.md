---
title: Vendo duas máquinas reivindicarem um endereço
version: 1
---

O sintoma do ARP spoofing também tem uma causa inocente, e a inocente é muito mais comum: duas
máquinas configuradas com o mesmo endereço. O laboratório tem uma agora. Uma impressora foi ligada à
LAN dos funcionários e, por engano, recebeu o endereço do `desk`, `192.168.10.21`. O `arping`
pergunta por esse endereço à mão e imprime cada resposta:

```
ana@laptop:~$ arping -c 3 -I eth0 192.168.10.21
ARPING 192.168.10.21 from 192.168.10.20 eth0
Unicast reply from 192.168.10.21 [52:54:00:0A:77:21]  0.548ms
Unicast reply from 192.168.10.21 [52:54:00:A8:0A:15]  0.562ms
Unicast reply from 192.168.10.21 [52:54:00:A8:0A:15]  0.551ms
Unicast reply from 192.168.10.21 [52:54:00:A8:0A:15]  0.558ms
Sent 3 probes (1 broadcast(s))
Received 4 response(s)
```

**Dois MACs diferentes responderam por um endereço.** `52:54:00:0A:77:21` respondeu uma vez, a
impressora; `52:54:00:A8:0A:15`, o `desk`, respondeu a todas as sondagens. Seja uma impressora
configurada às pressas, seja uma máquina mentindo sobre o gateway, a resposta de quem defende começa
do mesmo jeito: achar os dois MACs na tabela de endereços do switch, ir até as portas e descobrir qual
delas não deveria estar dizendo aquilo.

## Perguntar antes de assumir um endereço

`arping -D` é a **detecção de endereço duplicado** (duplicate address detection): pergunta por um
endereço a partir da origem `0.0.0.0`, como uma máquina deveria fazer antes de configurar um, e
informa se alguém já o tem. Do sensor, para um endereço em uso e um livre:

```
root@sensor:~# arping -D -c 2 -I eth0 192.0.2.80; echo "exit $?"
ARPING 192.0.2.80 from 0.0.0.0 eth0
Unicast reply from 192.0.2.80 [52:54:00:00:02:50]  0.540ms
Sent 1 probes (1 broadcast(s))
Received 1 response(s)
exit 1
root@sensor:~# arping -D -c 2 -I eth0 192.0.2.81; echo "exit $?"
ARPING 192.0.2.81 from 0.0.0.0 eth0
Sent 2 probes (2 broadcast(s))
Received 0 response(s)
exit 0
```

Para `192.0.2.80`, o `www` respondeu e o `arping` sai com 1: ocupado. Para `.81`, ninguém respondeu
e ele sai com 0: livre. Um script que atribui endereços à mão deveria perguntar isso primeiro.

## Vigiando mudanças

A pergunta que vale monitorar é contínua: **o MAC por trás de um endereço importante mudou?** O MAC
do gateway não deveria mudar a menos que o gateway tenha sido substituído. Ferramentas que observam o
tráfego ARP de um segmento, sendo a clássica o `arpwatch`, registram cada par endereço-MAC que veem e
avisam de um par novo, de um que mudou e de um que fica alternando. Um sensor de detecção de intrusão
no segmento pode fazer o mesmo; o alerta que importa é *o MAC do gateway mudou*, e ele deveria ser
raro o bastante para que cada ocorrência seja lida.
