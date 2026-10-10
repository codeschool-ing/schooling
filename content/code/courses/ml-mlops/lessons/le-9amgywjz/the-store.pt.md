---
title: Uma feature store em oitenta linhas
version: 1
---

Aqui está uma feature store inteira para o modelo de afastamento: um armazenamento offline, um
online, a materialização que os enche e as duas formas de lê-los. Ela é pequena de propósito, para
que cada parte da seção anterior seja uma função que você consegue ler. Ela guarda os dados num
segundo arquivo SQLite, `features.db`, ao lado do `shop.db`. Salve-a em `~/ml` como
`featurestore.py`; ela importa o `features.py` e o `project.py` da lição 5.

```schooling-example
{
  "language": "python",
  "file": "featurestore.py",
  "parts": [
    {
      "code": "\"\"\"featurestore.py: a small feature store for the lapse model, on SQLite.\n\n    python featurestore.py backfill 2025-06-01 2026-02-22   # one snapshot a week\n    python featurestore.py snapshot 2026-02-28              # tonight's snapshot\n    python featurestore.py online                           # latest values, for serving\n    python featurestore.py get 2                            # one member, as a service would ask\n\nThe offline store keeps every snapshot, so training can ask what a member looked\nlike on any past day. The online store keeps only the latest, one row per member,\nso a service can ask what they look like now.\n\"\"\"\n",
      "note": "Os quatro comandos são a interface inteira. Dois gravam o armazenamento offline, um monta o online a partir dele, e um lê um membro do jeito que um serviço leria."
    },
    {
      "code": "import datetime as dt\nimport sqlite3\nimport sys\n\nimport pandas as pd\n\nimport features\nfrom project import ROOT, SHOP\n\nSTORE = ROOT / \"features.db\"\nCOLUMNS = features.CATEGORICAL + features.NUMERIC\nMAX_AGE = dt.timedelta(days=7)       # older than this, a value is too stale to use\n\n\n",
      "note": "O armazenamento é um arquivo próprio, `features.db`, ao lado da loja. `MAX_AGE` é a idade máxima de um valor que ainda pode ser usado, o **tempo de vida** do armazenamento."
    },
    {
      "code": "def snapshot(day):\n    rows = features.build(day, SHOP).drop(columns=\"lapsed\")   # never store a label here\n    rows.insert(1, \"as_of\", day)\n    with sqlite3.connect(STORE) as db:\n        if db.execute(\"SELECT 1 FROM sqlite_master WHERE name = 'offline'\").fetchone():\n            db.execute(\"DELETE FROM offline WHERE as_of = ?\", (day,))   # rerunning a day replaces it\n        rows.to_sql(\"offline\", db, if_exists=\"append\", index=False)\n        db.execute(\"CREATE INDEX IF NOT EXISTS offline_by_member ON offline (member_id, as_of)\")\n    return len(rows)\n\n\n",
      "note": "Uma fotografia é o `features.py` rodado para um dia e anexado, com o dia ao lado de cada linha como `as_of`. **O rótulo é descartado antes de qualquer coisa ser guardada**: uma feature store guarda o que se sabia num dia, e o rótulo é o que se descobriu depois dele. Rodar um dia duas vezes o substitui em vez de duplicá-lo."
    },
    {
      "code": "def historical(entities):\n    \"\"\"For each (member_id, at) row, the features as they stood at that moment, or nothing.\"\"\"\n    with sqlite3.connect(STORE) as db:\n        offline = pd.read_sql_query(\"SELECT * FROM offline\", db)\n    offline[\"as_of\"] = pd.to_datetime(offline[\"as_of\"])\n    left = entities.assign(at=pd.to_datetime(entities[\"at\"]), row=range(len(entities)))\n    joined = pd.merge_asof(left.sort_values(\"at\", kind=\"stable\"), offline.sort_values(\"as_of\"),\n                           left_on=\"at\", right_on=\"as_of\", by=\"member_id\",\n                           direction=\"backward\", tolerance=pd.Timedelta(MAX_AGE))\n    return joined.sort_values(\"row\").drop(columns=\"row\").reset_index(drop=True)\n\n\n",
      "note": "A **junção no ponto do tempo**. Para cada linha perguntada, o `merge_asof` pega a fotografia mais nova daquele membro até o momento, nunca depois, e não dá nada se a mais nova for mais velha que `MAX_AGE`. A coluna `row` devolve as respostas na ordem em que foram perguntadas."
    },
    {
      "code": "def online():\n    \"\"\"The latest value per member, leaving out members whose latest is too old to serve.\"\"\"\n    with sqlite3.connect(STORE) as db:\n        newest = db.execute(\"SELECT max(as_of) FROM offline\").fetchone()[0]\n        oldest = (dt.date.fromisoformat(newest) - MAX_AGE).isoformat()\n        db.executescript(f\"\"\"\n            DROP TABLE IF EXISTS online;\n            CREATE TABLE online AS\n              SELECT * FROM offline o\n              WHERE as_of = (SELECT max(as_of) FROM offline WHERE member_id = o.member_id)\n                AND as_of >= '{oldest}';\n            CREATE UNIQUE INDEX online_by_member ON online (member_id);\n        \"\"\")\n        kept = db.execute(\"SELECT count(*) FROM online\").fetchone()[0]\n        known = db.execute(\"SELECT count(DISTINCT member_id) FROM offline\").fetchone()[0]\n    return kept, known - kept, newest\n\n\n",
      "note": "O armazenamento online é reconstruído a partir do offline: a linha mais nova de cada membro, **a menos que ela seja mais velha que `MAX_AGE`**, e um índice para que a busca por membro seja um único acesso."
    },
    {
      "code": "def get(member_id):\n    with sqlite3.connect(STORE) as db:\n        db.row_factory = sqlite3.Row\n        row = db.execute(\"SELECT * FROM online WHERE member_id = ?\", (member_id,)).fetchone()\n    return dict(row) if row else None\n\n\n",
      "note": "O que um serviço chama: um membro, uma linha, ou `None` quando o armazenamento não tem nada novo o bastante."
    },
    {
      "code": "if __name__ == \"__main__\":\n    command = sys.argv[1]\n    if command == \"backfill\":\n        day, last = dt.date.fromisoformat(sys.argv[2]), dt.date.fromisoformat(sys.argv[3])\n        total, weeks = 0, 0\n        while day <= last:\n            total += snapshot(day.isoformat())\n            weeks += 1\n            day += dt.timedelta(days=7)\n        print(f\"{weeks} snapshots, {total} rows in the offline store\")\n    elif command == \"snapshot\":\n        print(f\"{sys.argv[2]}: {snapshot(sys.argv[2])} members\")\n    elif command == \"online\":\n        kept, stale, newest = online()\n        print(f\"online store: {kept} members as of {newest}; {stale} left out as too old to serve\")\n    elif command == \"get\":\n        print(get(int(sys.argv[2])))\n",
      "note": "`backfill` tira uma fotografia por semana entre dois dias; `snapshot` tira uma, que é o que um job noturno rodaria depois da carga da loja."
    }
  ]
}
```

**Tudo o que uma store de produção acrescenta fica em volta destas cinco funções, não no lugar
delas**: uma agenda para o `snapshot`, um banco que responde mais rápido que o SQLite para muitos
leitores ao mesmo tempo, um registro de quais visões de atributos existem e de quem são, e
monitoramento de quão atualizada cada uma está. A seção 10 nomeia os produtos que acrescentam isso.
