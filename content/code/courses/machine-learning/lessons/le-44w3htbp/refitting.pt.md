---
title: Reajustando, e o que isso conserta
version: 1
---

No dia 1º de março, janeiro e fevereiro têm respostas. São 8.614 linhas a mais, 174 delas no plano
mensal, e o bastante para tentar a resposta óbvia: ajustar de novo o pipeline da aula 15 em tudo o que se
sabe, gravá-lo ao lado do antigo e comparar os dois em março, que nenhum dos dois viu. Salve isto como
`refit.py`:

```python
# refit.py
import pandas as pd
from sklearn.metrics import roc_auc_score

import stored
from churn_model import build
from feira import CREDIT, KEPT, SAVED, load_churn, net_value

labels = pd.read_csv("data/churn_2026_labels.csv")
known = pd.read_csv("data/churn_2026.csv").merge(labels, on=["customer_id", "snapshot"])
earlier = pd.read_csv("data/churn.csv").drop(columns="cancel_reason")
pd.concat([earlier, known[known["snapshot"] < "2026-03-01"]]).to_csv("train_2026-02.csv", index=False)
history = load_churn("train_2026-02.csv")
stored.save(build().fit(history, history["churned"]), "churn-2026-02", "train_2026-02.csv", history)

march = load_churn("data/churn_2026.csv").merge(labels.astype({"snapshot": "datetime64[s]"}))
march = march[march["snapshot"] == "2026-03-01"]
left = march["churned"]
monthly = march["plan"] == "monthly"
rival = march["city"].isin(["Curitiba", "Belo Horizonte"])
print(f"March 2026: {len(march):,} subscribers")
print("model          AUC    chance  monthly plan  Curitiba + BH  credits  net value")
for name in ["churn-2025-12", "churn-2026-02"]:
    model, _ = stored.load(name)
    chance = pd.Series(model.predict_proba(march)[:, 1], index=march.index)
    send = chance >= CREDIT / (SAVED * KEPT)
    print(f"{name}  {roc_auc_score(left, chance):.3f}  {chance.mean():.3f}  {chance[monthly].mean():12.3f}"
          f"  {chance[rival].mean():13.3f}  {send.sum():7}  R$ {net_value(left, send):,.0f}")
print(f"what happened         {left.mean():.3f}  {left[monthly].mean():12.3f}  {left[rival].mean():13.3f}")
```

A tabela de treino é gravada em `train_2026-02.csv` antes de ser usada, para a impressão digital da
ficha nova ser exatamente das linhas com que o modelo aprendeu. O `cancel_reason` sai porque as linhas de
2026 não o têm, e a aula 4 já mostrou que ele nunca pode chegar a um modelo. O modelo novo ganha um nome
novo, **`churn-2026-02`**, e o arquivo antigo fica intocado: se o novo se mostrar pior, voltar é carregar
outro nome.

```
ana@lab:~/ml$ python refit.py
March 2026: 4,540 subscribers
model          AUC    chance  monthly plan  Curitiba + BH  credits  net value
churn-2025-12  0.788  0.065         0.106          0.058      180  R$ 1,296
churn-2026-02  0.790  0.058         0.070          0.054      157  R$ 2,072
what happened         0.056         0.068          0.073
```

Leia coluna por coluna, contra a última linha.

- **A AUC mal se mexeu**, de 0,788 para 0,790. A ordenação nunca foi o problema.
- **O nível geral foi consertado**: 0,058 contra os 0,056 que saíram. Dois meses de dados mais calmos o
  puxaram para baixo.
- **O plano mensal foi consertado**: 0,070 contra 0,068. Com 174 linhas com resposta ele tem uma coluna
  própria, e o artefato sumiu.
- **Curitiba e Belo Horizonte não**, e agora estão mais longe: 0,054 contra 0,073. Dois meses de
  concorrente são uma parte pequena de vinte meses de histórico em que essas cidades se comportaram como as
  outras, e o nível geral baixou para todos, elas incluídas.
- **Os créditos renderam mais**, R$ 2.072 contra R$ 1.296, com 23 a menos enviados. Isso é um mês, e o
  bootstrap da aula 2 daria a ele um intervalo largo; as colunas de calibração são a evidência mais firme.

**Reajustar consertou o que os dados conseguiam ver e deixou o que não conseguiam.** O plano mensal era
uma lacuna nos dados, e dados a preencheram. O concorrente é uma mudança no mundo que as colunas não
descrevem, e mais linhas das mesmas colunas só o descrevem devagar. Os caminhos adiante não são só técnicos. O negócio pode fornecer uma coluna, *um
concorrente entrega nesta cidade desde este mês*. Os meses recentes podem pesar mais, pelos pesos de
amostra do modelo, o que custa estabilidade em todo o resto. E, enquanto isso se decide, uma pessoa pode
ser avisada de que o modelo subestima duas cidades, com um orçamento de crédito para elas definido à mão. As três são decisões de quem é dono do crédito. A parte do
modelo é tornar o erro visível, por grupo, todo mês.

O `churn-2026-02` é o melhor modelo para março, em toda medida que não é ruído, e é ele que deve ser
carregado a partir de abril. Isso é a troca de uma palavra no `monthly.py`, e uma linha nova no registro
de qual modelo pontuou qual mês.
