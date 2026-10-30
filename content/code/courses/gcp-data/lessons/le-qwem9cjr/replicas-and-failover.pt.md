---
title: Nível Standard, réplicas e o failover que você faz à mão
version: 1
---

**Uma instância do nível Basic é um servidor Redis só, e quando ele falha o cache fica vazio.** O
Memorystore troca o nó, e o novo começa sem nenhuma chave, então toda requisição falta até o cache
encher de novo, e o banco aguenta a carga inteira enquanto isso. Para um cache de cópias é uma hora
lenta. Para as sessões da seção anterior é todo mundo deslogado. **O nível Standard mantém uma réplica
em outra zona e a promove sozinho quando a primária para de responder**, que é o que o preço mais alto
da primeira seção compra. Criar uma é um comando, mostrado e não executado:

```sh
gcloud redis instances create quitanda-cache --region=southamerica-east1 \
  --tier=standard --size=5 --redis-version=redis_7_0
```

## Uma réplica, na sua máquina

O mecanismo por baixo é a replicação do Redis, e ela roda localmente. Ligue um segundo servidor, uma
réplica do primeiro, em mais um terminal só dele:

```sh
redis-server --port 6380 --save '' --appendonly no --replicaof 127.0.0.1 6379
```

Ele se conecta ao servidor da porta 6379, copia todas as chaves que ele tem, e daí em diante recebe
cada escrita que a primária aceita. A primeira cópia leva alguns segundos, porque o Redis 7.0 espera
cinco antes de mandá-la, para o caso de mais réplicas se conectarem e poderem aproveitá-la. No
terminal em que você digita, `-p 6380` manda um comando para a réplica:

```
ana@laptop:~/gcp$ redis-cli -p 6380 INFO replication | grep -E '^(role|master_link_status)'
role:slave
master_link_status:up
ana@laptop:~/gcp$ redis-cli SET product:p-103 '{"name":"cafe torrado 500g","price_cents":3450}' EX 600
OK
ana@laptop:~/gcp$ redis-cli -p 6380 GET product:p-103
"{\"name\":\"cafe torrado 500g\",\"price_cents\":3450}"
ana@laptop:~/gcp$ redis-cli -p 6380 SET product:p-103 0
(error) READONLY You can't write against a read only replica.
```

**A réplica respondeu `role:slave` com o link `up`, serviu o preço escrito na primária um instante
antes, e recusou uma escrita própria.** `READONLY` é a réplica protegendo a única regra em que a
replicação se apoia: cada chave tem um só escritor, a primária. A palavra `slave` é a do próprio
Redis 7.0 nesse campo. Leituras podem ir para uma réplica, e é isso que são as **réplicas de
leitura** do Memorystore: até cinco numa instância do nível Standard, do M2 para cima, atrás de um
endpoint de leitura para onde a aplicação manda as leituras.

**A replicação é assíncrona.** A primária confirma uma escrita antes de a réplica tê-la, então uma
escrita nesse intervalo se perde se a primária morrer naquele momento. Para um cache isso é aceitável,
porque o banco continua guardando a verdade; é mais um motivo para a verdade ficar fora do cache.

## O failover, à mão

Agora a primária falha. Pare-a, e faça à mão o que o Memorystore faz numa instância Standard:

```
ana@laptop:~/gcp$ redis-cli SHUTDOWN NOSAVE
ana@laptop:~/gcp$ redis-cli -p 6380 INFO replication | grep -E '^(role|master_link_status)'
role:slave
master_link_status:down
ana@laptop:~/gcp$ redis-cli -p 6380 SET product:p-104 2790
(error) READONLY You can't write against a read only replica.
ana@laptop:~/gcp$ redis-cli -p 6380 REPLICAOF NO ONE
OK
ana@laptop:~/gcp$ redis-cli -p 6380 SET product:p-104 2790
OK
ana@laptop:~/gcp$ redis-cli -p 6380 GET product:p-103
"{\"name\":\"cafe torrado 500g\",\"price_cents\":3450}"
```

**Sem a primária, a réplica manteve as chaves e continuou recusando escritas, com o link `down`.** O
`REPLICAOF NO ONE` a promoveu: ela parou de seguir alguém, e a escrita seguinte foi aceita. A chave
escrita antes da falha continuava lá. Duas coisas isso não fez, e o Memorystore faz. Não mudou o
endereço que o programa usa, então um programa ainda apontado para a porta 6379 continuaria falhando;
**o endpoint primário do Memorystore continua o mesmo e passa a apontar para o nó promovido**. E nada
criou uma réplica nova para substituir a antiga primária, o que o Memorystore também faz sozinho.

**Um failover derruba as conexões que estavam abertas**, no Memorystore como aqui. Um cliente precisa
se reconectar e tentar de novo, e a hora de descobrir se o seu faz isso é antes de uma zona cair. O
Memorystore for Redis tem um comando exatamente para isso, mostrado e não executado:

```sh
gcloud redis instances failover quitanda-cache --region=southamerica-east1 \
  --data-protection-mode=limited-data-loss
```

`limited-data-loss`, o padrão, só faz o failover enquanto os dados em risco estão dentro dos limites
do próprio serviço; `force-data-loss` faz o failover custe o que custar. Um time que nunca o rodou
não sabe o que a própria aplicação faz no minuto seguinte.

## Shards, quando uma primária não basta

**Uma primária recebe todas as escritas e guarda todas as chaves, então uma instância é tão grande e
tão rápida quanto uma máquina.** O Memorystore for Redis Cluster e o Memorystore for Valkey dividem as
chaves em 16.384 slots de hash e repartem os slots entre shards, cada um uma primária com suas
réplicas. O slot de uma chave é um hash da chave, então o cliente calcula qual shard é o dono e manda
o comando para lá. Acrescentar um shard move alguns slots para ele, que é como um cache cresce além da
memória ou das escritas de um nó. O preço é que um comando que mexe em duas chaves só funciona se as
duas estiverem no mesmo slot, e o cliente precisa ser um que fale o modo cluster, o que o pacote
`redis` desta aula faz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma instância do Memorystore for Valkey ou for Redis Cluster com dois shards, em duas zonas. As chaves se dividem em 16.384 slots: o shard 0001 tem os slots 0 a 8191 e o shard 0002 os slots 8192 a 16383. Cada shard tem uma primária, que recebe as escritas, e uma réplica na outra zona, que recebe uma cópia e pode ser promovida. O cliente calcula o slot da chave e manda a escrita à primária daquele slot.\" data-fig=\"g12-replication-pt\"><defs><marker id=\"g12-replication-pt-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker><marker id=\"g12-replication-pt-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"200\" y=\"14\" width=\"240\" height=\"276\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">zona a</text><text x=\"320\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-a</text><rect x=\"460\" y=\"14\" width=\"240\" height=\"276\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">zona b</text><text x=\"580\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-b</text><rect x=\"16\" y=\"116\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cliente</text><text x=\"96\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">slot = CRC16(key)</text><text x=\"96\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">% 16384</text><text x=\"320\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">shard 0001, slots 0 - 8191</text><rect x=\"230\" y=\"78\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primária</text><text x=\"320\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recebe as escritas</text><rect x=\"490\" y=\"78\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">réplica</text><text x=\"580\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê; pode ser promovida</text><polyline points=\"410,106 488,106\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#g12-replication-pt-ah-0)\"></polyline><text x=\"450\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cópia</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">shard 0002, slots 8192 - 16383</text><rect x=\"490\" y=\"186\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primária</text><text x=\"580\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recebe as escritas</text><rect x=\"230\" y=\"186\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">réplica</text><text x=\"320\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê; pode ser promovida</text><polyline points=\"490,214 412,214\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#g12-replication-pt-ah-0)\"></polyline><text x=\"450\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">cópia</text><polyline points=\"176,136 200,136 200,106 228,106\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-replication-pt-ah-1)\"></polyline><polyline points=\"176,164 190,164 190,268 580,268 580,244\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-replication-pt-ah-1)\"></polyline><text x=\"330\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">escritas da chave vão para a primária do slot</text></svg>", "caption": "Dois shards, cada um com a primária numa zona e a réplica na outra: perder uma zona custa uma promoção por shard, e nada dos dados que a primária já tinha copiado. Desenhado a partir da documentação; nada aqui criou um.", "same": ["shard 0001, slots 0 - 8191", "shard 0002, slots 8192 - 16383"]}
```

**O Memcached não tem nada disso.** Uma instância do Memorystore for Memcached é um conjunto de nós
independentes; o cliente faz o hash de cada chave para um deles, e um nó que morre leva as chaves
junto. Nada é replicado e nada faz failover. Tudo nesta seção sobre o Memorystore vem da documentação
do Google e não foi executado; a réplica e a promoção acima foram de verdade, e foram o Redis 7.0 na
sua própria máquina, não o serviço.
