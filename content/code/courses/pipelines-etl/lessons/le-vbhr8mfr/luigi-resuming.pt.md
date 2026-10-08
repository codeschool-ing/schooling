---
title: Luigi, quando um passo falha
version: 1
---

Chega o dia 15, e a Ana pede o relatório dele:

```
ana@vm:~/etl$ sudo shop day 2026-03-15
ana@vm:~/etl$ PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-15 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"
===== Luigi Execution Summary =====

Scheduled 3 tasks of which:
* 1 ran successfully:
    - 1 LoadRaw(day=2026-03-15)
* 1 failed:
    - 1 BuildModels(day=2026-03-15)
* 1 were left pending, among these:
    * 1 had failed dependencies:
        - 1 DailyReport(day=2026-03-15)

This progress looks :( because there were failed tasks

===== Luigi Execution Summary =====
ana@vm:~/etl$ ls marks
models_2026-03-14.done
raw_2026-03-14.done
raw_2026-03-15.done
```

A carga crua rodou e deixou a sua marca. O `BuildModels` falhou, então não deixou nenhuma, e o
`DailyReport` nem foi tentado: a dependência dele tinha falhado. O resumo do Luigi nomeia as três, e
é o primeiro lugar a olhar. O motivo está na saída do próprio dbt:

```
ana@vm:~/etl$ dbt build --project-dir shop 2>&1 | grep -E "FAIL|Done"
08:49:45  12 of 14 FAIL 2 fact_sales_has_not_drifted ..................................... [FAIL 2 in 0.06s]
08:49:45  Done. PASS=11 WARN=1 ERROR=1 SKIP=0 NO-OP=1 REUSED=0 TOTAL=14
ana@vm:~/etl$ dbt build --project-dir shop -s fact_sales+ --full-refresh 2>&1 | grep -E "Done"
08:49:48  Done. PASS=2 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=2
```

O teste de deriva da lição 12, fazendo o seu trabalho: dois dias mais antigos do `fact_sales` não
batem mais com a loja. A Ana faz o que aquela lição fez, uma recarga completa da tabela fato e do que
vem depois dela, e pede ao Luigi de novo:

```
ana@vm:~/etl$ PYTHONPATH=. luigi --module nightly_luigi DailyReport --day 2026-03-15 --local-scheduler 2>&1 | sed -n "/Execution Summary/,/Execution Summary/p"
===== Luigi Execution Summary =====

Scheduled 3 tasks of which:
* 1 complete ones were encountered:
    - 1 LoadRaw(day=2026-03-15)
* 2 ran successfully:
    - 1 BuildModels(day=2026-03-15)
    - 1 DailyReport(day=2026-03-15)

This progress looks :) because there were no failed tasks or missing dependencies

===== Luigi Execution Summary =====
```

O `LoadRaw` estava **completo** — a marca dele estava lá —, então não rodou uma segunda vez, e os dois
passos que não tinham terminado rodaram. Essa é a metade útil da completude por existência: **um
pipeline retoma do passo que falhou, sem ninguém dizer a ele onde foi.** O Airflow faz o mesmo com o
*clear* (lição 10), mas uma pessoa tem de escolher o que limpar; o Luigi descobre pelos arquivos.

Um cuidado vem junto. A marca crua do dia 15 quer dizer *a carga crua rodou uma vez no dia em que o
15 foi pedido*. Se a loja tivesse continuado vendendo entre a falha e a nova tentativa, o raw estaria
agora mais velho que a loja, e o Luigi não o recarregaria. Aqui nada se moveu no meio, então nada se
perdeu; num sistema vivo, uma marca é uma promessa sobre o passado.
