---
title: EIGRP: uma reserva calculada de antemão
version: 1
---

O **EIGRP** (*Enhanced Interior Gateway Routing Protocol*) foi um protocolo da própria Cisco durante a
maior parte de sua vida. A Cisco o publicou como RFC informativo, o RFC 7868, em 2016, e o FRR tem uma
implementação, o `eigrpd`, que este laboratório usou **só para mostrar as tabelas que o EIGRP mantém**.
Redes EIGRP em produção são, na prática, redes Cisco, e o comportamento descrito aqui é o do protocolo, não
uma medição do FRR.

A configuração são duas linhas, iguais em todo roteador:

```
root@r1:~# vtysh -c "configure terminal" -c "router eigrp 64500" -c "network 10.20.0.0/16"
```

O número depois de `router eigrp` se chama número de sistema autônomo e tem de bater em todo vizinho. É o
rótulo do próprio EIGRP para o domínio de roteamento, sem relação com os números BGP da aula 17, embora o
laboratório tenha usado 64500, um número que reaparece lá. O OSPF continuava configurado quando o EIGRP
foi acrescentado; esta seção lê as tabelas do próprio EIGRP, e não quais rotas o kernel acabou usando.

## Vizinhos

```
root@r1:~# vtysh -c "show ip eigrp neighbor"

EIGRP neighbors for AS(64500)

H   Address           Interface            Hold   Uptime   SRTT   RTO   Q     Seq  
                                           (sec)           (ms)        Cnt    Num   
0   10.20.0.2         eth1                 14     0        0      2    0      3
0   10.20.0.13        eth4                 12     0        0      2    0      3
```

Os dois vizinhos, r2 e r4. `Hold` é o temporizador de morte do EIGRP, que conta para trás a partir de 15
segundos por padrão e é reiniciado por um hello a cada 5 segundos, e é por isso que mostra 14 e 12
aqui.

## A tabela de topologia

**O EIGRP guarda a oferta de cada vizinho, não só a melhor.** Essa é a diferença em relação ao RIP:

```
root@r1:~# vtysh -c "show ip eigrp topology"

EIGRP Topology Table for AS(64500)/ID(10.20.1.1)

Codes: P - Passive, A - Active, U - Update, Q - Query, R - Reply
       r - reply Status, s - sia Status

P  10.20.0.0/30, 1 successors, FD is 28160, serno: 0 
       via Connected, eth1
P  10.20.0.4/30, 1 successors, FD is 30720, serno: 0 
       via 10.20.0.2 (30720/28160), eth1
P  10.20.0.8/30, 1 successors, FD is 30720, serno: 0 
       via 10.20.0.13 (30720/28160), eth4
P  10.20.0.12/30, 1 successors, FD is 28160, serno: 0 
       via Connected, eth4
P  10.20.1.0/24, 1 successors, FD is 28160, serno: 0 
       via Connected, eth0
P  10.20.2.0/24, 1 successors, FD is 30720, serno: 0 
       via 10.20.0.2 (30720/28160), eth1
```

Pegue a rede de pc2, `10.20.2.0/24`. `P` quer dizer **passiva**, o estado saudável: o EIGRP não está
procurando rota. `1 successors` é o número de melhores caminhos, e o **sucessor** é o vizinho em uso, aqui
`10.20.0.2`, r2, em `eth1`. `FD is 30720` é a **distância viável** (*feasible distance*), a métrica do
melhor caminho a partir de r1.

O par depois do vizinho é `(30720/28160)`: a distância de r1 através daquele vizinho, e a **distância
anunciada** (*reported distance*), a distância do próprio vizinho até a rede, que r2 contou a r1. r2 está
conectado à rede de pc2, então anuncia 28160, o mesmo número que r1 mostra para as próprias redes
conectadas. A diferença, 2560, é o que um enlace a mais acrescenta.

Com os ajustes padrão, a métrica é calculada a partir da menor largura de banda do caminho e do atraso total das interfaces. O
custo do OSPF não entra, e é por isso que o EIGRP escolheu o cabo direto que o OSPF evitou: o
`cost 100` era uma configuração do OSPF, e o EIGRP vê duas interfaces iguais.

## Sucessores viáveis, e por que não há nenhum aqui

O motivo de o EIGRP lembrar todas as ofertas é o **sucessor viável** (*feasible successor*): um segundo
vizinho que assume na hora, sem perguntar a ninguém, se o sucessor falhar. Nem todo vizinho se qualifica.
**A condição de viabilidade é que a distância anunciada pelo vizinho seja menor que a distância viável de
r1**: um vizinho mais perto da rede do que r1 não tem como estar roteando através de r1, então usá-lo não
cria loop.

Para `10.20.2.0/24`, o outro vizinho é r4, e r4 está mais longe da rede de pc2 do que r1. O que ele anuncia
é maior que 30720, então ele falha na condição, e a tabela lista um sucessor e nenhuma reserva. Se r2
falhasse, r1 teria de pedir aos vizinhos um novo caminho, o que o EIGRP chama de ficar *ativo* (`A` nos
códigos) e que seu algoritmo, o **DUAL** (*Diffusing Update Algorithm*), administra.

**Um anel não dá ao EIGRP nada para guardar de reserva para a rede ao lado**, porque o outro lado do anel é
sempre o caminho mais longo. Um projeto em que um segundo vizinho fica ele mesmo ao lado da rede, como dois
roteadores cabeados à LAN de pc2, é onde aparecem sucessores viáveis, e a troca para um deles não pergunta
nada a ninguém.
