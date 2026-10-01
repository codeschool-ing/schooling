---
title: Redundância, um segundo caminho já na tabela
version: 1
---

**Redundância** quer dizer dois de tudo aquilo de que muita gente depende: dois cabos, dois roteadores,
duas fontes. A ideia errada é achar que um reserva é redundância. Um roteador reserva na caixa, ou um
cabo de backup pelo qual ninguém nunca mandou tráfego, é um plano para uma queda longa. A redundância
que importa é o segundo caminho **já em uso, ou já na tabela de rotas**, para que a falha do primeiro
não custe nada.

No campus, cada roteador de distribuição tem um cabo até cada núcleo. Pergunte ao d1 como ele alcança a
LAN do pc2:

```
root@d1:~# ip route show 10.20.12.0/24
10.20.12.0/24 nhid 24 proto ospf metric 20 
	nexthop via 10.20.0.5 dev eth1 weight 1 
	nexthop via 10.20.0.13 dev eth2 weight 1 
```

**Uma rota, dois próximos saltos**: por `10.20.0.5` (c1) na `eth1`, e por `10.20.0.13` (c2) na `eth2`,
cada um com `weight 1`. O OSPF achou dois caminhos de custo igual e instalou os dois, então o d1 espalha
o tráfego pelos dois núcleos. Isso se chama **multicaminho de custo igual** (*equal-cost multipath*), e o
traceroute da seção anterior, que passou pelo c2, pegou um dos dois.

## O corte

O pc1 começa vinte pings, um a cada meio segundo. Enquanto eles rodam, o cabo do d1 até o c2 é cortado —
a `eth2` do d1 é desligada. O ping terminou depois do corte, então o resumo dele aparece depois do
comando que cortou o cabo:

```
root@d1:~# ip link set eth2 down
ana@pc1:~$ ping -c 20 -i 0.5 -q 10.20.12.22
PING 10.20.12.22 (10.20.12.22) 56(84) bytes of data.

--- 10.20.12.22 ping statistics ---
20 packets transmitted, 20 received, 0% packet loss, time 9532ms
rtt min/avg/max/mdev = 0.842/1.203/2.074/0.308 ms
```

**20 enviados, 20 recebidos, 0% de perda.** Compare com o anel da aula 3, que perdeu 19 de 30 com o
mesmo tipo de corte. Lá, o segundo caminho teve de ser descoberto depois que o primeiro morreu. Aqui ele
já estava na tabela do d1, e o d1 só precisou parar de usar um dos dois próximos saltos:

```
root@d1:~# ip route show 10.20.12.0/24
10.20.12.0/24 nhid 20 via 10.20.0.5 dev eth1 proto ospf metric 20 
ana@pc1:~$ traceroute -n 10.20.12.22
traceroute to 10.20.12.22 (10.20.12.22), 30 hops max, 60 byte packets
 1  10.20.11.1  1.090 ms  0.592 ms  0.466 ms
 2  10.20.0.5  0.332 ms  0.283 ms  0.284 ms
 3  10.20.0.10  0.610 ms  0.448 ms  0.390 ms
 4  10.20.12.22  0.372 ms  0.583 ms  0.551 ms
```

A rota agora tem um próximo salto só, `10.20.0.5` pela `eth1`, e os pacotes do pc1 sobem até o c1
(`10.20.0.5`) e descem até o d2 (`10.20.0.10`, a ponta do d2 no cabo c1–d2). Mesmo comprimento de antes,
pelo outro núcleo.

Seja honesto sobre o que uma execução mostra: esses vinte pings tiveram sorte, ou o corte foi rápido o
bastante, e nenhum caiu no buraco. Uma rede real pode perder um ou dois pacotes na mesma mudança. O que
não depende de sorte é a forma: **a alternativa não precisou ser achada, então não tinha como demorar
para ser achada**.

## Redundância que não é

Três jeitos de um projeto parecer redundante no papel e não ser:

- **Destino compartilhado.** Dois cabos no mesmo duto são cortados pela mesma escavadeira. Dois
  roteadores na mesma régua de tomadas apagam juntos. A redundância é só tão independente quanto a coisa
  menos óbvia que as duas metades compartilham.
- **Um caminho que ninguém usa.** Um link de backup que não carrega tráfego há um ano pode estar
  quebrado, mal configurado ou desligado no dia em que for necessário, e nada avisa. Caminhos de custo
  igual evitam isso mantendo as duas metades ocupadas; um link de reserva deveria ao menos ser testado
  com hora marcada.
- **Metade da capacidade.** Com os dois núcleos em uso, cada um carrega metade da carga. Se um falha, o
  outro carrega tudo. Um projeto em que cada núcleo roda a 70% é redundante no desenho e sobrecarregado
  na falha.

O preço é o óbvio — o dobro de cabos e o dobro de roteadores de núcleo — e o menos óbvio: **mais
caminhos são mais coisa para entender**. Uma tabela de rotas com dois próximos saltos é mais difícil de
ler de olho do que uma com um, o que é motivo para manter a redundância onde o projeto diz que ela está e
em nenhum outro lugar.
