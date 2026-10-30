---
title: Os bytes que uma consulta vai pagar, calculados
version: 1
---

**Antes de uma consulta rodar, três coisas fixam o que ela vai ser cobrada sob demanda: as colunas que
ela cita, as partições que o filtro dela mantém e os tipos dessas colunas.** Nada mais. Nem as linhas
que ela devolve, nem os filtros em outras colunas, nem o quanto o motor precisa trabalhar. Isso torna a
conta calculável antes, e o BigQuery a calcula: o dry run da próxima seção é esse cálculo, feito pelo
Google. Este laboratório não pode perguntar ao Google, então esta seção escreve o mesmo cálculo como
programa, a partir dos tamanhos documentados da aula 13 e das regras da aula 14.

## O programa

**É um dry run que você consegue ler.** Dê a ele uma tabela, as colunas que uma consulta cita e a faixa
de dias que o filtro de partição mantém, e ele imprime os bytes que o BigQuery processaria e cobraria.
Salve como `~/gcp/bqbill.py`:

```schooling-example
{"language": "python", "file": "bqbill.py", "parts": [{"code": "import math\nimport sys\n\nimport duckdb\n\nPRICE_PER_TIB, MB, TIB = 11.25, 2**20, 2**40  # on demand, southamerica-east1, read 2026-10-30\nFIXED = {'BIGINT': 8, 'DOUBLE': 8, 'DATE': 8, 'TIMESTAMP WITH TIME ZONE': 8, 'BOOLEAN': 1}\n\n", "note": "**Os tamanhos documentados, pelos nomes que o DuckDB dá aos tipos.** `BIGINT` é `INT64`, `DOUBLE` é `FLOAT64`, `BOOLEAN` é `BOOL`, e `TIMESTAMP WITH TIME ZONE` é `TIMESTAMP`. `VARCHAR`, a `STRING` do BigQuery, não está aqui porque o tamanho dela depende de cada valor."}, {"code": "table, columns = sys.argv[1], sys.argv[2].split(',')\nfirst, last = (sys.argv[3], sys.argv[4]) if len(sys.argv) > 4 else ('0001-01-01', '9999-12-31')\n\n", "note": "**Uma consulta é descrita do jeito que o BigQuery a cobra**: uma tabela, toda coluna que a consulta cita em qualquer lugar, e a faixa de `dt` que o filtro de partição mantém. Nenhum outro filtro é aceito, porque nenhum outro filtro muda os bytes cobrados; esse é o sentido do programa inteiro."}, {"code": "con = duckdb.connect()\ncon.sql(f\"CREATE VIEW t AS SELECT * FROM read_parquet(\"\n        f\"'warehouse/{table}/**/*.parquet', hive_partitioning = true)\")\ntypes = dict(con.sql(\"SELECT column_name, column_type FROM (DESCRIBE t)\").fetchall())\n\n", "note": "**Os tipos vêm dos arquivos**, pela mesma view que o `ask.py` cria, então uma coluna acrescentada à tabela é precificada pelo próprio tipo sem mudança aqui."}, {"code": "sizes = []\nfor column in columns:\n    if types[column] == 'VARCHAR':\n        sizes.append(f\"coalesce(sum(2 + strlen({column})), 0)\")\n    else:\n        sizes.append(f\"{FIXED[types[column]]} * count({column})\")\nlogical = con.sql(f\"SELECT {' + '.join(sizes)} FROM t \"\n                  f\"WHERE dt BETWEEN DATE '{first}' AND DATE '{last}'\").fetchone()[0]\n\n", "note": "**A regra da aula 13, escrita como SQL para cada coluna.** Uma string são 2 bytes mais o comprimento UTF-8; o resto é o tamanho fixo vezes `count(coluna)`, que ignora os `NULL`s, porque um `NULL` conta 0 byte. Só as linhas das partições mantidas são contadas."}, {"code": "billed = math.ceil(max(logical, 10 * MB) / MB) * MB\nprint(f'{len(columns)} columns of {table}, {first} to {last}')\nprint(f'  bytes processed {logical:>15,}')\nprint(f'  bytes billed    {billed:>15,}   {billed / TIB * PRICE_PER_TIB:.6f} USD')\n", "note": "**Processados e cobrados são os dois números que o BigQuery informa para um job**, `total_bytes_processed` e `total_bytes_billed`, e o mínimo e o arredondamento são a diferença entre eles. Este programa trata uma tabela; um join é precificado rodando-o uma vez por tabela e somando."}]}
```

## Três consultas, com preço antes de rodar

A pergunta do painel, loja 7 ontem, cita `dt`, `store_id` e `total_cents` num dia. As vendas de
setembro por bairro citam `dt`, `district` e `total_cents` em 29 dias. E `SELECT *` cita as nove
colunas, sem filtro de partição:

```
ana@laptop:~/gcp$ python3 bqbill.py orders dt,store_id,total_cents 2026-09-29 2026-09-29
3 columns of orders, 2026-09-29 to 2026-09-29
  bytes processed         392,616
  bytes billed         10,485,760   0.000107 USD
ana@laptop:~/gcp$ python3 bqbill.py orders dt,district,total_cents 2026-09-01 2026-09-29
3 columns of orders, 2026-09-01 to 2026-09-29
  bytes processed      15,023,069
  bytes billed         15,728,640   0.000161 USD
ana@laptop:~/gcp$ python3 bqbill.py orders order_id,customer_id,store_id,district,items,total_cents,payment,created_at,dt
9 columns of orders, 0001-01-01 to 9999-12-31
  bytes processed      99,177,572
  bytes billed         99,614,720   0.001019 USD
```

**O painel processa 392.616 bytes e é cobrado por 10.485.760**, o mínimo, como a aula 15 achou por outro
caminho. **Setembro por bairro processa 15.023.069 bytes** e é cobrado por 15.728.640: o arredondamento
para o próximo MB soma 705.571 bytes, e neste tamanho o arredondamento é a única diferença entre os dois
números. **`SELECT *` processa os 99.177.572 bytes que a aula 13 contou coluna por coluna**, que é a
mesma regra chegando ao mesmo total por outro caminho, e uma conferência das duas.

**Toda coluna citada conta, onde quer que seja citada.** A consulta por bairro cita `dt` só no `WHERE`,
e `dt` ainda são 8 bytes por linha dos 29 dias, 4.759.056 bytes dos 15.023.069. Uma coluna usada só para
filtrar é lida como qualquer outra, porque o motor precisa olhar para ela para filtrar. A única exceção é
o efeito da coluna de particionamento: ela decide quais linhas são contadas.

## O que ele deixa de fora, de propósito

**Ele não sabe nada de clustering**, e é por isso que é um dry run honesto: o dry run também não enxerga
os blocos que um filtro de cluster vai pular, e os dois imprimem um limite superior para uma tabela
clusterizada. **Ele trata um join como duas tabelas**, cada uma com o próprio mínimo, então um join de
`orders` com uma tabela de dezesseis lojas são as duas execuções somadas. **Ele ignora o cache**, que não
cobraria nada por uma consulta repetida sobre uma tabela sem mudança, e **o TiB gratuito**, que sai do
mês e não de uma consulta. E ele usa a visão do DuckDB do tipo de uma coluna, mapeada para a do BigQuery
pela tabela do topo; um tipo para o qual ele não tem entrada o faz parar com um erro em vez de chutar,
que é o jeito certo de uma calculadora de custo falhar.

**O que ele divide com a coisa de verdade é a propriedade que faz qualquer um dos dois valer a pena**: o
número é conhecido antes de qualquer coisa ser lida, então uma consulta pode ser recusada, reescrita ou
permitida enquanto ainda é só texto.
