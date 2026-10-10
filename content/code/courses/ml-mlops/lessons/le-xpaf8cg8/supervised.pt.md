---
title: Aprendizado supervisionado, com respostas já conhecidas
version: 1
---

**Aprendizado supervisionado é aprender com exemplos que vêm com a resposta.** Cada linha é um membro
descrito em números, e ao lado dele a coisa que lhe aconteceu depois. O trabalho do algoritmo é
encontrar uma função dos números para a resposta que acerte o máximo possível nas linhas que recebeu,
na esperança de que continue acertando nas linhas que não recebeu.

A esperança é a parte interessante, e a palavra *supervisionado* a esconde. O supervisor não é uma
pessoa; é o passado. Só dá para supervisionar com respostas que você já tem, então **todo modelo
supervisionado aprende de uma época em que o desfecho já acabou**, e depois é usado numa época em que
ele não acabou. Tudo o que dá errado entre essas duas épocas é o assunto das lições 3 e 10.

## Os exemplos

O primeiro programa transforma a loja em exemplos. Salve-o em `~/ml` como `features.py`; todos os
programas seguintes da lição o importam.

```schooling-example
{
  "language": "python",
  "file": "features.py",
  "parts": [
    {
      "code": "\"\"\"features.py: one row per active member as of a cutoff day, and whether they lapsed.\n\nA member is active at the cutoff if they bought something in the 180 days\nbefore it, and lapsed if they then bought nothing in the 90 days after it.\n\"\"\"\nimport sqlite3\n\nimport pandas as pd\n\n",
      "note": "As definições sobre as quais o curso inteiro roda. **Ativo** quer dizer que comprou algo nos 180 dias até o corte; **afastado** (`lapsed`) quer dizer que não comprou nada nos 90 dias depois dele."
    },
    {
      "code": "QUERY = \"\"\"\nWITH recent AS (\n  SELECT p.member_id, p.day, p.shop,\n         (SELECT sum(price_cents) FROM lines l WHERE l.purchase_id = p.purchase_id) AS cents\n  FROM purchases p\n  WHERE p.day > date(:cutoff, '-180 days') AND p.day <= :cutoff\n)\n",
      "note": "`recent` é cada visita nos 180 dias até `:cutoff`, com quanto custou. Só membros com alguma linha aqui aparecem no resultado, e é isso que os torna ativos."
    },
    {
      "code": "SELECT m.member_id, m.channel, m.age_band, m.home_shop,\n       julianday(:cutoff) - julianday(m.joined)        AS tenure_days,\n       julianday(:cutoff) - julianday(max(r.day))      AS recency_days,\n       count(*)                                        AS visits_180d,\n       sum(r.cents)                                    AS spend_180d,\n       avg(r.cents)                                    AS basket_avg,\n       avg(r.shop = 'Online')                          AS online_share,\n       count(DISTINCT r.shop)                          AS shops_180d,\n",
      "note": "Os atributos: um número por membro, cada um calculado com dias até o corte, nunca depois dele."
    },
    {
      "code": "       NOT EXISTS (SELECT 1 FROM purchases f WHERE f.member_id = m.member_id\n                   AND f.day > :cutoff AND f.day <= date(:cutoff, '+90 days')) AS lapsed\nFROM members m JOIN recent r USING (member_id)\nGROUP BY m.member_id\n\"\"\"\n\n",
      "note": "O rótulo, e a única linha que lê o futuro: uma compra nos 90 dias depois do corte. **Para um corte de menos de 90 dias atrás o futuro ainda não acabou**, e esta linha responde 1 para membros que só não tiveram tempo de voltar. A lição 3 é sobre isso."
    },
    {
      "code": "NUMERIC = [\"tenure_days\", \"recency_days\", \"visits_180d\", \"spend_180d\", \"basket_avg\",\n           \"online_share\", \"shops_180d\"]\nCATEGORICAL = [\"channel\", \"age_band\", \"home_shop\"]\n\n\ndef build(cutoff, path=\"shop.db\"):\n    with sqlite3.connect(path) as db:\n        return pd.read_sql_query(QUERY, db, params={\"cutoff\": cutoff})\n",
      "note": "Duas listas que os programas seguintes usam para escolher colunas, e a única função que eles chamam. Um corte é uma data em texto, `2025-09-30`."
    }
  ]
}
```

**Um corte é o dia em relação ao qual os exemplos são descritos.** Tudo à esquerda dele vira
atributo, tudo nos 90 dias à direita vira rótulo. Escolha 30 de setembro de 2025, e os 90 dias
depois dele acabaram em 29 de dezembro, muito antes do último dia do banco: todo rótulo é conhecido.

## O modelo

Agora o aprendizado. Salve isto como `supervised.py`:

```python
"""supervised.py: learn who lapses, from members whose outcome is already known."""
from sklearn.linear_model import LogisticRegression

import features

COLUMNS = ["recency_days", "visits_180d", "spend_180d"]

past = features.build("2025-09-30")   # the 90 days after this cutoff are history
model = LogisticRegression(max_iter=1000).fit(past[COLUMNS], past["lapsed"])
print(f"learned from {len(past)} members; {past['lapsed'].mean():.1%} of them lapsed")

now = features.build("2025-11-30")    # two months later: other members, other days
now["p_lapse"] = model.predict_proba(now[COLUMNS])[:, 1].round(2)
riskiest = now.sort_values("p_lapse", ascending=False).head(5)
print(riskiest[["member_id", *COLUMNS, "p_lapse", "lapsed"]].to_string(index=False))
```

`LogisticRegression` é um dos algoritmos de aprendizado mais antigos e ainda um dos mais usados: ele
encontra um peso por atributo e transforma a soma ponderada deles numa probabilidade entre 0 e 1.
**`fit` é o treino**; ele lê os exemplos de 30 de setembro. **`predict_proba` é a predição**; ela é
perguntada sobre os membros como estavam em 30 de novembro, dois meses depois, que o modelo nunca
viu. O desfecho real deles aparece ao lado do palpite, porque para um corte tão antigo o banco já o
conhece.

```
ana@dev:~/ml$ python supervised.py
learned from 2940 members; 17.0% of them lapsed
 member_id  recency_days  visits_180d  spend_180d  p_lapse  lapsed
      1670         178.0            1        9980     0.86       1
      1470         179.0            1        6990     0.86       1
      1569         178.0            1        3990     0.86       1
      3022         179.0            1        9980     0.86       1
       418         179.0            1       12980     0.86       1
```

Leia as colunas de uma linha. O membro 1670 não visitava havia 178 dias, tinha vindo uma vez em seis
meses, e o modelo lhe deu 0,86. Ele não voltou. Os cinco no topo da lista têm todos uma recência
perto de 180 dias, a beira do que conta como ativo, e uma visita: o modelo aprendeu que quanto mais
tempo desde a última visita, mais provável que o membro tenha ido embora, que é o que uma pessoa
teria adivinhado.

**O que uma pessoa não teria adivinhado é o número.** A regra da primeira seção, "120 dias quer
dizer afastado", diz sim ou não. O modelo diz 0,86 para esses cinco e algo menor para o membro com
recência de 150 e quatro visitas, e a lição 4 mostra que uma probabilidade é o que permite ao time de
marketing escolher quantos vouchers mandar.

Duas palavras para depois. **Classificação** é aprendizado supervisionado em que a resposta é uma
categoria, como esta. **Regressão** é aprendizado supervisionado em que a resposta é uma quantidade,
como quanto um membro vai gastar no mês que vem. A lição 2 faz as duas.
