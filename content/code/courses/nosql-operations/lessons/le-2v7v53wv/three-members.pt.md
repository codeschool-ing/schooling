---
title: Três membros, um primário
version: 1
---

Um replica set parece três bancos que se copiam, e não é. **É um banco só, guardado em três cópias,
e exatamente uma cópia recebe escritas.** Essa cópia é o **primário**. As outras duas são
**secundários**: copiam o que o primário fez, na ordem em que fez, e qualquer uma pode assumir o
lugar dele quando ele sai.

Três é o menor número que funciona. Com duas cópias, um membro que deixa de ouvir o parceiro não
distingue um parceiro morto de um cabo cortado, que é a partição da aula 1 sem ninguém para
desempatar. Com três, quaisquer dois são uma **maioria**, e a maioria sustenta todas as decisões
desta aula: quem é primário, quais escritas contam como seguras e qual lado de uma rede partida
continua funcionando.

## O que esta aula precisa

A rede `nosql` da aula 1 e três contêineres novos. Pare o `mongo` único da aula 1 para devolver a
memória à VM, e crie a rede se esta máquina nunca a teve:

```sh
docker stop mongo
docker network create nosql
```

Se a rede já existir, a segunda linha falha e nada mais muda.

## Três servidores que sabem que pertencem a um conjunto

```sh
docker run -d --name mongo1 --hostname mongo1 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
docker run -d --name mongo2 --hostname mongo2 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
docker run -d --name mongo3 --hostname mongo3 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
```

Tudo o que vem depois de `mongo:8.0` substitui o comando padrão da imagem, então cada contêiner roda
o `mongod` com duas configurações próprias. `--replSet rs0` dá nome ao conjunto ao qual o servidor
pertence. `--bind_ip_all` faz o servidor escutar na rede além de em `127.0.0.1`, que é tudo o que o
`mongod` escuta por padrão; sem isso os outros dois não o alcançariam. `--hostname` dá a cada
contêiner o mesmo nome por dentro e na rede, para que toda resposta que cita um host diga `mongo1`
em vez de um id de contêiner.

```
ana@vm:~$ docker run -d --name mongo1 --hostname mongo1 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
c8956ec01b97034f5a583e53dde98bf01a26d6d4b3fd8cf34b96148278a06f4e
ana@vm:~$ docker run -d --name mongo2 --hostname mongo2 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
1c02c81c47b9f936f9d7f23147b5f8a1489b201b72217470efb6e04d016c9952
ana@vm:~$ docker run -d --name mongo3 --hostname mongo3 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all
26bbba0ee053f30c285ba22b47fdd06d417f4f8632fd76fa024b273c61b62a1e
```

## Formando o conjunto

Três servidores iniciados com `--replSet` ainda não são um conjunto: cada um espera ser informado de
quem são os outros. O `rs.initiate` informa um deles, citando cada membro pelo nome que a rede
resolve, e esse membro repassa a configuração aos demais:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet
test> rs.initiate({ _id: "rs0", members: [ { _id: 0, host: "mongo1:27017" }, { _id: 1, host: "mongo2:27017" }, { _id: 2, host: "mongo3:27017" } ] })
{
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1791618858, i: 1 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: Long('0')
    }
  },
  operationTime: Timestamp({ t: 1791618858, i: 1 })
}
rs0 [direct: secondary] test> rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))
[
  { name: 'mongo1:27017', state: 'PRIMARY', health: 1 },
  { name: 'mongo2:27017', state: 'SECONDARY', health: 1 },
  { name: 'mongo3:27017', state: 'SECONDARY', health: 1 }
]
rs0 [direct: primary] test> exit
```

**O prompt é a primeira coisa a ler.** Logo depois do `rs.initiate`, o `mongo1` se chamava
`[direct: secondary]`: todo membro começa como secundário, e o conjunto faz a primeira eleição entre
eles. A captura esperou quinze segundos antes da linha seguinte, e nesse ponto o `mongo1` já tinha
vencido e o prompt dizia `primary`. `direct:` quer dizer que o `mongosh` está falando com este membro
e não com o conjunto, diferença que importa na seção sobre preferência de leitura.

O `rs.status()` sozinho imprime umas duzentas linhas por chamada. O `map` no final guarda três
campos de cada membro: o nome, o estado e o `health`, que vale 1 quando o último heartbeat que este
membro lhe mandou teve resposta. **Cada campo é o que o membro consultado acredita**, montado a
partir de heartbeats enviados a cada dois segundos. Na última seção desta aula dois membros
respondem à mesma pergunta de formas diferentes, e os dois dizem a verdade como a enxergam.
