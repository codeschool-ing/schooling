---
title: Um classificador treinado
version: 1
---

Vizinhos mais próximos e centroides comparam vetores inteiros, e num produto escalar cada uma das
384 coordenadas pesa o mesmo. Um **classificador treinado** aprende quais direções do espaço separam
os setores e dá peso a elas. O embedding vira uma lista de 384 **atributos** (*features*), a
entrada que um modelo clássico espera, e o modelo por cima dela pode ser bem pequeno.

## Regressão logística sobre os vetores

O `LogisticRegression` do scikit-learn aprende, para cada setor, um peso por coordenada e uma
constante. A nota de um ticket novo para um setor é a soma ponderada das coordenadas mais a
constante, e as cinco notas viram probabilidades que somam 1.

```schooling-example
{
  "language": "python",
  "file": "trained.py",
  "parts": [
    {
      "code": "import time\nimport numpy as np\nfrom sklearn.linear_model import LogisticRegression\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")",
      "note": "Os vetores são a entrada e os rótulos são as respostas. Não precisa de mais nada."
    },
    {
      "code": "t0 = time.perf_counter()\nmodel = LogisticRegression(max_iter=1000).fit(Xtr, ytr)\nprint(f\"trained in {(time.perf_counter() - t0) * 1000:.0f} ms\")\nprint(\"weights:\", model.coef_.shape, \"+\", model.intercept_.shape)",
      "note": "`fit` aprende os pesos. `max_iter` aumenta o número de passos que o otimizador pode dar, para que ele termine em vez de parar com um aviso. Imprime quanto tempo levou e o formato do que foi aprendido."
    },
    {
      "code": "pred = model.predict(Xte)\nprint((pred == yte).sum(), \"of\", len(yte), \"right\")",
      "note": "`predict` dá um rótulo por ticket de teste."
    },
    {
      "code": "i = [t[\"id\"] for t in test].index(\"t027\")\nprint(test[i][\"text\"])\nfor label, p in zip(model.classes_, model.predict_proba(Xte[i:i + 1])[0]):\n    print(f\"  {label:9} {p:.3f}\")",
      "note": "`predict_proba` dá, para um ticket, uma probabilidade por setor, na ordem de `model.classes_`."
    }
  ]
}
```

```
ana@lab:~/emb$ python trained.py
trained in 11 ms
weights: (5, 384) + (5,)
47 of 50 right
I was charged for delivery twice on one order that came in two boxes.
  account   0.069
  ebooks    0.042
  payments  0.388
  returns   0.132
  shipping  0.368
```

**O modelo inteiro é uma tabela de 5 × 384 pesos e cinco constantes**, 1.925 números, e o treino
levou o tempo que a primeira linha imprimiu. A parte pesada, ler a língua, o modelo de embedding fez
antes de o treino começar; o classificador só aprende onde traçar linhas entre pontos que já estão
arrumados por significado.

E ele acertou **47 de 50, exatamente o que os centroides acertaram**. Isso contradiz uma imagem que
vale nomear: a de que um modelo treinado tem de vencer os métodos que não aprendem nada. Não tem, e
aqui não vence, por dois motivos visíveis nos dados. Os vetores do MiniLM já põem estes cinco
setores em lugares diferentes, então sobra pouco para um peso corrigir; e 20 exemplos por setor não
são muitos para aprender 384 pesos cada.

## Quando o treino compensa

O jeito de descobrir é mudar as condições e medir. `fewer.py` fica com os primeiros 1, 2, 3, 5, 10
ou 20 tickets de treino de cada setor e roda os três métodos com cada um. Depois repete tudo com o
WordLlama, o modelo estático da aula 1, cujos vetores são menos nítidos:

```schooling-example
{
  "language": "python",
  "file": "fewer.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom sklearn.linear_model import LogisticRegression\nfrom wordllama import WordLlama\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")\nlabels = sorted(set(ytr))\nwl = WordLlama.load()\ntexts = lambda rows: [t[\"text\"] for t in rows]\nmodels = {\"minilm\": (Xtr, Xte),\n          \"wordllama\": (wl.embed(texts(train), norm=True), wl.embed(texts(test), norm=True))}\n\ndef scores(A, y, B):\n    C = np.array([A[y == label].mean(axis=0) for label in labels])\n    C /= np.linalg.norm(C, axis=1, keepdims=True)\n    knn = y[(B @ A.T).argmax(axis=1)]\n    cen = np.array(labels)[(B @ C.T).argmax(axis=1)]\n    lr = LogisticRegression(max_iter=1000).fit(A, y).predict(B)\n    return [(p == yte).sum() for p in (knn, cen, lr)]\n\nprint(\"model      per label   1-nn  centroid  logistic\")\nfor name, (A, B) in models.items():\n    for n in (1, 2, 3, 5, 10, 20):\n        keep = np.concatenate([np.flatnonzero(ytr == label)[:n] for label in labels])\n        k1, cen, lr = scores(A[keep], ytr[keep], B)\n        print(f\"{name:10} {n:>9} {k1:>6} {cen:>9} {lr:>9}\")",
      "note": "Os dois modelos transformam os mesmos tickets; os vetores do WordLlama são calculados aqui e os do MiniLM vêm dos arquivos gravados. `scores` roda os três métodos com um conjunto de treino e conta os acertos no conjunto de teste inteiro. O laço fica com os `n` primeiros tickets de cada setor, então toda execução usa o mesmo subconjunto e nada é sorteado."
    }
  ]
}
```

```
ana@lab:~/emb$ python fewer.py
model      per label   1-nn  centroid  logistic
minilm             1     37        37        37
minilm             2     36        36        36
minilm             3     35        39        39
minilm             5     36        40        40
minilm            10     40        45        44
minilm            20     46        47        47
wordllama          1     32        32        35
wordllama          2     37        39        36
wordllama          3     35        37        37
wordllama          5     40        40        41
wordllama         10     42        40        43
wordllama         20     40        42        44
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Dois gráficos de linhas lado a lado, acertos em 50 tickets de teste contra o número de tickets de treino mantidos por setor: 1, 2, 3, 5, 10 e 20. À esquerda, com vetores do all-MiniLM-L6-v2: os três métodos começam juntos em 37, o vizinho mais próximo nunca fica acima dos outros dois, e centroides e regressão logística terminam em 47. À direita, com vetores do WordLlama: tudo fica mais baixo, as linhas se cruzam várias vezes, e com 20 por setor a regressão logística lidera com 44, os centroides têm 42 e o vizinho mais próximo 40.\"><text x=\"205\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><path d=\"M70 280 L340 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L70 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L340 280\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M70 225 L340 225\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"225\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">35</text><path d=\"M70 170 L340 170\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><path d=\"M70 115 L340 115\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">45</text><path d=\"M70 60 L340 60\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><text x=\"85\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"133\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"181\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"229\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"277\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"325\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M85.0 203.0 L133.0 214.0 L181.0 225.0 L229.0 214.0 L277.0 170.0 L325.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"85\" cy=\"203\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"133\" cy=\"214\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"181\" cy=\"225\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"229\" cy=\"214\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"277\" cy=\"170\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"325\" cy=\"104\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><path d=\"M85.0 203.0 L133.0 214.0 L181.0 181.0 L229.0 170.0 L277.0 115.0 L325.0 93.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"81\" y=\"199\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"129\" y=\"210\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"177\" y=\"177\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"166\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"273\" y=\"111\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"321\" y=\"89\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M85.0 203.0 L133.0 214.0 L181.0 181.0 L229.0 170.0 L277.0 126.0 L325.0 93.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"85\" cy=\"203\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"133\" cy=\"214\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"181\" cy=\"181\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"229\" cy=\"170\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"277\" cy=\"126\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"325\" cy=\"93\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"205\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tickets de treino por setor</text><text x=\"545\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">WordLlama</text><path d=\"M410 280 L680 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 280 L410 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 280 L680 280\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M410 225 L680 225\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"225\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">35</text><path d=\"M410 170 L680 170\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><path d=\"M410 115 L680 115\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">45</text><path d=\"M410 60 L680 60\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><text x=\"425\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"473\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"521\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"569\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"617\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"665\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M425.0 258.0 L473.0 203.0 L521.0 225.0 L569.0 170.0 L617.0 148.0 L665.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"425\" cy=\"258\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"473\" cy=\"203\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"521\" cy=\"225\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"569\" cy=\"170\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"617\" cy=\"148\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"665\" cy=\"170\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><path d=\"M425.0 258.0 L473.0 181.0 L521.0 203.0 L569.0 170.0 L617.0 170.0 L665.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"421\" y=\"254\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"469\" y=\"177\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"517\" y=\"199\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"565\" y=\"166\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"613\" y=\"166\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"661\" y=\"144\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M425.0 225.0 L473.0 214.0 L521.0 203.0 L569.0 159.0 L617.0 137.0 L665.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"425\" cy=\"225\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"473\" cy=\"214\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"521\" cy=\"203\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"569\" cy=\"159\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"617\" cy=\"137\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"665\" cy=\"126\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"545\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tickets de treino por setor</text><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">acertos em 50</text><path d=\"M70 338 L77 338\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M87 338 L94 338\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"82\" cy=\"338\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"102\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 vizinho mais próximo</text><path d=\"M290 338 L297 338\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M307 338 L314 338\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"298\" y=\"334\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"322\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">centroides</text><path d=\"M450 338 L457 338\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M467 338 L474 338\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"462\" cy=\"338\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"482\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">regressão logística</text></svg>", "caption": "Acertos em 50 conforme o conjunto de treino encolhe, para os três métodos que aprendem com rótulos. Com os vetores do MiniLM as linhas ficam próximas e terminam juntas; com os do WordLlama, a regressão logística termina na frente. Cada degrau são poucos tickets, e por isso nenhuma linha é suave."}
```

Três leituras, cada uma de uma linha dessa tabela.

**Com vetores mais fracos, o treino vale mais.** Com os vetores do WordLlama e 20 por setor, o
vizinho mais próximo acerta 40, os centroides 42 e a regressão logística 44. Onde o espaço é menos
arrumado, aprender quais direções importam recupera parte do que o embedding perdeu.

**Com pouquíssimos exemplos, a média vence o vizinho único.** Com o MiniLM e 3 por setor, o vizinho
mais próximo acerta 35 e os centroides 39. Um exemplo pode ser atípico; a média de três já suaviza
isso.

**Nenhuma das curvas é suave.** O vizinho mais próximo com o MiniLM acerta 37 com um exemplo por
setor e 36 com dois, porque o segundo exemplo, por acaso, puxou alguns tickets para o lado errado.
Com 50 tickets de teste, cada degrau da tabela são uns poucos tickets, e a próxima seção é sobre
quanto uns poucos tickets significam.

## Uma probabilidade é um motivo para perguntar

As últimas linhas de `trained.py` mostram o que o modelo acha de **t027**, *I was charged for
delivery twice on one order that came in two boxes* ("cobraram a entrega duas vezes num pedido que
veio em duas caixas"). Pagamentos fica com 0,388 e entrega com 0,368: o modelo está quase dividido
ao meio, e diz isso. O k-NN e os centroides respondem com um rótulo e mais nada.

Essa divisão é útil. Uma fila pode mandar para uma pessoa, em vez de para um setor, todo ticket cuja
maior probabilidade seja baixa. O quanto é baixo tem de ser medido nos seus próprios dados, do mesmo
jeito que a aula 6 define o limite de uma anomalia. Uma probabilidade de 0,388 deste modelo é uma
ordem da confiança dele, e não uma promessa de que ele acerta 38,8% das vezes.

Regressão logística é uma escolha entre muitas. Qualquer classificador que recebe uma tabela de
números recebe embeddings, e escolher, ajustar e validar um deles é o que o curso `machine-learning`
ensina. O que pertence a este curso é a observação por baixo: **o embedding fez a parte cara uma
vez, e todo classificador por cima dele é barato.**
