---
title: Sob demanda, cobrado pelo byte
version: 1
---

**Sob demanda é o padrão do BigQuery, e ele cobra uma consulta pelos bytes que ela lê, nunca pelo
tempo que ela leva.** Um projeto que não comprou nada está nele. Uma consulta que lê 1 TiB custa 11,25
USD em `southamerica-east1`, termine ela em dois segundos ou em dois minutos, devolva uma linha ou um
milhão. O preço é de `cloud.google.com/bigquery/pricing`, lido em 2026-10-30, como todo preço desta
aula, e o primeiro TiB de todo mês é gratuito.

Parece a conta mais simples da nuvem, e ela esconde cinco regras, todas na página de preços. Cada uma
muda um número que você erraria sem ela.

## As cinco regras

**Os bytes são os bytes lógicos das colunas que a consulta cita**, contados por tipo como a aula 13 os
contou. Uma coluna citada em qualquer lugar da consulta conta: no `SELECT`, no `WHERE`, no
`GROUP BY` ou num `JOIN`. Uma coluna que a consulta nunca cita não custa nada.

**`LIMIT` não reduz a conta.** A página diz isso com todas as letras: "When you run a query, you're
charged according to the data processed in the columns you select, even if you set an explicit LIMIT
on the results." `SELECT * FROM orders LIMIT 10` lê todas as colunas de todas as linhas para achar
dez delas, e é cobrado por tudo isso.

**Toda consulta é arredondada para cima até o próximo MB, e é cobrada por pelo menos 10 MB.** O mínimo
vale para cada tabela que a consulta cita, e para a consulta como um todo. O BigQuery conta um MB como
2^20 bytes, então a menor consulta que ele cobra tem 10.485.760 bytes.

**Uma consulta que falha não custa nada, e uma respondida pelo cache também não.** O BigQuery guarda o
resultado de uma consulta por um tempo e, se a mesma consulta chega de novo e as tabelas não mudaram,
devolve o resultado guardado e não cobra byte nenhum.

**Cancelar não é reembolso.** Nas palavras da página, "Canceling a running query job might incur
charges up to the full cost for the query if you let the query run to completion." Uma consulta que já
leu a tabela já foi cobrada por isso.

## As regras, como programa

Salve isto como `~/gcp/ondemand.py`. Ele recebe os bytes que uma consulta lê de cada tabela que cita,
um número por tabela, e aplica o mínimo, o arredondamento e o preço:

`ondemand.py`:

```python
import math
import sys

PRICE_PER_TIB = 11.25  # USD, on demand, southamerica-east1, cloud.google.com/bigquery/pricing, read 2026-10-30
MB, TIB = 2**20, 2**40
MINIMUM = 10 * MB


def billed(bytes_per_table):
    per_table = [max(b, MINIMUM) for b in bytes_per_table]
    return math.ceil(max(sum(per_table), MINIMUM) / MB) * MB


tables = [int(b) for b in sys.argv[1:]]
b = billed(tables)
print(f'read {sum(tables):>15,} bytes   billed {b:>15,} bytes   {b / TIB * PRICE_PER_TIB:.6f} USD')
```

**Os bytes para dar a ele vêm da regra da aula 13**: uma coluna `INT64` são 8 bytes por linha. O
DuckDB conta as linhas, na tabela inteira e no último dia dela:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT 8 * count(*) AS total_cents_bytes, 8 * count(*) FILTER (WHERE dt = DATE '2026-09-29') AS one_day FROM orders"
┌───────────────────┬─────────┐
│ total_cents_bytes │ one_day │
│       int64       │  int64  │
├───────────────────┼─────────┤
│           9960944 │  130872 │
└───────────────────┴─────────┘
```

Cinco consultas, com preço. `total_cents` sobre a tabela inteira; a mesma coluna num dia só; um
`SELECT *`, que a aula 13 mediu em 99.177.572 bytes; um join que lê `store_id` e `total_cents` de
`orders` e algumas centenas de bytes de uma tabela de dezesseis lojas; e um `SELECT *` sobre uma
tabela de 2 TiB:

```
ana@laptop:~/gcp$ python3 ondemand.py 9960944
read       9,960,944 bytes   billed      10,485,760 bytes   0.000107 USD
ana@laptop:~/gcp$ python3 ondemand.py 130872
read         130,872 bytes   billed      10,485,760 bytes   0.000107 USD
ana@laptop:~/gcp$ python3 ondemand.py 99177572
read      99,177,572 bytes   billed      99,614,720 bytes   0.001019 USD
ana@laptop:~/gcp$ python3 ondemand.py 19921888 400
read      19,922,288 bytes   billed      30,408,704 bytes   0.000311 USD
ana@laptop:~/gcp$ python3 ondemand.py 2199023255552
read 2,199,023,255,552 bytes   billed 2,199,023,255,552 bytes   22.500000 USD
```

**Os pedidos da Quitanda são pequenos demais para custar algo que valha contar**, e as duas primeiras
linhas mostram o mínimo fazendo todo o trabalho. O `total_cents` da tabela inteira tem 9.960.944
bytes e é cobrado como 10.485.760; um dia dele tem 130.872 bytes e é cobrado pelos mesmos 10.485.760,
oitenta vezes o que leu. **Ler menos de 10 MB não economiza nada.** Isso importa na aula 15, porque um
filtro de partição que transforma uma varredura de 9 MB numa de 0,1 MB não muda nada na conta de uma
tabela deste tamanho.

**O join é cobrado por 20 MB de mínimos e um pouco mais**, 30.408.704 bytes, porque cada tabela que ele
cita é cobrada por pelo menos 10 MB sozinha. Uma consulta que junta cinco tabelas pequenas paga por
cinquenta. **E o `SELECT *` sobre 2 TiB custa 22,50 USD toda vez que roda.** Não há nada de incomum
nele: dois TiB é o tamanho que um fluxo de cliques atinge em poucos meses, e uma consulta escrita sem
pensar nas colunas é a consulta mais comum que existe.

## Um mês disso

**A conta que dói nunca é uma consulta, é uma consulta que se repete.** A consulta de 2 TiB rodada de
hora em hora por um painel, num mês de 30 dias, sem e com o TiB gratuito:

```
ana@laptop:~/gcp$ python3 -c 'print(24 * 30 * 22.5, (24 * 30 * 2**41 / 2**40 - 1) * 11.25)'
16200.0 16188.75
```

**16.200 USD antes do TiB gratuito e 16.188,75 depois dele.** O nível gratuito vale 11,25 USD por mês,
o que é dinheiro de verdade para um estudante e nada para um painel. O mesmo painel lendo as duas
colunas que desenha, só da partição do último dia, seria cobrado por alguns MB por hora, que é o
assunto das aulas 15 e 16.

**Sob demanda também tem um teto de velocidade, e o teto é dividido.** A página diz que um projeto sob
demanda tem "access to up to 2,000 concurrent slots, shared among all queries in a single project", até
2.000 slots simultâneos divididos entre as consultas do projeto, que ele pode ultrapassar por pouco
tempo e que podem ser menos quando a região está ocupada. Um projeto que roda cem consultas pesadas ao
mesmo tempo divide esses slots entre elas. Isso não é custo, e é o primeiro motivo pelo qual uma
empresa sai do sob demanda: não para pagar menos, mas para saber quanta computação vai ter.
