---
title: Registrando, e o que o registro é
version: 1
---

Cada instância, ao subir, mandou ao Consul o nome, `stock`, o próprio endereço e um health check para
rodar. Pergunte ao registro, como uma biblioteca cliente faria, as instâncias que estão passando:

```
ana@vm:~/lab/gateway$ $D stock
3 healthy instance(s) of stock
  stock-1 at 172.18.0.6:8000
  stock-2 at 172.18.0.5:8000
  stock-3 at 172.18.0.3:8000
```

Três instâncias, cada uma no endereço que o Docker deu ao contêiner dela, e ninguém anotou nenhum.
Isso é **auto-registro** (*self-registration*): cada instância se anuncia. A alternativa, o **registro
por terceiros** (*third-party registration*), deixa a plataforma fazer isso em nome da instância; o
Kubernetes, que sobe todo contêiner, o registra como parte de subi-lo, e a aplicação nem fica sabendo.

O registro é o componente do qual todo outro depende para achar qualquer coisa, então não pode ser uma
máquina só que falha. O Consul guarda o catálogo num cluster **Raft** de servidores:

```
ana@vm:~/lab/gateway$ docker compose exec consul consul operator raft list-peers
Node          ID                                    Address         State   Voter  RaftProtocol  Commit Index  Trails Leader By
dc9cab511ced  c072e083-9c16-1313-1091-d748802d3c50  127.0.0.1:8300  leader  true   3             23            -
```

Um par, o líder, sem ninguém para segui-lo, porque o laboratório roda o Consul em modo de
desenvolvimento. Um cluster Consul de verdade roda três ou cinco servidores, e a aula 10 explicou por quê:
uma maioria de três sobrevive a uma falha, e dois servidores não sobreviveriam a nenhuma. O **etcd**, que
guarda o estado do Kubernetes, e o **ZooKeeper** são o mesmo tipo de armazenamento pelo mesmo motivo. A
aula 8 pôs essa família do lado consistente, e eis por que ela pertence a ele: as duas metades de um
cluster dividido entregando cada uma uma lista diferente de instâncias é uma falha pior que um registro
que se recusa a mudar até o cabo ser consertado.
