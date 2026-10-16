---
title: Memtables, SSTables e compactação
version: 1
---

Um banco relacional atualiza uma linha onde ela está no disco. **O Cassandra nunca faz isso.** Uma
escrita vai para uma tabela em memória, a memtable, e para o commit log por segurança; quando a
memtable enche, ou quando você pede, ela é gravada como um arquivo novo, uma SSTable, e esse arquivo
nunca mais muda. Um `UPDATE` é uma versão nova de algumas células num arquivo mais novo, e um
`DELETE`, como a próxima seção mostra, também é um arquivo novo. Ler uma linha significa juntar
todas as SSTables que têm um pedaço dela, vencendo o timestamp mais novo, e a **compactação** é o
trabalho de fundo que junta SSTables em menos arquivos, maiores, para que as leituras não precisem
fazer isso.

Esta aula usa os três nós da aula 16 com o keyspace `shop` em três cópias, como a aula 17 o deixou. Se
você remontou o cluster, a aula 16 tem o laço e a aula 17 o `ALTER KEYSPACE`.

## Vendo os arquivos aparecerem

Uma tabela de cestas, duas linhas, e o diretório da tabela no `c1`:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE TABLE shop.baskets (customer text, sku text, qty int, PRIMARY KEY (customer, sku));
cqlsh> INSERT INTO shop.baskets (customer, sku, qty) VALUES ('ana@example.com', 'KB-101', 1);
cqlsh> INSERT INTO shop.baskets (customer, sku, qty) VALUES ('ana@example.com', 'CB-012', 2);
cqlsh> exit
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/"
ana@vm:~$ docker exec c1 nodetool flush shop baskets
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/"
nb-1-big-CompressionInfo.db
nb-1-big-Data.db
nb-1-big-Digest.crc32
nb-1-big-Filter.db
nb-1-big-Index.db
nb-1-big-Statistics.db
nb-1-big-Summary.db
nb-1-big-TOC.txt
```

**O primeiro `ls` não imprimiu nada**: as duas linhas existiam só na memtable e no commit log. O
`nodetool flush` gravou a memtable, e o diretório agora tem uma SSTable, que são oito arquivos com o
prefixo `nb-1-big`. `Data.db` guarda as linhas; os outros são o índice, um resumo do índice, um
filtro de Bloom que deixa uma leitura pular um arquivo que não pode conter uma chave, estatísticas,
posições de compressão, um checksum e um sumário. `nb` é a versão do formato do arquivo e `1` a
geração, a ordem em que o nó os gravou.

Mais duas escritas, cada uma com seu flush. A segunda é um `UPDATE` de uma linha que já está em
`nb-1`:

```
ana@vm:~$ docker exec c1 cqlsh -e "INSERT INTO shop.baskets (customer, sku, qty) VALUES ('bruno@example.com', 'MN-330', 1);"
ana@vm:~$ docker exec c1 nodetool flush shop baskets
ana@vm:~$ docker exec c1 cqlsh -e "UPDATE shop.baskets SET qty = 3 WHERE customer = 'ana@example.com' AND sku = 'CB-012';"
ana@vm:~$ docker exec c1 nodetool flush shop baskets
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"
nb-1-big-Data.db
nb-2-big-Data.db
nb-3-big-Data.db
ana@vm:~$ docker exec c1 nodetool tablestats shop.baskets | grep "SSTable count"
		SSTable count: 3
		Old SSTable count: 0
```

Três SSTables agora, e o `CB-012` da Ana existe em duas delas: quantidade 2 em `nb-1`, quantidade 3
em `nb-3`. Nada voltou para mudar o `nb-1`. Uma leitura da cesta da Ana abre os dois arquivos e fica
com a célula de timestamp mais novo.

## Compactação

A compactação roda sozinha quando se acumulam SSTables parecidas o bastante, e o `nodetool compact`
força uma completa agora:

```
ana@vm:~$ docker exec c1 nodetool compact shop baskets
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"
nb-4-big-Data.db
ana@vm:~$ docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/baskets-*/*Data.db"
[
  {
    "table kind" : "REGULAR",
    "partition" : {
      "key" : [ "bruno@example.com" ],
      "position" : 31
    },
    "rows" : [
      {
        "type" : "row",
        "position" : 31,
        "clustering" : [ "MN-330" ],
        "liveness_info" : { "tstamp" : "2026-10-10T19:58:52.270805Z" },
        "cells" : [
          { "name" : "qty", "value" : 1 }
        ]
      }
    ]
  },
  {
    "table kind" : "REGULAR",
    "partition" : {
      "key" : [ "ana@example.com" ],
      "position" : 81
    },
    "rows" : [
      {
        "type" : "row",
        "position" : 81,
        "clustering" : [ "CB-012" ],
        "liveness_info" : { "tstamp" : "2026-10-10T19:58:49.088621Z" },
        "cells" : [
          { "name" : "qty", "value" : 3, "tstamp" : "2026-10-10T19:58:54.207711Z" }
        ]
      },
      {
        "type" : "row",
        "position" : 104,
        "clustering" : [ "KB-101" ],
        "liveness_info" : { "tstamp" : "2026-10-10T19:58:48.075283Z" },
        "cells" : [
          { "name" : "qty", "value" : 1 }
        ]
      }
    ]
  }
]
```

Três arquivos viraram **um, o `nb-4`**, e o `sstabledump` o imprime como JSON. Cada partição aparece
uma vez, com as linhas ordenadas pela chave de clustering, e o `CB-012` da Ana tem um valor só, `3`,
com dois timestamps: o `liveness_info` da linha, do primeiro `INSERT`, e o da própria célula, do
`UPDATE`. O valor antigo, 2, sumiu; a compactação ficou só com a versão mais nova de cada célula. As
partições estão na ordem dos tokens, não em ordem alfabética, que é o anel da aula 16 outra vez.

## Qual estratégia, e como conferir

Como a compactação escolhe o que juntar é a **estratégia de compactação** da tabela, e o jeito honesto
de saber qual uma tabela tem é perguntar a ela:

```
ana@vm:~$ docker exec c1 cqlsh -e "DESCRIBE TABLE shop.baskets" | grep -E "compaction|gc_grace"
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND gc_grace_seconds = 864000
ana@vm:~$ docker exec c1 grep -A2 "^default_compaction" /etc/cassandra/cassandra_latest.yaml
default_compaction:
  class_name: UnifiedCompactionStrategy
  parameters:
```

A tabela ganhou **`SizeTieredCompactionStrategy`**, STCS, que junta SSTables de tamanho parecido
quando há `min_threshold` delas, quatro aqui. Esse é o padrão do `cassandra.yaml` que a imagem oficial
traz. O mesmo diretório tem o `cassandra_latest.yaml`, as configurações recomendadas do Cassandra 5.0
para clusters novos, e ali o padrão é a **`UnifiedCompactionStrategy`**, UCS, nova no 5.0. Um cluster
só a usa se alguém a escolher, para o cluster ou por tabela com `ALTER TABLE … WITH compaction =
{'class': 'UnifiedCompactionStrategy'}`.

As estratégias numa tabela:

| estratégia | junta | serve para |
| --- | --- | --- |
| `SizeTieredCompactionStrategy` | SSTables de tamanho parecido, em faixas | tabelas com muita escrita; pode deixar versões velhas de uma linha espalhadas em muitos arquivos |
| `LeveledCompactionStrategy` | em níveis em que cada partição está em no máximo um arquivo por nível | tabelas com muita leitura que atualizam linhas com frequência; custa mais escrita em disco |
| `TimeWindowCompactionStrategy` | SSTables da mesma janela de tempo, e nunca entre janelas | séries temporais gravadas uma vez e expiradas por TTL, como as visualizações da aula 16 |
| `UnifiedCompactionStrategy` | configurável para se comportar como qualquer uma das duas primeiras, por nível | clusters novos no 5.0, como o `cassandra_latest.yaml` recomenda |

O `gc_grace_seconds = 864000` ao lado dela na saída do `DESCRIBE` é o assunto da seção depois da
próxima. Primeiro, o que um delete grava.
