---
title: Quando uma regra falha
version: 1
---

O dia 16, desta vez de verdade:

```
ana@vm:~/etl$ make 2>&1 | grep -v "^ "
mkdir -p .made
python load_raw.py > /dev/null
touch .made/raw
dbt build --project-dir shop --quiet
06:49:06  14 of 14 FAIL 5 fact_sales_has_not_drifted ..................................... [FAIL 5 in 0.04s]
06:49:06  [ERROR]: in test fact_sales_has_not_drifted (tests/fact_sales_has_not_drifted.sql)
06:49:06    Got 5 results, configured to fail if != 0
make: *** [Makefile:16: .made/models] Error 1
ana@vm:~/etl$ ls .made
models
raw
```

O raw carregou e a marca dele foi tocada. Depois o `dbt build` falhou — o teste de deriva da lição 12
de novo, cinco dias mais antigos do `fact_sales` que a loja mudou desde então — e o `make` parou na
hora, dizendo qual regra e qual linha. O `touch` depois do `dbt build` nunca rodou, então o
`.made/models` continua sendo o do dia 15: **mais velho que o `.made/raw`**, e portanto
desatualizado. A falha deixou os arquivos dizendo exatamente o que é verdade: o raw está atual, os
modelos não.

A Ana faz o que o teste de deriva pede, uma recarga completa da tabela fato e do que vem depois dela,
e roda o `make` de novo — o filtro no fim só esconde as linhas de continuação do comando `psql`
comprido:

```
ana@vm:~/etl$ dbt build --project-dir shop -s fact_sales+ --full-refresh --quiet
ana@vm:~/etl$ make 2>&1 | grep -v "^ "
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
mv reports/daily_2026-03-16.csv.part reports/daily_2026-03-16.csv
```

Nada de carga crua desta vez. O `.made/raw` era mais novo que tudo de que é feito, então esse passo
estava feito; os modelos e o relatório não, então rodaram. **A versão declarativa retomou do passo que
falhou, e o motivo de ela conseguir é que nunca lhe disseram os passos** — só de que cada arquivo é
feito, o que continua verdade aconteça o que acontecer de noite.

É a mesma coisa que o Luigi fez na lição 13, com uma melhora e um limite em comum. A melhora é a
comparação: o Luigi teria mantido a marca de modelos do dia 15 e chamado os modelos de feitos; o
`make` viu que ela era mais velha que o raw. O limite em comum é que os dois decidem a partir de
arquivos que representam o trabalho, não a partir dos próprios dados. Quem percebeu os dados foi o
teste de deriva.
