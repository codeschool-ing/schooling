---
title: Um Redis local, e o que ele diz de si mesmo
version: 1
---

**Os dois serviços do Azure rodam o motor do Redis, e o motor roda num notebook.** O `compose.yaml` do
laboratório da lição 1 o tem no perfil `redis`: a imagem oficial, versão 8.2.2, na porta 6379 de
`127.0.0.1` apenas. Suba junto com o emulador do Cosmos DB, porque a próxima seção o põe na frente do
Cosmos DB:

```sh
docker compose --profile cosmos --profile redis up -d
```

O `redis-cli` está dentro do contêiner, e `docker compose exec redis` chega nele sem instalar nada:

```
ana@laptop:~/azure$ docker compose exec redis redis-server --version
Redis server v=8.2.2 sha=00000000:1 malloc=jemalloc-5.3.0 bits=64 build=fe8f07ffb18b0e6d
ana@laptop:~/azure$ docker compose exec redis redis-cli CONFIG GET maxmemory
maxmemory
0
ana@laptop:~/azure$ docker compose exec redis redis-cli CONFIG GET maxmemory-policy
maxmemory-policy
noeviction
ana@laptop:~/azure$ docker compose exec redis redis-cli CONFIG GET cluster-enabled
cluster-enabled
no
ana@laptop:~/azure$ docker compose exec redis redis-cli CLUSTER INFO
ERR This instance has cluster support disabled
```

**Versão 8.2.2, sem limite de memória, `noeviction`, e sem suporte a cluster.** Um `maxmemory` de 0
quer dizer que o Redis pode usar a memória que a máquina tiver, e `noeviction` quer dizer que, quando
não puder, ele recusa escritas em vez de jogar alguma coisa fora. São os padrões do próprio motor, e
sensatos para um notebook. Um cache gerenciado é configurado de outro jeito: tem um tamanho fixo, a
política padrão documentada do Azure Cache for Redis é `volatile-lru`, e não dá para rodar `CONFIG`
lá para descobrir, porque o serviço o bloqueia. A seção de despejo define essas opções à mão, para ver
o que cada política faz.

**O `CLUSTER INFO` recusa porque este Redis é um servidor só**, que é como um cache Basic, Standard ou
Premium sem clusterização aparece para um cliente. A última seção sobe um segundo Redis com suporte a
cluster, para ver o que muda para as chaves.

**O que este contêiner não ensina é o serviço em volta do motor**: failover para uma réplica,
correções, TLS na 6380, as regras de rede e o login com o Microsoft Entra ID. Isso é ensinado a partir
da documentação na seção anterior, e nada aqui imita essas coisas.
