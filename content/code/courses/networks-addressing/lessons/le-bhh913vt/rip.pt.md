---
title: RIP: contando roteadores
version: 1
---

O **RIP** (*Routing Information Protocol*) é o protocolo mais antigo aqui e o mais simples de ler. Sua
métrica é o número de roteadores entre você e uma rede, e ele acredita no que os vizinhos dizem. Três
linhas o ligam, digitadas no `vtysh` do FRR em r1 e iguais nos outros três:

```
root@r1:~# vtysh -c "configure terminal" -c "router rip" -c "version 2" -c "network 10.20.0.0/16"
```

`version 2` é a versão que leva uma máscara com cada rota, que é do que as sub-redes da aula 12 precisam;
a versão 1 supunha as antigas fronteiras de classe. `network 10.20.0.0/16` diz *fale RIP em toda
interface com endereço dentro desta faixa*, que aqui são todas.

Alguns segundos depois, r1 já ouviu os dois vizinhos:

```
root@r1:~# vtysh -c "show ip rip"
Codes: R - RIP, C - connected, S - Static, O - OSPF, B - BGP
Sub-codes:
      (n) - normal, (s) - static, (d) - default, (r) - redistribute,
      (i) - interface

     Network            Next Hop         Metric From            Tag Time
C(i) 10.20.0.0/30       0.0.0.0               1 self              0
R(n) 10.20.0.4/30       10.20.0.2             2 10.20.0.2         0 02:55
R(n) 10.20.0.8/30       10.20.0.13            2 10.20.0.13        0 02:58
C(i) 10.20.0.12/30      0.0.0.0               1 self              0
C(i) 10.20.1.0/24       0.0.0.0               1 self              0
R(n) 10.20.2.0/24       10.20.0.2             2 10.20.0.2         0 02:55
```

Leia a coluna `Metric`. **As redes do próprio r1 estão em 1, e tudo o que foi aprendido de um vizinho está
em 2**: o vizinho disse 1, e r1 somou um por si. A rede de pc2, `10.20.2.0/24`, veio de `10.20.0.2`, que é
r2 pelo cabo direto. A `10.20.0.8/30` entre r3 e r4 veio de r4, `10.20.0.13`, à mesma distância.

A coluna `Time` é uma contagem regressiva. Todo roteador RIP manda a tabela inteira aos vizinhos a cada 30
segundos, e **uma rota que não é renovada por 180 segundos é declarada inválida**; `02:55` é uma rota
ouvida cinco segundos atrás. Esse temporizador é o único jeito que o RIP tem de perceber um vizinho morto.

As rotas estão no kernel agora:

```
root@r1:~# ip route
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1 
10.20.0.4/30 nhid 14 via 10.20.0.2 dev eth1 proto rip metric 20 
10.20.0.8/30 nhid 17 via 10.20.0.13 dev eth4 proto rip metric 20 
10.20.0.12/30 dev eth4 proto kernel scope link src 10.20.0.14 
10.20.1.0/24 dev eth0 proto kernel scope link src 10.20.1.1 
10.20.2.0/24 nhid 14 via 10.20.0.2 dev eth1 proto rip metric 20 
```

`proto rip` as marca. O `metric 20` aqui não é a contagem de saltos: é um número que o FRR escreve em toda
rota que instala, e as rotas BGP da aula 17 trazem o mesmo 20. pc1 alcança pc2 pelo cabo direto, com um
roteador entre os dois:

```
ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  5.897 ms  0.612 ms  0.503 ms
 2  10.20.0.2  1.022 ms  0.219 ms  0.215 ms
 3  10.20.2.10  1.784 ms  0.669 ms  0.574 ms
```

## O que o RIP não enxerga

**O RIP conta roteadores e mais nada.** Um salto por um circuito alugado lento e um salto por uma fibra
de dez gigabits contam 1 os dois. As seções de OSPF desta aula tornam caro o cabo direto entre r1 e r2, e o
RIP não tem como ser avisado.

**Seu alcance é quinze.** Uma métrica 16 quer dizer inalcançável, então uma rede a mais de quinze
roteadores de distância não é alcançável com RIP. Esse limite é proposital, e existe por causa do pior
hábito do RIP: quando uma rede some, os vizinhos continuam oferecendo uns aos outros versões antigas da
rota, cada um somando um, **contando até o infinito** até o número chegar a 16. O *split horizon*, não
anunciar uma rota de volta pela interface por onde ela foi aprendida, e o *poisoned reverse*,
anunciá-la de volta como 16, encurtam isso, e o temporizador de 180 segundos ainda deixa o RIP lento para
esquecer.

O RIP raramente é escolhido para uma rede nova. Ele sobrevive em equipamentos pequenos, em instalações
antigas e em provas, porque é o exemplo mais claro de vetor de distância que existe. Antes de o OSPF ser
digitado, o RIP foi desligado nos quatro roteadores:

```
root@r1:~# vtysh -c "configure terminal" -c "no router rip"
```
