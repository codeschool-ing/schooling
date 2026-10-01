---
title: SLAAC, um endereço montado a partir de um anúncio
version: 1
---

O hábito do IPv4 diz que um PC recebe o endereço de um servidor DHCP, assunto da aula 10. O IPv6 também
tem DHCP, mas **na maioria das LANs os PCs montam sozinhos os seus endereços globais**. O roteador
anuncia o prefixo da rede, e cada máquina cola o seu identificador de interface no fim. Isso é o
**SLAAC**, autoconfiguração de endereço sem estado (*stateless address autoconfiguration*): sem estado
porque ninguém guarda uma lista de quem tem qual endereço.

O anúncio é um **Router Advertisement** (anúncio de roteador), uma mensagem ICMPv6. O r1 roda um
programa chamado radvd que manda um a cada 30 a 100 segundos na configuração deste laboratório, e
também em resposta a um **Router Solicitation** (pedido de roteador), que uma máquina manda para
perguntar. O `rdisc6` manda essa pergunta, para `ff02::2`, o endereço em que todo roteador de um
enlace escuta, e imprime a resposta:

```
ana@pc2:~$ rdisc6 eth0
Soliciting ff02::2 (ff02::2) on eth0...

Hop limit                 :           64 (      0x40)
Stateful address conf.    :           No
Stateful other conf.      :           No
Mobile home agent         :           No
Router preference         :       medium
Neighbor discovery proxy  :           No
Router lifetime           :          300 (0x0000012c) seconds
Reachable time            :  unspecified (0x00000000)
Retransmit time           :  unspecified (0x00000000)
 Prefix                   : 2001:db8:20:10::/64
  On-link                 :          Yes
  Autonomous address conf.:          Yes
  Valid time              :        86400 (0x00015180) seconds
  Pref. time              :        14400 (0x00003840) seconds
 Source link-layer address: 02:1F:23:E7:E9:D5
 from fe80::1f:23ff:fee7:e9d5
```

Leia de cima para baixo. `Hop limit: 64` é o limite de saltos inicial que o roteador sugere para os
pacotes, o nome que o IPv6 dá ao TTL do IPv4. `Stateful address conf.: No` é o roteador dizendo que não
há servidor DHCPv6 distribuindo endereços aqui. `Router lifetime: 300` diz que o r1 pode servir de
roteador padrão pelos próximos 300 segundos; um anúncio novo renova o prazo. Depois, a parte que mais
importa: **o prefixo `2001:db8:20:10::/64`, com `Autonomous address conf.: Yes`, que é o roteador
dizendo a cada máquina para montar o próprio endereço a partir dele**. `On-link: Yes` diz que todo
endereço do prefixo é alcançável direto, sem o roteador. A última linha,
`from fe80::1f:23ff:fee7:e9d5`, é o endereço link-local do r1 da seção anterior: roteadores anunciam a
partir do endereço link-local.

O pc2 fez o que lhe disseram:

```
ana@pc2:~$ ip -6 addr show eth0 scope global
30: eth0@if29: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netns sw1
    inet6 2001:db8:20:10:fd:f2ff:fed2:63ba/64 scope global dynamic mngtmpaddr 
       valid_lft 86396sec preferred_lft 14396sec
ana@pc2:~$ ip -6 route
2001:db8:20:10::/64 dev eth0 proto kernel metric 256 expires 86394sec pref medium
fe80::/64 dev eth0 proto kernel metric 256 pref medium
default via fe80::1f:23ff:fee7:e9d5 dev eth0 proto ra metric 1024 expires 294sec hoplimit 64 pref medium
```

O endereço do pc2 é `2001:db8:20:10:fd:f2ff:fed2:63ba`: o prefixo anunciado, depois um identificador
com `ff:fe` no meio, montado a partir do MAC do pc2 exatamente como o endereço link-local do pc1.
`dynamic` marca um endereço que veio de um anúncio e vai expirar se não for renovado.

Os dois prazos vêm das linhas do prefixo no anúncio. `Valid time: 86400` segundos é um dia,
`Pref. time: 14400` segundos são quatro horas, e o pc2 mostra os dois em contagem regressiva:
`valid_lft 86396sec preferred_lft 14396sec`, quatro segundos depois de ouvi-los. **Enquanto dura o
prazo preferido, o endereço é usado para conexões novas.** Depois dele, o endereço fica obsoleto
(*deprecated*) e só serve às conexões já abertas, e quando acaba o prazo de validade ele some.
Cada anúncio novo reinicia os dois relógios, então numa rede saudável nenhum dos dois chega a zero. Um
roteador que para de anunciar é uma rede cujos endereços vão sumindo ao longo de um dia.

A tabela de rotas tem a última surpresa. **A rota padrão é `via fe80::1f:23ff:fee7:e9d5`, o endereço
link-local do r1, e não o global**, com `proto ra` dizendo que ela veio do anúncio e `expires 294sec`
contando o prazo de 300 do roteador. Isso é normal no IPv6: um gateway só precisa ser alcançável no
enlace, e o endereço link-local é o que não muda quando a rede troca de numeração. É também por isso
que um gateway mostrado como `fe80::…` vem sempre junto com uma interface, aqui `dev eth0`.

O srv não participou de nada disso. O lab.sh desligou a autoconfiguração nele e lhe deu
`2001:db8:20:10::10` à mão, como costuma ser com servidores: **o endereço de um servidor não deve
depender de qual placa de rede ele tem hoje**. Uma placa trocada, com SLAAC e EUI-64, quer dizer um
endereço novo, e todo cliente que tinha o antigo anotado para de funcionar.
