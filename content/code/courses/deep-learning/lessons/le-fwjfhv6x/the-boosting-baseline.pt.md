---
title: A linha de base do boosting, rodada primeiro
version: 1
---

A aula 2 de `machine-learning` defendeu a linha de base: a regra trivial que um modelo precisa
superar antes que a nota dele queira dizer alguma coisa. **Numa tabela, a linha de base que vale a
pena superar não é a regra trivial. É o gradient boosting com os padrões**, porque é barato, raramente
perde por muito, e as duas seções anteriores o mostraram vencendo de vez. Uma rede numa tabela tem de
conquistar o lugar contra esse número, e o número precisa existir antes.

Então a receita, na ordem em que se roda:

1. **A classe majoritária.** O piso. Um modelo que não a supera não aprendeu nada.
2. **Um modelo linear sobre colunas padronizadas.** Barato, legível, e numa tabela como a de câncer,
   difícil de vencer.
3. **O `HistGradientBoostingClassifier` com os padrões, na tabela do jeito que veio.** Sem escala,
   sem preencher valores faltantes, sem codificar categorias além de dizer quais colunas elas são.
4. **As mesmas dobras para todos**, e a métrica que corresponde ao custo de cada tipo de erro, que é
   o assunto da aula 10 de `machine-learning`. Aqui se usa acurácia porque as classes não estão longe
   do equilíbrio e os dois erros custam o mesmo.

Só depois disso uma rede ganha a sua vez, e ela precisa superar o passo 3 por mais que a dispersão
entre dobras, ou entre sementes, a medida que a aula 18 ensinou.

O "do jeito que veio" do terceiro passo merece uma demonstração, porque tabelas reais têm buracos. O
programa abaixo roda a receita sobre os clientes do `table.py` depois de apagar um quinto das contas
mensais. Salve como `~/dl/baseline.py`:

```schooling-example
{
  "language": "python",
  "file": "baseline.py",
  "parts": [
    {
      "code": "\"\"\"baseline: the runs to make on any table before a network is considered.\"\"\"\nimport textwrap\nimport time\n\nimport numpy as np\nfrom sklearn.dummy import DummyClassifier\nfrom sklearn.ensemble import HistGradientBoostingClassifier\nfrom sklearn.impute import SimpleImputer\nfrom sklearn.linear_model import LogisticRegression\nfrom sklearn.model_selection import StratifiedKFold, cross_val_score\nfrom sklearn.pipeline import make_pipeline\nfrom sklearn.preprocessing import StandardScaler\nfrom threadpoolctl import threadpool_limits\n\nimport table\n\nthreadpool_limits(1)"
    },
    {
      "code": "X, y = table.make()\ngone = np.random.default_rng(1).random(len(y)) < 0.2\nX[gone, 1] = np.nan",
      "note": "Um quinto das contas mensais é apagado, do jeito que uma coluna chega de um sistema real: `NaN` onde alguém nunca preencheu."
    },
    {
      "code": "folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)\ncandidates = {\n    \"majority class\": DummyClassifier(),\n    \"logistic regression\": make_pipeline(StandardScaler(), LogisticRegression()),\n    \"logistic, imputed\": make_pipeline(SimpleImputer(), StandardScaler(), LogisticRegression()),\n    \"gradient boosting\": HistGradientBoostingClassifier(random_state=0),\n}",
      "note": "A receita em quatro linhas: a resposta trivial, um modelo linear, o mesmo modelo linear com os buracos preenchidos pela média da coluna, e o boosting na tabela do jeito que veio."
    },
    {
      "code": "for name, model in candidates.items():\n    start = time.perf_counter()\n    try:\n        scores = cross_val_score(model, X, y, cv=folds, error_score=\"raise\")\n    except ValueError as error:\n        reason = str(error).splitlines()[1].split(\". \")[:2]\n        print(f\"{name:20s} refused:\")\n        print(textwrap.fill(\". \".join(reason) + \".\", 72, initial_indent=\"    \", subsequent_indent=\"    \"))\n        continue\n    print(f\"{name:20s} accuracy {scores.mean():.3f}  worst fold {scores.min():.3f}  \"\n          f\"{time.perf_counter() - start:5.2f} s\")",
      "note": "`error_score=\"raise\"` faz um modelo que não consegue treinar dizer por quê, em vez de pontuar `nan` e seguir em frente. As duas primeiras frases do motivo são impressas."
    }
  ]
}
```

```
ana@vm:~/dl$ python baseline.py
majority class       accuracy 0.759  worst fold 0.758   0.02 s
logistic regression  refused:
    LogisticRegression does not accept missing values encoded as NaN
    natively. For supervised learning, you might want to consider
    sklearn.ensemble.HistGradientBoostingClassifier and Regressor which
    accept missing values encoded as NaNs natively.
logistic, imputed    accuracy 0.797  worst fold 0.775   0.07 s
gradient boosting    accuracy 0.867  worst fold 0.858   1.38 s
```

**A regressão logística recusa a tabela de cara**, e a própria mensagem do scikit-learn nomeia o
modelo que não recusaria: o gradient boosting deste mesmo programa. Preencher cada buraco com a média
da coluna a deixa rodar, com 0,797. O boosting aceitou os buracos como estavam e chegou a 0,867,
contra 0,883 na tabela completa da seção anterior. Ele aprende, em cada corte, para que lado vão os
valores faltantes, e assim um buraco vira informação em vez de erro.

O `HistGradientBoostingClassifier` tem a mesma ideia de duas bibliotecas que você vai encontrar no
código dos outros: **XGBoost e LightGBM**, os nomes de sempre para gradient boosting em produção. As
duas constroem árvores sobre colunas agrupadas em faixas do mesmo jeito, a versão do scikit-learn foi
inspirada no LightGBM, e qualquer uma pode substituí-la no passo 3. Nenhuma está instalada no
ambiente deste curso, então nenhuma roda aqui; a aula 8 de `machine-learning` trata delas.

A receita inteira levou menos de dois segundos. **Uma linha de base tão barata não tem desculpa para
ser pulada**, e uma rede que não a supera já disse algo que vale saber antes de gastar a primeira
época.
