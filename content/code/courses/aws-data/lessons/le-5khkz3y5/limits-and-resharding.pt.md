---
title: O que um shard aguenta, e como mudar o número de shards
version: 1
---

**Um shard é uma unidade de capacidade além de uma unidade de ordem.** A AWS documenta o que um shard
aceita e serve, e a capacidade de um stream provisionado é esse número vezes o número de shards:

| por shard | limite |
|---|---|
| escrita | 1 MB por segundo, ou 1.000 registros por segundo, o que vier primeiro |
| leitura, dividida entre todos os consumidores comuns | 2 MB por segundo, e 5 chamadas `GetRecords` por segundo |
| leitura, com enhanced fan-out | 2 MB por segundo para cada consumidor registrado, empurrados até ele |

Uma escrita acima do limite é recusada com `ProvisionedThroughputExceededException`, e espera-se que o
produtor aguarde e tente de novo. **O limite é por shard, não por stream**, e isso traz de volta a chave de
partição da primeira seção. Um stream de dez shards cuja chave mais movimentada põe 1,5 MB por
segundo num deles é estrangulado nesse shard enquanto os outros nove ficam parados. Isso é um **shard
quente** (*hot shard*), e acrescentar shards não o cura, porque a chave continua caindo num lugar só.

## O moto nunca estrangula

Este é o caso mais claro da lição de o moto responder a uma pergunta que a AWS responderia de outro
jeito. Um stream com um shard, e 2.000 registros escritos tão rápido quanto um laço consegue mandar:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders-test --shard-count 1
ana@laptop:~/aws$ python3 -c "import boto3, time; k = boto3.client('kinesis'); t = time.time(); f = sum(k.put_records(StreamName='orders-test', Records=[{'PartitionKey': f'c-{i}', 'Data': b'x' * 900} for i in range(500)])['FailedRecordCount'] for _ in range(4)); print(f, 'failed of 2000 in', round(time.time() - t, 2), 's')"
0 failed of 2000 in 0.16 s
```

**Nada falhou, em bem menos de um segundo**, onde um shard só na AWS aceita 1.000 registros por
segundo e teria recusado parte disso. O moto confere o formato da requisição e mantém os registros em
ordem; não tem relógio para capacidade. Então nada neste curso mostra um estrangulamento acontecendo, e
um produtor que funciona contra o moto não foi testado contra o limite de jeito nenhum. O retry de que
ele precisa é assunto da lição 23.

## Reshard

**O número de shards pode mudar com o stream em uso, e os shards antigos são fechados em vez de
redimensionados.** O `update-shard-count` pede ao Kinesis que faça a conta; aqui ele dobra o stream das
seções anteriores, de dois shards para quatro:

```
ana@laptop:~/aws$ aws kinesis update-shard-count --stream-name orders --target-shard-count 4 --scaling-type UNIFORM_SCALING
{
    "StreamName": "orders",
    "CurrentShardCount": 2,
    "TargetShardCount": 4
}
ana@laptop:~/aws$ aws kinesis list-shards --stream-name orders --query 'Shards[].[ShardId,ParentShardId,HashKeyRange.StartingHashKey,SequenceNumberRange.EndingSequenceNumber]' --output text
shardId-000000000000	None	0	6
shardId-000000000001	None	170141183460469231731687303715884105728	5
shardId-000000000002	shardId-000000000000	0	None
shardId-000000000003	shardId-000000000000	85070591730234615865843651857942052864	None
shardId-000000000004	shardId-000000000001	170141183460469231731687303715884105728	None
shardId-000000000005	shardId-000000000001	255211775190703847597530955573826158592	None
ana@laptop:~/aws$ python3 shard_of.py orders c-17 c-03 c-02 c-05
c-17    146071825190439638704466073634825402563  shardId-000000000003
c-03     88352402212612476087593936981806328046  shardId-000000000003
c-02    254303140926280561521588452831818067638  shardId-000000000004
c-05    332192223557910061300396319758440839601  shardId-000000000005
```

**Seis shards aparecem, e só quatro estão abertos.** Os shards 0 e 1 agora têm um
`EndingSequenceNumber`: estão **fechados**, não aceitam escrita, e guardam os registros até o período
de retenção removê-los. Cada um foi dividido em dois: os shards 2 e 3 têm o shard 0 como pai e dividem
a metade dele do espaço de hash, e os shards 4 e 5 fazem o mesmo com o shard 1. O último comando é o
`shard_of.py` de novo, que pula os shards fechados e acha a casa nova das chaves.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Os shards do stream orders depois de update-shard-count de 2 para 4. Na linha de cima, os dois pais fechados: o shard 0, de 0 a 2^127, cujo último número de sequência é 6, e o shard 1, de 2^127 a 2^128, cujo último é 5. Na linha de baixo, quatro filhos abertos, cada um com um quarto do espaço de chaves de hash: os shards 2 e 3 dividem o shard 0, os shards 4 e 5 dividem o shard 1. A chave c-17 fica no shard 0 antes do reshard e no shard 3 depois dele, então os eventos dela são lidos primeiro no pai e depois no filho.\" data-fig=\"l20-lineage\"><text x=\"20.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fechados</text><text x=\"20.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem escrita nova</text><text x=\"20.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">abertos</text><text x=\"20.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a escrita vai aqui</text><rect x=\"112.0\" y=\"50.0\" width=\"286.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"255.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 0</text><text x=\"255.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">último número de sequência 6</text><rect x=\"402.0\" y=\"50.0\" width=\"286.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"545.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 1</text><text x=\"545.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">último número de sequência 5</text><rect x=\"112.0\" y=\"160.0\" width=\"141.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"182.5\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 2</text><line x1=\"255.0\" y1=\"90.0\" x2=\"182.5\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"257.0\" y=\"160.0\" width=\"141.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 3</text><line x1=\"255.0\" y1=\"90.0\" x2=\"327.5\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"402.0\" y=\"160.0\" width=\"141.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"472.5\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 4</text><line x1=\"545.0\" y1=\"90.0\" x2=\"472.5\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"547.0\" y=\"160.0\" width=\"141.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"617.5\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 5</text><line x1=\"545.0\" y1=\"90.0\" x2=\"617.5\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"110.0\" y1=\"202.0\" x2=\"110.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"110.0\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><line x1=\"255.0\" y1=\"202.0\" x2=\"255.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"255.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2^126</text><line x1=\"400.0\" y1=\"202.0\" x2=\"400.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"400.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2^127</text><line x1=\"545.0\" y1=\"202.0\" x2=\"545.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"545.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 x 2^126</text><line x1=\"690.0\" y1=\"202.0\" x2=\"690.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"690.0\" y=\"224.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2^128</text><circle cx=\"359.0\" cy=\"84.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"359.0\" cy=\"166.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><line x1=\"359.0\" y1=\"88.0\" x2=\"359.0\" y2=\"162.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></line><text x=\"367.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-17</text><text x=\"400.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">leia cada pai até o fim antes dos filhos</text></svg>", "caption": "O reshard fecha os pais e abre filhos sobre as mesmas faixas; a história de uma chave vai do pai para o filho.", "same": ["shard 0", "shard 1", "shard 2", "shard 3", "shard 4", "shard 5"]}
```

**Um consumidor precisa terminar um pai antes de ler os filhos dele**, ou a ordem de uma chave se
quebra no momento do reshard. Os últimos eventos de `c-17` antes da divisão estão no shard 0, os
primeiros depois dela estão no shard 3, e ler o shard 3 primeiro os põe ao contrário. A Kinesis Client
Library, a biblioteca da AWS para consumidores, segue o `ParentShardId` e faz isso por você; o
`consumer.py` só acerta porque o `ListShards` devolveu os pais primeiro e ele lê um shard de cada vez.

O `update-shard-count` é a forma prática. Por baixo dele há duas operações que podem ser chamadas
diretamente, em qualquer shard, com qualquer ponto de divisão:

```
ana@laptop:~/aws$ aws kinesis split-shard --stream-name orders-test --shard-to-split shardId-000000000000 --new-starting-hash-key 170141183460469231731687303715884105728
ana@laptop:~/aws$ aws kinesis list-shards --stream-name orders-test --query 'Shards[].[ShardId,ParentShardId,SequenceNumberRange.EndingSequenceNumber]' --output text
shardId-000000000000	None	2000
shardId-000000000001	shardId-000000000000	None
shardId-000000000002	shardId-000000000000	None
ana@laptop:~/aws$ aws kinesis merge-shards --stream-name orders-test --shard-to-merge shardId-000000000001 --adjacent-shard-to-merge shardId-000000000002
ana@laptop:~/aws$ aws kinesis list-shards --stream-name orders-test --query 'Shards[].[ShardId,ParentShardId,AdjacentParentShardId,SequenceNumberRange.EndingSequenceNumber]' --output text
shardId-000000000000	None	None	2000
shardId-000000000001	shardId-000000000000	None	0
shardId-000000000002	shardId-000000000000	None	0
shardId-000000000003	shardId-000000000001	shardId-000000000002	None
```

**O `split-shard` fechou o shard 0 e fez dois filhos na chave de hash dada**, e o `merge-shards`
fechou esses dois e fez um filho com dois pais, `ParentShardId` e `AdjacentParentShardId`. Juntar
exige dois shards cujas faixas se encostam; dividir aceita qualquer ponto dentro da faixa de um shard.
Na AWS cada uma dessas leva alguns segundos, durante os quais o stream aparece como `UPDATING`. A
AWS também documenta limites de quantas vezes um stream pode ser redimensionado e de quanto de uma vez; o
moto aplicou as duas na mesma linha, então nenhum dos dois foi visto aqui. Streams on-demand, na
próxima seção, fazem essa divisão e essa junção sozinhos.
