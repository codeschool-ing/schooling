---
title: Bytes cobrados contra os bytes de fato lidos
version: 1
---

**Os bytes que o BigQuery cobra não são os bytes que ele lê.** Ele cobra bytes lógicos, o tamanho sem
compressão de cada valor pelo tipo, e lê os próprios arquivos comprimidos, que são bem menores. Os dois
números vêm de lugares diferentes e respondem perguntas diferentes: os bytes lógicos são uma tabela de
preços, fixa e conferível antes de a consulta rodar, e os bytes lidos são o que o motor de fato moveu. No
BigQuery você só vê o primeiro. No DuckDB, lendo Parquet, você vê os dois, e pô-los lado a lado mostra que
tipo de número a conta é.

## A consulta por bairro, em bytes de Parquet

**Um arquivo Parquet registra, para cada coluna de cada grupo de linhas, quantos bytes ela ocupa**,
comprimida e sem compressão. O `parquet_metadata` lê isso dos rodapés dos arquivos de setembro, para as
duas colunas que a consulta por bairro projeta:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT path_in_schema AS column_name, sum(total_compressed_size) AS on_disk, sum(total_uncompressed_size) AS uncompressed FROM parquet_metadata('warehouse/orders/dt=2026-09-*/*.parquet') WHERE path_in_schema IN ('district', 'total_cents') GROUP BY ALL ORDER BY column_name"
┌─────────────┬─────────┬──────────────┐
│ column_name │ on_disk │ uncompressed │
│   varchar   │ int128  │    int128    │
├─────────────┼─────────┼──────────────┤
│ district    │  230035 │       229830 │
│ total_cents │ 2748124 │      4179766 │
└─────────────┴─────────┴──────────────┘

ana@laptop:~/gcp$ python3 ask.py "SELECT path_in_schema AS column_name, encodings, compression FROM parquet_metadata('warehouse/orders/dt=2026-09-29/*.parquet') WHERE path_in_schema IN ('district', 'total_cents')"
┌─────────────┬────────────────────────────┬─────────────┐
│ column_name │         encodings          │ compression │
│   varchar   │          varchar           │   varchar   │
├─────────────┼────────────────────────────┼─────────────┤
│ district    │ PLAIN, RLE, RLE_DICTIONARY │ SNAPPY      │
│ total_cents │ PLAIN, RLE, RLE_DICTIONARY │ SNAPPY      │
└─────────────┴────────────────────────────┴─────────────┘
```

**Juntas elas são 2.978.159 bytes em disco, contra os 15.023.069 que o BigQuery cobraria.** Três coisas
fazem a diferença, e vale nomear cada uma.

**`dt` não custa nada em disco e custa 4.759.056 bytes na conta.** Nestes arquivos a data é o nome da
pasta, e o DuckDB a leu sem tocar numa coluna. Numa tabela do BigQuery, `dt` é uma coluna `DATE` como
outra qualquer, 8 bytes por linha, e uma consulta que filtra por ela é cobrada por ela.

**`district` são 230.035 bytes em disco e cerca de 5,5 milhões na conta.** A conta conta 2 bytes mais o
nome, para cada um dos 594.882 pedidos. O Parquet escreveu cada nome uma vez por grupo de linhas, num
dicionário, e depois um número pequeno por linha dizendo qual entrada é: a codificação `RLE_DICTIONARY`
que a segunda consulta mostra. Oito bairros comprimem para quase nada, e a conta não se importa.

**`total_cents` é a única coluna em que as duas concordam no tipo de coisa**: 2.748.124 bytes em disco
contra 4.759.056 na conta. Totais se repetem bem menos que bairros, então o dicionário economiza menos, e
o Snappy, a compressão que os arquivos usam, leva os 4.179.766 sem compressão a cerca de um terço a menos.

```
ana@laptop:~/gcp$ python3 ask.py "SELECT path_in_schema AS column_name, encodings, compression FROM parquet_metadata('warehouse/orders/dt=2026-09-29/*.parquet') WHERE path_in_schema IN ('district', 'total_cents')"
┌─────────────┬────────────────────────────┬─────────────┐
│ column_name │         encodings          │ compression │
│   varchar   │          varchar           │   varchar   │
├─────────────┼────────────────────────────┼─────────────┤
│ district    │ PLAIN, RLE, RLE_DICTIONARY │ SNAPPY      │
│ total_cents │ PLAIN, RLE, RLE_DICTIONARY │ SNAPPY      │
└─────────────┴────────────────────────────┴─────────────┘
```

## Por que a conta é lógica

**Porque uma tabela de preços tem de ser conhecível antes.** Se o BigQuery cobrasse os bytes que de fato
lê, o preço de uma consulta dependeria de quão bem o armazenamento comprimiu cada bloco naquele dia, da
codificação que escolheu, de uma carga recente ter deixado alguns blocos menos comprimidos que outros.
Ninguém conseguiria calculá-lo antes de rodar a consulta, e um dry run seria um palpite. Bytes lógicos só
dependem dos valores e dos tipos deles, então o `bqbill.py`, o dry run e a fatura concordam. O preço dessa
previsibilidade é que a compressão, que o armazenamento do Google faz muito bem, é uma economia que o
Google guarda do lado das consultas e só divide pelo modelo de armazenamento físico da aula 13.

**A mesma regra vai além das consultas.** A página de preços cobra a **Storage Read API**, o caminho
rápido que ferramentas como Spark e pandas usam para tirar uma tabela do BigQuery, "according to the
total amount of data read", com "the size of the data ... calculated based on the column's data type":
bytes lógicos de novo, a 1,98 USD por TiB em `southamerica-east1`, com 300 TiB por mês gratuitos. Um
notebook que lê uma tabela por ela paga o tamanho lógico das colunas que pede, por menor que a tabela
seja em disco.

## O hábito que esta aula deixa

**Antes de uma consulta rodar muitas vezes, saiba três números sobre ela.** Os bytes que ela vai ser
cobrada, por um dry run ou pelo `bqbill.py`. O plano, para conferir que ela lê as colunas e partições que
você esperava: o do DuckDB aqui, o grafo de execução no BigQuery depois que ela rodou. E, numa reserva, o
tempo de slot do grafo, que é a conta ali. Os dois primeiros não custam nada para obter e o terceiro custa
uma execução, e juntos pegam a consulta que custa uma fortuna antes de ela custar uma.
