---
title: Aplicando as mudanças
version: 1
---

Um fluxo de mudanças precisa de um ponto de partida onde aplicá-las. A Ana copia os clientes
inteiros, uma vez, para um schema do warehouse chamado `cdc` — depois de criar o slot, para que nada
confirmado no meio-tempo possa cair no vão:

```
-- The starting point: the customers as they are now, copied whole.
CREATE SCHEMA IF NOT EXISTS cdc;
DROP TABLE IF EXISTS cdc.customers;
CREATE TABLE cdc.customers (
  customer_id integer PRIMARY KEY, name text, email text, city text, state text,
  created_at timestamptz, updated_at timestamptz);
```

```
ana@vm:~/etl$ psql -q -d wh -f snapshot_customers.sql
psql:snapshot_customers.sql:3: NOTICE:  table "customers" does not exist, skipping
ana@vm:~/etl$ psql -c "\copy customers TO /tmp/customers.csv" && psql -d wh -c "\copy cdc.customers FROM /tmp/customers.csv"
COPY 5079
COPY 5079
```

Daí em diante a cópia é mantida em dia lendo o slot e fazendo nela o que a loja fez:

```schooling-example
{
  "language": "python",
  "file": "apply_cdc.py",
  "parts": [
    {
      "code": "\"\"\"Apply the shop's committed changes to customers, read from a logical\nreplication slot, to the copy in the warehouse.\"\"\"\nimport re\n\nimport psycopg\n\n"
    },
    {
      "code": "FIELD = re.compile(r\"(\\w+)\\[[^\\]]+\\]:('(?:[^']|'')*'|\\S+)\")\n\n\n",
      "note": "O `test_decoding` escreve cada coluna como `nome[tipo]:valor`, com texto entre aspas e uma aspa interna dobrada. Uma expressão regular lê isso."
    },
    {
      "code": "def values(text):\n    out = {}\n    for name, raw in FIELD.findall(text):\n        out[name] = None if raw == \"null\" else raw.strip(\"'\").replace(\"''\", \"'\")\n    return out\n\n\n",
      "note": "Transforma o texto de uma mudança num dicionário de coluna para valor, com `null` como `None`."
    },
    {
      "code": "done = {\"INSERT\": 0, \"UPDATE\": 0, \"DELETE\": 0, \"other tables\": 0}\nwith psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:\n    changes = shop.execute(\n        \"SELECT lsn, data FROM pg_logical_slot_get_changes('wh_cdc', NULL, NULL)\").fetchall()\n",
      "note": "**O `get_changes` consome.** Ele devolve tudo o que foi confirmado desde a última chamada e passa o slot para depois disso — mas só quando a transação da loja é confirmada, o que acontece depois da do warehouse, porque as conexões fecham em ordem inversa."
    },
    {
      "code": "    for lsn, data in changes:\n        if not data.startswith(\"table \"):\n            continue                                   # BEGIN and COMMIT lines\n        if not data.startswith(\"table public.customers: \"):\n            done[\"other tables\"] += 1\n            continue\n",
      "note": "Os limites de transação e todas as outras tabelas são contados e pulados. Uma implantação de verdade pediria ao banco só as tabelas que quer, o que o `test_decoding` não sabe fazer."
    },
    {
      "code": "        op, _, rest = data.removeprefix(\"table public.customers: \").partition(\": \")\n        row = values(rest)\n",
      "note": "A operação e as colunas."
    },
    {
      "code": "        if op == \"DELETE\":\n            wh.execute(\"DELETE FROM cdc.customers WHERE customer_id = %s\", (row[\"customer_id\"],))\n",
      "note": "Uma exclusão traz a chave, e a chave basta."
    },
    {
      "code": "        else:\n            cols = list(row)\n            wh.execute(\n                f\"INSERT INTO cdc.customers ({', '.join(cols)}) VALUES ({', '.join(['%s'] * len(cols))})\"\n                f\" ON CONFLICT (customer_id) DO UPDATE SET \"\n                + \", \".join(f\"{c} = excluded.{c}\" for c in cols if c != \"customer_id\"),\n                list(row.values()))\n",
      "note": "Uma inserção ou uma atualização viram o mesmo comando: inserir a linha, ou sobrescrevê-la se a chave já estiver lá. **Aplicar a mesma mudança duas vezes deixa a mesma linha**, então uma execução que morre depois de o warehouse confirmar e antes de o slot andar não faz mal quando as mudanças vêm de novo."
    },
    {
      "code": "        done[op] += 1\nprint(f\"{len(changes)} changes read up to {changes[-1][0] if changes else '-'}: {done}\")"
    }
  ]
}
```

A primeira execução aplica o dia 1º de março. A segunda, logo em seguida, não acha nada — a primeira
consumiu as mudanças e o slot seguiu em frente:

```
ana@vm:~/etl$ python apply_cdc.py
1088 changes read up to 0/BA8A238: {'INSERT': 19, 'UPDATE': 4, 'DELETE': 0, 'other tables': 643}
ana@vm:~/etl$ python apply_cdc.py
0 changes read up to -: {'INSERT': 0, 'UPDATE': 0, 'DELETE': 0, 'other tables': 0}
```

Vinte e três mudanças de clientes entre 666: o resto eram pedidos, linhas e pagamentos, que este
script lê e descarta. **Ler as mudanças de todas as tabelas para manter uma é desperdício**, e uma
implantação de verdade o evita com uma *publicação*, que lista as tabelas que um leitor quer, e o
plugin `pgoutput`, que a respeita. O `test_decoding` não tem essa opção; é o plugin para aprender,
não o de produção.

## O dia em que a marca d'água falhou

A Ana toca os dias de 2 a 13 de março com o `shop day`, rodando o `apply_cdc.py` depois de
cada um, e depois toca o dia 14 — o dia em
que um cliente pediu para ser esquecido:

```
ana@vm:~/etl$ sudo shop day 2026-03-14
ana@vm:~/etl$ python apply_cdc.py
2268 changes read up to 0/BE7CF38: {'INSERT': 22, 'UPDATE': 4, 'DELETE': 1, 'other tables': 1387}
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM cdc.customers WHERE customer_id = 1880"
 count 
-------
     0
(1 row)
```

`'DELETE': 1`, e o cliente 1880 sumiu da cópia. **A exclusão que a extração incremental da lição 4
nunca viu chegou aqui como uma linha qualquer.** E a cópia, depois de catorze dias de mudanças
aplicadas uma a uma, concorda com a loja em cada linha:

```
ana@vm:~/etl$ psql -c "\copy customers TO /tmp/customers.csv" && psql -d wh -c "CREATE TEMP TABLE now_in_shop (LIKE cdc.customers)" -c "\copy now_in_shop FROM /tmp/customers.csv" -c "SELECT (SELECT count(*) FROM (TABLE now_in_shop EXCEPT TABLE cdc.customers) a) AS only_in_shop, (SELECT count(*) FROM (TABLE cdc.customers EXCEPT TABLE now_in_shop) b) AS only_in_copy"
COPY 5345
CREATE TABLE
COPY 5345
 only_in_shop | only_in_copy 
--------------+--------------
            0 |            0
(1 row)
```

A mesma verificação com `EXCEPT` da lição 2, agora num comando só porque a loja e o warehouse são
bancos diferentes: a tabela da loja é copiada antes para uma tabela temporária, e as duas são
comparadas nas duas direções.
