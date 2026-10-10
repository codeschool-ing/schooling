---
title: A loja, sorteada por um programa que fica com você
version: 1
---

Um modelo só é tão bom quanto as linhas com que aprende, então o curso precisa de linhas, e as de
clientes reais não são algo que um curso possa distribuir. **Os dados da loja são sorteados por um
programa curto, a partir de uma semente fixa**, para que o banco no seu computador seja o mesmo,
linha por linha, que aquele contra o qual cada transcrição do curso foi gravada.

Crie o diretório do projeto e salve nele o programa abaixo como `generate.py`. O botão de copiar do
bloco entrega o programa inteiro, sem as notas.

```sh
mkdir ~/ml
cd ~/ml
```

```schooling-example
{
  "language": "python",
  "file": "generate.py",
  "parts": [
    {
      "code": "\"\"\"generate.py: two years of the Ponto Final card, drawn from a fixed seed.\n\n    python generate.py                     # the shop as it stood on 28 February 2026\n    python generate.py --until 2026-06-30  # the same history, four months further on\n\nWrites shop.db, an SQLite database with four tables: members, the people who\ncarry the shop's loyalty card; purchases, one row per visit to a till or to the\nwebsite; lines, one row per book in a purchase; and titles, the books. Nobody\nin it is real, and the same seed draws the same shop on every computer.\n\"\"\"\nimport argparse\nimport datetime as dt\nimport sqlite3\n\nimport numpy as np\n\n",
      "note": "A docstring diz como rodar. Sem argumento ele para em 28 de fevereiro de 2026, a noite em que este curso começa; `--until` deixa a lição 10 ler a mesma história mais adiante."
    },
    {
      "code": "FIRST, LAST = dt.date(2024, 7, 1), dt.date(2026, 6, 30)\nSHOPS = [\"Paulista\", \"Pinheiros\", \"Cambuí\", \"Savassi\", \"Batel\", \"Moinhos\", \"Online\"]\nAGES = [\"18-24\", \"25-34\", \"35-49\", \"50-64\", \"65+\"]\nCATEGORIES = [\"crime\", \"fantasy\", \"literary\", \"children\", \"cooking\", \"history\",\n              \"science\", \"travel\"]\nWORDS = [\"Harbour\", \"River\", \"Garden\", \"Winter\", \"Letter\", \"Island\", \"Station\",\n         \"Mirror\", \"Lantern\", \"Orchard\"]\nSHIPPING_FREE = dt.date(2026, 3, 16)   # online orders stop paying postage\nRIVAL_OPENS = dt.date(2026, 4, 1)      # a book subscription launches in São Paulo\n\n",
      "note": "As lojas são as de `pipelines-etl`. As duas datas no fim são coisas que vão acontecer com a loja depois de fevereiro. Nada nas nove primeiras lições depende delas, e a lição 10 é sobre percebê-las só pelos dados."
    },
    {
      "code": "args = argparse.ArgumentParser()\nargs.add_argument(\"--until\", default=\"2026-02-28\")\nuntil = args.parse_args().until\nrng = np.random.default_rng(2026)\n\n",
      "note": "**Uma semente, `2026`, sorteia tudo.** Mude-a e você terá outra loja, com todos os números do curso diferentes dos seus."
    },
    {
      "code": "# 80 titles, ten to a category, each with a price in cents\ntitles = []\nfor t in range(80):\n    category = CATEGORIES[t // 10]\n    price = int(rng.choice([3990, 4990, 5990, 6990, 7990]))\n    titles.append((t, category, f\"The {WORDS[t % 10]} of {category.title()}\", price))\n\n",
      "note": "Oitenta livros, dez em cada uma de oito categorias, para a lição 2 ter o que recomendar."
    },
    {
      "code": "members, purchases, lines = [], [], []\nfor m in range(1, 5001):\n    joined = FIRST + dt.timedelta(days=int(rng.integers(-365, (LAST - FIRST).days - 30)))\n    if joined >= dt.date(2025, 9, 1):                  # the app arrived in September 2025\n        channel = str(rng.choice([\"store\", \"web\", \"app\"], p=[0.45, 0.2, 0.35]))\n    else:\n        channel = str(rng.choice([\"store\", \"web\"], p=[0.7, 0.3]))\n    age = str(rng.choice(AGES, p=[0.14, 0.27, 0.31, 0.18, 0.10]))\n    home = 6 if channel != \"store\" else int(rng.choice(6, p=[0.27, 0.21, 0.13, 0.16, 0.12, 0.11]))\n",
      "note": "Cada membro recebe uma data de adesão, o canal pelo qual se cadastrou, uma faixa de idade e uma loja de referência. O aplicativo só existe a partir de setembro de 2025, então ninguém antes disso aderiu por ele."
    },
    {
      "code": "    rate = rng.gamma(4.0, 1 / 100)                   # visits a day: one every 25 on average\n    life = 1500 * rng.exponential() * {\"18-24\": 0.5, \"25-34\": 0.8}.get(age, 1.0)\n    if channel == \"app\":\n        life *= 0.6\n    leaves = joined + dt.timedelta(days=int(life))\n    likes = rng.choice(8, size=2, replace=False)       # two favourite categories\n    members.append((m, joined.isoformat(), channel, age, SHOPS[home]))\n\n",
      "note": "Dois números escondidos decidem a vida de um membro: com que frequência ele visita e quanto tempo fica antes de ir embora de vez. Membros jovens e do aplicativo saem antes. **Nenhuma coluna do banco registra nenhum dos dois**, que é a situação de todo modelo real: ele vê o que as pessoas fizeram, nunca o porquê."
    },
    {
      "code": "    day = max(joined, FIRST)\n    while True:\n        day += dt.timedelta(days=int(rng.exponential(1 / rate)) + 1)\n        if day > min(leaves, LAST):\n            break\n        if (day >= RIVAL_OPENS and SHOPS[home] in (\"Paulista\", \"Pinheiros\")\n                and age in (\"18-24\", \"25-34\") and rng.random() < 0.35):\n            break                                      # gone to the rival\n        online = 0.15 + (0.6 if channel != \"store\" else 0) + (0.35 if day >= SHIPPING_FREE else 0)\n        if rng.random() < online:\n            shop = \"Online\"\n        else:\n            shop = SHOPS[home] if home != 6 else SHOPS[int(rng.integers(6))]\n        purchases.append((len(purchases) + 1, m, day.isoformat(), shop))\n        for _ in range(1 + rng.poisson(0.6)):\n            roll = rng.random()\n            category = likes[0] if roll < 0.5 else likes[1] if roll < 0.8 else rng.integers(8)\n            title = titles[int(category) * 10 + int(rng.integers(10))]\n            lines.append((len(purchases), title[0], title[3]))\n\n",
      "note": "Depois as visitas, uma de cada vez, até o membro sair ou a história acabar. Cada visita é numa loja ou online, e tem um ou mais livros, na maioria das duas categorias favoritas do membro."
    },
    {
      "code": "db = sqlite3.connect(\"shop.db\")\ndb.executescript(\"\"\"\nDROP TABLE IF EXISTS members; DROP TABLE IF EXISTS purchases;\nDROP TABLE IF EXISTS lines; DROP TABLE IF EXISTS titles;\nCREATE TABLE members (member_id INTEGER PRIMARY KEY, joined TEXT, channel TEXT,\n                      age_band TEXT, home_shop TEXT);\nCREATE TABLE purchases (purchase_id INTEGER PRIMARY KEY, member_id INTEGER,\n                        day TEXT, shop TEXT);\nCREATE TABLE lines (purchase_id INTEGER, title_id INTEGER, price_cents INTEGER);\nCREATE TABLE titles (title_id INTEGER PRIMARY KEY, category TEXT, title TEXT,\n                     price_cents INTEGER);\nCREATE INDEX purchases_by_member ON purchases (member_id, day);\nCREATE INDEX lines_by_purchase ON lines (purchase_id);\n\"\"\")\n",
      "note": "As tabelas são reescritas toda vez, então rodar duas vezes é seguro. Os dois índices são o que faz a consulta da lição 1 levar um segundo em vez de minutos."
    },
    {
      "code": "kept = {p[0] for p in purchases if p[2] <= until}\ndb.executemany(\"INSERT INTO titles VALUES (?, ?, ?, ?)\", titles)\ndb.executemany(\"INSERT INTO members VALUES (?, ?, ?, ?, ?)\", [r for r in members if r[1] <= until])\ndb.executemany(\"INSERT INTO purchases VALUES (?, ?, ?, ?)\", [r for r in purchases if r[0] in kept])\ndb.executemany(\"INSERT INTO lines VALUES (?, ?, ?)\", [r for r in lines if r[0] in kept])\ndb.commit()\nfor table in (\"members\", \"purchases\", \"lines\", \"titles\"):\n    print(f\"{table:10} {db.execute(f'SELECT count(*) FROM {table}').fetchone()[0]:>7}\")\nprint(\"last day  \", db.execute(\"SELECT max(day) FROM purchases\").fetchone()[0])\n",
      "note": "**Só o que aconteceu até `--until` é escrito.** Os dois anos inteiros são sempre sorteados, então os primeiros meses saem idênticos qualquer que seja a data, e uma rodada posterior só acrescenta a eles."
    }
  ]
}
```

Rode-o de dentro de `~/ml`, com o ambiente ativo:

```
ana@dev:~/ml$ python generate.py
members       4558
purchases    57422
lines        91963
titles          80
last day   2026-02-28
```

**Essas quatro contagens são a verificação de que a sua cópia está certa.** Um programa com uma
linha faltando ainda roda, e sorteia outra loja; se as suas forem diferentes, copie o arquivo de
novo.

## As quatro tabelas

`members` é uma linha por portador do cartão, `purchases` uma linha por visita a um caixa ou ao site,
`lines` uma linha por livro comprado numa visita, e `titles` os oitenta livros. Uma olhada em cada
uma, com o comando `sqlite3` e as opções `-header -column`, que imprimem uma tabela do jeito que uma
pessoa lê:

```
ana@dev:~/ml$ sqlite3 -header -column shop.db "SELECT * FROM members LIMIT 3"
member_id  joined      channel  age_band  home_shop
---------  ----------  -------  --------  ---------
1          2024-09-08  store    25-34     Savassi  
2          2024-11-17  store    25-34     Savassi  
3          2024-11-19  store    35-49     Pinheiros
ana@dev:~/ml$ sqlite3 -header -column shop.db "SELECT * FROM purchases WHERE member_id = 2"
purchase_id  member_id  day         shop   
-----------  ---------  ----------  -------
10           2          2024-11-24  Savassi
11           2          2024-12-23  Online 
12           2          2025-01-03  Savassi
13           2          2025-02-23  Savassi
14           2          2025-04-05  Savassi
15           2          2025-05-21  Online 
16           2          2025-06-13  Savassi
17           2          2025-09-26  Online 
18           2          2025-11-08  Savassi
19           2          2025-11-30  Savassi
20           2          2026-02-25  Savassi
ana@dev:~/ml$ sqlite3 -header -column shop.db "SELECT * FROM lines JOIN titles USING (title_id) WHERE purchase_id = 12"
purchase_id  title_id  price_cents  category  title                   price_cents
-----------  --------  -----------  --------  ----------------------  -----------
12           8         6990         crime     The Lantern of Crime    6990       
12           3         6990         crime     The Winter of Crime     6990       
12           22        6990         literary  The Garden of Literary  6990       
```

Três coisas ali importam para o resto do curso.

**Nada diz se um membro foi embora.** Não há coluna `lapsed` nem data de saída: a loja só vê
visitas, e um membro que parou de vir é idêntico a um que ainda não veio. Todo rótulo deste curso é
*calculado*, a partir do que aconteceu depois de um dia escolhido, e a lição 3 mostra o que dá errado
quando esse cálculo lê um dia além da conta.

**Dinheiro está em centavos**, como inteiro, do jeito que `pipelines-etl` guardava. `price_cents`
5990 é R$ 59,90.

**A última compra é de 28 de fevereiro de 2026.** Esse é o "hoje" das nove primeiras lições. Na
lição 10 você vai rodar o mesmo programa com `--until 2026-06-30`, e chegam mais quatro meses da
mesma loja, sorteados com a mesma semente, então tudo antes de março fica exatamente como está agora.
