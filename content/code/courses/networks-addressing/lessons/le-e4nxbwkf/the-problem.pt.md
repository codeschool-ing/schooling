---
title: Duas VLANs, e nenhum caminho entre elas
version: 1
---

A aula 19 dividiu uma rede em VLANs e mostrou cada uma isolada da outra. Era esse o objetivo, e mais
cedo ou mais tarde ele também vira o problema: o almoxarifado precisa do servidor de arquivos que
vive na VLAN do escritório, e todo departamento precisa das impressoras. **Um switch configurado com
VLANs não passa tráfego de uma VLAN para outra sozinho**, por mais óbvio que o caminho pareça no
desenho, porque cada VLAN é um domínio de broadcast separado e, pela convenção que a aula 19 seguiu,
uma sub-rede IP separada. Tráfego entre sub-redes é trabalho de roteador, que as aulas 14 e 15
cobriram.

O laboratório desta aula é um switch, o sw1, configurado do jeito que a aula 19 deixou os switches
dela. O pc1 e um servidor web, o srv, estão na VLAN 10, em 10.20.10.0/24; o pc2 está na VLAN 20, em
10.20.20.0/24. Um roteador, o r1, está ligado na porta p8, e a p8 é um tronco que leva as duas VLANs.
O r1 ainda não tem endereço. Todo PC já indica um gateway padrão: 10.20.10.1 para as máquinas da
VLAN 10 e 10.20.20.1 para o pc2.

```
root@sw1:~# bridge vlan show
port              vlan-id  
p1                10 PVID Egress Untagged
p2                20 PVID Egress Untagged
p3                10 PVID Egress Untagged
p8                1 PVID Egress Untagged
                  10
                  20
br0               1 PVID Egress Untagged
```

A p1 e a p3 (pc1 e srv) são portas de acesso na VLAN 10, a p2 (pc2) é porta de acesso na VLAN 20, e a
p8 leva a 10 e a 20 com tag, com a VLAN 1 sem tag, como a aula 19 avisou. Agora o pc1 tenta os dois
vizinhos:

```
ana@pc1:~$ ping -c 1 -W 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 10.843/10.843/10.843/0.000 ms
ana@pc1:~$ ping -c 1 -W 1 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@pc1:~$ ip neigh
10.20.10.1 dev eth0 INCOMPLETE 
10.20.10.10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
```

O srv responde, porque está na mesma VLAN e na mesma sub-rede: o pc1 pediu o MAC dele, recebeu, e a
tabela de vizinhos o guarda como `REACHABLE`. O pc2 não. O pc1 comparou 10.20.20.22 com o próprio
/24, viu outra sub-rede e fez o que a aula 14 diz que um host faz: mandou o pacote para o gateway
padrão. Para isso precisava do MAC do gateway, então perguntou por 10.20.10.1 — e **a entrada
`10.20.10.1 dev eth0 INCOMPLETE` é o diagnóstico inteiro: o pc1 perguntou quem tem o endereço do
gateway, e ninguém na VLAN 10 o tem ainda.**

Repare no que o switch fez e no que não fez. Os quadros para o pc2 teriam de passar da VLAN 10 para
a VLAN 20 em algum lugar dentro do sw1, e um switch só entrega um quadro dentro da VLAN em que ele
chegou. Nenhuma configuração nas portas de acesso muda isso, e mesmo um switch que levasse o quadro
de um lado para o outro nem seria chamado a fazê-lo: o pc1 acredita que o pc2 está em outra
sub-rede, então só vai mandar para o gateway.

Então entre VLANs tem de haver um roteador, e há três jeitos de dar as VLANs a ele. O simples é um
roteador com uma porta e um cabo por VLAN: correto, e custa uma porta de roteador e uma porta de
switch por VLAN, o que deixa de ser razoável lá pela meia dúzia delas. As duas próximas seções
constroem o segundo jeito, um roteador com uma porta num tronco, e a seção depois delas constrói o
terceiro, em que o roteamento vai para dentro do switch.
