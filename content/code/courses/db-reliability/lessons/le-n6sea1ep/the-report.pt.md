---
title: Um relatório que descreve um banco que ninguém listou
version: 1
---

O `verify.sql` da lição 1 nomeava as duas tabelas do shop e as colunas que somava. Isso estava certo
para uma primeira restauração e está errado para um ensaio que roda toda semana durante anos: no dia
em que alguém cria uma tabela, o relatório deixa de olhar para uma parte do banco, e continua
passando. **O relatório de um ensaio tem que achar as tabelas sozinho.**

Salve isto como `report.sql`:

```schooling-example
{"language": "sql", "file": "report.sql", "parts": [{"code": "-- report.sql: describe every table in public, without naming one\nSELECT format(\n  'SELECT %L, count(*), md5(coalesce(string_agg(x::text, %L ORDER BY x::text), %L)) FROM %I AS x',\n  table_name, ',', '', table_name)\nFROM information_schema.tables\nWHERE table_schema = 'public' AND table_type = 'BASE TABLE'\nORDER BY table_name", "note": "Uma consulta que escreve consultas. Para cada tabela comum do schema public, ela monta um comando que conta as linhas e tira uma impressão digital do conteúdo delas."}, {"code": "\\gexec", "note": "\\gexec é do próprio psql: ele roda cada linha que a consulta acima devolveu, como um comando. Uma tabela criada no mês que vem está no relatório do mês que vem sem ninguém editar este arquivo."}, {"code": "SELECT 'indexes', string_agg(indexname, ' ' ORDER BY indexname)\nFROM pg_indexes WHERE schemaname = 'public';", "note": "E os índices pelo nome, que uma restauração pode perder sem perder uma única linha."}]}
```

A impressão digital é o ponto. `x::text` transforma cada linha em texto, `string_agg` junta todas
numa ordem fixa, e `md5` reduz o resultado a 32 caracteres. **Mude um caractere numa linha de três
milhões, e a impressão digital fica diferente.** Onde as somas da lição 1 podiam deixar passar duas
mudanças que se anulavam, esta não deixa.

```
ana@vm:~$ psql -X -A -t shop -f report.sql
customers|1000|59bcef50f813ab10bc9dd1a77f952779
orders|50000|c6b0e3dce001bde7ecbf7aa7cbccebb5
indexes|customers_pkey orders_customer orders_pkey
ana@vm:~$ time psql -X -A -t bigshop -f report.sql
customers|1000|59bcef50f813ab10bc9dd1a77f952779
orders|3000000|d522ec3f50864e9ad8762c972bfde456
indexes|customers_pkey orders_customer orders_pkey

real	0m5.860s
user	0m0.028s
sys	0m0.002s
```

Dois bancos, duas tabelas cada, e uma linha de índices. No `bigshop` levou **alguns segundos**,
porque tirar a impressão digital significa ler e ordenar cada linha: a prova de um ensaio custa
tempo proporcional aos dados, como uma restauração lógica, e esse tempo entra nas medições do
ensaio.

Num banco de centenas de gigabytes, tirar a impressão digital de cada linha de cada tabela leva
horas, e o meio-termo de costume é contagem para toda tabela, impressão digital para as tabelas que
mais importam, e uma amostra de linhas por chave primária para o resto. Seja qual for o meio-termo,
ele fica **escrito no arquivo e aplicado do mesmo jeito dos dois lados**, e é isso que torna a
comparação honesta.
