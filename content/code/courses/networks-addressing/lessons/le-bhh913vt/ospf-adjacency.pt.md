---
title: OSPF: vizinhos e um mapa compartilhado
version: 1
---

O **OSPF** (*Open Shortest Path First*) é o protocolo de estado de enlace, e aquele que você tem mais
chance de encontrar dentro da rede de uma empresa. Sua configuração nomeia as interfaces e a área, e
ajusta duas coisas por interface que a próxima seção explica:

```
root@r1:~# vtysh -c "configure terminal" -c "interface eth1" -c "ip ospf network point-to-point" -c "ip ospf cost 100" -c "interface eth2" -c "ip ospf network point-to-point" -c "interface eth3" -c "ip ospf network point-to-point" -c "interface eth4" -c "ip ospf network point-to-point" -c "router ospf" -c "network 10.20.0.0/16 area 0"
```

`network 10.20.0.0/16 area 0` roda o OSPF em toda interface dentro dessa faixa e as põe na **área 0**, o
backbone. Uma rede OSPF grande é dividida em áreas ligadas à área 0, para que nem todo roteador precise
guardar todos os detalhes; este anel é pequeno o bastante para uma só. `ip ospf network point-to-point` diz
ao OSPF que cada cabo tem exatamente dois roteadores. Num segmento Ethernet o OSPF espera, se nada for
dito, muitos roteadores e elege um **roteador designado** para falar pelo segmento, coisa de que um cabo
entre dois roteadores não precisa. `ip ospf cost 100` em `eth1` é para a próxima seção.

## Vizinhos

O OSPF encontra os vizinhos com pacotes hello, e os lista:

```
root@r1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.20.2.1         1 Full/-          13.122s           38.490s 10.20.0.2       eth1:10.20.0.1                       0     0     0
10.20.0.13        1 Full/-          13.129s           31.744s 10.20.0.13      eth4:10.20.0.14                      0     0     0

```

Dois vizinhos, os dois em **`Full`**, que é o estado a que o OSPF chega quando dois roteadores terminaram
de trocar seus bancos de dados e guardam cópias idênticas. Antes disso um vizinho passa por `Init`,
`2-Way`, `ExStart`, `Exchange` e `Loading`; um vizinho preso num desses é a primeira coisa a procurar
quando o OSPF se comporta mal. O `-` depois da barra é o papel de roteador designado, vazio porque os
enlaces são ponto a ponto.

A coluna `Dead Time` conta para trás. Cada hello de um vizinho a reinicia, e se ela chegar a zero o vizinho
é declarado morto. A interface mostra os dois temporizadores por trás disso:

```
root@r1:~# vtysh -c "show ip ospf interface eth1" | grep -E "Cost|Timer|Network Type"
  Router ID 10.20.1.1, Network Type POINTOPOINT, Cost: 100
  Timer intervals configured, Hello 10s, Dead 40s, Wait 40s, Retransmit 5
```

**Um hello a cada 10 segundos, e um vizinho declarado morto depois de 40 segundos de silêncio**: os
padrões. Dois roteadores só viram vizinhos se esses temporizadores baterem, junto com a área e o tipo de
rede, então uma diferença aparece como um vizinho que nunca surge, e não como um erro.

## IDs de roteador

Todo roteador OSPF tem um **ID de roteador** (*router ID*), um número de 32 bits escrito como um endereço.
O de r1 é `10.20.1.1`; seus vizinhos são `10.20.2.1` (r2) e `10.20.0.13` (r4). Nenhum foi digitado, então
cada roteador escolheu um dos próprios endereços, nos quatro casos o mais alto. O anel da aula 3 os definiu
à mão com `ospf router-id`, que é o hábito melhor: **um ID escolhido entre os endereços que existem é um ID
que muda quando os endereços mudam**.

## Um mapa em cada roteador

Cada roteador descreve os próprios enlaces num **LSA de roteador** (*link-state advertisement*) e o
inunda para todos os roteadores da área. A coleção é o **banco de dados de estado de enlace**:

```
root@r1:~# vtysh -c "show ip ospf database"

       OSPF Router with ID (10.20.1.1)

                Router Link States (Area 0.0.0.0)

Link ID         ADV Router      Age  Seq#       CkSum  Link count
10.20.0.9      10.20.0.9         18 0x80000004 0xc70c 4
10.20.0.13     10.20.0.13        17 0x80000004 0x2f91 4
10.20.1.1      10.20.1.1         20 0x80000005 0xde14 5
10.20.2.1      10.20.2.1         19 0x80000005 0x8c78 5


```

Quatro roteadores, quatro LSAs de roteador, e **todo roteador da área guarda esta mesma lista**. Esse é o
ponto do estado de enlace: ninguém repassa um resumo da opinião de outro, então todo roteador calcula seus
caminhos a partir dos mesmos fatos com o algoritmo de caminho mais curto de Dijkstra, que é o *SPF*
(*shortest path first*) do nome.

A coluna `Link count` confere com o desenho. Num cabo ponto a ponto o OSPF descreve duas coisas, o vizinho
e o próprio `/30`, então os dois cabos de r1 dão quatro enlaces e sua LAN um quinto: **5**. r2 tem o mesmo
formato. r3 e r4 têm dois cabos e nenhuma LAN: **4**. `Seq#` sobe cada vez que um roteador descreve de novo
seus enlaces, e é assim que os outros distinguem um LSA mais novo de uma cópia mais velha.
