---
title: Backfill: preencher o passado de propósito
version: 1
---

Um **backfill** pede ao Airflow execuções para um intervalo de datas lógicas que alguém escolheu — a
semana em que um bug esteve em produção, o mês antes de um DAG existir, ou, no laboratório, os dias
que a loja viveu e que nenhuma execução carregou ainda. A Ana toca a primeira semana de março e pede
as execuções que a carregam:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh until 2026-03-07
ana@vm:~/etl$ airflow backfill create --dag-id shop_nightly --from-date 2026-03-03 --to-date 2026-03-08 2>&1 | grep -c "Created backfill Dag run"
5
ana@vm:~/etl$ airflow dags unpause shop_nightly
dag_id       | is_paused
=============+==========
shop_nightly | True     
                        
ana@vm:~/etl$ airflow dags list-runs shop_nightly -o plain | cut -c1-118
dag_id        run_id                                state    run_after                  logical_date               sta
shop_nightly  scheduled__2026-10-07T05:00:00+00:00  success  2026-10-07T05:00:00+00:00  2026-10-07T05:00:00+00:00  202
shop_nightly  backfill__2026-03-07T05:00:00+00:00   success  2026-03-07T05:00:00+00:00  2026-03-07T05:00:00+00:00  202
shop_nightly  backfill__2026-03-06T05:00:00+00:00   failed   2026-03-06T05:00:00+00:00  2026-03-06T05:00:00+00:00  202
shop_nightly  backfill__2026-03-05T05:00:00+00:00   success  2026-03-05T05:00:00+00:00  2026-03-05T05:00:00+00:00  202
shop_nightly  backfill__2026-03-04T05:00:00+00:00   failed   2026-03-04T05:00:00+00:00  2026-03-04T05:00:00+00:00  202
shop_nightly  backfill__2026-03-03T05:00:00+00:00   failed   2026-03-03T05:00:00+00:00  2026-03-03T05:00:00+00:00  202
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-02 |   412
 2026-03-04 |   441
 2026-03-06 |   439
(3 rows)
```

Duas surpresas numa transcrição.

**Cinco execuções, não seis.** O intervalo era de 3 a 8 de março, e a execução que carrega o dia 7 é
a das 02:00 de 8 de março. Mas `--to-date 2026-03-08` quer dizer *meia-noite* de 8 de março, e 02:00
é depois da meia-noite: essa execução ficou de fora. **Datas na linha de comando do Airflow são
momentos**, e um intervalo que deve incluir a execução de um dia precisa ir além da hora em que ela
roda.

**E execuções falharam.** A tabela fato só tem os dias cujas execuções por acaso deram certo. O motivo
está nos logs das tarefas:

```
ana@vm:~/etl$ grep -ho "ERROR: [^\\]*" ~/airflow/logs/dag_id=shop_nightly/run_id=backfill__*/task_id=*/attempt=1.log | sort | uniq -c
      2 ERROR:  duplicate key value violates unique constraint 
      1 ERROR:  relation
```

O backfill iniciou as execuções ao mesmo tempo, e cada execução deste DAG refaz as mesmas tabelas de
`raw` e `staging`. Duas execuções criando `staging.books` ao mesmo tempo colidem no catálogo do
PostgreSQL — *duplicate key value violates unique constraint*. O `DROP TABLE` de uma execução
puxa uma tabela de baixo da consulta de outra — *relation does not exist*. Quais execuções perdem é
uma corrida, e é uma corrida diferente a cada vez.

## Uma de cada vez

Um DAG cujas execuções compartilham estado não pode rodar em paralelo, e precisa dizer isso. A Ana
acrescenta `max_active_runs=1` ao DAG, e dá ao backfill o mesmo limite, porque um backfill tem um
limite próprio e na gravação ele não usou o do DAG:

```
ana@vm:~/etl$ sed -i 's|    tags=\["shop"\],|    tags=["shop"],\n    max_active_runs=1,          # every run rebuilds raw and staging: one at a time|' dags/shop_nightly.py
ana@vm:~/etl$ grep -n -B1 -A1 max_active_runs dags/shop_nightly.py
14-    tags=["shop"],
15:    max_active_runs=1,          # every run rebuilds raw and staging: one at a time
16-)
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow backfill create --dag-id shop_nightly --from-date 2026-03-03 --to-date 2026-03-08T12:00:00-03:00 --reprocess-behavior failed --max-active-runs 1 2>&1 | grep -c "Created backfill Dag run"
6
ana@vm:~/etl$ airflow dags list-runs shop_nightly -o plain | cut -c1-118
dag_id        run_id                                state    run_after                  logical_date               sta
shop_nightly  scheduled__2026-10-07T05:00:00+00:00  success  2026-10-07T05:00:00+00:00  2026-10-07T05:00:00+00:00  202
shop_nightly  backfill__2026-03-08T05:00:00+00:00   success  2026-03-08T05:00:00+00:00  2026-03-08T05:00:00+00:00  202
shop_nightly  backfill__2026-03-07T05:00:00+00:00   success  2026-03-07T05:00:00+00:00  2026-03-07T05:00:00+00:00  202
shop_nightly  backfill__2026-03-06T05:00:00+00:00   success  2026-03-06T05:00:00+00:00  2026-03-06T05:00:00+00:00  202
shop_nightly  backfill__2026-03-05T05:00:00+00:00   success  2026-03-05T05:00:00+00:00  2026-03-05T05:00:00+00:00  202
shop_nightly  backfill__2026-03-04T05:00:00+00:00   success  2026-03-04T05:00:00+00:00  2026-03-04T05:00:00+00:00  202
shop_nightly  backfill__2026-03-03T05:00:00+00:00   success  2026-03-03T05:00:00+00:00  2026-03-03T05:00:00+00:00  202
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-02 |   412
 2026-03-03 |   476
 2026-03-04 |   441
 2026-03-05 |   464
 2026-03-06 |   439
 2026-03-07 |   539
(6 rows)
```

O segundo backfill vai até o meio-dia de 8 de março, então inclui a execução das 02:00, e o
`--reprocess-behavior failed` pede que as execuções que falharam rodem de novo. Seis execuções, uma
depois da outra, todas com sucesso, e a tabela fato tem cada dia de 2 a 7 de março.

## O que torna um backfill seguro

- **O DAG carrega o dia para o qual a execução existe**, não o dia em que por acaso ela roda — o
  `day_to_load` da lição 8. Um backfill de março rodado em outubro carrega março.
- **Cada execução substitui o seu período** em vez de acrescentar a ele — o apagar-e-inserir da lição
  7. Um backfill que roda de novo um dia já carregado não pode dobrá-lo, e a lição 15 transforma isso
  numa propriedade que você testa em vez de torcer.
- **Execuções que compartilham estado não se sobrepõem** — `max_active_runs=1`, no DAG e no backfill.

Sem as três, um backfill é o jeito mais rápido que existe de estragar um warehouse: muitas execuções,
ao mesmo tempo, sobre o histórico, sem ninguém olhando.
