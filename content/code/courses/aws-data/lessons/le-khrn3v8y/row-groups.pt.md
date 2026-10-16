---
title: Grupos de linhas, e as estatísticas que os pulam
version: 1
---

**Dentro de um arquivo Parquet, um filtro numa coluna pode pular blocos de linhas sem lê-los**, e é
o rodapé que torna isso possível. Cada column chunk de cada grupo de linhas carrega o menor e o maior
valor que guarda. Um leitor a quem pedem `hour >= 21` lê o rodapé primeiro, e qualquer grupo cuja
maior hora fique abaixo de 21 não pode ter uma única linha que sirva, então os chunks dele nem são
buscados. Isso se chama predicate pushdown, e o motor do Athena faz isso para Parquet e ORC como o
DuckDB e o PyArrow fazem.

**Só funciona se os valores estiverem agrupados.** A faixa de um grupo só diz alguma coisa quando as
linhas dele se parecem. O arranjo `groups` e o arranjo `groups-shuffled` guardam as mesmas linhas em
grupos de 2.000; um mantém a ordem do dia, o outro não. O `footer.py`, da lição 15, imprime a faixa
de cada grupo:

```
ana@laptop:~/aws$ python3 footer.py s3://quitanda-curated-prod/layouts/groups/dt=2026-10-15/orders.parquet | grep -E 'rows|hour'
23,781 rows in 12 row groups, footer 9,494 bytes
  0  hour                 101 bytes             7 .. 10
  1  hour                  88 bytes            10 .. 11
  2  hour                  88 bytes            11 .. 12
  3  hour                  94 bytes            12 .. 14
  4  hour                  95 bytes            14 .. 16
  5  hour                  95 bytes            16 .. 18
  6  hour                  88 bytes            18 .. 19
  7  hour                  81 bytes            19 .. 19
  8  hour                  88 bytes            19 .. 20
  9  hour                  88 bytes            20 .. 21
  10  hour                  88 bytes            21 .. 22
  11  hour                  88 bytes            22 .. 23
```

```
ana@laptop:~/aws$ python3 footer.py s3://quitanda-curated-prod/layouts/groups-shuffled/dt=2026-10-15/orders.parquet | grep -E 'rows|hour'
23,781 rows in 12 row groups, footer 9,496 bytes
  0  hour               1,404 bytes             7 .. 23
  1  hour               1,404 bytes             7 .. 23
  2  hour               1,404 bytes             7 .. 23
  3  hour               1,404 bytes             7 .. 23
  4  hour               1,404 bytes             7 .. 23
  5  hour               1,404 bytes             7 .. 23
  6  hour               1,404 bytes             7 .. 23
  7  hour               1,404 bytes             7 .. 23
  8  hour               1,404 bytes             7 .. 23
  9  hour               1,404 bytes             7 .. 23
  10  hour               1,404 bytes             7 .. 23
  11  hour               1,269 bytes             7 .. 23
```

**Ordenado, cada grupo cobre uma hora ou duas; embaralhado, todo grupo cobre o dia inteiro, de 7 a
23.** Um filtro em `hour >= 21` pode pular os nove primeiros grupos do arquivo ordenado, e nenhum do
embaralhado. Os chunks de `hour` embaralhados também são dezesseis vezes maiores, 1.404 bytes contra
88, porque uma sequência de valores iguais comprime até quase nada e uma mistura de dezessete não. E
os dois rodapés passaram de 9.000 bytes contra os 1.576 do grupo único da lição 15: o rodapé lista
cada chunk de cada grupo, então doze grupos são um rodapé doze vezes mais longo.

## O que os três arranjos leram

A mesma pergunta, as vendas depois das nove da noite, feita à camada curated com um grupo por dia, e
depois aos dois arranjos com doze:

```
ana@laptop:~/aws$ python3 ask.py "SELECT sum(total_cents) / 100 AS late FROM orders WHERE hour >= 21" | tail -2
read from S3: 4,914,494 bytes in 93 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/groups/:parquet "SELECT sum(total_cents) / 100 AS late FROM t WHERE hour >= 21"
┌─────────────┐
│    late     │
│   double    │
├─────────────┤
│ 16481827.62 │
└─────────────┘

read from S3: 3,154,464 bytes in 126 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/groups-shuffled/:parquet "SELECT sum(total_cents) / 100 AS late FROM t WHERE hour >= 21" | tail -2
read from S3: 7,261,486 bytes in 418 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**3.154.464 bytes ordenado, 7.261.486 embaralhado, e 4.914.494 para o grupo único por dia.** Os
grupos ordenados ganharam: o leitor pulou a maior parte do `total_cents` de cada dia. Os grupos
embaralhados perderam até para o grupo único, porque não pularam nada e ainda pagaram rodapés mais
longos e compressão pior. **As estatísticas são de graça, e só ajudam um leitor cujo filtro combina
com a ordem em que as linhas foram gravadas.**

## Qual deve ser o tamanho de um grupo

O PyArrow põe até cerca de um milhão de linhas num grupo por padrão, e é por isso que cada dia do
`lake.py`, uns 20.000 a 32.000 pedidos, é um único grupo com uma só faixa para o dia inteiro. O Spark
e o Hive miram grupos de uns 128 MB. Duas mil linhas é pequeno demais para um lago de verdade, e só é
usado aqui para que um dia tenha grupos bastantes para se ver. A lição para um lago real é a ordem, não
o tamanho: **ordene pela coluna que a maioria das consultas filtra depois da chave de partição**,
quando o arquivo é gravado, que é assunto do job, o da lição 17, e não custa nada na hora da consulta.
