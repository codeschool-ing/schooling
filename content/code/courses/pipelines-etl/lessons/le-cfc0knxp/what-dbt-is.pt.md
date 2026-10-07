---
title: O que o dbt faz, e o que ele deixa com você
version: 1
---

As transformações da Ana são uma pasta de arquivos SQL e um script de shell que os roda **na ordem
dos nomes**. Todo arquivo começa com `DROP TABLE IF EXISTS` e um `CREATE TABLE … AS`, e a ordem só
está certa porque ela deu aos arquivos nomes que a deixam certa. Quando o `daily_sales` lê o
`staging.books`, nada registra isso a não ser o alfabeto.

O **dbt** — a *data build tool* — assume esse trabalho. Um **modelo** do dbt é um arquivo com um
`select`: nada de `CREATE`, nada de `DROP`, nada de transação. O dbt escreve os comandos que
transformam o `select` numa view ou numa tabela, roda-os no warehouse e descobre a ordem a partir
dos próprios modelos, porque cada modelo nomeia os modelos que lê. Ele não move dados entre
máquinas: tudo roda dentro do PostgreSQL, o que faz dele o T do ELT e mais nada. Extrair e carregar o
`raw` continua sendo trabalho do `load_raw.py`, e agendar continua sendo do Airflow.

O dbt do laboratório é o dbt-core com o adaptador de PostgreSQL, instalado num ambiente virtual
próprio. A Ana começa um projeto em `~/etl/shop`, com o mesmo staging e os mesmos marts que ela já
tem. As configurações dele:

```schooling-example
{
  "language": "yaml",
  "file": "shop/dbt_project.yml",
  "parts": [
    {
      "code": "name: shop\nversion: \"1.0\"\nprofile: ponto_final            # which entry of ~/.dbt/profiles.yml to connect with\n\n",
      "note": "O nome do projeto, que também é a primeira parte do nome de todo modelo no `dbt ls`, e o **profile**: qual conexão, num arquivo que mora fora do projeto."
    },
    {
      "code": "flags:\n  send_anonymous_usage_stats: false\n  use_colors: false\n\n",
      "note": "O laboratório não tem internet. Sem a primeira flag o dbt tenta mandar estatísticas de uso a cada comando; sem a segunda, a saída dele vem cheia de códigos de cor."
    },
    {
      "code": "models:\n  shop:\n",
      "note": "Configurações por pasta. Um `+` marca uma configuração que vale para todo modelo daqui para baixo."
    },
    {
      "code": "    staging:                    # everything under models/staging\n      +schema: staging\n      +materialized: view\n",
      "note": "**Os modelos de staging viram views**, que não custam nada para construir e sempre mostram o que está em `raw` agora."
    },
    {
      "code": "    marts:                      # everything under models/marts\n      +schema: marts\n      +materialized: table",
      "note": "**Os marts viram tabelas**, refeitas a cada execução, porque relatórios as leem o dia inteiro e uma view refaria todo join a cada vez."
    }
  ]
}
```

Como se conectar fica fora do projeto, em `~/.dbt/profiles.yml`, para que o projeto possa ser
compartilhado sem a senha de ninguém dentro:

```
ponto_final:
  target: dev
  outputs:
    dev:
      type: postgres
      host: /run/etl-pg         # the socket's directory: a path, not a name
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt
      threads: 4
```

O `schema: dbt` é para onde vão os modelos, a menos que digam outra coisa; a próxima seção mostra o
que aconteceu com os que disseram. O projeto, até aqui, são seis arquivos:

```
ana@vm:~/etl/shop$ find . -type f | sort
./dbt_project.yml
./models/marts/daily_sales.sql
./models/staging/sources.yml
./models/staging/stg_books.sql
./models/staging/stg_order_lines.sql
./models/staging/stg_orders.sql
```

E o `dbt debug` confere tudo antes de qualquer coisa ser construída — que os dois arquivos fazem
sentido, que o `git` está lá para os pacotes e que a conexão funciona:

```
ana@vm:~/etl/shop$ dbt debug 2>&1 | grep -E "OK|ERROR|checks"
06:26:56    profiles.yml file [OK found and valid]
06:26:56    dbt_project.yml file [OK found and valid]
06:26:56   - git [OK found]
06:26:57    Connection test: [OK connection ok]
06:26:57  All checks passed!
```
