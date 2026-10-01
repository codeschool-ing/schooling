---
title: Dois cabos que funcionam como um
version: 1
---

O enlace entre dois switches carrega o tráfego de todo mundo ao mesmo tempo: cada PC de um lado
falando com cada servidor do outro. Quando ele enche, ou quando o único cabo dele é puxado, o andar
inteiro percebe. A resposta óbvia é um segundo cabo, e a lição 20 mostrou o que um segundo cabo faz
sozinho. **Com o spanning tree desligado, dois cabos entre dois switches são um laço. Com o spanning
tree ligado, um deles fica bloqueado**, e não carrega nada até o outro falhar, e mesmo assim só
depois de meio minuto de listening e learning.

A **agregação de enlaces** (*link aggregation*) é a terceira opção. Ela diz aos dois switches que os
cabos entre eles são uma porta lógica. O spanning tree, a tabela MAC e tudo o mais acima veem um
enlace só, então não há laço para quebrar nem nada para bloquear. Por baixo, o tráfego se espalha
pelos cabos, e perder um deles reduz a capacidade em vez de cortar o enlace.

A ideia tem um nome diferente em quase todo sistema que você encontra:

| onde | como se chama |
| --- | --- |
| o padrão IEEE | agregação de enlaces, um LAG (*link aggregation group*) |
| switches Cisco | EtherChannel, ou port channel |
| Linux | um bond, com os cabos como membros |
| servidores Windows | NIC teaming |

Todos descrevem o mesmo arranjo. **O protocolo que permite às duas pontas combinarem isso é o
LACP**, o assunto da próxima seção.

## O laboratório: dois switches, dois cabos sobrando

O laboratório desta lição são dois switches, `sw1` e `sw2`, ligados por dois cabos, `e1` e `e2` em
cada ponta. O `pc1` está no `sw1`; `pc2`, `pc3` e `pc4` estão no `sw2`, com os endereços
`10.20.10.21` a `10.20.10.24`. No começo os dois cabos estão conectados e ativos, mas nenhum foi
posto em nenhum dos switches:

```
root@sw1:~# ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
br0              UP             02:6a:dc:93:3b:8a <BROADCAST,MULTICAST,UP,LOWER_UP> 
e1@if485         UP             02:1d:22:fd:7e:72 <BROADCAST,MULTICAST,UP,LOWER_UP> 
e2@if487         UP             02:ce:7c:39:59:d3 <BROADCAST,MULTICAST,UP,LOWER_UP> 
p1@if490         UP             02:b7:0a:5d:30:6c <BROADCAST,MULTICAST,UP,LOWER_UP> 
ana@pc1:~$ ping -c 1 -W 1 -q 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.

--- 10.20.10.22 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 1ms

```

`br0` é o próprio switch e `p1` é a porta do `pc1`. **`e1` e `e2` estão `UP` e com sinal
(`LOWER_UP`), e ainda assim o `pc1` não alcança o `pc2`**: um cabo com sinal não é um caminho até o
switch encaminhar quadros por ele, e estes dois ainda não pertencem a bridge nenhuma. É também o
estado de um cabo novo num switch gerenciável. Conectá-lo é metade do trabalho, e a configuração é a
outra metade.

## O que a agregação não dá

É tentador ler dois cabos de 10 Gb/s como um enlace de 20 Gb/s. **O total está certo e o número de um
fluxo só não está.** Um LAG decide, conversa por conversa, qual membro a carrega, e uma conversa fica
no seu membro; a seção sobre hashing desta lição mostra como, e mostra os contadores. Então uma cópia
grande de arquivo entre duas máquinas anda na velocidade de um cabo, e o segundo cabo só ajuda
quando há outras conversas para carregar.

A agregação também é um assunto entre dois vizinhos. Os cabos de um LAG vão entre os mesmos dois
dispositivos, e nesta lição eles ligam dois switches. Alguns fabricantes deixam um LAG terminar em
dois switches que se comportam como um, para que perder um switch inteiro também seja suportável,
mas isso é um projeto à parte, e não algo que este laboratório montou.
