---
title: "Sumarização: uma rota para quatro sub-redes"
version: 1
---

O r2 alcança quatro sub-redes por uma rota, `10.20.32.0/24 via 10.20.32.225`. **Sumarizar é anunciar
um prefixo mais curto no lugar de vários mais longos que ele contém**, e é metade do motivo de planos
VLSM serem desenhados do jeito que as duas últimas seções desenharam um. As quatro sub-redes cabem
num resumo porque o plano as colocou lado a lado dentro de um /24. Se operações tivesse recebido um
/27 de 10.20.33.0, o r2 precisaria de uma segunda rota, ou de um resumo com o dobro do tamanho que
também reivindicaria endereços de outra pessoa.

O resumo é o prefixo que as sub-redes têm em comum. Escreva os endereços em binário e fique com os
bits que todos compartilham: 10.20.32.192/27 e 10.20.32.224/27 concordam nos primeiros 26 bits,
então juntos são 10.20.32.192/26, e as quatro sub-redes deste plano concordam nos primeiros 24, que é
o /24. **Um resumo só é tão arrumado quanto o plano por baixo dele**: blocos vizinhos e alinhados se
resumem numa linha, e blocos espalhados por uma faixa precisam de uma linha cada.

O que ele compra é tamanho e sossego. A tabela do r2 tem uma linha para o local inteiro, por mais
sub-redes que o r1 crie, e recortar um /28 novo do espaço livre depois muda o r1 e nada acima dele.
Numa empresa com dezenas de locais, cada um anunciando um resumo, essa é a diferença entre uma tabela
de dezenas de linhas e uma de milhares, e entre uma mudança num local ser notícia em toda parte ou em
parte nenhuma.

O que ele custa é que **um resumo cobre endereços que não existem em lugar nenhum**. Pergunte ao r2
sobre um endereço real e um vazio:

```
root@r2:~# ip route get 10.20.32.140
10.20.32.140 via 10.20.32.225 dev eth0 src 10.20.32.226 uid 0 
    cache 
root@r2:~# ip route get 10.20.32.250
10.20.32.250 via 10.20.32.225 dev eth0 src 10.20.32.226 uid 0 
    cache 
```

A mesma resposta para os dois: em direção ao r1. O 10.20.32.250 está no espaço livre do plano, então
o r1 não tem sub-rede para ele, e o r1 faz o que qualquer roteador faz com um endereço para o qual
não tem rota específica: usa a padrão, que aponta de volta para o r2. Um ping do hq1 mostra onde isso
termina:

```
ana@hq1:~$ ping -c 1 -W 1 10.20.32.250
PING 10.20.32.250 (10.20.32.250) 56(84) bytes of data.
From 10.20.32.225 icmp_seq=1 Time to live exceeded

--- 10.20.32.250 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 0ms

ana@hq1:~$ traceroute -n -m 6 10.20.32.250
traceroute to 10.20.32.250 (10.20.32.250), 6 hops max, 60 byte packets
 1  10.20.99.1  0.846 ms  0.222 ms  0.128 ms
 2  10.20.32.225  0.260 ms  0.177 ms  0.105 ms
 3  10.20.32.226  0.200 ms  0.133 ms  0.311 ms
 4  10.20.32.225  0.158 ms  0.103 ms *
 5  * * *
 6  * * *
```

`Time to live exceeded`, de 10.20.32.225, que é o r1. O pacote foi para o r1, voltou para o r2, foi
de novo para o r1, cada roteador tirando um do TTL, até que um deles tirou o último e avisou. O
traceroute desenha o círculo: o salto 2 é o r1, o salto 3 é o r2 em 10.20.32.226, o salto 4 é o r1 de
novo, e depois disso as respostas param de chegar e o limite de seis saltos (`-m 6`) o encerra.
**Isso é um loop de roteamento**, e numa rede movimentada é pior que um pacote perdido, porque cada
pacote em loop atravessa o mesmo enlace de novo e de novo até o TTL acabar.

A correção é fazer o r1 ser dono do resumo inteiro, para que o que cai dentro dele e não bate com
nenhuma sub-rede seja recusado no r1 em vez de mandado de volta. Uma rota resolve:

```
root@r1:~# ip route add unreachable 10.20.32.0/24
ana@hq1:~$ ping -c 1 -W 1 10.20.32.250
PING 10.20.32.250 (10.20.32.250) 56(84) bytes of data.
From 10.20.32.225 icmp_seq=1 Destination Host Unreachable

--- 10.20.32.250 ping statistics ---
1 packets transmitted, 0 received, +1 errors, 100% packet loss, time 1ms

ana@hq1:~$ ping -c 1 -q 10.20.32.140
PING 10.20.32.140 (10.20.32.140) 56(84) bytes of data.

--- 10.20.32.140 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.725/0.725/0.725/0.000 ms
```

`unreachable 10.20.32.0/24` é uma rota cuja resposta é "não". As quatro sub-redes do r1 são prefixos
mais longos que o /24, então continuam vencendo para os endereços que contêm (a aula 14 trata dessa
regra), e o ping para 10.20.32.140 é respondido como antes. Um endereço no espaço livre agora não bate
com nada mais específico que o /24, e o r1 responde na hora: `Destination Host Unreachable`, um
pacote, sem círculo.

**Quem anuncia um resumo deve ter uma rota que descarte o que o resumo não contém.** Os protocolos de
roteamento que sumarizam em geral instalam essa rota sozinhos, apontando para uma interface de
descarte que a Cisco chama de Null0; com rotas estáticas, como aqui, é mais uma linha para lembrar.
