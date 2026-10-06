---
title: Escala vertical, medida
version: 1
---

Para ver como uma consulta usa mais núcleos, ela precisa rodar tempo bastante para ser cronometrada. A
`fact_sales` responde em milissegundos, então esta seção usa uma tabela sintética: **vinte cópias da
tabela de vendas**, uma depois da outra, com uma coluna dizendo a que cópia cada linha pertence. Nada
nela é uma venda real; ela existe para ter algo que demore.

```sql
-- Twenty copies of the sales table, to have something that takes time.
CREATE TABLE fact_sales_x20 AS
SELECT f.*, c.copy FROM fact_sales f, range(20) AS c(copy);
SELECT count(*) AS rows FROM fact_sales_x20;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < x20.sql
┌──────────┐
│   rows   │
│  int64   │
├──────────┤
│ 17749540 │
└──────────┘
```

17.749.540 linhas. Agora uma pergunta, receita por departamento e mês, feita com uma thread, duas e
quatro:

```sql
-- One question, asked with one, two and four threads.
.timer on
SET threads = 1;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
SET threads = 2;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
SET threads = 4;
SELECT count(*) FROM (SELECT b.department, d.month, sum(f.net_cents)
                      FROM fact_sales_x20 f JOIN dim_book b USING (book_key)
                      JOIN dim_date d USING (date_key) GROUP BY ALL);
```

```
ana@lab:~/wh$ duckdb -list wh.duckdb < threads.sql | grep 'Run Time'
Run Time (s): real 0.001 user 0.000895 sys 0.000000
Run Time (s): real 0.358 user 0.333962 sys 0.024018
Run Time (s): real 0.000 user 0.000760 sys 0.000051
Run Time (s): real 0.164 user 0.320615 sys 0.003833
Run Time (s): real 0.000 user 0.001108 sys 0.000045
Run Time (s): real 0.126 user 0.490955 sys 0.003989
```

As linhas que não levam tempo são os comandos `SET`. As três que importam:

| threads | segundos | contra uma thread |
|---|---|---|
| 1 | 0,358 | 1,0 vez |
| 2 | 0,164 | 2,2 vezes mais rápido |
| 4 | 0,126 | 2,8 vezes mais rápido |

**Quatro núcleos não deixaram a consulta quatro vezes mais rápida.** Uma execução cada numa máquina
compartilhada mexe nesses números, e a forma ainda é clara: a segunda thread mais ou menos dobrou a
velocidade, e as duas seguintes acrescentaram bem menos. Parte do trabalho não se divide entre threads:
começar a consulta, montar as pequenas tabelas de busca, juntar as somas parciais de cada thread numa
resposta. Essa parte leva o mesmo tempo com quantos núcleos houver, e a próxima seção transforma isso em
aritmética.

Repare no tempo `user` da transcrição: o tempo total de processador gasto, somando todas as threads. Com
quatro threads ele é maior que o tempo decorrido, que é a cara do trabalho em paralelo.
