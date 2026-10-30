---
title: Shards, slots de hash e as chaves que precisam dividir um
version: 1
---

**Um Redis clusterizado divide as chaves entre vários servidores, os shards, por uma regra que todo
cliente consegue calcular: 16.384 slots de hash.** O slot de uma chave é um checksum do nome dela, CRC16,
módulo 16.384, e cada shard é dono de uma faixa de slots. Na política de clusterização OSS do Azure
Managed Redis, e num cache Premium clusterizado, o cliente calcula o slot sozinho e manda o comando ao
shard dono dele. É isso que deixa um cache crescer além de uma máquina, e custa uma regra: **um comando
que nomeia várias chaves precisa encontrar todas no mesmo slot.**

O Redis local desta lição é um servidor só e recusa todo comando `CLUSTER`. Um segundo, iniciado com
suporte a cluster, os responde: um nó, que recebe os 16.384 slots para servir todas as chaves. Ainda é
uma máquina só e nada parecido com um cluster gerenciado, mas o slot de uma chave e a recusa de um
comando entre slots são do motor, e são os mesmos aqui e no Azure:

```
ana@laptop:~/azure$ docker run -d --rm --name cluster-check redis:8.2.2 redis-server --cluster-enabled yes > /dev/null
ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER ADDSLOTSRANGE 0 16383
OK
ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER KEYSLOT product:cafe-500g
8271
ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER KEYSLOT product:cha-250g
5910
ana@laptop:~/azure$ docker exec cluster-check redis-cli MSET product:cafe-500g 2790 product:cha-250g 1590
CROSSSLOT Keys in request don't hash to the same slot

ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER KEYSLOT "{cart:c-7}:items"
9373
ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER KEYSLOT "{cart:c-7}:total"
9373
ana@laptop:~/azure$ docker exec cluster-check redis-cli MSET "{cart:c-7}:items" 3 "{cart:c-7}:total" 7680
OK
ana@laptop:~/azure$ docker rm -f cluster-check > /dev/null
```

**Os dois produtos estão nos slots 8271 e 5910, e o `MSET` dos dois foi recusado com `CROSSSLOT`**,
mesmo num cluster de um nó em que os dois slots estão na mesma máquina. A regra é sobre slots, não
servidores, então o código que funciona contra um shard continua funcionando quando o cluster cresce.

**As duas chaves do carrinho dividem o slot 9373 por causa das chaves `{}`.** Quando um nome contém
`{…}`, só a parte de dentro entra no hash, então `{cart:c-7}:items` e `{cart:c-7}:total` caem juntas e
uma transação ou um `MSET` sobre as duas é permitido. Isso é um hash tag, e é a versão do cluster da
chave de partição da lição 11: tudo o que precisa ser mexido junto divide um, e um hash tag dividido por
chaves demais põe todas num shard só, que é uma partição quente com outro nome.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Os 16.384 slots de hash, de 0 a 16383, divididos em três shards: 0 a 5460, 5461 a 10922 e 10923 a 16383. product:cha-250g cai no slot 5910 e product:cafe-500g no slot 8271, os dois no shard 2 mas em slots diferentes, então um MSET dos dois é recusado com CROSSSLOT. As chaves {cart:c-7}:items e {cart:c-7}:total caem as duas no slot 9373, porque só a parte entre chaves entra no hash, então um MSET das duas dá certo.\" data-fig=\"l15-slots\"><rect x=\"40.0\" y=\"90\" width=\"209.3\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"146.66015625\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">shard 1</text><text x=\"146.66015625\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0–5460</text><rect x=\"253.3\" y=\"90\" width=\"209.4\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"360.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">shard 2</text><text x=\"360.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5461–10922</text><rect x=\"466.7\" y=\"90\" width=\"209.3\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"573.33984375\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">shard 3</text><text x=\"573.33984375\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10923–16383</text><line x1=\"270.9\" y1=\"48\" x2=\"270.9\" y2=\"88\" stroke=\"var(--amber)\" stroke-width=\"1.4\"/><circle cx=\"270.9\" cy=\"90\" r=\"3.5\" fill=\"var(--amber)\"/><text x=\"270.859375\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">product:cha-250g  →  5910</text><line x1=\"363.1\" y1=\"70\" x2=\"363.1\" y2=\"88\" stroke=\"var(--amber)\" stroke-width=\"1.4\"/><circle cx=\"363.1\" cy=\"90\" r=\"3.5\" fill=\"var(--amber)\"/><text x=\"363.0859375\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">product:cafe-500g  →  8271</text><line x1=\"406.1\" y1=\"136\" x2=\"406.1\" y2=\"180\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"/><circle cx=\"406.1\" cy=\"134\" r=\"3.5\" fill=\"var(--phosphor)\"/><text x=\"406.1328125\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">{cart:c-7}:items  {cart:c-7}:total  →  9373</text><text x=\"360\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">MSET dos dois produtos: CROSSSLOT, embora os dois morem no shard 2</text><text x=\"360\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">MSET das duas chaves do carrinho: OK, porque {cart:c-7} põe as duas no slot 9373</text><text x=\"40\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"680\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16383</text></svg>", "caption": "Os slots que a transcrição acima imprimiu, distribuídos em três shards. Um comando sobre várias chaves precisa delas num slot, não só num shard.", "same": ["shard 1", "shard 2", "shard 3"]}
```

## No Azure

**O Azure Managed Redis é sempre clusterizado, e a política de clusterização decide quem vê os slots.**
Na política OSS o cliente vê cada shard e precisa lidar com a regra acima, o que toda biblioteca de Redis
atual faz. Na política Enterprise o serviço apresenta um endpoint só, e o proxy dele roteia cada comando,
então um cliente escrito para um servidor só conecta nele sem mudança. O Azure Cache for Redis oferece
clusterização só no Premium, do tipo OSS.

**Persistência e geo-replicação são o que um cache precisa quando esvaziá-lo não é aceitável**, o que é
sinal de que ele está sendo usado como mais que um cache. A persistência grava os dados em disco, como
snapshots ou um log só de acréscimo, para um reinício não começar vazio. A geo-replicação guarda uma
cópia em outra região. As duas custam dinheiro e as duas merecem ser questionadas antes: o cache de
catálogo da Quitanda se recarrega do Cosmos DB, e não precisa de nenhuma delas.
