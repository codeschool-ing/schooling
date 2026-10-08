---
title: Um comando reconstrói tudo
version: 1
---

Ao longo de dezesseis aulas, as decisões foram parar em arquivos pequenos: `years.py` e
`consent.py` da aula 10, `ready.py` e `derive.py` da aula 12, `survivors.csv` da aula 5. Cada um
funciona quando importado. O que falta é a ordem, e **uma ordem que mora na memória de alguém é um
pipeline que mais ninguém consegue rodar**. Então um script roda todos, dos arquivos brutos às
tabelas limpas:

```schooling-example
{
  "language": "python",
  "file": "run.py",
  "parts": [
    {
      "code": "\"\"\"Rebuild the clean tables from raw/, in order, and record every value that changed.\"\"\"\nimport logging\nimport pathlib\n\nimport pandas as pd\n\n",
      "note": "Para que serve o script, numa linha."
    },
    {
      "code": "logging.basicConfig(level=logging.INFO, format=\"%(name)s: %(message)s\")\nOUT = pathlib.Path(\"out\")\n\n\n",
      "note": "**Toda linha de log diz o seu passo**, e vai para a saída de erro, longe dos dados."
    },
    {
      "code": "def change(table, keys, column, before, after, rule):\n    return pd.DataFrame({\"table\": table, \"key\": keys, \"column\": column,\n                         \"before\": before, \"after\": after, \"rule\": rule})\n\n\n",
      "note": "Uma linha do registro de mudanças: que tabela, que chave, que coluna, antes, depois, e a regra."
    },
    {
      "code": "def build_customers():\n    log = logging.getLogger(\"customers\")\n    from consent import customers  # lesson 10: consent as True, False or blank\n    from years import customers as same  # lesson 10: the same table, with the century rule\n    assert customers is same\n",
      "note": "**Os clientes vêm dos dois arquivos da aula 10**, que mudam a mesma tabela; o `assert` garante isso."
    },
    {
      "code": "    written = customers[\"birth_year\"]\n    placeholder = written == \"1900\"\n    two = written.str.len() == 2\n",
      "note": "Que valores as duas regras tocaram, achados pelo que estava escrito."
    },
    {
      "code": "    log.info(f\"{len(customers)} rows, {placeholder.sum()} placeholders blanked, \"\n             f\"{two.sum()} years given a century, {customers['opt_in'].isna().sum()} consents unknown\")\n",
      "note": "**As contagens do passo**, numa linha."
    },
    {
      "code": "    changes = pd.concat([\n        change(\"customers\", customers.loc[placeholder, \"customer_id\"], \"birth_year\", \"1900\", \"\",\n               \"placeholder, lesson 4\"),\n        change(\"customers\", customers.loc[two, \"customer_id\"], \"birth_year\", written[two],\n               customers.loc[two, \"birth\"].astype(str), \"century rule, lesson 10\")])\n",
      "note": "Todo marcador esvaziado e todo ano de dois dígitos, registrados com a sua regra."
    },
    {
      "code": "    table = customers[[\"customer_id\", \"birth\", \"opt_in\"]].rename(columns={\"birth\": \"birth_year\"})\n    return table, changes\n\n\n",
      "note": "A tabela limpa de clientes: código, ano de nascimento e consentimento."
    },
    {
      "code": "def build_orders():\n    log = logging.getLogger(\"orders\")\n    from derive import orders  # lesson 12: decided totals, derived columns, corporate flag\n    from typos import wrong  # lesson 9: the seven totals typed ten times too big\n",
      "note": "**Os pedidos vêm da aula 12**, e os sete totais digitados errado da aula 9."
    },
    {
      "code": "    raw = pd.read_csv(\"raw/orders.csv\", dtype=str).drop_duplicates().set_index(\"order_id\")\n    before = pd.to_numeric(raw[\"total\"])\n    after = orders.set_index(\"order_id\")[\"total\"]\n    moved = after.index[after != before]\n    typo = moved.isin(wrong[\"order_id\"])\n",
      "note": "**O que mudou é achado por comparação**, não lembrado: total bruto contra total decidido."
    },
    {
      "code": "    survivors = pd.read_csv(\"survivors.csv\", dtype=str)  # lesson 5\n    owner = orders[\"customer_id\"].map(dict(zip(survivors[\"customer_id\"], survivors[\"kept_id\"])))\n    rekeyed = owner.notna()\n",
      "note": "O mapa de segundos registros da aula 5, aplicado aos códigos de cliente dos pedidos."
    },
    {
      "code": "    log.info(f\"{len(orders)} rows, {typo.sum()} totals recomputed from lines, \"\n             f\"{(~typo).sum()} negative totals set to 0, {rekeyed.sum()} moved to a surviving \"\n             f\"customer, {orders['corporate'].sum()} flagged corporate\")\n",
      "note": "As contagens do passo."
    },
    {
      "code": "    changes = pd.concat([\n        change(\"orders\", moved, \"total\", before[moved].astype(str), after[moved].astype(str),\n               [\"typed total, lesson 9\" if t else \"coupon above basket, lesson 9\" for t in typo]),\n        change(\"orders\", orders.loc[rekeyed, \"order_id\"], \"customer_id\",\n               orders.loc[rekeyed, \"customer_id\"], owner[rekeyed], \"same person, lesson 5\")])\n    orders.loc[rekeyed, \"customer_id\"] = owner[rekeyed]\n",
      "note": "**Todo total mudado e todo pedido movido registrados**, e depois a mudança aplicada."
    },
    {
      "code": "    columns = [\"order_id\", \"customer_id\", \"channel\", \"placed\", \"status\", \"total\", \"items\",\n               \"corporate\"]\n    return orders[columns], changes\n\n\n",
      "note": "As colunas que a tabela limpa de pedidos mantém."
    },
    {
      "code": "if __name__ == \"__main__\":\n    OUT.mkdir(exist_ok=True)\n    customers, c1 = build_customers()\n    orders, c2 = build_orders()\n    changes = pd.concat([c1, c2])\n    customers.to_csv(OUT / \"customers.csv\", index=False)\n    orders.to_csv(OUT / \"orders.csv\", index=False)\n    changes.to_csv(OUT / \"changes.csv\", index=False)\n    logging.getLogger(\"run\").info(f\"{len(changes)} changes recorded in out/changes.csv\")\n",
      "note": "Monta as duas, grava os três arquivos e diz quantas mudanças foram registradas."
    }
  ]
}
```

```
ana@lab:~/clean$ python run.py
customers: 2376 rows, 338 placeholders blanked, 105 years given a century, 57 consents unknown
orders: 28526 rows, 7 totals recomputed from lines, 137 negative totals set to 0, 2 moved to a surviving customer, 16 flagged corporate
run: 589 changes recorded in out/changes.csv
ana@lab:~/clean$ ls out
changes.csv
customers.csv
orders.csv
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l17-pipeline\" aria-label=\"Um diagrama do pipeline. À esquerda, os arquivos brutos, só de leitura, com as suas impressões digitais em raw.sha256. Uma seta leva ao run.py, um comando que importa os módulos das aulas. Dele, setas levam a duas saídas em out/: as tabelas limpas e o registro de mudanças, e o checks.py lê as saídas. Um contorno tracejado em volta do código, dos mapas e do raw.sha256 marca o que está sob controle de versão; os arquivos brutos e out/ ficam fora dele.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M188 20 L532 20 Q540 20 540 28 L540 262 Q540 270 532 270 L188 270 Q180 270 180 262 L180 28 Q180 20 188 20 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">sob controle de versão</text><rect x=\"20.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">raw/</text><text x=\"90.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só leitura</text><rect x=\"200.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">raw.sha256</text><text x=\"270.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">impressões digitais</text><rect x=\"200.0\" y=\"160.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">run.py</text><text x=\"270.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um comando</text><rect x=\"380.0\" y=\"160.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">*.py, *.csv</text><text x=\"450.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os módulos das aulas</text><rect x=\"570.0\" y=\"60.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">out/*.csv</text><text x=\"635.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tabelas limpas</text><rect x=\"570.0\" y=\"160.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">changes.csv</text><text x=\"635.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">registro de mudanças</text><rect x=\"380.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">checks.py</text><text x=\"450.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">verificações</text><path d=\"M160.0 88.0 L198.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M90 116 L90 188 L198 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M378.0 188.0 L342.0 188.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M270 216 L270 245 L635 245 L635 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M300 160 L300 138 L635 138 L635 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M568.0 88.0 L522.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"635.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">refeito a cada execução</text></svg>", "caption": "O que se guarda e o que se reconstrói. Tudo dentro da linha tracejada é versionado; os arquivos brutos recebem impressões digitais em vez disso, e o out/ é jogado fora e feito de novo."}
```

Três propriedades fazem esse script valer mais que os comandos que ele substitui:

- **Ele parte de `raw/` toda vez.** Nada do que lê foi escrito por uma execução anterior, então não
  há estado escondido: apague `out/` e a próxima execução devolve exatamente os mesmos arquivos.
- **Cada passo reaproveita a aula que o decidiu** em vez de copiá-la. Se a regra do século um dia
  mudar, ela muda no `years.py`, e o pipeline a pega sem ninguém precisar lembrar onde mais ela foi
  colada.
- **Cada passo diz o que fez**, em números: 338 marcadores, 105 séculos, 7 totais recalculados, 137
  zerados, 2 pedidos passados a um cliente sobrevivente, 16 marcados. Uma linha de log com uma
  contagem é a diferença entre "o pipeline rodou" e "o pipeline fez o que esperávamos". Quando a
  execução do mês que vem disser 412 marcadores, alguém vai perguntar por quê, e é essa a ideia.

O log vai para a saída de erro pelo `logging` do Python, então nunca se mistura com os dados e pode
ser guardado num arquivo próprio. As saídas vão para `out/`, que é descartável de propósito: tudo
nele pode ser reconstruído com um comando.
