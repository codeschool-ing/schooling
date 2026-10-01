---
title: Uma rede stub só precisa de uma rota padrão
version: 1
---

Uma **rede stub** tem uma entrada e uma saída, e nenhum tráfego a atravessa a caminho de outro lugar. O
lado de pc3 no laboratório pode virar uma: se r3 mandar tudo o que não é local para r1, pelo cabo
reserva, ele precisa de exatamente uma rota, não importa o que seja acrescentado ao resto da rede
depois.

A rota que casa com tudo é a **rota padrão**, `0.0.0.0/0`, que a aula 14 mostrou perdendo para qualquer
prefixo mais longo e vencendo quando nada mais casa. r3 apaga suas duas rotas específicas para a rede de
pc1, a principal e a flutuante, e acrescenta uma rota padrão no lugar delas:

```
root@r3:~# ip route del 10.20.1.0/24 via 10.20.23.1
root@r3:~# ip route del 10.20.1.0/24 via 10.20.13.1 metric 200
root@r3:~# ip route add default via 10.20.13.1
root@r3:~# ip route
default via 10.20.13.1 dev eth3 
10.20.3.0/24 dev eth0 proto kernel scope link src 10.20.3.1 
10.20.13.0/30 dev eth3 proto kernel scope link src 10.20.13.2 
10.20.23.0/30 dev eth2 proto kernel scope link src 10.20.23.2 
```

A tabela de r3 agora tem quatro linhas: a rota padrão e suas três redes conectadas. **Não há linha com a
rede de pc1**, e nenhuma é necessária. Qualquer destino que não seja de r3 vai para `10.20.13.1`.

O cabo de r1 a r2 continua puxado, e o ping que falhava na seção anterior agora funciona:

```
ana@pc1:~$ ping -c 2 -W 1 10.20.3.10
PING 10.20.3.10 (10.20.3.10) 56(84) bytes of data.
64 bytes from 10.20.3.10: icmp_seq=1 ttl=62 time=1.53 ms
64 bytes from 10.20.3.10: icmp_seq=2 ttl=62 time=1.22 ms

--- 10.20.3.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.222/1.373/1.525/0.151 ms
```

As respostas trazem `ttl=62` onde as anteriores traziam `61`. **Um roteador a menos no caminho de
volta**: r3 as entrega direto a r1 pelo cabo reserva, e r2 não está mais no caminho em nenhum dos
sentidos.

## Onde esse formato aparece

- *Uma filial* com um enlace até a matriz: uma rota padrão em direção à matriz, e a matriz guarda uma
  rota para o bloco da filial apontando de volta por esse enlace.
- *Uma casa ou um escritório pequeno* atrás de um provedor: uma rota padrão em direção ao provedor, que
  é o que o DHCP da aula 10 entrega a cada PC como gateway e o que o próprio roteador doméstico guarda em
  direção ao provedor.
- *O cliente de um provedor*: o provedor mantém uma rota estática para o bloco do cliente apontando
  para o enlace do cliente, e o cliente mantém uma rota padrão apontando de volta. Nenhum dos lados roda
  protocolo.

**Uma rede stub só precisa de uma rota padrão; a rede em volta dela precisa da rota específica de
volta.** As duas metades são estáticas, e são o mesmo par que esta aula digitou para pc1 e pc3, com um
dos lados reduzido a `0.0.0.0/0`.

## Onde uma rota padrão dá errado

**Uma rota padrão só é segura num roteador que tem mesmo uma saída só.** Dê a dois roteadores rotas
padrão que apontam um para o outro, e um pacote para um destino que nenhum dos dois conhece fica
quicando entre eles até o TTL acabar. Cada um entrega o pacote ao outro, certo de que o outro sabe.

É também por isso que a rota padrão de r3 foi pelo cabo reserva até r1, e não até r2. Com o cabo de r1 a
r2 ainda puxado, r2 não tem rota para a rede de pc1, então uma rota padrão em direção a r2 entregaria as
respostas de r3 a um roteador que só conseguiria responder `!N`. **Escolher para onde a rota padrão
aponta é a única decisão de roteamento que uma rede stub toma**, e ela tem de ser tomada sabendo o que
há atrás do próximo salto.

O padrão com que esta aula termina é o que sobrevive na prática: redes stub nas bordas com uma única rota
padrão, uma rota específica de volta para elas a partir do núcleo, e um protocolo de roteamento no meio
onde houver mais de um caminho. A aula 16 começa pelo meio.
