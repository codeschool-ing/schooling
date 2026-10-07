---
title: Convergência: a falha com a luz ainda acesa
version: 2
---

**Convergência** é o tempo entre algo mudar e todos os roteadores concordarem com os novos caminhos.
Até ela terminar, alguns pacotes vão em direção a um caminho que não funciona mais, e se perdem.

A falha fácil é um cabo puxado. A interface perde o sinal, o roteador vê na hora, como r1 viu na aula 15,
e o OSPF recalcula em instantes. **A falha difícil é a que deixa o sinal no ar**: um conversor de mídia, ou
um switch entre dois roteadores, morre ainda alimentando a porta, e o cabo parece perfeito das duas
pontas. O laboratório encenou isso entre r1 e r4, com regras em r1 que descartam todo quadro em `eth4`
nos dois sentidos. A interface continua no ar; nada passa. Estas são as regras, digitadas num prompt de
root no r1, e `nft delete table netdev cut; nft delete table inet cutout` as remove:

```sh
nft add table netdev cut
nft add chain netdev cut in "{ type filter hook ingress device eth4 priority 0; policy drop; }"
nft add table inet cutout
nft add chain inet cutout out "{ type filter hook output priority 0; }"
nft add rule inet cutout out oifname eth4 drop
nft add chain inet cutout fwd "{ type filter hook forward priority 0; }"
nft add rule inet cutout fwd oifname eth4 drop
```

Primeiro começou um ping de pc1 para pc2, um pacote por segundo durante 70 segundos, e o corte veio dois
segundos depois. Vinte segundos após o corte, r1 ainda acreditava em r4:

```
root@r1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.20.2.1         1 Full/-          46.216s           35.402s 10.20.0.2       eth1:10.20.0.1                       0     0     0
10.20.0.13        1 Full/-          46.223s            8.651s 10.20.0.13      eth4:10.20.0.14                      2     0     0

```

r4, `10.20.0.13`, continua em `Full`, com **`8.651s`** restando no temporizador de morte: os hellos
pararam de chegar quando os quadros pararam, e a contagem que começou em 40 segundos está quase no fim.
`RXmtL 2` é a lista de retransmissão de r1, duas atualizações que ele mandou a r4 e cuja confirmação ainda
espera. Até o temporizador acabar, a tabela de r1 continua mandando o tráfego de pc1 para r4, e todo pacote
se perde.

Enquanto isso o ping de pc1 rodou até o fim, e imprimiu seu resumo:

```
ana@pc1:~$ ping -c 70 -i 1 -q 10.20.2.10
PING 10.20.2.10 (10.20.2.10) 56(84) bytes of data.

--- 10.20.2.10 ping statistics ---
70 packets transmitted, 40 received, +21 errors, 42.8571% packet loss, time 69901ms
rtt min/avg/max/mdev = 0.434/1.257/4.335/0.694 ms, pipe 3
```

**70 enviados, 40 respondidos.** Os outros 30 se perderam, e o ping contou 21 mensagens de erro pelo
caminho. A um pacote por segundo, isso é **cerca de 30 segundos sem caminho** entre pc1 e pc2, e quase tudo
é o intervalo de morte sendo esperado. O cálculo do SPF em si, quando rodou, não foi o que tomou o tempo.

Depois disso r4 some da lista, e o tráfego toma o único caminho que restou, o cabo direto e caro:

```
root@r1:~# vtysh -c "show ip ospf neighbor"

Neighbor ID     Pri State           Up Time         Dead Time Address         Interface                        RXmtL RqstL DBsmL
10.20.2.1         1 Full/-          1m34s             36.799s 10.20.0.2       eth1:10.20.0.1                       0     0     0

ana@pc1:~$ traceroute -n 10.20.2.10
traceroute to 10.20.2.10 (10.20.2.10), 30 hops max, 60 byte packets
 1  10.20.1.1  0.854 ms  0.201 ms  0.375 ms
 2  10.20.0.2  0.263 ms  0.210 ms  0.388 ms
 3  10.20.2.10  0.181 ms  0.154 ms  0.104 ms
```

## Tornando mais rápido

**O intervalo de morte é o tempo de convergência de uma falha silenciosa**, então a alavanca são os
temporizadores. O anel da aula 3 rodava o OSPF com um hello por segundo e um intervalo de morte de quatro
segundos, e é por isso que um cabo quebrado ali era percebido em quatro segundos em vez de quarenta. O
preço são mais hellos em cada enlace e uma chance maior de declarar morto um vizinho ocupado que só demorou
a responder, e os temporizadores têm de bater nas duas pontas de cada enlace.

A resposta comum em redes reais é o **BFD** (*Bidirectional Forwarding Detection*), que a aula 15 citou:
um protocolo separado e muito leve que troca hellos várias vezes por segundo e avisa o OSPF no instante em
que um vizinho para de responder, e assim os temporizadores do próprio OSPF ficam nos padrões. Ele não foi
executado neste laboratório.

A aritmética para guardar: **uma falha que derruba o sinal custa o tempo de recalcular; uma falha que
mantém o sinal custa antes o intervalo de morte.** Quando você projeta redundância, é o segundo número que
diz quanto tempo a redundância leva para funcionar.
