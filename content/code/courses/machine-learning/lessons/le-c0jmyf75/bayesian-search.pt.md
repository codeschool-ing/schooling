---
title: Busca bayesiana, que aprende onde procurar
version: 1
---

A grade e a busca aleatória escolhem todo candidato sem olhar os resultados até ali. A **busca
bayesiana** olha. Depois de cada ajuste, ela monta um modelo da própria nota, um palpite de quão bom
seria cada ajuste ainda não testado, com uma incerteza junto, e escolhe o próximo ajuste onde esse
modelo diz que a melhora é mais provável. Regiões boas são refinadas; regiões inexploradas são
visitadas quando a incerteza delas é grande o bastante para valer a pena.

Bibliotecas fazem isso bem, entre elas o Optuna e o scikit-optimize, e o curso não instala nenhuma
porque a ideia cabe em umas quarenta linhas com o que o scikit-learn já tem. O modelo da nota é um
**processo gaussiano**, e a regra para escolher o próximo ponto é a **melhora esperada**. Dois
hiperparâmetros são buscados, a taxa de aprendizado e o número de folhas, com os mesmos 18 ajustes das
outras duas buscas. Salve isto como `bayes_search.py`:

```schooling-example
{
  "language": "python",
  "file": "bayes_search.py",
  "parts": [
    {
      "code": "# bayes_search.py\nimport numpy as np\nfrom scipy.stats import norm\nfrom sklearn.gaussian_process import GaussianProcessRegressor\nfrom sklearn.gaussian_process.kernels import Matern, WhiteKernel\nfrom sklearn.model_selection import cross_val_score\n\nfrom feira import by_time, load_churn\nfrom tuning import FEATURES, booster, time_folds, value_per_thousand\n\ntrain, _ = by_time(load_churn())\nfolds = list(time_folds(train))\n",
      "note": "As mesmas partes, nota e modelo de toda outra busca aqui, do `tuning.py`."
    },
    {
      "code": "\ndef settings(point):\n    \"\"\"A point in [0, 1] x [0, 1] as a learning rate from 0.01 to 0.5 and 4 to 64 leaves.\"\"\"\n    return {\"learning_rate\": round(float(10 ** (-2 + 1.7 * point[0])), 3),\n            \"max_leaf_nodes\": int(round(4 * 16 ** point[1])), \"max_iter\": 150}\n\n\ndef score(point):\n    return cross_val_score(booster(**settings(point)), train[FEATURES], train[\"churned\"],\n                           cv=folds, scoring=value_per_thousand).mean()\n",
      "note": "**Dois botões, mapeados num quadrado unitário.** A taxa vai de 0,01 a 0,5 em escala logarítmica e as folhas de 4 a 64, para um passo do mesmo tamanho em qualquer ponto do quadrado ser uma mudança da mesma proporção."
    },
    {
      "code": "\nrng = np.random.default_rng(0)\ntried = list(rng.random((5, 2)))                     # five points at random to start\nscores = [score(p) for p in tried]",
      "note": "Cinco ajustes ao acaso, para a busca ter algo com que aprender."
    },
    {
      "code": "for step in range(13):\n    kernel = Matern(length_scale=0.25, nu=2.5) + WhiteKernel(noise_level=0.1)\n    gp = GaussianProcessRegressor(kernel, optimizer=None, normalize_y=True).fit(tried, scores)",
      "note": "**O substituto.** Um processo gaussiano é ajustado às notas até agora: um palpite suave da nota em todo o quadrado, com uma incerteza pequena perto dos pontos testados e grande longe deles. A suavidade fica fixa aqui; uma biblioteca a ajustaria."
    },
    {
      "code": "    candidates = rng.random((2000, 2))\n    mean, sd = gp.predict(candidates, return_std=True)\n    gain = mean - max(scores)                        # expected improvement over the best so far\n    z = gain / np.maximum(sd, 1e-9)\n    improvement = gain * norm.cdf(z) + sd * norm.pdf(z)\n    nxt = candidates[np.argmax(improvement)]\n    tried.append(nxt)\n    scores.append(score(nxt))\nbest = int(np.argmax(scores))\nprint(f\"{len(scores)} settings tried; best {scores[best]:.0f} at try {best + 1}: {settings(tried[best])}\")\nprint(\"scores in the order tried:\", \" \".join(f\"{s:.0f}\" for s in scores))",
      "note": "**Melhora esperada.** Para 2.000 candidatos ao acaso, quanto se espera que cada um supere a melhor nota até agora, contando tanto um palpite alto quanto uma incerteza larga. O candidato com mais é o próximo ajustado. Esse equilíbrio faz a busca explorar terreno novo e também refinar o terreno bom."
    }
  ]
}
```

```
ana@lab:~/ml$ python bayes_search.py
18 settings tried; best 846 at try 14: {'learning_rate': 0.124, 'max_leaf_nodes': 4, 'max_iter': 150}
scores in the order tried: 697 556 301 618 583 658 820 807 795 819 808 810 591 846 646 782 804 680
```

**O melhor ajuste tira R$ 846 por mil linhas**, com taxa de 0,124 e 4 folhas, as menores árvores que a
faixa permite. Leia as notas na ordem em que foram testadas: os cinco começos ao acaso vão de 301 a
697, e **o segundo ponto que a busca escolheu tirou 820**, melhor que qualquer coisa que a busca
aleatória achou em 18 tentativas. A busca aprendeu com cinco ajustes que árvores pequenas e uma taxa
moderada eram promissoras, e foi direto para lá.

Ela também continuou olhando em outros lugares: as tentativas 13, 15 e 18 caem para entre 591 e 680,
que é a busca gastando ajustes em regiões de que não tinha certeza. Isso não é desperdício. Uma busca
que nunca explora se acomoda na primeira região boa que acha.

## Quando vale a pena

A busca bayesiana se paga quando cada ajuste é caro, um minuto ou uma hora, de modo que pensar onde
procurar custa menos que ajustar ao acaso. Aqui um ajuste leva um segundo, e a vantagem dela sobre a
busca aleatória é real mas pequena. Ela também traz ajustes próprios, a suavidade do palpite e quanto
explorar, e por isso uma biblioteca madura é a melhor escolha para trabalho de verdade, e este
programa é a explicação do que uma biblioteca dessas faz.
