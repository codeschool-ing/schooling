---
title: nodetool repair, completo e incremental
version: 1
---

Hints e read repair são oportunistas. **O `nodetool repair` é o deliberado: ele compara todas as
réplicas de cada intervalo de um keyspace e copia o que uma tem e outra não.** É chamado de
anti-entropia porque é a entropia, as réplicas se afastando, que ele remove, e é o único mecanismo que
dá a garantia da qual a aula 18 depende.

## Comparar sem mandar tudo

Mandar toda linha a toda réplica para compará-las custaria tanto quanto os dados. Em vez disso cada
réplica monta uma **árvore de Merkle** para o intervalo: o intervalo é cortado em fatias, as linhas de
cada fatia viram um hash, e pares de hashes viram hash de novo até uma raiz única. Duas réplicas com
raízes iguais concordam no intervalo inteiro. Quando as raízes diferem, as réplicas descem pela
árvore, e só as fatias cujos hashes diferem são transmitidas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Duas árvores de Merkle lado a lado, uma montada pelo c1 e outra pelo c3, sobre o mesmo intervalo de tokens. Cada árvore tem um hash na raiz, dois hashes no meio e quatro nas folhas, uma folha por fatia do intervalo. As raízes diferem. Descendo pelos hashes que diferem, só uma folha difere, a terceira fatia. O repair transmite só essa fatia entre os dois nós.\"><defs><marker id=\"mk19-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">árvore montada pelo c1</text><rect x=\"125\" y=\"34\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">raiz</text><line x1=\"175\" y1=\"68\" x2=\"100\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"50\" y=\"108\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash A</text><line x1=\"175\" y1=\"68\" x2=\"250\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"200\" y=\"108\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash B</text><line x1=\"100\" y1=\"142\" x2=\"54\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"20\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"54.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatia 1</text><line x1=\"100\" y1=\"142\" x2=\"132\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"98\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatia 2</text><line x1=\"250\" y1=\"142\" x2=\"210\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"176\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatia 3</text><line x1=\"250\" y1=\"142\" x2=\"288\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"254\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"288.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatia 4</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">árvore montada pelo c3</text><rect x=\"475\" y=\"34\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"525.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">raiz</text><line x1=\"525\" y1=\"68\" x2=\"450\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"400\" y=\"108\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash A</text><line x1=\"525\" y1=\"68\" x2=\"600\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"550\" y=\"108\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash B</text><line x1=\"450\" y1=\"142\" x2=\"404\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"370\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"404.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatia 1</text><line x1=\"450\" y1=\"142\" x2=\"482\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"448\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatia 2</text><line x1=\"600\" y1=\"142\" x2=\"560\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"526\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatia 3</text><line x1=\"600\" y1=\"142\" x2=\"638\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"604\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"638.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fatia 4</text><text x=\"350\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">raízes diferem → hash A igual, hash B difere → fatia 3 difere, fatia 4 igual</text><line x1=\"230\" y1=\"290\" x2=\"470\" y2=\"290\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#mk19-ah-amber)\" marker-start=\"url(#mk19-ah-amber)\"></line><text x=\"350\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">transmite só a fatia 3</text></svg>", "caption": "O repair compara árvores de hashes em vez dos dados. Hashes iguais encerram a busca naquele galho, e só as fatias cujas folhas diferem são transmitidas.", "same": ["hash A", "hash B"]}
```

Montar a árvore significa ler os dados da réplica naquele intervalo, o que se chama compactação de
validação. Essa leitura é a maior parte do custo do repair.

## Um repair completo que acha algo

Faça as réplicas discordarem de novo em duas linhas, como na seção anterior, e depois rode o repair
do keyspace inteiro a partir do `c1`:

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
cqlsh> UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330';
cqlsh> UPDATE shop.stock SET units = 10 WHERE sku = 'MS-204';
cqlsh> exit
ana@vm:~$ docker start c3
c3
ana@vm:~$ until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
ana@vm:~$ for n in c1 c2; do docker exec $n nodetool enablehandoff; done
```

```
ana@vm:~$ docker exec c1 nodetool repair -full shop | sed -E "s/for range \[.*\] finished/for range [...] finished/"
[2026-10-10 20:24:22,084] Starting repair command #1 (940c5910-c4e8-11f1-8032-c51f469b786c), repairing keyspace shop with repair options (parallelism: parallel, primary range: false, incremental: false, job threads: 1, ColumnFamilies: [], dataCenters: [], hosts: [], previewKind: NONE, # of ranges: 48, pull repair: false, force repair: false, optimise streams: false, ignore unreplicated keyspaces: false, repairPaxos: true, paxosOnly: false)
[2026-10-10 20:24:23,227] Repair session 94278230-c4e8-11f1-8032-c51f469b786c for range [...] finished (progress: 57%)
[2026-10-10 20:24:23,246] Repair completed successfully
[2026-10-10 20:24:23,255] Repair command #1 finished in 1 second
[2026-10-10 20:24:23,265] condition satisfied queried for parent session status and discovered repair completed.
[2026-10-10 20:24:23,265] Repair completed successfully
ana@vm:~$ docker logs --since 1m c1 2>&1 | grep -oE "(Requesting merkle trees|Received merkle tree|Created [0-9]+ sync tasks|Endpoints .* out of sync|Performing streaming repair|shop\.[a-z_]+ is fully synced).*"
Requesting merkle trees for stock (to [/172.18.0.3:7000, /172.18.0.4:7000, /172.18.0.2:7000])
Requesting merkle trees for orders_by_customer (to [/172.18.0.3:7000, /172.18.0.4:7000, /172.18.0.2:7000])
Received merkle tree for orders_by_customer from /172.18.0.2:7000
Received merkle tree for stock from /172.18.0.2:7000
Received merkle tree for orders_by_customer from /172.18.0.4:7000
Received merkle tree for stock from /172.18.0.3:7000
Received merkle tree for stock from /172.18.0.4:7000
Created 2 sync tasks based on 3 merkle tree responses for 940c5910-c4e8-11f1-8032-c51f469b786c (took: 3ms)
Received merkle tree for orders_by_customer from /172.18.0.3:7000
Created 3 sync tasks based on 3 merkle tree responses for 940c5910-c4e8-11f1-8032-c51f469b786c (took: 1ms)
Endpoints /172.18.0.2:7000 and /172.18.0.3:7000 have 4 range(s) out of sync for orders_by_customer
Performing streaming repair of 4 ranges with /172.18.0.3:7000
Endpoints /172.18.0.2:7000 and /172.18.0.4:7000 have 3 range(s) out of sync for orders_by_customer
Endpoints /172.18.0.3:7000 and /172.18.0.4:7000 have 3 range(s) out of sync for orders_by_customer
Performing streaming repair of 3 ranges with /172.18.0.4:7000
Endpoints /172.18.0.3:7000 and /172.18.0.4:7000 have 2 range(s) out of sync for stock
Endpoints /172.18.0.2:7000 and /172.18.0.4:7000 have 2 range(s) out of sync for stock
Performing streaming repair of 2 ranges with /172.18.0.4:7000
shop.orders_by_customer is fully synced
shop.stock is fully synced
```

O `nodetool repair` relata o comando e a sessão; o `sed` só troca a lista de 48 intervalos por
`[...]`. `-full` e o `incremental: false` da linha de opções dizem que foi um repair completo. O log do
nó diz o que ele fez, e o `grep` guarda as linhas que contam a história:

- **`Requesting merkle trees`** para cada tabela, às três réplicas, e **`Received merkle tree`** de
  cada uma;
- **`Created 2 sync tasks`** para `stock`: o `c3` discordava de cada um dos outros dois em 2
  intervalos, as duas linhas mudadas enquanto ele estava fora;
- **`Created 3 sync tasks`** para `orders_by_customer`, com 3 ou 4 intervalos fora de sincronia entre
  cada par de nós. Esses são os pedidos da aula 16, gravados quando o keyspace tinha uma cópia; o
  `ALTER` da aula 17 subiu para três e avisou que era preciso um repair completo. **Este é esse
  repair.** Cada pedido existia num nó, e agora está em três;
- **`fully synced`** para as duas tabelas no fim.

Rode de novo e não há nada a fazer:

```
ana@vm:~$ docker exec c1 nodetool repair -full shop stock | grep -E "Starting repair|Repair completed"
[2026-10-10 20:24:24,823] Starting repair command #2 (95b267f0-c4e8-11f1-8032-c51f469b786c), repairing keyspace shop with repair options (parallelism: parallel, primary range: false, incremental: false, job threads: 1, ColumnFamilies: [stock], dataCenters: [], hosts: [], previewKind: NONE, # of ranges: 48, pull repair: false, force repair: false, optimise streams: false, ignore unreplicated keyspaces: false, repairPaxos: true, paxosOnly: false)
[2026-10-10 20:24:25,260] Repair completed successfully
[2026-10-10 20:24:25,266] Repair completed successfully
ana@vm:~$ docker logs --since 20s c1 2>&1 | grep -oE "(Created [0-9]+ sync tasks|shop\.[a-z_]+ is fully synced).*"
Created 2 sync tasks based on 3 merkle tree responses for 940c5910-c4e8-11f1-8032-c51f469b786c (took: 3ms)
Created 3 sync tasks based on 3 merkle tree responses for 940c5910-c4e8-11f1-8032-c51f469b786c (took: 1ms)
shop.orders_by_customer is fully synced
shop.stock is fully synced
Created 0 sync tasks based on 3 merkle tree responses for 95b267f0-c4e8-11f1-8032-c51f469b786c (took: 1ms)
shop.stock is fully synced
```

O `--since 20s` voltou o bastante para pegar também as últimas linhas do primeiro repair, as que nomeiam
`940c5910-…`. O segundo repair, `95b267f0-…`, diz **`Created 0 sync tasks`**: três árvores iguais.

## Repair incremental

Reparar tudo toda vez lê todos os dados toda vez. O **repair incremental**, o padrão quando não se dá
`-full`, marca as SSTables que já reparou e as pula da próxima vez, então cada execução só compara o
que foi gravado desde a anterior:

```
ana@vm:~$ docker exec c1 nodetool tablestats shop.stock | grep -E "Percent repaired|Bytes (un)?repaired"
		Percent repaired: 0.0
		Bytes repaired: 0B
		Bytes unrepaired: 334B
ana@vm:~$ docker exec c1 nodetool repair shop stock | grep -E "Starting repair|Repair completed"
[2026-10-10 20:24:28,017] Starting repair command #3 (97995060-c4e8-11f1-8032-c51f469b786c), repairing keyspace shop with repair options (parallelism: parallel, primary range: false, incremental: true, job threads: 1, ColumnFamilies: [stock], dataCenters: [], hosts: [], previewKind: NONE, # of ranges: 48, pull repair: false, force repair: false, optimise streams: false, ignore unreplicated keyspaces: false, repairPaxos: true, paxosOnly: false)
[2026-10-10 20:24:28,663] Repair completed successfully
[2026-10-10 20:24:28,675] Repair completed successfully
ana@vm:~$ docker exec c1 nodetool tablestats shop.stock | grep -E "Percent repaired|Bytes (un)?repaired"
		Percent repaired: 100.0
		Bytes repaired: 334B
		Bytes unrepaired: 0B
ana@vm:~$ docker exec c1 sh -c "/opt/cassandra/tools/bin/sstablemetadata /var/lib/cassandra/data/shop/stock-*/*Data.db | grep -E \"^SSTable:|Repaired at\""
SSTable: /var/lib/cassandra/data/shop/stock-4fc84de0c4e811f18032c51f469b786c/nb-1-big
Repaired at: 1791663868031 (10/10/2026 20:24:28)
SSTable: /var/lib/cassandra/data/shop/stock-4fc84de0c4e811f18032c51f469b786c/nb-2-big
Repaired at: 1791663868031 (10/10/2026 20:24:28)
SSTable: /var/lib/cassandra/data/shop/stock-4fc84de0c4e811f18032c51f469b786c/nb-3-big
Repaired at: 1791663868031 (10/10/2026 20:24:28)
```

Antes, `Percent repaired: 0.0`: um repair completo compara dados mas não marca nada. Depois de
`nodetool repair shop stock`, cuja linha de opções diz `incremental: true`, **100.0**, e o
`sstablemetadata` mostra cada SSTable carimbada com a hora em que foi reparada. Daqui em diante um
repair incremental desta tabela lê só SSTables sem esse carimbo.

Dois cuidados vêm junto. O repair incremental mantém dados reparados e não reparados em SSTables
separadas, então muda o comportamento da compactação. E ele confia no carimbo: dados no disco que se
danificaram depois de marcados como reparados não são olhados de novo. A prática habitual é repairs
incrementais com frequência e um repair completo de vez em quando, e a próxima seção trata da
"frequência".
