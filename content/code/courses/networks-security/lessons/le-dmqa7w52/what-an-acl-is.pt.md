---
title: Uma lista de acesso é um firewall sem memória, em uma interface
version: 1
---

Uma **lista de controle de acesso** (access control list, ACL) em um roteador ou switch é uma lista
ordenada de linhas de *permit* e *deny*, vinculada a uma interface em um sentido. Cada pacote que
atravessa essa interface nesse sentido é comparado com as linhas a partir do topo; a primeira linha que
casa decide; e um pacote que não casa com nada é negado. Quatro propriedades a separam do firewall das
aulas 1 a 5:

| propriedade | uma ACL | o conjunto de regras do `fw` |
|---|---|---|
| memória | nenhuma: cada pacote julgado sozinho, como o filtro sem estado da aula 1 | rastreamento de conexões |
| onde se aplica | uma interface, um sentido: *in* ou *out* | um hook que vê todas as interfaces |
| quando nada casa | um **deny implícito** no fim, invisível na configuração | a `policy` da chain, escrita |
| onde roda | muitas vezes no hardware de comutação, na velocidade total da porta | em software |

A última linha é o motivo de as ACLs sobreviverem. **Aplicá-las não custa quase nada**, então elas
filtram onde um firewall com estado seria lento ou caro demais: entre VLANs em um switch de núcleo, na
borda de um roteador com a internet, nas portas por onde se chega a uma rede de gerência.

O laboratório não tem equipamento Cisco, e a sintaxe desta aula é Cisco IOS porque é ali que a maioria
dos engenheiros de rede encontra ACLs pela primeira vez. **A configuração IOS mostrada é notação, não é
executada.** Ao lado de cada uma, a mesma ACL roda em `branch`, o roteador Linux da filial, na família
`netdev` do nftables: uma chain vinculada a um dispositivo no seu hook de **ingress**, antes do
roteamento, sem rastreamento de conexões. É o mais perto que o Linux chega da ACL de interface de um
roteador, e todo resultado da aula vem dela.
