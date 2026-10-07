---
title: Mudando o formato em SQL
version: 1
---

O PostgreSQL não tem as palavras `PIVOT` nem `UNPIVOT`. Os dois movimentos continuam curtos, e
escrevê-los por extenso tem o mérito de deixar toda coluna à vista.

**Despivotar** é uma junção com uma pequena tabela de valores, montada linha a linha com `CROSS
JOIN LATERAL`. Cada par nomeia um mês e a coluna de onde ele vem:

```sql
SELECT t.loja, m.month, m.target::int AS target
FROM raw.targets_2025 t
CROSS JOIN LATERAL (VALUES
  ('2025-01', t."jan/25"), ('2025-02', t."fev/25"), ('2025-03', t."mar/25"),
  ('2025-04', t."abr/25"), ('2025-05', t."mai/25"), ('2025-06', t."jun/25"),
  ('2025-07', t."jul/25"), ('2025-08', t."ago/25"), ('2025-09', t."set/25"),
  ('2025-10', t."out/25"), ('2025-11', t."nov/25"), ('2025-12', t."dez/25")
) AS m(month, target)
ORDER BY t.loja, m.month;
```

O `Total` não está na lista, então não tem como derreter por acidente: em SQL **as colunas a
despivotar são nomeadas uma a uma**, o que dá mais digitação e uma armadilha a menos. O mês é
escrito como `2025-01`, que ordena certo como texto e casa com o que `to_char(date, 'YYYY-MM')` dá
do lado das vendas.

Salvo como view, pode ser conferido do mesmo jeito que o resultado do pandas, pelas linhas e pela
soma:

```
ana@lab:~/clean$ psql -c "CREATE VIEW targets_long AS $(cat unpivot.sql | tr -d ';')"
CREATE VIEW
ana@lab:~/clean$ psql -c 'SELECT count(*), sum(target) FROM targets_long'
 count |   sum   
-------+---------
    72 | 3801000
(1 row)

ana@lab:~/clean$ psql -c "SELECT * FROM targets_long WHERE loja = 'Batel' LIMIT 3"
 loja  |  month  | target 
-------+---------+--------
 Batel | 2025-01 |  14000
 Batel | 2025-02 |  14000
 Batel | 2025-03 |  14000
(3 rows)
```

72 linhas e R$ 3.801.000, os mesmos dois números do pandas.

**Pivotar** é agregação condicional: um `sum(...) FILTER (WHERE ...)` por coluna desejada, agrupado
pela linha desejada.

```
ana@lab:~/clean$ psql -c "SELECT loja, sum(target) FILTER (WHERE month = '2025-01') AS jan, sum(target) FILTER (WHERE month = '2025-02') AS feb, sum(target) FILTER (WHERE month = '2025-03') AS mar, sum(target) AS year FROM targets_long GROUP BY loja ORDER BY year DESC"
   loja    |  jan   |  feb   |  mar   |  year   
-----------+--------+--------+--------+---------
 Online    | 180000 | 180000 | 180000 | 2286000
 Pinheiros |  52000 |  52000 |  52000 |  660000
 Botafogo  |  23000 |  23000 |  23000 |  294000
 Savassi   |  16000 |  16000 |  16000 |  204000
 Cambuí    |  14000 |  14000 |  14000 |  180000
 Batel     |  14000 |  14000 |  14000 |  177000
(6 rows)
```

A cláusula `FILTER` decide que linhas cada coluna soma. Como o `pivot_table`, ela agrega o que
casar, então vale o mesmo cuidado: o grão da origem decide se `sum` é a função certa. Diferente do
`pivot_table`, toda coluna é escrita à mão, o que serve para um relatório com um conjunto fixo de
meses e não serve para um conjunto de colunas que cresce. Para isso, a tabela longa é a que se
guarda, e a larga é produzida no último passo, por quem desenha o relatório.
