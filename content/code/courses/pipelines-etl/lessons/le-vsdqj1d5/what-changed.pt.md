---
title: Refazer só o que mudou
version: 1
---

A graça de comparar horários é o que acontece depois de uma mudança. A Ana edita o comentário no topo
do `stg_books.sql` e pergunta ao `make` o que ele *faria* — o `-n` imprime os comandos sem rodá-los:

```
ana@vm:~/etl$ sed -i '1s/.*/-- One row per book, as the publishers catalogue it./' shop/models/staging/stg_books.sql
ana@vm:~/etl$ make -n
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
  FROM dbt_marts.daily_sales WHERE order_date = '2026-03-15' ORDER BY 1, 2) \
  TO STDOUT WITH (FORMAT csv, HEADER)" > reports/daily_2026-03-15.csv.part
mv reports/daily_2026-03-15.csv.part reports/daily_2026-03-15.csv
ana@vm:~/etl$ make
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
  FROM dbt_marts.daily_sales WHERE order_date = '2026-03-15' ORDER BY 1, 2) \
  TO STDOUT WITH (FORMAT csv, HEADER)" > reports/daily_2026-03-15.csv.part
mv reports/daily_2026-03-15.csv.part reports/daily_2026-03-15.csv
```

O `stg_books.sql` agora é mais novo que o `.made/models`, então os modelos estão desatualizados, e o
relatório feito deles também. O raw não: nada de que ele é feito mudou. **O `make` pulou o passo cujas
entradas não se mexeram, e refez os dois cujas entradas se mexeram**, sem que lhe dissessem quais.

Um dia novo da loja mexe no arquivo de relógio, e a cadeia inteira fica desatualizada a partir de
baixo:

```
ana@vm:~/etl$ sudo shop day 2026-03-16
ana@vm:~/etl$ make -n
mkdir -p .made
python load_raw.py > /dev/null
touch .made/raw
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
  FROM dbt_marts.daily_sales WHERE order_date = '2026-03-16' ORDER BY 1, 2) \
  TO STDOUT WITH (FORMAT csv, HEADER)" > reports/daily_2026-03-16.csv.part
mv reports/daily_2026-03-16.csv.part reports/daily_2026-03-16.csv
```

O `make -n` lista os três passos, e o nome do relatório passou para o dia 16, porque o `DAY` é lido
do mesmo relógio. A regra do raw tem o relógio como entrada justamente para que um dia novo queira
dizer *recarregar*; essa única linha é toda a ideia que o pipeline tem de *a loja mudou*.

Horários de modificação são um sinal grosseiro. Salvar um arquivo sem mudá-lo deixa tudo o que vem
depois desatualizado, e uma mudança que não toca nenhum arquivo que o `make` vigia — um reembolso no
dia 14, no banco da própria loja — não deixa nada desatualizado. As regras são tão boas quanto as
entradas que listam; o arquivo de relógio aqui é uma conveniência do laboratório, no lugar de *chegaram
dados novos*, que um pipeline de verdade tem de detectar de outro jeito.
