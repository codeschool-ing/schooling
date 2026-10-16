---
title: MongoDB, o punhado de números entre centenas
version: 1
---

O primeiro instinto é olhar a máquina: processador, memória, disco. Esses gráficos importam, mas um
banco com problema muitas vezes parece calmo visto de fora. **Os números que dizem que um banco está
com problema são os que o próprio banco informa sobre si**, e o `db.serverStatus()` devolve várias
centenas deles. Esta seção escolhe os seis que decidem alguma coisa, e faz cada um se mexer de
propósito.

## O conjunto a observar

Os sinais que valem a pena no MongoDB são os de um replica set, então esta seção reconstrói o
conjunto de três membros da aula 9 com um acréscimo. Antes, os contêineres da aula 1 são parados,
para devolver a memória deles à VM:

```sh
docker stop mongo redis cassandra
for n in 1 2 3; do
  docker run -d --name mongo$n --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all --wiredTigerCacheSizeGB 0.25
done
```

```sh
docker exec mongo1 mongosh --quiet --eval 'rs.initiate({ _id: "rs0", members: [
  { _id: 0, host: "mongo1:27017" }, { _id: 1, host: "mongo2:27017" }, { _id: 2, host: "mongo3:27017" } ] })'
```

**O acréscimo é `--wiredTigerCacheSizeGB 0.25`.** O WiredTiger, o motor de armazenamento do
MongoDB, mantém um cache próprio e, por padrão, o dimensiona em metade da memória menos 1 GB, ou
256 MB se isso for maior. Na máquina de 15,7 GiB do laboratório seriam mais de 7 GB, e nada nesta
aula chegaria perto de enchê-lo. Um quarto de gigabyte enche em segundos, e é essa a ideia.

Dê alguns segundos para a eleição e confira os papéis:

```
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.status().members.map(m => m.name + " " + m.stateStr)'
[
  'mongo1:27017 PRIMARY',
  'mongo2:27017 SECONDARY',
  'mongo3:27017 SECONDARY'
]
```

## Uma carga para observar

Um banco em repouso informa zeros. Este script grava 600.000 pedidos da loja em lotes de mil. Cada
um leva uma observação de 200 bytes, para que os dados ultrapassem o cache pequeno:

```javascript
// load.js: the shop's orders, written in batches of 1,000
const customers = ["ana", "bruno", "carla", "diego", "elisa"];
const products = [["KB-101", 34990], ["MS-204", 18900], ["MN-330", 149900], ["CB-012", 3990]];
for (let b = 0; b < 600; b++) {
  const batch = [];
  for (let i = 1; i <= 1000; i++) {
    const n = b * 1000 + i;
    const [sku, cents] = products[n % 4];
    batch.push({ n: n, customer: customers[n % 5] + "@example.com",
                 items: [{ sku: sku, qty: 1 + (n % 3), cents: cents }],
                 note: "x".repeat(200) });
  }
  db.orders.insertMany(batch);
}
```

Salve como `load.js`, copie para o contêiner do primário e rode em segundo plano com `-d`, para o
terminal ficar livre para observar:

```sh
docker cp load.js mongo1:/load.js
docker exec -d mongo1 mongosh --quiet shop /load.js
```

## `mongostat`: uma linha por segundo

O `mongostat` vem na imagem e imprime uma linha de taxas por segundo; `-n 5` para depois de cinco:

```
ana@vm:~$ docker exec mongo1 mongostat -n 5
insert query update delete getmore command dirty  used flushes vsize  res qrw arw net_in net_out conn set repl                time
 51858    *0     *0     *0     382   539|0  6.5% 38.2%       0 3.90G 323M 0|0 0|0  18.0m   45.6m   18 rs0  SLV Oct 10 07:41:19.111
 46366    *0     *0     *0     335   518|0  9.6% 48.3%       0 3.90G 343M 0|0 0|0  16.1m   40.8m   18 rs0  SLV Oct 10 07:41:20.081
 60935    *0     *0     *0     455   715|0  2.3% 54.7%       0 3.90G 374M 0|0 0|0  21.2m   53.6m   18 rs0  SLV Oct 10 07:41:21.082
 58988    *0     *0     *0     445   692|0  4.4% 66.3%       0 3.90G 395M 0|0 0|0  20.6m   51.9m   18 rs0  SLV Oct 10 07:41:22.083
 56810    *0     *0     *0     435   670|0  2.6% 70.4%       0 3.90G 415M 0|0 0|0  19.8m   50.0m   18 rs0  SLV Oct 10 07:41:23.086
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.status().members.map(m => m.name + " " + m.stateStr)'
[
  'mongo1:27017 PRIMARY',
  'mongo2:27017 SECONDARY',
  'mongo3:27017 SECONDARY'
]
```

Entre 46.366 e 60.935 inserções por segundo, e a coluna `used` subindo de 38,2% para 70,4% do cache
em cinco segundos. `qrw` e `arw` são operações na fila e ativas, leitores antes da barra e escritores
depois dela; **uma fila que fica acima de zero é o primeiro sinal de um servidor que não dá conta**,
e aqui ela é `0|0` o tempo todo.

**Leia a coluna `repl` com desconfiança.** Ela diz `SLV`, secundário, em todas as linhas, e o comando
logo depois mostra que o `mongo1` é o primário. Esta versão da ferramenta informa o papel errado
diante de um servidor 8.0. Uma ferramenta de monitoramento é software com defeitos próprios, e o
papel de um membro se lê no `rs.status()`, que é a resposta do próprio replica set.

## `db.serverStatus()`: os mesmos números, por dentro

O `mongostat` é um leitor do `serverStatus`. Perguntar direto dá os contadores que ele transforma em
taxas, e os números do cache que ele arredonda:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet shop
rs0 [direct: primary] shop> const s = db.serverStatus()

rs0 [direct: primary] shop> s.connections.current
19
rs0 [direct: primary] shop> s.opcounters
{
  insert: Long('543002'),
  query: Long('42'),
  update: Long('0'),
  delete: Long('0'),
  getmore: Long('4016'),
  command: Long('6313')
}
rs0 [direct: primary] shop> const c = s.wiredTiger.cache

rs0 [direct: primary] shop> const max = c["maximum bytes configured"]

rs0 [direct: primary] shop> max / 1024 / 1024
256
rs0 [direct: primary] shop> (100 * c["bytes currently in the cache"] / max).toFixed(1)
68.7
rs0 [direct: primary] shop> (100 * c["tracked dirty bytes in the cache"] / max).toFixed(1)
4.2
rs0 [direct: primary] shop> exit
```

Para que serve cada um:

| campo | o que é | quando significa problema |
|---|---|---|
| `connections.current` | conexões de clientes abertas, 19 aqui | uma subida constante rumo a `available`: um pool que vaza, ou uma aplicação escalada sem ninguém dimensionar as conexões |
| `opcounters` | operações desde que o servidor subiu, por tipo | nunca sozinho. Ele só sobe; o sinal é a taxa, que é o que o `mongostat` imprime |
| cache usado | 68,7% dos 256 MB | parado acima de 95%, onde o WiredTiger faz as threads que atendem suas consultas pararem para expulsar páginas elas mesmas |
| cache sujo | 4,2%, alterações ainda não gravadas em disco | parado acima de 20%, a mesma trava para escritas |

Os dois limites do cache são os padrões do WiredTiger: ele começa a expulsar em segundo plano com
80% usado e 5% sujo, e convoca as threads da própria aplicação a 95% e 20%. **Um cache em 80% é um
cache fazendo seu trabalho.** Um que fica em 95% é um servidor em que toda consulta agora espera pela
faxina, e o gráfico de latência mostra isso antes de qualquer outro.

## Atraso de replicação, provocado de propósito

Um secundário que fica para trás é invisível para a aplicação até haver um failover, e aí as
escritas que ele nunca aplicou se perdem ou sofrem rollback (aula 9). Para fazer um ficar para trás,
trave o `mongo3` para escrita do jeito que um snapshot de sistema de arquivos faz na aula 11, e rode
a carga de novo:

```
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ docker exec mongo1 mongosh --quiet shop /load.js
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.printSecondaryReplicationInfo()'
source: mongo2:27017
{
  syncedTo: 'Sat Oct 10 2026 07:41:44 GMT+0000 (Coordinated Universal Time)',
  replLag: '0 secs (0 hrs) behind the primary '
}
---
source: mongo3:27017
{
  syncedTo: 'Sat Oct 10 2026 07:41:26 GMT+0000 (Coordinated Universal Time)',
  replLag: '18 secs (0.01 hrs) behind the primary '
}
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.printSecondaryReplicationInfo()'
source: mongo2:27017
{
  syncedTo: 'Sat Oct 10 2026 07:41:44 GMT+0000 (Coordinated Universal Time)',
  replLag: '0 secs (0 hrs) behind the primary '
}
---
source: mongo3:27017
{
  syncedTo: 'Sat Oct 10 2026 07:41:44 GMT+0000 (Coordinated Universal Time)',
  replLag: '0 secs (0 hrs) behind the primary '
}
```

O `mongo3` ficou **18 segundos atrás** enquanto estava travado, e se recuperou segundos depois de
destravado. As escritas continuaram dando certo o tempo todo, porque o write concern padrão exige a
maioria, e `mongo1` e `mongo2` eram maioria. Nada do que a aplicação via teria contado a ela.

**O atraso é medido no tempo do primário, não no relógio.** `syncedTo` é a hora da última escrita
que o secundário aplicou, e o atraso é quanto isso fica atrás da última escrita do próprio primário.
Num primário que não recebe escritas há algum tempo, um secundário travado parece menos atrasado do
que está. Os horários estão em UTC porque os contêineres mantêm UTC, qualquer que seja o fuso da VM.

## A operação lenta, enquanto ela roda

Uma consulta que examina todos os documentos de uma coleção é a operação lenta mais comum que
existe. Esta é lenta de propósito: um `$where` roda JavaScript para cada documento, e `sleep(5)` faz
cada um custar cinco milissegundos. Sobre os 1.200.000 pedidos que as duas cargas gravaram, são
6.000 segundos, uma hora e quarenta minutos. Rode em segundo plano e encontre a consulta de outro
shell:

```
ana@vm:~$ docker exec -d mongo1 mongosh --quiet shop --eval 'db.orders.find({ $where: "sleep(5) || false" }).itcount()'
ana@vm:~$ docker exec -it mongo1 mongosh --quiet shop
rs0 [direct: primary] shop> const slow = db.currentOp({ ns: "shop.orders", secs_running: { $gte: 2 } }).inprog

rs0 [direct: primary] shop> slow.map(o => ({ opid: o.opid, secs_running: o.secs_running, planSummary: o.planSummary, filter: o.command.filter }))
[
  {
    opid: 118785,
    secs_running: Long('5'),
    planSummary: 'COLLSCAN',
    filter: { '$where': 'sleep(5) || false' }
  }
]
rs0 [direct: primary] shop> db.killOp(slow[0].opid).info
attempting to kill op
rs0 [direct: primary] shop> db.getProfilingStatus().slowms
100
rs0 [direct: primary] shop> db.adminCommand({ getLog: "global" }).log.map(JSON.parse).filter(l => l.msg == "Slow query" && l.attr.command.find).map(l => ({ ns: l.attr.ns, planSummary: l.attr.planSummary, durationMillis: l.attr.durationMillis, errName: l.attr.errName }))
[
  {
    ns: 'shop.orders',
    planSummary: 'COLLSCAN',
    durationMillis: 7283,
    errName: 'Interrupted'
  }
]
rs0 [direct: primary] shop> exit
```

O `db.currentOp()` aceita um filtro como uma consulta, e este pede tudo em `shop.orders` rodando há
dois segundos ou mais. **`COLLSCAN` no `planSummary` é a palavra a procurar**: uma varredura da
coleção inteira, aquilo que os índices da aula 7 existem para evitar. O `db.killOp()` a encerra.

A segunda metade é o **log de consultas lentas**. Toda operação que leva mais que `slowms`, 100
milissegundos por padrão, é escrita no log do servidor como uma linha `Slow query`, com o profiler
ligado ou não. O `getLog` devolve as últimas linhas desse log como JSON, e a consulta encerrada está
lá com seus 7.283 milissegundos e `Interrupted`. Fora do shell as mesmas linhas estão em
`docker logs mongo1`, um objeto JSON longo cada; um coletor de logs é o que as transforma numa lista
das piores consultas do dia.
