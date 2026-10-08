---
title: A carga completa
version: 1
---

A extração mais simples copia a tabela inteira, toda vez. **Ela joga fora o que o warehouse tinha e
põe no lugar o que a origem tem agora**, então está certa por construção: cada inserção, cada
atualização e cada exclusão desde a última execução estão na nova cópia, sem o pipeline precisar
saber qual delas aconteceu.

A extração completa dos clientes da loja feita pela Ana esvazia `raw.customers` e a enche de novo
com `COPY`, numa transação só, para que quem lê veja a cópia antiga ou a nova e nunca uma tabela
vazia no meio:

```
"""Replace raw.customers with a complete copy of the shop's customers."""
import psycopg

with psycopg.connect("dbname=shop") as shop, psycopg.connect("dbname=wh") as wh:
    wh.execute("""CREATE TABLE IF NOT EXISTS raw.customers (
                    customer_id integer, name text, email text, city text, state text,
                    created_at timestamptz, updated_at timestamptz)""")
    wh.execute("TRUNCATE raw.customers")
    src, dst = shop.cursor(), wh.cursor()
    with src.copy("COPY customers TO STDOUT") as out, \
         dst.copy("COPY raw.customers FROM STDIN") as into:
        for chunk in out:
            into.write(chunk)
print(f"raw.customers: {src.rowcount} rows, all of them")
```

Nas duas primeiras noites:

```
ana@vm:~/etl$ python full_customers.py
raw.customers: 5098 rows, all of them
```

```
ana@vm:~/etl$ python full_customers.py
raw.customers: 5119 rows, all of them
```

Vinte e um clientes novos em 2 de março, e para achá-los o pipeline leu 5.119 linhas. **O custo de
uma carga completa cresce com a tabela, não com a mudança.** Para clientes tudo bem: cinco mil
linhas copiam num piscar e vão continuar assim por anos. Os pedidos da loja crescem duzentos ou
trezentos por dia e nunca diminuem, então uma carga completa deles lê o histórico inteiro toda noite
para achar um dia de novidade. Em 1º de março são dezessete mil linhas; em cinco anos, meio milhão,
lidas toda noite por causa de trezentas.

## Quando a carga completa é a resposta certa

- **A tabela é pequena**, e vai continuar pequena: lojas, categorias, uma tabela de moedas, os
  1.200 livros.
- **A origem não sabe dizer o que mudou**: nenhum `updated_at`, nenhum log, um arquivo que é sempre o
  catálogo inteiro. Aí não há alternativa além de comparar cada linha, e comparar cada linha *é* uma
  carga completa.
- **As exclusões importam e nada as registra.** A última seção desta lição mostra por que esse é o
  motivo decisivo.

Uma carga completa também é a primeira versão segura de qualquer pipeline, e aquela para a qual se
volta quando há suspeita de que uma incremental está se desviando: recarregue a tabela inteira,
compare, e veja o que a versão incremental vinha perdendo.
