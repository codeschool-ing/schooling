---
title: Um stream é um conjunto de shards
version: 1
---

**Um data stream do Kinesis não é uma fila só.** É um número fixo de **shards**, e cada shard é um
log ordenado próprio: os registros são acrescentados no fim dele e lidos de qualquer ponto dele. Um
registro escrito no stream vai para exatamente um shard, e qual deles é decidido por uma conta sobre
uma string que o produtor fornece, a **chave de partição** (*partition key*). Todo o resto desta
lição, a ordem, os limites e o preço, é propriedade do shard e não do stream, então é pelo shard que
se começa.

O terminal é o da lição 1: o moto rodando no terminal dele e as quatro linhas de "O seu laboratório,
em resumo" da lição 1 digitadas neste. O moto começa vazio, e esta lição constrói os streams do zero.
Um stream com dois shards para os eventos de pedido da Quitanda:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders --shard-count 2
ana@laptop:~/aws$ aws kinesis describe-stream-summary --stream-name orders --query 'StreamDescriptionSummary.[StreamStatus,OpenShardCount,RetentionPeriodHours]' --output text
ACTIVE	2	24
ana@laptop:~/aws$ aws kinesis list-shards --stream-name orders --query 'Shards[].[ShardId,HashKeyRange.StartingHashKey,HashKeyRange.EndingHashKey]' --output text
shardId-000000000000	0	170141183460469231731687303715884105727
shardId-000000000001	170141183460469231731687303715884105728	340282366920938463463374607431768211455
```

**Os dois shards dividem uma reta numérica entre si.** O Kinesis pega a chave de partição, calcula o
MD5 dela e lê os 16 bytes do resumo como um único inteiro sem sinal, um número de 0 a 2^128 − 1. Essa
faixa é o **espaço de chaves de hash** do stream, e cada shard é dono de um trecho contíguo dela. O
shard `0` fica com tudo abaixo de 2^127, que é `170141183460469231731687303715884105728`, e o shard `1`
fica com 2^127 e tudo acima. O moto dividiu o espaço exatamente ao meio, que é também o que a AWS faz
quando um stream é criado com um número de shards.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"O espaço de chaves de hash do stream orders, uma linha de 0 a 2^128 menos 1, dividida em 2^127 em dois shards. O shard 0 tem a metade de baixo e o shard 1 a de cima. O MD5 de quatro chaves de partição está marcado na linha: c-03 e c-17 caem na metade de baixo, no shard 0; c-02 e c-05 caem na de cima, no shard 1.\" data-fig=\"l20-hashspace\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">MD5 da chave de partição</text><rect x=\"60.0\" y=\"80.0\" width=\"300.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"360.0\" y=\"80.0\" width=\"300.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shardId-000000000000</text><text x=\"510.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shardId-000000000001</text><line x1=\"215.8\" y1=\"48.0\" x2=\"215.8\" y2=\"73.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"215.8,79.0 218.8,73.0 212.8,73.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"215.8\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-03</text><line x1=\"317.6\" y1=\"48.0\" x2=\"317.6\" y2=\"73.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"317.6,79.0 320.6,73.0 314.6,73.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"317.6\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-17</text><line x1=\"508.4\" y1=\"48.0\" x2=\"508.4\" y2=\"73.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"508.4,79.0 511.4,73.0 505.4,73.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"508.4\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-02</text><line x1=\"645.7\" y1=\"48.0\" x2=\"645.7\" y2=\"73.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"645.7,79.0 648.7,73.0 642.7,73.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"649.7\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-05</text><line x1=\"60.0\" y1=\"120.0\" x2=\"60.0\" y2=\"132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"60.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"360.0\" y1=\"120.0\" x2=\"360.0\" y2=\"132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"360.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2^127</text><line x1=\"660.0\" y1=\"120.0\" x2=\"660.0\" y2=\"132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"660.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2^128 - 1</text><text x=\"210.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shard 0: a metade de baixo</text><text x=\"510.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shard 1: a metade de cima</text></svg>", "caption": "O MD5 de uma chave de partição é um ponto numa linha, e o shard é a faixa em que o ponto cai."}
```

## Prevendo o shard

Como a regra é MD5 e uma faixa, dá para saber onde uma chave vai cair antes de escrever qualquer
coisa. O programa abaixo lê os shards abertos do stream e faz a conta para cada chave da linha de
comando. Salve-o como `~/aws/shard_of.py`, do mesmo jeito que salvou o `prices.py` na lição 1. O
`boto3`, a biblioteca da AWS para Python, veio com o moto:

`shard_of.py`:

```python
import hashlib
import sys

import boto3

shards = boto3.client('kinesis').list_shards(StreamName=sys.argv[1])['Shards']
for key in sys.argv[2:]:
    h = int(hashlib.md5(key.encode()).hexdigest(), 16)
    for s in shards:
        r, open_ = s['HashKeyRange'], 'EndingSequenceNumber' not in s['SequenceNumberRange']
        if open_ and int(r['StartingHashKey']) <= h <= int(r['EndingHashKey']):
            print(f'{key:<6} {h:>40}  {s["ShardId"]}')
```

```
ana@laptop:~/aws$ python3 shard_of.py orders c-17 c-03 c-02 c-05
c-17    146071825190439638704466073634825402563  shardId-000000000000
c-03     88352402212612476087593936981806328046  shardId-000000000000
c-02    254303140926280561521588452831818067638  shardId-000000000001
c-05    332192223557910061300396319758440839601  shardId-000000000001
```

**`c-17` e `c-03` vão para o shard 0, e `c-02` e `c-05` para o shard 1**, e a próxima seção escreve
registros de verdade com essas chaves e os encontra onde a conta disse. O teste `open_` importa depois
de um reshard, mais adiante nesta lição: um shard que foi fechado ainda lista a faixa antiga, e nada
novo entra nele.

## O que a chave de partição decide

**A chave decide duas coisas ao mesmo tempo, e elas puxam para lados opostos.** Todo registro com a
mesma chave vai para o mesmo shard, então a chave é a unidade de ordem: a Quitanda usa o cliente como
chave dos eventos de pedido, e por isso os eventos de um cliente são lidos de volta na ordem em que
foram escritos. E a chave é a unidade de distribuição: os shards dividem a carga só tão por igual
quanto as chaves dividem o espaço de hash.

Uma chave com muitos valores se espalha bem. Os ids de cliente chegam às dezenas de milhares, e os
resumos deles ficam espalhados pela reta. Uma chave com poucos valores não: com a loja como chave, e
as três lojas da Quitanda em São Paulo, o stream tem três valores de hash no total, e por mais shards
que tenha, no máximo três deles recebem alguma coisa. Uma chave com um valor só, como a constante
`orders`, põe o stream inteiro num shard e faz dos outros enfeite. **Escolha como chave a menor coisa
cujos eventos precisam ficar em ordem**, nunca a maior.

Um produtor também pode pular o hash e apontar um ponto da reta diretamente, com `ExplicitHashKey` no
`PutRecord`. É a ferramenta para espalhar à mão um conjunto conhecido de chaves, e raramente é
necessária; a conta padrão é aquela em que o resto deste curso se apoia.
