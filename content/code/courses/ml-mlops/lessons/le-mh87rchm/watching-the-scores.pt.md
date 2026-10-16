---
title: Observando o que o modelo diz
version: 1
---

A terceira pergunta, o que o modelo está dizendo, não precisa de desfechos. **Ela compara esta noite
com o passado recente**: se o mesmo modelo, alimentado com o mesmo tipo de membro, de repente diz algo
diferente, ou os membros mudaram ou algo entre a loja e o modelo quebrou. Nos dois casos alguém
deveria olhar antes de o marketing mandar a lista.

O lote da lição 8 pontuou uma noite. Uma comparação precisa de um passado, então pontue os quatro
domingos anteriores a partir das fotografias semanais da feature store, como o job teria feito se
já estivesse rodando:

```
ana@dev:~/ml$ for night in 2026-02-01 2026-02-08 2026-02-15 2026-02-22; do python score_batch.py $night; done
3291 members scored as of 2026-02-01 by lapse version 1; 6646 rows in lapse_scores
3300 members scored as of 2026-02-08 by lapse version 1; 9946 rows in lapse_scores
3316 members scored as of 2026-02-15 by lapse version 1; 13262 rows in lapse_scores
3341 members scored as of 2026-02-22 by lapse version 1; 16603 rows in lapse_scores
```

Depois, o vigia. Ele lê as notas e as entradas dos 28 dias antes da noite e compara a noite com
elas. Salve-o como `watch.py`:

```python
"""watch.py: one night's inputs and scores against the four weeks before it.

    python watch.py 2026-02-28      # exits 1 if anything is out of line
"""
import sqlite3
import sys

import pandas as pd

import features
from featurestore import STORE
from project import ROOT

night = sys.argv[1]
WINDOW = (night, night)   # the reference is every snapshot in the 28 days before the night
with sqlite3.connect(STORE) as db:
    inputs = pd.read_sql_query("SELECT * FROM offline WHERE as_of <= ? "
                               "AND as_of >= date(?, '-28 days')", db, params=WINDOW)
with sqlite3.connect(ROOT / "scores.db") as db:
    scores = pd.read_sql_query("SELECT * FROM lapse_scores WHERE cutoff <= ? "
                               "AND cutoff >= date(?, '-28 days')", db, params=WINDOW)

alarms = []


def check(name, before, tonight, low, high):
    """Alarm when tonight is outside low..high times what the reference saw."""
    ok = before * low <= tonight <= before * high
    print(f"{'ok   ' if ok else 'ALARM'} {name:<22} before {before:>9.3f}   tonight {tonight:>9.3f}")
    if not ok:
        alarms.append(name)


ref, now = scores[scores["cutoff"] < night], scores[scores["cutoff"] == night]
if now.empty:
    sys.exit(f"ALARM no scores for {night}: the batch did not run")
check("members scored", ref.groupby("cutoff").size().mean(), len(now), 0.9, 1.1)
check("mean p_lapse", ref["p_lapse"].mean(), now["p_lapse"].mean(), 0.8, 1.25)
check("share over 0.2", (ref["p_lapse"] > 0.2).mean(), (now["p_lapse"] > 0.2).mean(), 0.8, 1.25)

ref, now = inputs[inputs["as_of"] < night], inputs[inputs["as_of"] == night]
for column in features.NUMERIC:
    check(column + " median", ref[column].median(), now[column].median(), 0.5, 2)
for column in features.CATEGORICAL:
    new = set(now[column].dropna()) - set(ref[column].dropna())
    if new:
        print(f"ALARM {column}: values never seen before: {sorted(new)}")
        alarms.append(column)

sys.exit(f"{len(alarms)} alarm(s) for {night}" if alarms else 0)
```

Ele pergunta três coisas às notas e duas às entradas:

- **quantos membros foram pontuados**, contra a média das noites anteriores: uma junção que perdeu
  uma loja em silêncio aparece aqui primeiro;
- **a probabilidade média e a fração acima de 0,2**, o limiar com que o marketing age: um modelo
  alimentado com entradas quebradas raramente falha de forma barulhenta, ele escorrega para dizer
  todo mundo ou ninguém;
- **a mediana de cada entrada numérica**, que pode cair à metade ou dobrar antes de soar o alarme,
  porque a mediana não liga para alguns membros estranhos e só se move quando a maioria se move;
- **qualquer categoria nunca vista antes**, uma loja nova ou um canal escrito errado, que o
  codificador da lição 2 transforma em zeros sem dizer nada.

Os limites, 10% para a contagem, 25% para as notas, metade e dobro para as entradas, são
julgamentos, não leis, e a seção 10 volta a eles. **E o programa sai com status 1 quando algo está
fora da linha**, o que permite a um agendador parar a cadeia e avisar alguém. Nesta noite:

```
ana@dev:~/ml$ python watch.py 2026-02-28; echo "exit status $?"
ok    members scored         before  3312.000   tonight  3355.000
ok    mean p_lapse           before     0.174   tonight     0.174
ok    share over 0.2         before     0.241   tonight     0.243
ok    tenure_days median     before   430.000   tonight   437.000
ok    recency_days median    before    20.000   tonight    20.000
ok    visits_180d median     before     6.000   tonight     5.000
ok    spend_180d median      before 52910.000   tonight 51910.000
ok    basket_avg median      before  9485.000   tonight  9486.000
ok    online_share median    before     0.250   tonight     0.231
ok    shops_180d median      before     2.000   tonight     2.000
exit status 0
```

Dez linhas, todas `ok`, e status de saída 0. Esta noite se parece com as quatro semanas anteriores,
que é como uma noite normal deveria parecer, e é tudo o que o vigia consegue dizer sozinho: ele sabe
que o modelo está dizendo o que costuma dizer, não que o que ele costuma dizer está certo.
