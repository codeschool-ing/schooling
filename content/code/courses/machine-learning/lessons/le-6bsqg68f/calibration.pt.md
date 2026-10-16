---
title: Calibrando um modelo que distorce
version: 1
---

Quando a distorção é do próprio modelo, ela tem conserto. A **calibração** ajusta um segundo modelo,
pequeno, que lê a chance do primeiro e devolve uma honesta, aprendida em linhas com que o primeiro
modelo não treinou. O scikit-learn tem dois tipos:

- **sigmoid**, também chamada de escala de Platt, ajusta às chances a curva em S da aula 5. São dois
  números, então ela precisa de poucos dados, e só sabe esticar e deslocar.
- **isotonic** ajusta qualquer curva que só sobe. Ela conserta qualquer distorção que mantenha a
  ordem, e precisa de mais linhas para fazer isso sem aprender ruído.

Para ver uma em ação, ajuda ter um modelo que distorce. **`class_weight="balanced"` faz o modelo
tratar cada pessoa que sai como se fosse umas dezesseis**, o que a aula 13 usa de propósito e o que
infla toda chance que ele dá. O programa abaixo treina um modelo simples e um com pesos nos meses até
março de 2025, guarda abril a junho para calibrar e então manda créditos nos meses de teste no corte
de equilíbrio. Salve isto como `calibrate.py`:

```python
# calibrate.py
from sklearn.calibration import CalibratedClassifierCV
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.frozen import FrozenEstimator

from feira import CATEGORICAL, CREDIT, KEPT, NUMERIC, SAVED, by_time, load_churn, net_value

features = NUMERIC + CATEGORICAL
train, test = by_time(load_churn())
early = train[train["snapshot"] < "2025-04-01"]
late = train[train["snapshot"] >= "2025-04-01"]

def booster(**settings):
    model = HistGradientBoostingClassifier(categorical_features="from_dtype", random_state=0,
                                           **settings)
    return model.fit(early[features], early["churned"])

plain, weighted = booster(), booster(class_weight="balanced")
models = {"plain": plain, "weighted": weighted}
for method in ["sigmoid", "isotonic"]:
    calibrator = CalibratedClassifierCV(FrozenEstimator(weighted), method=method)
    models[f"weighted, {method}"] = calibrator.fit(late[features], late["churned"])

cut = CREDIT / (SAVED * KEPT)
print(f"April to June: {late['churned'].mean():.3f} of rows cancelled")
print("model                chance on April to June   sent in test   net value")
for name, model in models.items():
    print(f"{name:20} {model.predict_proba(late[features])[:, 1].mean():23.3f}", end="")
    send = model.predict_proba(test[features])[:, 1] >= cut
    print(f" {send.sum():14,}   R$ {net_value(test['churned'], send):9,.0f}")
```

`FrozenEstimator` avisa ao `CalibratedClassifierCV` que o modelo já está ajustado e não deve ser
ajustado de novo; aí ele aprende só a correção, com as linhas que recebe.

```
ana@lab:~/ml$ python calibrate.py
April to June: 0.052 of rows cancelled
model                chance on April to June   sent in test   net value
plain                                  0.054            713   R$    18,856
weighted                               0.307          9,645   R$  -215,016
weighted, sigmoid                      0.052            636   R$    17,760
weighted, isotonic                     0.052            381   R$    13,848
```

Leia a segunda coluna primeiro. De abril a junho, 5,2% das linhas cancelaram. **O modelo simples disse
5,4%, honesto o bastante**, o que confirma a seção anterior: antes do aumento de preço, as chances dele
queriam dizer o que diziam. O modelo com pesos disse 30,7%, seis vezes demais, e no corte de equilíbrio
mandou 9.645 créditos e perdeu R$ 215.016. Mesmas colunas, mesmas árvores, quase a mesma ordenação;
só o nível estava errado, e o nível é o que um corte lê.

As duas calibrações o trazem de volta a 5,2% e de volta a dar dinheiro. Nenhuma vence o modelo
simples, e esse é o resultado de costume: **a calibração conserta uma distorção, ela não acrescenta
informação.** A isotônica faz pior que a sigmoide, porque três meses tinham só 559 pessoas que saíram,
e uma curva livre para tomar qualquer forma aprende parte do ruído delas. O modelo simples também tinha
uma vantagem fácil de não ver. Ele não precisou de meses reservados, enquanto as duas calibrações
tiveram de abrir mão de abril a junho, que num projeto de verdade seriam dados de treino.

Três regras saem daqui:

- **Calibre quando o modelo distorce**: pesos de classe, reamostragem (aula 13) e alguns algoritmos que
  sabidamente distorcem, como naive Bayes e máquinas de vetores de suporte. Confira com o
  `reliability.py` antes; um modelo de boosting como este costuma já estar perto.
- **Calibre em linhas que o modelo nunca viu**, mais tarde no tempo do que as de onde ele aprendeu,
  pelo mesmo motivo de toda nota deste curso.
- **A calibração não conserta o problema de setembro.** A calibração aprende com abril a junho, e abril
  a junho também eram antes do aumento.
