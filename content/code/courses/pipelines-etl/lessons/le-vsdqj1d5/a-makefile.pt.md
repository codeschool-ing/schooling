---
title: Um Makefile: de que cada arquivo é feito
version: 1
---

A ferramenta de build declarativa mais antiga de qualquer máquina Unix é o `make`, escrito em 1976
para compilar programas em C, e a ideia dele cabe exatamente num pipeline. Uma **regra** nomeia um
arquivo, os arquivos de que ele é feito e os comandos que o fazem. O `make` só constrói um arquivo
quando ele não existe **ou quando algo de que ele é feito foi modificado mais recentemente que ele**.

Uma tabela num banco não tem um horário de modificação que o `make` consiga ver, então a Ana faz o que
o Luigi a fez fazer: um pequeno arquivo em `.made/` representa cada passo, tocado quando o passo dá
certo. A diferença em relação ao Luigi está naquilo com que os arquivos são comparados:

```
# The nightly as a Makefile: each rule says what a file is made from, and how.
# make rebuilds a file only when something it is made from is newer than it.
DAY    := $(shell cat /var/lib/etl-run/clock)
MODELS := $(shell find shop/models shop/tests -name '*.sql' -o -name '*.yml')

report: reports/daily_$(DAY).csv

reports/daily_$(DAY).csv: .made/models
	mkdir -p reports
	psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
	  FROM dbt_marts.daily_sales WHERE order_date = '$(DAY)' ORDER BY 1, 2) \
	  TO STDOUT WITH (FORMAT csv, HEADER)" > $@.part
	mv $@.part $@

.made/models: .made/raw $(MODELS)
	dbt build --project-dir shop --quiet
	touch $@

.made/raw: /var/lib/etl-run/clock load_raw.py
	mkdir -p .made
	python load_raw.py > /dev/null
	touch $@

.PHONY: report
```

Três regras, cada uma a resposta para *de que isto é feito*. O relatório é feito dos modelos; os
modelos, do raw **e de cada arquivo do projeto dbt**; o raw, do `load_raw.py` **e do arquivo de
relógio do laboratório**, que o `lab.sh day` reescreve sempre que a loja vive mais um dia. Nada diz
*primeiro faça isto, depois aquilo*: o `make` descobre a ordem a partir das regras, como o dbt fez a
partir dos `ref`s.

```
ana@vm:~/etl$ make
mkdir -p .made
python load_raw.py > /dev/null
touch .made/raw
dbt build --project-dir shop --quiet
touch .made/models
mkdir -p reports
psql -d wh -c "COPY (SELECT shop_id, category, books, revenue_cents \
  FROM dbt_marts.daily_sales WHERE order_date = '2026-03-15' ORDER BY 1, 2) \
  TO STDOUT WITH (FORMAT csv, HEADER)" > reports/daily_2026-03-15.csv.part
mv reports/daily_2026-03-15.csv.part reports/daily_2026-03-15.csv
ana@vm:~/etl$ ls -l --time-style=+%T .made reports | grep -v total
.made:
-rw-r--r-- 1 ana ana 0 03:48:56 models
-rw-r--r-- 1 ana ana 0 03:48:52 raw

reports:
-rw-r--r-- 1 ana ana 1794 03:48:56 daily_2026-03-15.csv
```

Os três rodaram, na ordem das dependências, e os horários se alinham: o raw primeiro, depois os
modelos e o relatório alguns segundos mais tarde. Pedindo de novo:

```
ana@vm:~/etl$ make
make: Nothing to be done for 'report'.
```

**Nada a fazer**, e desta vez está certo por um motivo, não só por existência. Todo arquivo é mais
novo que tudo aquilo de que é feito, então nada pode ter mudado desde que ele foi feito.
