---
title: ONE, QUORUM e ALL na mesma tabela
version: 1
---

A aula 1 prometeu rodar uma tabela do Cassandra dos dois jeitos: recusando quando as cópias não
conseguem concordar, e respondendo mesmo assim. **A tabela não muda entre os dois. Só muda o nível
de consistência de cada comando.** Ele é o número de réplicas que precisam responder antes que o
coordenador responda ao cliente, e com três cópias os três níveis que vale conhecer são estes:

| nível | réplicas que precisam responder, de 3 | o que aguenta |
| --- | --- | --- |
| `ONE` | 1 | dois nós caídos |
| `QUORUM` | 2, uma maioria: 3 dividido por 2, arredondado para baixo, mais 1 | um nó caído |
| `ALL` | 3 | nada |

Uma escrita continua **enviada a toda réplica que está de pé**, seja qual for o nível; o nível é
quantas confirmações o coordenador espera antes de dizer sim. Uma leitura pergunta a tantas réplicas
quantas o nível exige e devolve o valor mais novo entre as respostas.

## Um nó caído

Pare o `c3` do jeito que uma queda ou um reboot o tiraria, e confirme que o cluster percebeu:

```
ana@vm:~$ docker stop c3
c3
ana@vm:~$ docker exec c1 nodetool status shop | grep -E "^(UN|DN)"
UN  172.18.0.3  80.02 KiB   16      100.0%            4e6c6943-bad2-4a89-a579-c61d93c795b4  rack1
UN  172.18.0.2  100.91 KiB  16      100.0%            4f53c005-bbb3-41b0-85b5-e123a1c42d23  rack1
DN  172.18.0.4  119.66 KiB  16      100.0%            1480b2b6-2542-4292-8efe-6389e94e299a  rack1
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY ONE
Consistency level set to ONE.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';

 units
-------
     1

(1 rows)
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';

 units
-------
     1

(1 rows)
cqlsh> UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330';
cqlsh> CONSISTENCY ALL
Consistency level set to ALL.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level ALL" info={\'consistency\': \'ALL\', \'required_replicas\': 3, \'alive_replicas\': 2}')})
cqlsh> UPDATE shop.stock SET units = 1 WHERE sku = 'MN-330';
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level ALL" info={\'consistency\': \'ALL\', \'required_replicas\': 3, \'alive_replicas\': 2}')})
cqlsh> exit
```

`DN` é down e normal: ainda membro do anel, sem responder. `ONE` e `QUORUM` leram o estoque do
monitor como antes, e o `UPDATE` em `QUORUM`, vendendo o monitor, deu certo com duas de três
réplicas. **`ALL` recusou, antes de tentar**: `Cannot achieve consistency level ALL`, com
`required_replicas` 3 e `alive_replicas` 2. O coordenador sabia pelo gossip que o `c3` estava fora,
então não mandou nada para ficar esperando; respondeu `Unavailable` na hora. A escrita em `ALL` foi
recusada do mesmo jeito, e esse é o sentido do `ALL`: nenhuma escrita é confirmada sem estar em todas
as cópias.

O `NoHostAvailable` em volta é o driver Python dentro do `cqlsh` dizendo que o único host com quem
falou, `127.0.0.1`, deu essa resposta. O erro do servidor é o `Unavailable` lá dentro.

## Dois nós caídos

```
ana@vm:~$ docker stop c2
c2
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level QUORUM" info={\'consistency\': \'QUORUM\', \'required_replicas\': 2, \'alive_replicas\': 1}')})
cqlsh> CONSISTENCY ONE
Consistency level set to ONE.
cqlsh> SELECT units FROM shop.stock WHERE sku = 'MN-330';

 units
-------
     0

(1 rows)
cqlsh> UPDATE shop.stock SET units = 5 WHERE sku = 'MN-330' IF units = 0;
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 dc1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level SERIAL" info={\'consistency\': \'SERIAL\', \'required_replicas\': 2, \'alive_replicas\': 1}')})
cqlsh> exit
```

Agora o `QUORUM` também é recusado: precisa de 2 e tem 1. **O `ONE` ainda responde, e responde
`0`**, a venda feita em `QUORUM` um minuto antes, porque o `c1` foi uma das duas réplicas que a
receberam. Isso não é sorte com que se possa contar em geral: uma leitura em `ONE` responde a partir
da única réplica que alcança, e se essa réplica tivesse perdido a última escrita, o `ONE` devolveria o
valor velho com a mesma segurança.

A última linha é uma transação leve, o assunto da última seção, e vale notar a recusa dela desde já:
**ela pediu `SERIAL`, precisando de 2 réplicas, embora a sessão estivesse em `ONE`.** Uma escrita
condicional precisa de maioria seja qual for o nível que você definir.

Traga os dois nós de volta e espere os três ficarem de pé:

```sh
docker start c2 c3
until [ "$(docker exec c1 nodetool status 2>/dev/null | grep -c '^UN')" = 3 ]; do sleep 5; done
```

```
ana@vm:~$ docker exec c1 nodetool status shop | grep -E "^(UN|DN)"
UN  172.18.0.3  159.33 KiB  16      100.0%            4e6c6943-bad2-4a89-a579-c61d93c795b4  rack1
UN  172.18.0.2  100.91 KiB  16      100.0%            4f53c005-bbb3-41b0-85b5-e123a1c42d23  rack1
UN  172.18.0.4  164.56 KiB  16      100.0%            1480b2b6-2542-4292-8efe-6389e94e299a  rack1
```

Essa é a promessa cumprida: a mesma tabela, a mesma linha e o mesmo cluster, e uma leitura que foi
recusada num nível respondeu em outro. **Nos termos do teorema da aula 1, `ALL` e `QUORUM` escolheram
consistência e `ONE` escolheu disponibilidade**, comando a comando. A próxima seção põe a conta por
baixo da escolha.
