---
title: Pontuando um arquivo que o modelo nunca viu
version: 1
---

De volta ao pedido que quebrou o `by_hand.py`: chances para todo assinante do `churn_2026.csv`. Com o
modelo num objeto só, o programa é curto. Desta vez o modelo é ajustado em **todo** o `churn.csv`, de
julho de 2024 a dezembro de 2025, porque os meses de teste já cumpriram sua função: mediram o modelo, e
agora são a evidência mais recente que existe, inclusive os meses depois do aumento de preço. Salve isto
como `score_2026.py`:

```python
# score_2026.py
from churn_model import build
from feira import CREDIT, KEPT, SAVED, load_churn

history = load_churn()
new = load_churn("data/churn_2026.csv")
model = build().fit(history, history["churned"])
new["chance"] = model.predict_proba(new)[:, 1]
new["send"] = new["chance"] >= CREDIT / (SAVED * KEPT)
summary = new.groupby(["snapshot", "plan"], observed=True).agg(
    subscribers=("chance", "size"), mean_chance=("chance", "mean"), credits=("send", "sum"))
print(summary.round(3).to_string())
```

O `churn_2026.csv` não tem a coluna `churned`, já que ninguém sabe ainda quem vai sair, e o pipeline não
precisa dela: o `ColumnTransformer` só lê as colunas que recebeu.

```
ana@lab:~/ml$ python score_2026.py
                        subscribers  mean_chance  credits
snapshot   plan                                          
2026-01-01 fortnightly         1898        0.051       43
           weekly              2328        0.070      111
2026-02-01 fortnightly         1904        0.052       52
           monthly              174        0.111       10
           weekly              2310        0.072      111
2026-03-01 fortnightly         1912        0.054       61
           monthly              322        0.106       20
           weekly              2306        0.068       99
```

**O plano mensal foi pontuado sem reclamação.** Ele aparece a partir de fevereiro, 174 assinantes e
depois 322, e o `OneHotEncoder` lhe deu zeros em toda coluna de plano, como o `encoders.py` mostrou na
aula 14. As chances dele ainda diferem dos outros planos, cerca de 0,11 contra 0,05 e 0,07, porque o
modelo lê o resto de cada linha: são pessoas que entraram há semanas, e pouco tempo de casa é um dos
sinais mais fortes que ele tem. Que colunas fizeram mais é a pergunta da aula 19. Se essas chances estão
certas, nenhum programa sabe dizer em março de 2026, porque as respostas ainda não aconteceram.

Vale dizer isso com todas as letras, porque é a situação de todo modelo em produção. **Em dados novos o
modelo é medido pelo tempo, não por um conjunto de teste**: os rótulos de janeiro chegam em fevereiro, e
só então alguém sabe quão boas eram as chances de janeiro. O `churn_2026_labels.csv` guarda essas
respostas, e a aula 22 as compara com esta tabela. Até lá, duas coisas já valem um olhar: um plano que o
modelo nunca viu é uma parte da população que ele conhece menos, e uma parte de créditos por mês que muda
de repente é uma pergunta a fazer antes de alguém agir.
