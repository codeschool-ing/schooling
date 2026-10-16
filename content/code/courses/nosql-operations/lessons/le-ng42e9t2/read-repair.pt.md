---
title: Read repair, consertando o que uma leitura por acaso nota
version: 1
---

Quando uma leitura pergunta a mais de uma réplica, o coordenador compara as respostas. **Se discordam,
ele devolve o valor mais novo ao cliente e grava esse valor nas réplicas que estavam atrás.** Isso é o
read repair: ele conserta exatamente as linhas que alguém lê, no momento em que lê.

## Fazendo duas réplicas discordarem

Os hints esconderiam a diferença, então desligue-os no `c1` e no `c2`, pare o `c3`, mude o estoque do
teclado em `QUORUM` e ligue o `c3` de novo:

```
ana@vm:~$ for n in c1 c2; do docker exec $n nodetool disablehandoff; done
ana@vm:~$ docker stop c3
c3
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> UPDATE shop.stock SET units = 4 WHERE sku = 'KB-101';
cqlsh> exit
ana@vm:~$ docker start c3
c3
ana@vm:~$ until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
ana@vm:~$ for n in c1 c2; do docker exec $n nodetool enablehandoff; done
```

O `c1` e o `c2` dizem que o teclado tem 4 unidades; o `c3` ainda diz 5, o valor de antes. Nada está
errado até onde qualquer monitoramento consegue ver.

## A leitura que percebe

Uma leitura em `ALL`, rastreada, com o `grep` guardando as linhas sobre qual réplica mandou o quê, e
depois a mesma leitura de novo:

```
ana@vm:~$ docker exec c1 cqlsh -e "CONSISTENCY ALL; TRACING ON; SELECT units FROM shop.stock WHERE sku = 'KB-101';" | grep -oE 'units|^ +[0-9]+$|reading (digest|data) from /[0-9.:]+|Digest mismatch|Sending read-repair-mutation to [^ ]+|READ_REPAIR_RSP message received from /[0-9.:]+'
units
     4
units
reading data from /172.18.0.4:7000
reading digest from /172.18.0.3:7000
Digest mismatch
Sending read-repair-mutation to Full(/172.18.0.4:7000,(4216882464000968657,4585225655627743975])
READ_REPAIR_RSP message received from /172.18.0.4:7000
ana@vm:~$ docker exec c1 cqlsh -e "CONSISTENCY ALL; TRACING ON; SELECT units FROM shop.stock WHERE sku = 'KB-101';" | grep -oE 'units|^ +[0-9]+$|reading (digest|data) from /[0-9.:]+|Digest mismatch|Sending read-repair-mutation to [^ ]+|READ_REPAIR_RSP message received from /[0-9.:]+'
units
     4
units
reading digest from /172.18.0.4:7000
reading digest from /172.18.0.3:7000
```

O primeiro rastreio se lê como uma frase. O coordenador pediu **ao `c3` os dados e ao `c2` um
digest**, um hash da resposta, mais barato de mandar que os dados. Os dois não bateram: **`Digest
mismatch`**. Então ele buscou os dados completos, ficou com o mais novo, `4`, e mandou uma
**`read-repair-mutation`** ao `c3`, que respondeu `READ_REPAIR_RSP`. O cliente ouviu 4, o valor
certo, e o `c3` o guarda agora. As linhas repetidas `units` são o cabeçalho da coluna e o texto da
própria consulta no rastreio.

A segunda leitura, um instante depois, pediu dois digests, achou-os iguais e não consertou nada.

## O que o read repair pode e não pode fazer

A configuração da tabela que o rege é `read_repair`, que o `DESCRIBE TABLE` mostra como `'BLOCKING'`
a menos que alguém a tenha mudado: **o cliente espera até o conserto estar gravado**, então uma leitura
posterior no mesmo nível não pode devolver o valor mais velho. É isso que torna seguras as leituras em
`QUORUM` depois de escritas em `QUORUM` mesmo quando uma réplica estava atrás.

O limite dele está no nome. **Ele conserta o que é lido, e só em níveis que perguntam a mais de uma
réplica.** Uma leitura em `ONE` não compara nada. Uma linha que ninguém lê continua errada até outra
coisa consertá-la, e uma linha apagada numa réplica atrasada é exatamente uma linha assim: ninguém lê o
que acredita ter apagado. A aula 18 mostrou aonde isso leva. A ferramenta que visita toda linha, leia
alguém ou não, é a próxima seção.
