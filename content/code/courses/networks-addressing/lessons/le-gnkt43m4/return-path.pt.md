---
title: Toda rota precisa do caminho de volta
version: 1
---

**Uma rota aponta num sentido só.** A linha de r1 para `10.20.3.0/24` diz como chegar lá e nada sobre
como voltar, e um ping são duas viagens. A resposta de pc3 começa em r3, então r3 precisa de uma rota
para a rede de pc1, e r2, que a resposta atravessa em seguida, também precisa:

```
root@r3:~# ip route add 10.20.1.0/24 via 10.20.23.1
root@r2:~# ip route add 10.20.1.0/24 via 10.20.12.1
```

Agora o ping:

```
ana@pc1:~$ ping -c 2 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.
64 bytes from 10.20.3.10: icmp_seq=1 ttl=61 time=1.39 ms
64 bytes from 10.20.3.10: icmp_seq=2 ttl=61 time=1.31 ms

--- 10.20.3.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.311/1.352/1.394/0.041 ms
```

Duas respostas, nenhuma perda. `ttl=61` conta os roteadores no caminho de volta: pc3 mandou a resposta
com TTL 64, e r3, r2 e r1 tiraram um cada. O `1.39 ms` é este laboratório, três namespaces numa máquina
virtual, e não diz nada sobre redes reais.

O `traceroute` nomeia cada roteador na ida:

```
ana@pc1:~$ traceroute -n 10.20.3.10
traceroute to 10.20.3.10 (10.20.3.10), 30 hops max, 60 byte packets
 1  10.20.1.1  2.280 ms  0.278 ms  0.197 ms
 2  10.20.12.2  0.256 ms  0.240 ms  0.305 ms
 3  10.20.23.2  0.341 ms  0.190 ms  0.125 ms
 4  10.20.3.10  0.840 ms  0.212 ms  0.107 ms
```

Quatro saltos: o endereço de r1 na rede de pc1, a ponta de r2 no primeiro `/30`, a ponta de r3 no
segundo, e pc3. Há um detalhe aqui que merece um segundo olhar. **r1 continua sem rota para
`10.20.23.0/30`**, o cabo entre r2 e r3, e o salto 3 imprimiu `10.20.23.2` mesmo assim. Funciona porque
a resposta de r3 ao traceroute era endereçada a `10.20.1.10`, e todo roteador no caminho de volta tem
rota para a rede de pc1. Uma rota é necessária para o destino de cada pacote, não para cada endereço que
aparece na conversa.

r2 está no meio, então sua tabela mostra as duas metades do trabalho:

```
root@r2:~# ip route
10.20.1.0/24 via 10.20.12.1 dev eth1 
10.20.3.0/24 via 10.20.23.2 dev eth2 
10.20.12.0/30 dev eth1 proto kernel scope link src 10.20.12.2 
10.20.23.0/30 dev eth2 proto kernel scope link src 10.20.23.1 
```

Duas rotas digitadas, uma para cada sentido, e seus dois `/30` conectados. **As linhas estáticas não
trazem `proto kernel`**: elas não derivam de um endereço numa interface, foram adicionadas. Essa
diferença é como você descobre, num roteador que não configurou, por quais linhas uma pessoa é
responsável.

## Contando as rotas

As duas redes de PCs precisaram de quatro rotas: r1 e r2 em direção a `10.20.3.0/24`, r3 e r2 em direção
a `10.20.1.0/24`. **Cada roteador no caminho precisa de uma rota para cada rede à qual não está
conectado e para a qual tem de encaminhar.** Acrescente uma terceira rede atrás de r2 e r1 e r3 precisam
de mais uma linha cada, e tudo o que deve alcançá-la a partir das outras redes precisa também do caminho
de volta.

Dois hábitos decorrem disso:

- *Escreva os dois sentidos na mesma mudança.* Um pedido de mudança que acrescenta a rota de ida para
  uma rede e não a de volta é meia mudança, e a metade que falta falha em silêncio, como a seção anterior
  mostrou.
- *Teste das duas pontas.* Um ping de pc1 testa os dois sentidos de uma vez e não diz qual deles
  quebrou. Um `traceroute` de cada lado, ou uma captura na outra ponta, diz.

Os caminhos de ida e de volta não precisam ser iguais. Nesta cadeia são, porque só existe um caminho
através de r2. A próxima seção acrescenta um segundo caminho, e daí em diante os dois sentidos podem se
separar, e é aí que o roteamento estático se complica.
