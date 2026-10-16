---
title: Shards, réplicas e o failover que o moto não mostra
version: 1
---

**Um cache Valkey ou Redis OSS no ElastiCache é um grupo de replicação, e um grupo de replicação são
shards, cada um feito de uma primária e algumas réplicas.** A primária recebe toda escrita da sua
parte das chaves. Uma réplica recebe uma cópia dessas escritas um instante depois e pode responder
leituras. Duas escolhas decidem o formato, e são independentes: em quantos shards as chaves se
dividem, e quantas réplicas cada shard mantém.

**Com o modo cluster desligado há um shard só**, então toda chave mora numa primária, com até cinco
réplicas ao lado. O conjunto inteiro de dados tem de caber na memória de um nó, e toda escrita passa
por uma máquina. É o caso simples, e o cliente só precisa conhecer dois endereços: o endpoint
primário para escritas e o endpoint de leitura para leituras.

**Com o modo cluster ligado as chaves se dividem em 16.384 hash slots**, e os slots se repartem
entre os shards, até 500 deles. O slot de uma chave é um hash da chave, então o cliente calcula qual
shard é dono dela e manda o comando para lá. Acrescentar um shard move alguns slots para ele, e é
assim que um cache cresce além da memória de um nó ou das escritas de uma primária. O preço é que um
comando que toca duas chaves só funciona se as duas estiverem no mesmo slot, e o cliente tem de ser
um que entenda o modo cluster.

**O failover automático é o que faz uma réplica valer o que custa.** Quando uma primária para de
responder, o ElastiCache promove uma das réplicas dela, aponta o endpoint primário para a réplica e
monta uma nova réplica no lugar da primária antiga. O **Multi-AZ** põe as réplicas em zonas de
disponibilidade diferentes da primária e exige o failover automático, então perder uma zona inteira
custa uma promoção, e não o shard. A replicação é assíncrona: uma escrita que a primária já tinha
confirmado e ainda não tinha repassado se perde num failover. Para um cache isso é aceitável, porque
o banco de dados continua guardando a verdade, e é mais um motivo para as próximas seções manterem a
verdade fora do cache.

**O Memcached não tem nada disso.** Um cluster Memcached é um conjunto de nós independentes; o
cliente faz o hash de cada chave para um deles, e um nó que morre leva as chaves junto. Nada é
replicado e nada faz failover.

## O que o moto registra

O moto aceita um cluster Memcached e um grupo de replicação em modo cluster, e registra cada um como
um documento:

```
ana@laptop:~/aws$ aws elasticache create-cache-cluster --cache-cluster-id quitanda-pages --engine memcached --cache-node-type cache.t4g.micro --num-cache-nodes 2 --query "CacheCluster.[CacheClusterStatus,Engine,NumCacheNodes]" --output text
available	memcached	2
ana@laptop:~/aws$ aws elasticache create-replication-group --replication-group-id quitanda-catalog --replication-group-description "product pages" --engine valkey --cache-node-type cache.r7g.large --cluster-mode enabled --num-node-groups 2 --replicas-per-node-group 1 --automatic-failover-enabled --multi-az-enabled --query "ReplicationGroup.[Status,ClusterMode,AutomaticFailover,MultiAZ,EngineVersion]" --output text
available	enabled	enabled	enabled	None
ana@laptop:~/aws$ aws elasticache describe-replication-groups --replication-group-id quitanda-catalog --query "ReplicationGroups[0].NodeGroups[].NodeGroupMembers[].[CacheClusterId,CacheNodeId,CurrentRole,PreferredAvailabilityZone]" --output text
quitanda-catalog-0001-001	0001	None	us-east-1a
quitanda-catalog-0001-002	0001	None	us-east-1b
quitanda-catalog-0002-001	0002	None	us-east-1a
quitanda-catalog-0002-002	0002	None	us-east-1b
```

**O grupo de replicação voltou `available` na mesma linha**, com dois shards de dois membros cada.
Na AWS, criá-lo leva minutos, e o status seria `creating` primeiro. Dois detalhes da resposta são do
moto e não da AWS, e cada um é motivo para não confiar no detalhe de uma imitação. A versão da engine
é `None`, onde a AWS diria a versão do Valkey que instalou. E as zonas são `us-east-1a` e
`us-east-1b`, num grupo criado em São Paulo.

Não há servidor nenhum por trás de nada disso. Nenhum endpoint que o moto entrega resolve, nenhuma
porta responde, e nenhuma chave pode ser escrita. E duas operações falham dentro do próprio moto:

```
ana@laptop:~/aws$ aws elasticache test-failover --replication-group-id quitanda-catalog --node-group-id 0001

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
ana@laptop:~/aws$ aws elasticache create-serverless-cache --serverless-cache-name quitanda-catalog-sl --engine valkey

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**Um failover não pode ser testado aqui**, e essa é a operação que mais vale testar. Na AWS, o
`test-failover` promove uma réplica do shard que você indicar, e rodá-lo antes de uma falha de
verdade é como um time descobre se o cliente dele reconecta ou continua escrevendo num nó que agora
é réplica. E **o Serverless nem pode ser criado**: o moto responde com uma página de erro dele mesmo,
um 500, que é um defeito da imitação e não uma resposta que a AWS daria. Tudo o que esta seção diz
sobre failover vem da documentação da AWS e não foi rodado. O cache que o resto desta lição usa é de
verdade, e roda na sua própria máquina.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um grupo de replicação com o modo cluster ligado, em duas zonas de disponibilidade. As chaves se dividem em 16.384 slots: o shard 0001 tem os slots 0 a 8191 e o shard 0002 os slots 8192 a 16383. Cada shard tem uma primária, que recebe as escritas, e uma réplica na outra zona, que recebe uma cópia e pode ser promovida. O cliente calcula o slot da chave e manda a escrita à primária daquele slot.\" data-fig=\"l13-replication-pt\"><defs><marker id=\"l13-replication-pt-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker><marker id=\"l13-replication-pt-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"200\" y=\"14\" width=\"240\" height=\"276\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">zona a</text><text x=\"320\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"460\" y=\"14\" width=\"240\" height=\"276\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">zona b</text><text x=\"580\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"16\" y=\"116\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cliente</text><text x=\"96\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">slot = CRC16(key)</text><text x=\"96\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">% 16384</text><text x=\"320\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">shard 0001, slots 0 - 8191</text><rect x=\"230\" y=\"78\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primária</text><text x=\"320\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recebe as escritas</text><rect x=\"490\" y=\"78\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">réplica</text><text x=\"580\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê; pode ser promovida</text><polyline points=\"410,106 488,106\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-replication-pt-ah-0)\"></polyline><text x=\"450\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor-dim)\">cópia</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">shard 0002, slots 8192 - 16383</text><rect x=\"490\" y=\"186\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primária</text><text x=\"580\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recebe as escritas</text><rect x=\"230\" y=\"186\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">réplica</text><text x=\"320\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê; pode ser promovida</text><polyline points=\"490,214 412,214\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-replication-pt-ah-0)\"></polyline><text x=\"450\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor-dim)\">cópia</text><polyline points=\"176,136 200,136 200,106 228,106\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-replication-pt-ah-1)\"></polyline><polyline points=\"176,164 190,164 190,268 580,268 580,244\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-replication-pt-ah-1)\"></polyline><text x=\"330\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">escritas da chave vão para a primária do slot</text></svg>", "caption": "Dois shards, cada um com a primária numa zona e a réplica na outra: perder uma zona custa uma promoção em cada shard, e nenhum dado que a primária já tinha copiado.", "same": ["shard 0001, slots 0 - 8191", "shard 0002, slots 8192 - 16383"]}
```
