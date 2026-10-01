---
title: "A rota padrão: para onde vai todo o resto"
version: 1
---

A rota mais simples de acrescentar é a que cobre tudo. **A rota padrão é o prefixo 0.0.0.0/0: zero
bits a comparar, então todo endereço bate com ela.** É para lá que vai um pacote quando nada mais
específico o reivindica, e num host ela tem um nome mais conhecido, o gateway padrão. O r1 ganha uma
em direção ao ra:

```
root@r1:~# ip route add default via 10.20.1.2
root@r1:~# ip route
default via 10.20.1.2 dev eth1 
10.20.1.0/30 dev eth1 proto kernel scope link src 10.20.1.1 
10.20.2.0/30 dev eth2 proto kernel scope link src 10.20.2.1 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.1 
```

`default via 10.20.1.2 dev eth1`. Só o próximo salto foi digitado; o r1 deduziu o `dev eth1` sozinho,
porque 10.20.1.2 está dentro de 10.20.1.0/30, a rota conectada da eth1. Isso é uma regra, não uma
conveniência. **Um próximo salto precisa estar numa rede à qual o roteador está diretamente
conectado**, porque o roteador entrega o pacote a ele pelo endereço de hardware, através de um cabo.
O Linux recusa um `via` que não consegue alcançar desse jeito.

O pc1 tenta de novo, desta vez com traceroute:

```
ana@pc1:~$ traceroute -n 10.30.5.10
traceroute to 10.30.5.10 (10.30.5.10), 30 hops max, 60 byte packets
 1  10.20.10.1  2.829 ms  0.366 ms  0.189 ms
 2  10.20.1.2  1.062 ms  0.243 ms  0.201 ms
 3  10.30.5.10  2.240 ms  0.356 ms  0.229 ms
```

Três saltos: o r1 em 10.20.10.1, o ra em 10.20.1.2, e o far1. O r1 continua sem nenhuma rota que
mencione 10.30.0.0/16; a padrão levou o pacote ao ra, e o ra, que está naquela rede, o entregou. (Os
tempos são o computador único deste laboratório falando consigo mesmo.)

**Uma rota funciona num sentido só.** As respostas do traceroute voltaram porque o ra e o rb já
tinham uma rota para 10.20.0.0/16 apontando para o r1, montada com o laboratório e não digitada nesta
aula, e a padrão do próprio far1 aponta para o ra. Tire a rota do ra e a padrão do r1 ainda
entregaria cada pacote, e nenhuma das respostas acharia o caminho de casa. Quando um ping falha, a
rota que falta tem tanta chance de estar na volta quanto na ida.

Um host é a mesma máquina com uma tabela mais curta. A do pc1 é a sua sub-rede e `default via
10.20.10.1`, as duas linhas que a aula 10 viu o DHCP entregar: um endereço com a máscara, e o gateway
vindo de `option routers`. O gateway precisa estar dentro da sub-rede do host, pelo mesmo motivo que
o próximo salto de um roteador precisa.

A maioria dos roteadores também tem uma padrão, apontando para o resto do mundo: o roteador de um
escritório para o provedor, uma filial para a matriz. Ela deixa a tabela curta, e tem um preço. **Um
roteador com rota padrão nunca diz `Destination Net Unreachable`**; ele manda o que não conhece pela
padrão, e um erro viaja nessa direção. A aula 13 mostrou o pior caso: dois roteadores cujas rotas
apontavam um para o outro passaram um pacote para um endereço vazio de lá para cá até o TTL acabar.
