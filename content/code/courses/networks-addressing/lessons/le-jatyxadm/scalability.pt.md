---
title: Escalabilidade, crescer sem recomeçar
version: 1
---

Um projeto **escala** quando consegue crescer acrescentando mais das mesmas peças, sem mudar as peças
que já estão lá. O teste é concreto: quando o campus ganha um prédio, o que precisa mudar? Num bom
projeto, o prédio novo traz o próprio par de distribuição e os switches de acesso, liga no núcleo, e
**nada mais é tocado**. Num projeto ruim, todo roteador aprende uma lista comprida de rotas novas e
alguém edita as regras de firewall de todos os andares.

Duas coisas crescem quando uma rede cresce: o equipamento e as tabelas de rotas. A hierarquia da primeira
seção cuida do equipamento. As tabelas são a parte que as pessoas esquecem, então conte. Esta é a do c1,
inteira:

```
root@c1:~# ip route
10.20.0.0/30 dev eth1 proto kernel scope link src 10.20.0.1 
10.20.0.4/30 dev eth2 proto kernel scope link src 10.20.0.5 
10.20.0.8/30 dev eth3 proto kernel scope link src 10.20.0.9 
10.20.0.12/30 nhid 24 proto ospf metric 20 
	nexthop via 10.20.0.2 dev eth1 weight 1 
	nexthop via 10.20.0.6 dev eth2 weight 1 
10.20.0.16/30 nhid 33 proto ospf metric 20 
	nexthop via 10.20.0.2 dev eth1 weight 1 
	nexthop via 10.20.0.10 dev eth3 weight 1 
10.20.11.0/24 nhid 25 via 10.20.0.6 dev eth2 proto ospf metric 20 
10.20.12.0/24 nhid 34 via 10.20.0.10 dev eth3 proto ospf metric 20 
root@c1:~# ip route | wc -l
11
```

O `wc -l` conta 11 linhas, mas a tabela tem **7 rotas**: quatro linhas que começam com uma tabulação são
as continuações `nexthop` das duas rotas acima delas, que têm cada uma dois caminhos iguais. As sete
são:

- **5 links**, uma `/30` por cabo: `10.20.0.0/30`, `.4/30` e `.8/30` são os cabos do próprio c1
  (`proto kernel`, aprendidas por ter um endereço neles), e `.12/30` e `.16/30` são cabos em outro ponto
  do campus, aprendidos pelo OSPF;
- **2 LANs**: `10.20.11.0/24` pelo d1 e `10.20.12.0/24` pelo d2.

Então cada cabo acrescenta uma rota, e cada LAN de acesso acrescenta uma rota, em todo roteador. Neste
tamanho não importa. Com quarenta prédios, cada um com um par de distribuição e uma dúzia de LANs, são
centenas de rotas em cada roteador de núcleo, cada uma recalculada sempre que qualquer cabo em qualquer
lugar cai.

## Endereços que se resumem

A defesa é um **plano de endereços que se resume**: endereços distribuídos em blocos alinhados com a
hierarquia, para que uma rota curta valha por muitas compridas. O campus já faz isso em dois lugares:

- **Todo link vem de uma /24.** `10.20.0.0/24` cortada em `/30`s comporta 64 links. Qualquer coisa fora
  do campus que precise alcançar os links precisa de uma rota, `10.20.0.0/24`, não de uma por cabo.
- **Toda LAN é uma /24 dentro de 10.20.0.0/16.** A `10.20.11.0/24` do pc1 e a `10.20.12.0/24` do pc2
  ficam lado a lado. Para o resto da rede de uma empresa, o campus inteiro pode ser **uma rota:
  `10.20.0.0/16`**.

Distribua endereços na ordem em que as pessoas pedem — a LAN da contabilidade aqui, os links do próximo
prédio ali — e nenhuma rota se resume nunca, porque os blocos não se alinham com nada. **Um plano de
endereços é barato no primeiro dia e impossível de mudar no milésimo**, já que todo aparelho, toda regra
de firewall e todo documento carregam os endereços.

A conta das máscaras e de quantos hosts um bloco comporta é a aula 12; cortar um bloco em pedaços de
tamanhos diferentes, como o campus faz com suas `/30`s e `/24`s, é a aula 13; e fazer o OSPF anunciar um
resumo no lugar de muitas rotas fica para a aula 16. Esta seção só pede que você olhe uma tabela e conte.

## O outro tipo de crescimento

Escalabilidade também quer dizer que as pessoas conseguem acompanhar. Um projeto com um tipo de switch de
acesso, um tipo de par de distribuição e um jeito de numerar as coisas pode ser estendido por alguém que
não o montou. Um projeto em que cada prédio é um caso especial não pode, por mais rápidos que sejam os
roteadores. Essa é a ponte para a última seção desta aula: o que não está escrito não escala.
