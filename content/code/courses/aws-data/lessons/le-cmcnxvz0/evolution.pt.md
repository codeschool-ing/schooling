---
title: Quando os arquivos mudam de forma
version: 1
---

**Mudar a tabela é uma requisição; mudar os arquivos é cada arquivo.** O catálogo agora diz oito
colunas, e os 31 arquivos Parquet de outubro continuam com sete, porque um arquivo é gravado uma vez
e ninguém reescreve um mês de histórico para acrescentar uma coluna. Então todo lago acaba guardando
arquivos de mais de uma forma sob uma tabela, e o que uma consulta devolve depende de como o leitor
os alinha: **por nome ou por posição, e com o esquema de quem no comando**.

## Uma coluna que só novembro tem

O primeiro dia de cupons, gravado no mesmo prefixo de outubro. O programa toma emprestados `orders`
e `regulars` do `lake.py`, então o dia se parece com os outros mais uma coluna:

`coupons.py`:

```python
import datetime
import random

import pyarrow as pa
import pyarrow.parquet as pq

from lake import CURATED, filesystem, orders, regulars

day = datetime.date(2026, 11, 1)
rng = random.Random(1101)
table = orders(rng, day, regulars())
coupon = [rng.choice(['PRIMAVERA10', 'FRETEGRATIS']) if rng.random() < 0.2 else None
          for _ in range(table.num_rows)]
table = table.append_column('coupon', pa.array(coupon, pa.string()))
pq.write_table(table, f'{CURATED}/dt={day}/orders.parquet', filesystem=filesystem())
print(f'{table.num_rows:,} orders on {day}, {table["coupon"].null_count:,} of them with no coupon')
```

```
ana@laptop:~/aws$ python3 coupons.py
29,467 orders on 2026-11-01, 23,485 of them with no coupon
ana@laptop:~/aws$ python3 ask.py "SELECT dt, count(*) AS orders FROM orders WHERE dt >= '2026-10-30' GROUP BY dt ORDER BY dt"
┌────────────┬────────┐
│     dt     │ orders │
│  varchar   │ int64  │
├────────────┼────────┤
│ 2026-10-30 │  21249 │
│ 2026-10-31 │  31258 │
│ 2026-11-01 │  29467 │
└────────────┴────────┘

read from S3: 196,608 bytes in 3 GET requests to 3 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py "SELECT count(coupon) FROM orders WHERE dt = '2026-11-01'"
Binder Error: Referenced column "coupon" not found in FROM clause!
Candidate bindings: "hour", "total_cents"
```

**O dia novo é contado, e a coluna nova não pode ser pedida.** O primeiro `ask.py` viu 1º de
novembro como qualquer outra partição, e leu só 196.608 bytes, três rodapés e coluna nenhuma, porque
a contagem de linhas está no rodapé. O segundo recusou `coupon` de cara. O `ask.py` monta cada tabela
com o padrão do PyArrow, que tira o esquema do primeiro arquivo que encontra, `dt=2026-10-01`, e
esse arquivo não tem cupons. **O leitor decidiu o esquema, e decidiu a partir de outubro.**

Isso é uma simplificação do programa deste curso, e é a mais comum por aí. O Athena não a faz: ele
tira o esquema do catálogo, da versão 2 em diante a lista tem `coupon`, e o Parquet é lido por nome,
então outubro responderia `NULL` para todo cupom e novembro os seus valores. Isso não foi rodado, já
que o moto não roda SQL. O que o DuckDB faz com os dois arquivos diretamente dá para rodar, depois de
copiá-los para fora do moto:

```
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/orders/dt=2026-10-31/orders.parquet oct31.parquet --only-show-errors
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/orders/dt=2026-11-01/orders.parquet nov01.parquet --only-show-errors
ana@laptop:~/aws$ python3 -c "import duckdb; duckdb.sql(\"SELECT count(*) AS orders, count(coupon) AS with_coupon FROM read_parquet(['oct31.parquet', 'nov01.parquet'], union_by_name = true)\").show()"
┌────────┬─────────────┐
│ orders │ with_coupon │
│ int64  │    int64    │
├────────┼─────────────┤
│  60725 │        5982 │
└────────┴─────────────┘

ana@laptop:~/aws$ python3 -c "import duckdb; duckdb.sql(\"SELECT count(coupon) FROM read_parquet(['oct31.parquet', 'nov01.parquet'])\").show()"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
_duckdb.BinderException: Binder Error: Referenced column "coupon" not found in FROM clause!
Candidate bindings: "hour", "total_cents"
```

**`union_by_name = true` alinha os arquivos pelo nome da coluna**, e a coluna que falta num deles
volta vazia: 60.725 pedidos, 5.982 deles com cupom, que são 29.467 menos os 23.485 que o
`coupons.py` contou sem cupom. Sem a opção, o DuckDB faz o que o PyArrow fez e pega as colunas do
primeiro arquivo. Todo motor tem essa chave em algum lugar, com outro nome, e o padrão raramente é o
que um lago precisa.

## Uma coluna que muda de tipo

A outra mudança da seção anterior, o total em reais. Uma versão nova da exportação grava 2 de
novembro com `total_cents` como número decimal:

`reais.py`:

```python
import pyarrow as pa
import pyarrow.compute as pc
import pyarrow.parquet as pq

from lake import CURATED, filesystem

s3 = filesystem()
table = pq.read_table(f'{CURATED}/dt=2026-11-01/orders.parquet', filesystem=s3)
reais = pc.divide(table['total_cents'].cast(pa.float64()), 100)
table = table.set_column(table.schema.get_field_index('total_cents'), 'total_cents', reais)
pq.write_table(table, f'{CURATED}/dt=2026-11-02/orders.parquet', filesystem=s3)
print(table.schema.field('total_cents'))
```

```
ana@laptop:~/aws$ python3 reais.py
pyarrow.Field<total_cents: double>
ana@laptop:~/aws$ python3 ask.py "SELECT dt, sum(total_cents) AS total FROM orders WHERE dt >= '2026-11-01' GROUP BY dt ORDER BY dt"
Invalid Input Error: arrow_scan: get_next failed(): Invalid: Float value 265.680000 was truncated converting to int64
ana@laptop:~/aws$ aws s3 rm s3://quitanda-curated-prod/orders/dt=2026-11-02/orders.parquet
delete: s3://quitanda-curated-prod/orders/dt=2026-11-02/orders.parquet
```

**A leitura falhou no primeiro total com centavos.** Outubro disse `int64`, o esquema veio de
outubro, e 265,68 não vira inteiro sem perder alguma coisa, então o PyArrow recusou. Um total de
exatamente 52,00 teria virado 52, lido como cinquenta e dois centavos, sem uma palavra; a recusa é o
caso de sorte, e o arquivo sai antes que qualquer outra coisa o leia.

O Athena com a versão 3 do catálogo, `double` sobre arquivos `bigint` de outubro, recusa pelo outro
lado, que é o `HIVE_PARTITION_SCHEMA_MISMATCH` da seção anterior. De um jeito ou de outro, **um tipo
não pode mudar no lugar**, porque os arquivos antigos guardam o tipo antigo para sempre. As mudanças
que um lago aguenta são poucas e vale sabê-las de cor:

| mudança | Parquet, lido por nome | CSV, lido por posição |
|---|---|---|
| uma coluna nova no fim | segura: arquivos antigos respondem `NULL` | segura: linhas antigas são mais curtas |
| uma coluna nova no meio | segura | quebra toda coluna depois dela |
| uma coluna renomeada | arquivos antigos perdem a coluna | inofensiva para o leitor, confusa para as pessoas |
| um tipo trocado | quebra os arquivos antigos | quebra os arquivos antigos |

**Um tipo muda acrescentando uma coluna**, `total_reais` ao lado de `total_cents`, ou reescrevendo
toda partição antiga no tipo novo, o que é um job, o assunto da lição 17. As versões do catálogo
registram o que a tabela dizia; não fazem nada para os arquivos concordarem.
