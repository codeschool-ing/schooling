---
title: Perdendo um cabo do grupo
version: 1
---

Na lição 20 um cabo puxado custou meio minuto a um ping, porque o spanning tree teve de levar uma
porta bloqueada por listening e learning antes de ela encaminhar. **Num LAG não há porta bloqueada
para acordar**: o outro membro já está encaminhando, e o bond só tem de parar de usar o que morreu.

## Puxando o e1 com um ping rodando

No `pc1`, foi iniciado um ping para o `pc3`, dois pacotes por segundo durante dez segundos. Dois
segundos depois, o cabo `e1` foi puxado, desativando a ponta dele no `sw2`. O ping imprimiu o resumo
quando terminou, e então o `sw1` foi consultado sobre os membros:

```
ana@pc1:~$ ping -c 20 -i 0.5 -q 10.20.10.23
PING 10.20.10.23 (10.20.10.23) 56(84) bytes of data.

--- 10.20.10.23 ping statistics ---
20 packets transmitted, 20 received, 0% packet loss, time 9553ms
rtt min/avg/max/mdev = 0.538/1.079/4.054/0.725 ms
root@sw1:~# grep -A3 "Slave Interface" /proc/net/bonding/bond0
Slave Interface: e1
MII Status: down
Speed: 10000 Mbps
Duplex: full
--
Slave Interface: e2
MII Status: up
Speed: 10000 Mbps
Duplex: full
root@sw1:~# ip -br link show bond0
bond0            UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> 
```

**20 enviados, 20 recebidos.** O `e1` informa `MII Status: down`, o `e2` está `up`, e o próprio
`bond0` continua `UP` com `LOWER_UP`: para o switch, o uplink dele nunca sumiu. Compare com os 30
pings perdidos de 60 da lição 20.

Seja preciso sobre o que isso prova. A captura não diz em qual cabo o hash tinha posto os pings para
o `pc3`. Se eles estavam no `e2` o tempo todo, o teste teria passado sem o bond fazer nada por eles.
**O que ela mostra, seja qual for o membro que usaram, é um enlace que continuou funcionando com um
dos dois cabos fora**, e um bond que continuou se declarando ativo. O tráfego que estava no `e1`
passou para o `e2`, porque um hash sobre os membros ainda ativos só tem uma resposta sobrando.

## Como o bond percebe

Há dois jeitos, e eles pegam falhas diferentes.

- **O sinal do enlace.** `miimon 100` faz o bond conferir a portadora de cada membro a cada 100
  milissegundos. Um cabo puxado ou cortado, ou uma porta desligada no switch da outra ponta, é visto
  numa conferência. Foi o que aconteceu aqui.
- **O próprio LACP.** Um membro só fica no LAG enquanto os LACPDUs do parceiro continuam chegando.
  Com `lacp_rate fast` eles chegam a cada segundo, e **um membro que perde três seguidos é tirado,
  uns três segundos, mesmo que a luz do enlace continue acesa.** Essa é a falha que o sinal não
  enxerga: um conversor de mídia no meio do cabo, ou um switch na outra ponta que travou com as
  portas ainda acesas. Com a taxa lenta a mesma espera é de 90 segundos. Um LAG estático não tem
  nenhuma conferência além do sinal.

## O que sobra depois da falha

O LAG segue com metade da capacidade, e nada na rede precisa recalcular nada. Esse também é o risco
silencioso dele. **Um bond com um membro fora parece saudável visto de cima**: o `bond0` está `UP`,
os pings respondem, e o único sinal é uma linha em `/proc/net/bonding/bond0` ou o equivalente do
switch. O `Min links: 0` na saída da seção anterior é a configuração que mudaria isso: com
`min_links 2`, o bond se declararia fora do ar quando houvesse menos de dois membros ativos, para que
um projeto que precisa dos dois cabos falhe de forma visível em vez de andar devagar. Seja qual for a
escolha, um sistema de monitoramento deveria vigiar a contagem de membros, porque ninguém percebe a
metade que falta até o dia em que o cabo que sobrou enche.
