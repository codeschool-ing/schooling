---
title: Quanto pesa uma tabela, em bytes lógicos
version: 1
---

**O BigQuery não mede uma tabela pelo tamanho dos arquivos dela.** Nem poderia, porque arquivo é algo
que o armazenamento dele arruma e você nunca vê. Ele mede uma tabela **somando o tamanho de cada valor
nela, pelo tipo do valor**, como se nada estivesse comprimido: um `INT64` são 8 bytes, guarde ele 7
ou 7 bilhões, e uma `STRING` são 2 bytes mais o comprimento dela em UTF-8. Esse total é o **tamanho
lógico** da tabela, e é o número a partir do qual duas das três contas deste curso são calculadas: a
de armazenamento lógico da próxima seção e a de consultas sob demanda da aula 14.

## O tamanho de cada tipo

A página de preços manda você para uma tabela da documentação do BigQuery, "Data type sizes", para a
regra. Estas são as linhas que a tabela da Quitanda usa, e as que você tem mais chance de encontrar
em seguida:

| tipo | tamanho lógico de um valor |
|---|---|
| `INT64` | 8 bytes |
| `FLOAT64` | 8 bytes |
| `NUMERIC` | 16 bytes |
| `BOOL` | 1 byte |
| `STRING` | 2 bytes + o comprimento em UTF-8 |
| `BYTES` | 2 bytes + o comprimento |
| `DATE`, `TIMESTAMP`, `DATETIME`, `TIME` | 8 bytes |
| `ARRAY`, `STRUCT` | os tamanhos do que contêm |
| `NULL`, de qualquer tipo | 0 byte |

**Um tipo de largura fixa custa o mesmo para todo valor**, então uma coluna `INT64` numa tabela de um
milhão de linhas tem 8.000.000 de bytes, sempre. **Uma `STRING` custa o que guarda**, e "o que guarda"
é contado em bytes UTF-8, não em caracteres, o que em português não é a mesma coisa.

## Os bairros, contados

Os oito bairros da Quitanda são o lugar mais limpo para ver isso. O `length` do DuckDB conta
caracteres e o `strlen` conta bytes, que é a medida que o BigQuery usa:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT DISTINCT district, length(district) AS characters, strlen(district) AS utf8_bytes, 2 + strlen(district) AS bigquery_bytes FROM orders ORDER BY district"
┌──────────────┬────────────┬────────────┬────────────────┐
│   district   │ characters │ utf8_bytes │ bigquery_bytes │
│   varchar    │   int64    │   int64    │     int64      │
├──────────────┼────────────┼────────────┼────────────────┤
│ Butantã      │          7 │          8 │             10 │
│ Lapa         │          4 │          4 │              6 │
│ Moema        │          5 │          5 │              7 │
│ Mooca        │          5 │          5 │              7 │
│ Pinheiros    │          9 │          9 │             11 │
│ Santana      │          7 │          7 │              9 │
│ Tatuapé      │          7 │          8 │             10 │
│ Vila Mariana │         12 │         12 │             14 │
└──────────────┴────────────┴────────────┴────────────────┘
```

**`Butantã` e `Tatuapé` têm sete caracteres e oito bytes**, porque `ã` e `é` ocupam dois bytes cada
em UTF-8, então o BigQuery conta cada um deles como 10 bytes. `Vila Mariana` é o nome mais comprido e
custa 14. Numa tabela de um milhão de pedidos, a coluna do bairro pesa a mistura desses oito números
que os pedidos tiverem, e o único jeito de saber é somar.

## A tabela inteira, coluna por coluna

**A mesma regra, aplicada a toda coluna, é uma consulta só.** Cada coluna de texto é a soma de 2 + o
comprimento, e cada coluna de largura fixa é 8 vezes o número de linhas. `dt` também conta, porque
depois de carregada a tabela ela é uma coluna `DATE` como outra qualquer. Salve isto como
`~/gcp/logical.sql`:

`logical.sql`:

```sql
WITH sizes AS (
    SELECT
        sum(2 + strlen(order_id))    AS order_id,
        sum(2 + strlen(customer_id)) AS customer_id,
        8 * count(*)                 AS store_id,
        sum(2 + strlen(district))    AS district,
        8 * count(*)                 AS items,
        8 * count(*)                 AS total_cents,
        sum(2 + strlen(payment))     AS payment,
        8 * count(*)                 AS created_at,
        8 * count(*)                 AS dt
    FROM orders
)
SELECT coalesce(column_name, 'all nine') AS column_name,
       sum(logical_bytes)                AS logical_bytes
FROM (UNPIVOT sizes ON COLUMNS(*) INTO NAME column_name VALUE logical_bytes)
GROUP BY ROLLUP (column_name)
ORDER BY logical_bytes;
```

**O `UNPIVOT` transforma a única linha larga numa linha por coluna**, e o `ROLLUP` acrescenta o total
como última linha, sem nome, que o `coalesce` chama de `all nine`. Nenhum dos dois é GoogleSQL de que
você precisaria; eles estão ali para a resposta caber na tela:

```
ana@laptop:~/gcp$ python3 ask.py logical.sql
┌─────────────┬───────────────┐
│ column_name │ logical_bytes │
│   varchar   │    int128     │
├─────────────┼───────────────┤
│ payment     │       6723152 │
│ store_id    │       9960944 │
│ total_cents │       9960944 │
│ items       │       9960944 │
│ created_at  │       9960944 │
│ dt          │       9960944 │
│ customer_id │      11206062 │
│ district    │      11521750 │
│ order_id    │      19921888 │
│ all nine    │      99177572 │
└─────────────┴───────────────┘
  10 rows           2 columns
```

**A tabela pesa 99.177.572 bytes lógicos**, cerca de 94,6 MiB ou 0,092 GiB. As cinco colunas de
largura fixa pesam exatamente o mesmo, 9.960.944 bytes cada, que é 8 × 1.245.118. A coluna mais
pesada é `order_id`, com 19.921.888 bytes: catorze caracteres e dois bytes de acréscimo em toda
linha, então 16 bytes por linha, o dobro do peso de um número. `payment` é a mais leve, porque `pix`
e `card` são palavras curtas.

## O lógico contra os arquivos em disco

**Os arquivos Parquet com as mesmas linhas têm um terço desse tamanho**:

```
ana@laptop:~/gcp$ du -cb warehouse/orders/*/*.parquet | tail -1
32451790	total
```

**99.177.572 bytes lógicos contra 32.451.790 em disco é uma razão de 3,06.** O Parquet comprime cada
coluna separadamente, e estas colunas comprimem bem: `district` tem oito valores e `store_id`
dezesseis, então cada uma é quase só repetição, e os timestamps de um dia estão em ordem. O formato do
próprio BigQuery faz o mesmo tipo de coisa, e o tamanho guardado nele é o que o Google chama de bytes
**físicos** da tabela. Nada neste laboratório consegue medir esse número, porque nada aqui é o
armazenamento do BigQuery. O que os arquivos Parquet dão é uma boa ideia de quão comprimíveis essas
colunas são, e a próxima seção mostra por que essa razão, mais ou menos três, é exatamente o número
de que depende a escolha entre cobrança lógica e física.

**O tamanho lógico também é o tamanho pelo qual uma consulta é cobrada.** Sob demanda, o BigQuery
cobra os bytes lógicos das colunas que uma consulta lê, nas partições que ela lê. Uma consulta que
soma `total_cents` sobre a tabela inteira toca 9.960.944 bytes dela, e uma que lê `SELECT *` toca
todos os 99.177.572. A aula 14 põe preço nisso, e a aula 16 acrescenta as duas regras que esta seção
deixou de fora: toda consulta é arredondada para cima até o próximo MB, e nenhuma tabela citada é
cobrada por menos de 10 MB.
