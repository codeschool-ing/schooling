---
title: Bookmarks, e a exportação que chega duas vezes
version: 1
---

**Um bookmark é o que um job lembra entre execuções: qual entrada ele já processou.** Sem um, toda
noite lê a camada raw inteira de novo, o que serve para um mês e não serve para três anos. Com um, a
noite lê o que chegou desde a última execução que terminou, e a conta acompanha os dados novos em vez
do histórico.

## O que o etl.py lembra

Rode uma segunda vez, sem nada novo na camada raw:

```
ana@laptop:~/aws$ python3 etl.py
31 raw files, none of them new: nothing to do
```

**Nada a fazer, e nada lido além de uma listagem.** O bookmark tinha as 31 chaves da primeira
execução, e toda chave que a listagem encontrou estava nele. Esse é o mecanismo inteiro deste
programa: uma lista de chaves, gravada no S3 no fim de uma execução e lida no começo da próxima.

## O que o Glue lembra

O bookmark do Glue é a mesma ideia guardada pelo serviço, e três detalhes dele decidem como um job
precisa ser escrito. Esta parte é comportamento documentado da AWS; o moto não guarda bookmark
nenhum:

```
ana@laptop:~/aws$ aws glue get-job-bookmark --job-name orders-etl

aws: [ERROR]: An error occurred (500) when calling the GetJobBookmark operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**O moto responde com uma página de erro interno, um 500**, porque a operação não está implementada.
Na AWS essa chamada devolve o bookmark do job: para uma origem no S3, os objetos já processados,
julgados pela data da última modificação. Cada leitura que participa precisa de um
`transformation_ctx`, o nome que o `from_catalog` e o `getSink` do script receberam, porque esse
nome é a chave sob a qual o estado é guardado. **O bookmark só avança no `job.commit()`**, então uma
execução que falha no meio o deixa onde estava e a próxima lê os mesmos arquivos de novo, o que torna
essencial que ler os mesmos arquivos duas vezes não faça mal. E um bookmark pode ser zerado, para
reprocessar tudo, ou pausado, para rodar uma vez sem avançá-lo.

## A exportação que chega duas vezes

Agora o caso do último parágrafo do script. A loja reenvia os primeiros 500 pedidos de 15 de outubro
num segundo arquivo, na noite seguinte:

```
ana@laptop:~/aws$ aws s3 cp s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/orders.csv day15.csv --only-show-errors && head -501 day15.csv > resent.csv
ana@laptop:~/aws$ aws s3 cp resent.csv s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/orders-resent.csv --only-show-errors
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/
2026-10-16 13:39:34      26494 orders-resent.csv
2026-10-16 13:39:27    1279794 orders.csv
ana@laptop:~/aws$ python3 etl.py
1 new raw file in 1 day
  2026-10-15: 24,281 rows in 2 files, 500 of them duplicates
  24,281 rows read, 23,781 kept, 401,803 bytes of Parquet written
  0 partitions added to quitanda.orders, 1 already there
```

**Um arquivo novo, um dia reescrito, 500 duplicatas descartadas.** O bookmark entregou ao programa
só o `orders-resent.csv`, e o programa leu os dois arquivos de 15 de outubro mesmo assim, porque o
que ele substitui é o dia. A camada raw e a curated agora discordam, e devem discordar:

```
ana@laptop:~/aws$ python3 ask.py "SELECT count(*) AS orders, count(DISTINCT order_id) AS ids FROM orders_csv WHERE dt = '2026-10-15'"
┌────────┬───────┐
│ orders │  ids  │
│ int64  │ int64 │
├────────┼───────┤
│  24281 │ 23781 │
└────────┴───────┘

read from S3: 1,306,288 bytes in 6 GET requests to 2 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py "SELECT count(*) AS orders, count(DISTINCT order_id) AS ids FROM orders WHERE dt = '2026-10-15'"
┌────────┬───────┐
│ orders │  ids  │
│ int64  │ int64 │
├────────┼───────┤
│  23781 │ 23781 │
└────────┴───────┘

read from S3: 227,684 bytes in 2 GET requests to 1 object
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**24.281 linhas na camada raw para 23.781 pedidos, e 23.781 de cada na curated.** Um job que tivesse
acrescentado as linhas do arquivo novo ao dia, como o script do Glue faria, mostraria 24.281 e 23.781
ali também, e toda soma daquele dia teria 500 pedidos a mais. O próprio arquivo de bookmark agora
guarda a chave nova ao lado das outras 31:

```
ana@laptop:~/aws$ aws s3 cp s3://quitanda-glue-prod/bookmarks/orders-etl.json bookmark.json --only-show-errors
ana@laptop:~/aws$ jq length bookmark.json && jq -r '.[] | select(contains("resent"))' bookmark.json
32
quitanda-raw-prod/raw/orders/dt=2026-10-15/orders-resent.csv
```

Uma diferença em relação ao bookmark do Glue vale ser nomeada, porque é uma falha que este programa
tem e o do Glue não tem. **O `etl.py` lembra chaves, então um arquivo regravado sob a mesma chave
nunca mais é lido**; o Glue compara a data da última modificação, e o leria. Uma exportação que
corrige um dia sobrescrevendo o arquivo dele fica invisível para o `etl.py`, e a correção é lembrar
o ETag de cada chave, a impressão digital que a lição 1 apresentou, ao lado do nome.
