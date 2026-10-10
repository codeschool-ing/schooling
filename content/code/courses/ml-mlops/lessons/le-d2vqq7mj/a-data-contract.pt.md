---
title: Um contrato de dados que o conjunto de treino precisa cumprir
version: 1
---

Um modelo treinado com linhas quebradas é um modelo quebrado com uma boa nota, então **o conjunto de
treino é verificado antes que qualquer coisa aprenda com ele**, por uma etapa cujo único trabalho é
dizer sim ou não. As verificações são um **contrato de dados**: o que quem modela e a plataforma
combinaram que as linhas seriam. Salve isto como `validate.py`:

```python
"""validate.py: the checks a training set must pass before anything learns from it.

    python validate.py data/train.csv
"""
import sys

import pandas as pd

import features
from project import ROOT

path = ROOT / sys.argv[1]
rows = pd.read_csv(path)
problems = []

expected = ["cutoff", "member_id", *features.CATEGORICAL, *features.NUMERIC, "lapsed"]
if sorted(rows.columns) != sorted(expected):
    problems.append(f"columns differ: {sorted(set(rows.columns) ^ set(expected))}")
if rows["member_id"].duplicated().any():
    problems.append(f"{rows['member_id'].duplicated().sum()} members appear twice")
if rows["cutoff"].nunique() != 1:
    problems.append("more than one cutoff in one file")
for column in features.NUMERIC:
    if rows[column].isna().any():
        problems.append(f"{column} has {rows[column].isna().sum()} empty values")
    if (rows[column] < 0).any():
        problems.append(f"{column} is negative for {(rows[column] < 0).sum()} members")
if not rows["lapsed"].isin([0, 1]).all():
    problems.append("lapsed holds something other than 0 and 1")
if not 0.05 <= rows["lapsed"].mean() <= 0.35:
    problems.append(f"{rows['lapsed'].mean():.1%} lapsed, outside the 5% to 35% ever seen")
if len(rows) < 1000:
    problems.append(f"only {len(rows)} rows")

if problems:
    print(f"{sys.argv[1]}: REFUSED")
    for p in problems:
        print("  -", p)
    sys.exit(1)
print(f"{sys.argv[1]}: {len(rows)} rows, every check passed")
```

Cada verificação é uma frase com que alguém concordou:

| verificação | o que ela teria pegado |
| --- | --- |
| exatamente estas colunas | um atributo renomeado na origem, ou um novo que ninguém pediu |
| uma linha por membro | uma junção que multiplicou linhas, duplicando alguns membros |
| um corte por arquivo | arquivos de dois meses concatenados por engano |
| nenhum número vazio ou negativo | a recência da tabela de resumo da lição 3, que ficou negativa |
| o rótulo é 0 ou 1 | uma coluna de rótulo que chegou como texto |
| entre 5% e 35% afastados | rótulos inacabados, que chegaram a 65,5% na lição 3 |
| pelo menos 1.000 linhas | uma tabela de origem que carregou meio dia |

**A faixa do rótulo é a que precisa de uma pessoa.** 5% a 35% é mais largo do que qualquer coisa que
esta loja mostrou; está lá para pegar um rótulo quebrado, não uma mudança real nos membros, e a lição
10 é sobre distinguir as duas coisas.

```
ana@dev:~/ml$ python validate.py data/train.csv
data/train.csv: 2863 rows, every check passed
ana@dev:~/ml$ python validate.py data/test.csv
data/test.csv: 3130 rows, every check passed
ana@dev:~/ml$ python -c "import pandas as pd; r = pd.read_csv('data/train.csv'); r.loc[:9, 'recency_days'] -= 200; pd.concat([r, r.head(5)]).to_csv('data/broken.csv', index=False)"
ana@dev:~/ml$ python validate.py data/broken.csv; echo "exit status $?"
data/broken.csv: REFUSED
  - 5 members appear twice
  - recency_days is negative for 15 members
exit status 1
```

Os dois arquivos reais passam. O terceiro é quebrado de propósito pelo programa de uma linha antes
dele: a recência de dez membros empurrada 200 dias para o negativo, e cinco linhas copiadas no fim. A
contagem diz 15 negativos porque as cinco cópias eram de linhas quebradas. **A etapa o recusa e diz
cada motivo**, e o status de saída dela é 1, que é o que vai parar um pipeline antes do treino.

Uma verificação que falha deve ser lida antes de ser afrouxada. A correção errada mais comum para um
contrato que falha é alargar a faixa até as linhas passarem; a certa começa por descobrir o que mudou
nos dados.
