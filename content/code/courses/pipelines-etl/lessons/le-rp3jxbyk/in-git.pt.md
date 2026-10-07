---
title: Tudo o que é escrito, no git
version: 1
---

Até agora, o `~/etl` foi um diretório que é ao mesmo tempo o código que a Ana está editando e o
código que a carga noturna roda. Cada edição das últimas dez lições valeu no momento em que foi salva.
Isso funciona enquanto uma pessoa edita e nada importante lê o resultado. Para de funcionar na
primeira vez em que uma edição pela metade às cinco da tarde é o que roda às duas da manhã.

O primeiro passo é saber qual versão do código é qual, e isso é **controle de versão**. A Ana põe o
projeto no git, começando pelo que *não* pertence a ele:

```
# What is made by running the pipeline, not written by a person.
shop/target/
shop/logs/
__pycache__/
.made/
reports/
# What arrives from outside, and the decisions about it: data, not code.
landing/
inbox/
quarantine/
```

Dois tipos de coisa ficam de fora. O que rodar o pipeline **faz** — o `target/` do dbt, os logs, as
marcas, os relatórios — sempre pode ser feito de novo, e no git só produziria mudanças que ninguém
escreveu. O que **chega** de fora — os arquivos de landing, os de estoque, a quarentena — é dado: muda
toda noite, pode ser grande, e pode ser pessoal. Código é o que uma pessoa escreveu e de que gostaria
de ver o histórico.

Os dados de conexão não estão na lista porque nem estão no projeto: moram em `~/.dbt/profiles.yml`, e
a chave da API de preços é uma variável de ambiente. **Um segredo que nunca está no diretório não pode
ser commitado por engano**, que é o único tipo de nunca que se sustenta.

```
ana@vm:~/etl$ git config --global user.name "Ana" && git config --global user.email "ana@ponto-final.example"
ana@vm:~/etl$ git init -q -b main && git add . && git commit -q -m "The nightly as it runs today" && git log --oneline
cdef2c0 The nightly as it runs today
ana@vm:~/etl$ git ls-files | sed "s|/.*|/…|" | sort | uniq -c
      1 .gitignore
      1 dags/…
      3 load/…
      1 load_raw.py
      1 load_stock.py
      1 nightly.sh
      1 prices.py
      1 run_sql.sh
     15 shop/…
      9 sql/…
     10 tests/…
      1 trace.sh
      1 validate_prices.py
```

Quinze arquivos do projeto dbt, dez de testes e da fixture deles, e os scripts, o SQL e o DAG das
lições anteriores. Um commit, *a carga noturna como roda hoje*: daqui em diante, toda mudança tem
um antes.
