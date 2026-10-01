---
title: Vence o prefixo mais longo
version: 1
---

A ideia errada vem dos firewalls: uma tabela de rotas é lida de cima para baixo, e a primeira linha
que bate vence. É assim que uma lista de regras de firewall funciona, e não é assim que uma tabela de
rotas funciona. **Quando várias rotas contêm um destino, vence a de prefixo mais longo**, onde quer
que ela esteja na lista e quando quer que tenha sido acrescentada. O prefixo mais longo diz mais sobre
o endereço, então é nele que se confia.

O r1 ganha mais duas rotas. A rede distante inteira, o /16, vai via ra; um pedaço dela,
10.30.5.0/24, vai via rb:

```
root@r1:~# ip route add 10.30.0.0/16 via 10.20.1.2
root@r1:~# ip route add 10.30.5.0/24 via 10.20.2.2
root@r1:~# ip route
default via 10.20.1.2 dev eth1 
10.20.1.0/30 dev eth1 proto kernel scope link src 10.20.1.1 
10.20.2.0/30 dev eth2 proto kernel scope link src 10.20.2.1 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.1 
10.30.0.0/16 via 10.20.1.2 dev eth1 
10.30.5.0/24 via 10.20.2.2 dev eth2 
```

Para 10.30.5.10, o endereço do far1, três dessas linhas batem: a padrão, que compara 0 bits; o /16,
que compara 16; e o /24, que compara 24. Para 10.30.7.10, o do far2, só duas: a padrão e o /16,
porque o terceiro número é 7 e não 5. Para 192.0.2.1, nada além da padrão. O `ip route get` faz à
tabela a pergunta que um pacote faria:

```
root@r1:~# ip route get 10.30.5.10
10.30.5.10 via 10.20.2.2 dev eth2 src 10.20.2.1 uid 0 
    cache 
root@r1:~# ip route get 10.30.7.10
10.30.7.10 via 10.20.1.2 dev eth1 src 10.20.1.1 uid 0 
    cache 
root@r1:~# ip route get 192.0.2.1
192.0.2.1 via 10.20.1.2 dev eth1 src 10.20.1.1 uid 0 
    cache 
```

**O 10.30.5.10 sai via rb pelo /24; o 10.30.7.10 via ra pelo /16; o 192.0.2.1 via ra pela padrão.** O
`/24` aparece por último no `ip route` e foi digitado por último, e nenhum dos dois fatos teve nada a
ver com isso: se tivesse sido digitado primeiro, as respostas seriam as mesmas. O traceroute confirma
que os pacotes vão mesmo por ali, cada um por um segundo salto diferente:

```
ana@pc1:~$ traceroute -n 10.30.5.10
traceroute to 10.30.5.10 (10.30.5.10), 30 hops max, 60 byte packets
 1  10.20.10.1  1.064 ms  0.211 ms  0.137 ms
 2  10.20.2.2  0.911 ms  0.574 ms  0.152 ms
 3  10.30.5.10  1.171 ms  0.637 ms  0.418 ms
ana@pc1:~$ traceroute -n 10.30.7.10
traceroute to 10.30.7.10 (10.30.7.10), 30 hops max, 60 byte packets
 1  10.20.10.1  1.685 ms  0.547 ms  0.386 ms
 2  10.20.1.2  0.336 ms  0.556 ms  0.432 ms
 3  10.30.7.10  1.608 ms  0.439 ms  0.364 ms
```

10.20.2.2 para o far1 e 10.20.1.2 para o far2, embora os dois PCs estejam na mesma rede, atrás do
mesmo switch.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Três rotas do r1 desenhadas como caixas aninhadas. A caixa de fora é a padrão, 0.0.0.0/0, que contém todo endereço e compara 0 bits. Dentro dela está 10.30.0.0/16, via ra, 16 bits. Dentro dessa está 10.30.5.0/24, via rb, 24 bits. O endereço 10.30.5.10 fica dentro da caixa mais interna e sai pelo rb. O 10.30.7.10 fica dentro do /16 mas fora do /24, e sai pelo ra. O 192.0.2.1 fica só dentro da padrão, e sai pelo ra.\"><rect x=\"14\" y=\"12\" width=\"692\" height=\"202\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.0.0.0/0</text><text x=\"100\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">padrão: todo endereço, 0 bits</text><rect x=\"40\" y=\"62\" width=\"640\" height=\"140\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.30.0.0/16</text><text x=\"150\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">via ra, 16 bits</text><rect x=\"66\" y=\"100\" width=\"290\" height=\"88\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"78\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.30.5.0/24</text><text x=\"176\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">via rb, 24 bits</text><circle cx=\"96\" cy=\"155\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"110\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.30.5.10</text><text x=\"110\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sai pelo rb</text><circle cx=\"420\" cy=\"145\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"434\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.30.7.10</text><text x=\"434\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sai pelo ra</text><circle cx=\"420\" cy=\"37\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"434\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.0.2.1</text><text x=\"434\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sai pelo ra, pela padrão</text></svg>", "caption": "As rotas se aninham, e um endereço sai pela caixa mais interna que o contém.", "same": ["via ra, 16 bits", "via rb, 24 bits"]}
```

O desenho é a regra. As rotas se aninham, porque um prefixo CIDR ou contém o outro ou não encosta
nele, e um destino cai pelas caixas até a mais interna que o contém. A padrão é a caixa em volta de
tudo, e por isso só vence quando nada dentro dela vence. **Uma rota mais específica é uma exceção recortada de uma mais ampla**, e é assim que elas são
usadas. Um resumo para um local inteiro pode ter uma sub-rede mandada por outro caminho; uma padrão
para o mundo pode deixar o espaço da própria empresa para rotas mais específicas; e o /24 daqui
desvia uma parte de uma rede por outro roteador.

Duas coisas que a regra deixa em aberto. Duas rotas para exatamente o mesmo prefixo têm o mesmo
tamanho, então o tamanho não escolhe entre elas; as próximas duas seções tratam do que escolhe. E roteadores de verdade fazem essa busca para milhões de pacotes por segundo. Num roteador que
carrega as rotas da internet a tabela chega a centenas de milhares de entradas, então ela é guardada
em estruturas feitas para achar depressa o prefixo mais longo, em hardware nos roteadores maiores. A
resposta a que chegam é a que foi calculada à mão aqui.
