---
title: Codecs, e quanto custa um byte comprimido
version: 1
---

**O Athena cobra os bytes que lê do S3, e um arquivo comprimido é lido comprimido.** Então um codec
que corta pela metade o tamanho guardado corta pela metade a conta de toda consulta que lê o arquivo,
o que faz do codec a mais barata das decisões: um argumento para o gravador. O que ele custa é tempo
nos processadores que gravam e leem, que esta lição não mede, e, para um codec, a possibilidade de
dividir um arquivo.

A pergunta da lição 15, as vendas de outubro por forma de pagamento, feita a cinco arranjos. A
resposta são as mesmas quatro linhas toda vez, então só o CSV com gzip, o primeiro, aparece inteiro:

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/csv-gzip/:csv "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 348030 │ 41382125.37 │
│ credit       │ 249543 │ 29611096.91 │
│ debit        │  97614 │ 11585221.55 │
│ meal-voucher │  60324 │  7158978.69 │
└──────────────┴────────┴─────────────┘

read from S3: 8,421,323 bytes in 206 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/parquet-none/:parquet "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 6,481,669 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/orders/:parquet "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 5,102,048 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/parquet-zstd/:parquet "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 4,280,951 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/orc-zstd/:orc "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 2,820,788 bytes in 155 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

## Lendo os cinco números

**O CSV com gzip leu todos os seus 8.421.323 bytes**, um quinto dos 40.641.097 do CSV puro, e ainda
assim toda coluna de toda linha. A compressão deixou a leitura menor e não fez nada para deixá-la
seletiva: o motor descomprimiu cada arquivo desde o primeiro byte para achar dois campos por linha.
Há também um custo que não aparece aqui. **Um arquivo gzip não pode ser dividido**: a descompressão
começa do início, então um leitor pega o arquivo inteiro. Num mês de arquivos de 1 MB isso não
importa; numa exportação única de 10 GB quer dizer que um worker de um job a lê enquanto os outros
esperam.

**Os três números do Parquet caem com o codec**: 6.481.669 bytes sem nenhum, 5.102.048 com Snappy,
4.280.951 com zstd. Caem menos do que os tamanhos dos arquivos caíram, de 24.667.617 para 7.433.857. As duas colunas que esta pergunta lê já eram pequenas: `payment` é um dicionário de quatro
valores seja qual for o codec, e a maior parte do que a compressão tira está em `order_id` e
`customer_id`, que a pergunta nem toca. **Um codec economiza na proporção do que a pergunta lê, não
do que o arquivo guarda.**

**O ORC com zstd leu 2.820.788 bytes, o menor de todos**, em 155 requisições onde o Parquet fez 62. O
leitor de ORC busca o fim de um arquivo em mais pedaços e menores que o leitor de Parquet do PyArrow,
e essa diferença é do motor, não do formato: o motor do Athena lê os dois formatos com leitores
próprios.

## Qual codec

O Snappy é o padrão do PyArrow e do Spark para Parquet, rápido para gravar e para ler, e nunca é um
erro. O zstd é menor ao custo de mais trabalho na gravação. Para um lago lido muito mais vezes do que é gravado, um arquivo menor pago uma vez e lido milhares de vezes costuma ser a troca melhor.
Gzip e CSV puro pertencem à camada raw, onde os arquivos chegam do jeito que a origem os manda, e a
nenhum lugar que um painel leia.
