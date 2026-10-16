---
title: IPs virtuais e DNS
version: 1
---

As duas abordagens que este laboratório não consegue mostrar com honestidade, porque as duas dependem
de mais de uma máquina.

Um **IP virtual** é um endereço que não pertence a nenhum servidor específico: a máquina que for o
primário adiciona o endereço à sua própria interface de rede e o anuncia na rede, e a aplicação
conecta nesse endereço. Num failover, o novo primário assume o endereço. Ferramentas como o
`keepalived`, ou o `vip-manager`, que lê a chave de líder do Patroni no etcd, fazem a troca. É rápido,
e só funciona onde a rede deixa um endereço passar de uma máquina para outra, o que a maioria das
nuvens não deixa: lá, um **load balancer** fornecido pela nuvem cumpre o mesmo papel, e é um proxy com
outro nome.

O **DNS** coloca o primário atrás de um nome, e um failover altera o registro. Não precisa de nenhuma
rede especial, e demora a fazer efeito de jeitos que ninguém controla: cada resolver no caminho, e
muitas vezes o próprio runtime da aplicação, guarda em cache a resposta antiga por pelo menos o **TTL**
do registro, e alguns por mais tempo. Um TTL de poucos segundos ajuda e custa uma consulta a cada
conexão. O DNS combina mais com um switchover planejado e avisado com antecedência do que com um
failover às três da manhã.

Seja qual for a das quatro que um sistema usa, teste do jeito que a última seção fez: troque, e
**observe o que uma aplicação de fato vive**, não o que o gerenciador do cluster informa.
