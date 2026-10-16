---
title: Mais quatro meses da loja
version: 1
---

A lição 1 disse que o mesmo programa um dia desenharia a loja mais adiante. **O dia é hoje: mais
quatro meses de membros e compras, até 30 de junho de 2026**, o mesmo histórico até fevereiro e linhas
novas depois dele:

```
ana@dev:~/ml$ python generate.py --until 2026-06-30
members       5000
purchases    72448
lines       116019
titles          80
last day   2026-06-30
```

O `shop.db` é o dado que o DVC versiona, então a loja nova é uma versão nova dele, registrada como a
lição 7 registrou a primeira: o DVC calcula o hash do arquivo, e o Git commita o ponteiro.

```
ana@dev:~/ml$ dvc add -q shop.db && git add shop.db.dvc && git commit -qm "the shop to 30 June 2026" && git log --oneline -n 1
f0f580f the shop to 30 June 2026
```

Depois, a rotina noturna que a plataforma teria rodado desde fevereiro, feita de uma vez: as
fotografias semanais da feature store para os meses novos, e as notas do campeão para cada uma
delas. A consulta em seguida é a probabilidade média que o campeão deu em cada noite, o número que o
vigia observa:

```
ana@dev:~/ml$ python featurestore.py backfill 2026-03-01 2026-06-28
18 snapshots, 63113 rows in the offline store
ana@dev:~/ml$ for night in $(sqlite3 features.db "SELECT DISTINCT as_of FROM offline WHERE as_of > '2026-02-28'"); do python score_batch.py $night > /dev/null; done
ana@dev:~/ml$ sqlite3 -column scores.db "SELECT cutoff, round(avg(p_lapse), 3) AS mean_p FROM lapse_scores WHERE cutoff >= '2026-02-28' GROUP BY cutoff"
2026-02-28  0.174 
2026-03-01  0.174 
2026-03-08  0.175 
2026-03-15  0.175 
2026-03-22  0.174 
2026-03-29  0.177 
2026-04-05  0.177 
2026-04-12  0.176 
2026-04-19  0.178 
2026-04-26  0.18  
2026-05-03  0.182 
2026-05-10  0.183 
2026-05-17  0.186 
2026-05-24  0.187 
2026-05-31  0.189 
2026-06-07  0.193 
2026-06-14  0.195 
2026-06-21  0.198 
2026-06-28  0.201 
```

**A média subiu devagar, de 0,174 no fim de fevereiro para 0,201 no fim de junho**, um pouco a cada
semana. O vigia da lição 9 compara cada noite com as quatro semanas anteriores, então rode-o em
todas as noites novas:

```
ana@dev:~/ml$ for night in $(sqlite3 features.db "SELECT DISTINCT as_of FROM offline WHERE as_of > '2026-02-28'"); do python watch.py $night > /dev/null && echo "$night ok" || echo "$night ALARM"; done
2026-03-01 ok
2026-03-08 ok
2026-03-15 ok
2026-03-22 ok
2026-03-29 ok
2026-04-05 ok
2026-04-12 ok
2026-04-19 ok
2026-04-26 ok
2026-05-03 ok
2026-05-10 ok
2026-05-17 ok
2026-05-24 ok
2026-05-31 ok
2026-06-07 ok
2026-06-14 ok
2026-06-21 ok
2026-06-28 ok
```

**Todas as noites passaram.** Nada nunca ficou mais que alguns por cento longe do mês anterior,
porque o mês anterior já tinha se movido. Uma referência que anda junto com os dados não consegue
ver uma mudança lenta, por mais longe que ela chegue no fim. É o desenho certo para pegar uma carga
quebrada, que é súbita, e o errado para a deriva, que não é. A próxima seção acrescenta a
referência que não se move.
