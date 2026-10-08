---
title: A marca d'água
version: 1
---

"Desde a última execução" precisa estar escrito em algum lugar, e **o lugar onde está escrito se
chama marca d'água**: o maior `updated_at` que o pipeline já carregou. A Ana guarda a dela no
warehouse, uma linha por origem, ao lado das tabelas que ela descreve:

```
-- Every version of a row an incremental extraction has seen, with the moment
-- it was extracted. Nothing is ever updated here; a later version is a new row.
CREATE SCHEMA IF NOT EXISTS raw;
CREATE TABLE IF NOT EXISTS raw.orders_changes (
  order_id integer, shop_id integer, customer_id integer, ordered_at timestamptz,
  status text, updated_at timestamptz, extracted_at timestamptz NOT NULL);
CREATE TABLE IF NOT EXISTS raw.customers_changes (
  customer_id integer, name text, email text, city text, state text,
  created_at timestamptz, updated_at timestamptz, extracted_at timestamptz NOT NULL);
CREATE TABLE IF NOT EXISTS etl_state (
  source    text PRIMARY KEY,
  watermark timestamptz NOT NULL);
```

Toda noite a extração lê a sua marca d'água, pede à origem tudo acima dela, carrega as linhas e sobe
a marca d'água até a linha mais nova que carregou:

```schooling-example
{
  "language": "python",
  "file": "incremental.py",
  "parts": [
    {
      "code": "\"\"\"Copy the rows of a shop table that changed since the last run.\"\"\"\nimport sys\n\nimport psycopg\nfrom psycopg import sql\n\n"
    },
    {
      "code": "table = sys.argv[1]                                  # orders or customers\nlookback = int(sys.argv[2]) if len(sys.argv) > 2 else 0   # minutes to re-read\nsource = f\"shop.{table}\" + (f\"+{lookback}m\" if lookback else \"\")\ntarget = sql.Identifier(\"raw\", f\"{table}_changes\" + (f\"_{lookback}m\" if lookback else \"\"))\n\n",
      "note": "Um script para qualquer tabela e qualquer retrocesso. Cada combinação guarda a sua própria marca d'água com o seu próprio nome, para a lição poder rodar duas lado a lado e comparar."
    },
    {
      "code": "with psycopg.connect(\"dbname=wh\") as wh, psycopg.connect(\"dbname=shop\") as shop:\n    wh.execute(sql.SQL(\"CREATE TABLE IF NOT EXISTS {} (LIKE raw.{})\").format(\n        target, sql.Identifier(f\"{table}_changes\")))\n",
      "note": "O destino é criado no formato de `raw.orders_changes` se ainda não existir."
    },
    {
      "code": "    found = wh.execute(\"SELECT watermark FROM etl_state WHERE source = %s FOR UPDATE\",\n                       (source,)).fetchone()\n    since = found[0] if found else None\n\n",
      "note": "**Ler a marca d'água, e travar a linha dela.** O `FOR UPDATE` faz uma segunda cópia deste script, iniciada por engano, esperar aqui em vez de extrair as mesmas linhas ao mesmo tempo."
    },
    {
      "code": "    shop.execute(\"SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY\")\n    until = shop.execute(sql.SQL(\"SELECT max(updated_at) FROM {}\").format(\n        sql.Identifier(table))).fetchone()[0]\n    query = sql.SQL(\"SELECT *, now() FROM {} WHERE updated_at <= %s\").format(sql.Identifier(table))\n    params = [until]\n    if since is not None:\n        query += sql.SQL(\" AND updated_at > %s::timestamptz - make_interval(mins => %s)\")\n        params += [since, lookback]\n    rows = shop.execute(query, params).fetchall()\n\n",
      "note": "Um snapshot da loja. A nova marca d'água é o `updated_at` mais novo que o snapshot tem, e a consulta pede tudo depois da antiga e até a nova, para as duas nunca discordarem de onde a janela termina."
    },
    {
      "code": "    if rows:\n        insert = sql.SQL(\"INSERT INTO {} VALUES ({})\").format(\n            target, sql.SQL(\", \").join([sql.Placeholder()] * len(rows[0])))\n        wh.cursor().executemany(insert, rows)\n\n",
      "note": "Cada linha entra como uma linha nova, com o momento em que foi extraída. Nada no `raw` é atualizado."
    },
    {
      "code": "    wh.execute(\"\"\"INSERT INTO etl_state VALUES (%s, %s)\n                  ON CONFLICT (source) DO UPDATE SET watermark = excluded.watermark\"\"\",\n               (source, until))\n",
      "note": "**A marca d'água anda na mesma transação que as linhas.** Ou as duas são escritas ou nenhuma, então uma queda entre elas não deixa uma marca d'água que diz ter linhas que o warehouse nunca recebeu."
    },
    {
      "code": "print(f\"{source}: {len(rows)} rows since {since:%m-%d %H:%M:%S}, watermark now {until:%m-%d %H:%M:%S}\"\n      if since else f\"{source}: {len(rows)} rows, the first run, watermark now {until:%m-%d %H:%M:%S}\")"
    }
  ]
}
```

Depois de duas noites:

```
ana@vm:~/etl$ psql -d wh -c "SELECT * FROM etl_state ORDER BY source"
     source      |       watermark        
-----------------+------------------------
 shop.customers  | 2026-03-01 22:21:41-03
 shop.orders     | 2026-03-02 23:59:47-03
 shop.orders+60m | 2026-03-02 23:59:47-03
(3 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l04-watermark\" aria-label=\"Três noites numa linha de horários updated_at. Na primeira noite a extração lê tudo até 23:50:30 de 1º de março e a marca d'água é posta ali. Na segunda ela lê as 261 linhas entre essa marca e 23:59:47 de 2 de março, e a marca vai para 23:59:47. Na terceira ela lê as 301 linhas até 23:51:38 de 3 de março.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40.0 210.0 L690.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"365.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">updated_at dos pedidos da loja</text><text x=\"20.0\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">noite 1</text><rect x=\"90.0\" y=\"40.0\" width=\"240.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">17.195 linhas</text><path d=\"M330.0 64.0 L330.0 206.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M325.0 198 L335.0 198 L330.0 208 Z\" stroke=\"none\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"330.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1º mar 23:50:30</text><text x=\"20.0\" y=\"101.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">noite 2</text><rect x=\"330.0\" y=\"90.0\" width=\"160.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">261 linhas</text><path d=\"M490.0 114.0 L490.0 206.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M485.0 198 L495.0 198 L490.0 208 Z\" stroke=\"none\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"490.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 mar 23:59:47</text><text x=\"20.0\" y=\"151.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">noite 3</text><rect x=\"490.0\" y=\"140.0\" width=\"160.0\" height=\"22.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"570.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">301 linhas</text><path d=\"M650.0 164.0 L650.0 206.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M645.0 198 L655.0 198 L650.0 208 Z\" stroke=\"none\" stroke-width=\"1.2\" fill=\"var(--amber)\"></path><text x=\"650.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 mar 23:51:38</text><text x=\"338.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">marca d'água</text></svg>", "caption": "Cada noite lê a janela entre a última marca d'água e a linha mais nova do seu snapshot, e a marca só anda quando essas linhas foram carregadas."}
```

## Três escolhas nesse script que não são óbvias

**A nova marca d'água vem dos dados, não do relógio.** O `max(updated_at)` dentro do snapshot é a
mudança mais nova que a extração de fato leu. Usar a hora em que o job começou alegaria linhas que
ainda não estavam visíveis para ela — e o caixa lento da próxima seção é exatamente uma linha assim.

**A janela é fechada nas duas pontas.** A consulta pede `updated_at > antiga` *e* `updated_at <=
nova`, onde `nova` foi lida no mesmo snapshot. Uma linha confirmada um milissegundo depois do
snapshot não está nele e fica acima de `nova`, então a próxima noite a pega. Sem o limite de cima as
duas poderiam discordar, e uma linha poderia ser carregada e depois pulada.

**A marca d'água e as linhas são confirmadas juntas.** Se a carga falha, a marca d'água não andou e
amanhã a mesma janela é lida de novo. Se a marca d'água fosse salva antes, uma queda entre as duas
perderia a janela para sempre. **Uma marca d'água que corre na frente dos dados é um buraco que
ninguém vê**, e manter as duas numa transação só é o que torna isso impossível.
