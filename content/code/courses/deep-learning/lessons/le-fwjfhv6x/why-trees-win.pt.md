---
title: Why trees win on tables
version: 1
---

The cancer table is friendly to a linear model. Most business tables are not: **what decides the
outcome is a rule with a threshold**, a contract type, a tariff band, a limit somebody set, and
several columns that turn out to mean nothing at all. The program below generates a table with that
shape, so the rules are known and the scores can be read against them. Save it as `~/dl/table.py`:

```schooling-example
{
  "language": "python",
  "file": "table.py",
  "parts": [
    {
      "code": "\"\"\"table: a made-up customer table with the shape most business data has.\"\"\"\nimport numpy as np\n\n# The columns, in order: tenure, charge, calls, contract, age, noise1 to noise5.",
      "note": "Dez colunas: meses como cliente, a conta mensal, chamados de suporte no ano, o tipo de contrato, a idade e cinco colunas de puro ruído. Tabelas reais carregam colunas que não significam nada, e ninguém sabe de antemão quais."
    },
    {
      "code": "def make(n=3000, seed=0):\n    rng = np.random.default_rng(seed)\n    tenure = rng.integers(0, 73, n)\n    charge = rng.uniform(20, 120, n).round(2)\n    calls = rng.poisson(1.5, n)\n    contract = rng.integers(0, 3, n)\n    age = rng.integers(18, 80, n)\n    noise = rng.normal(size=(n, 5))",
      "note": "Cada coluna na sua própria escala: meses até 72, dinheiro de 20 a 120, uma contagem pequena, um código 0, 1 ou 2 para contratos mensais, anuais e de dois anos."
    },
    {
      "code": "    leaves = ((contract == 0) & (tenure < 24)) | ((calls >= 3) & (charge > 70)) \\\n        | ((contract == 0) & (age > 65) & (charge > 100))",
      "note": "Quem sai é decidido por regras com limiares: clientes novos em contrato mensal, quem ligou três vezes e paga mais de 70, clientes mais velhos pagando mais de 100 num plano mensal. É assim que uma regra de negócio, uma tarifa ou uma política moldam dados reais."
    },
    {
      "code": "    flipped = rng.random(n) < 0.1\n    y = (leaves ^ flipped).astype(np.int64)\n    X = np.column_stack([tenure, charge, calls, contract, age, noise]).astype(np.float64)\n    return X, y",
      "note": "Um rótulo em cada dez é trocado ao acaso, então nenhum modelo pode ser perfeito; algo perto de 0,9 é o teto."
    }
  ]
}
```

The rules make about one customer in four leave, and the random flips cap any model near 0.9. Run
the same bench on it. Save as `~/dl/churn.py`:

```schooling-example
{
  "language": "python",
  "file": "churn.py",
  "parts": [
    {
      "code": "\"\"\"churn: the made-up customer table through the same three models.\"\"\"\nimport bench\nimport table\n\nX, y = table.make()\nprint(X.shape[0], \"rows,\", X.shape[1], \"columns,\", f\"{y.mean():.0%} left\")\nbench.run(X, y)",
      "note": "O mesmo `bench.py`, então as mesmas dobras, os mesmos três modelos e o mesmo relógio, em 3.000 clientes gerados."
    }
  ]
}
```

```
PENDING churn
```

**Boosting reaches 0.883, within a couple of points of the ceiling, and the other two stall near
0.80.** A model that always answered "stays" would score 0.76, so logistic regression and the
network have each found only a small part of the rules. The worst folds tell the same story: boosting
0.877, the other two below 0.79. The network is again the slowest, at 4.40 seconds against
boosting's 0.82.

## Three reasons, each a property of the table

In 2022 Léo Grinsztajn, Edouard Oyallon and Gaël Varoquaux compared trees and networks on 45 tabular
data sets of about ten thousand rows each, including networks designed for tables, and asked why the
trees kept winning. **Their three answers are visible in `table.py`.**

**The target is irregular.** Whether a customer leaves jumps at 24 months, at three calls, at a bill
of 70. A tree places a split at exactly such a value and is done. A network builds its answer from
sums of ReLUs, which bend a little at a time, and approximating a sharp step and an `and` of two
thresholds takes many units and many examples. Networks are biased towards smooth functions, which is
a strength on images and a handicap here.

**Half the columns are noise.** A tree tries a split on each column, finds that `noise3` never
helps, and leaves it alone. The network gives every column a weight into each of its 64 first-layer
units, and it has to learn to set those 320 weights to nothing from 2,400 training rows, which leaves
room to fit the noise instead.

**Each column means something on its own.** Months, money and a contract code are not
interchangeable. A tree looks at one column at a time. A network's first layer mixes all ten into
weighted sums before anything else happens, which is the right move for pixels, where any
combination of neighbours may matter, and the wrong one for a table, where the columns were chosen by
somebody who knew what each one meant.

None of this says a network cannot reach 0.88 here. It could be tuned: more units, dropout
(lesson 7), a different rate (lesson 5), a search over all of them (`machine-learning` lesson 9).
**Every one of those is an afternoon, and boosting got 0.883 with its defaults.** That is the
comparison that matters on a working day.
