---
title: Little data
version: 1
---

The digits are where networks have done well in this course: lesson 11's CNN reached 0.978 on the
validation set. **That was with 1,077 training images.** The question this section asks is what
happens to the ranking when there are far fewer, which is the normal case for a new problem: a
company starting to label its own documents has twenty of them, not a thousand.

The program trains three models with 2, 5 and 20 images of each digit, and then with all 1,077:
logistic regression, lesson 9's MLP from its `mlp.py`, and lesson 11's CNN from `cnn.py`. It needs
those two files, the `tdigits.py` and `loop.py` from lesson 9 and the `digits.py` from lesson 1
beside it. Save it as `~/dl/small.py`:

```schooling-example
{
  "language": "python",
  "file": "small.py",
  "parts": [
    {
      "code": "\"\"\"small: logistic regression, lesson 9's MLP and lesson 11's CNN, given 2, 5, 20 or all the images of each digit.\"\"\"\nimport torch\nfrom sklearn.linear_model import LogisticRegression\nfrom threadpoolctl import threadpool_limits\n\nimport cnn\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\ntorch.set_num_threads(1)\nthreadpool_limits(1)\n\n(x, y), val, _ = tdigits.load()\nval_images = (val[0].reshape(-1, 1, 8, 8), val[1])",
      "note": "O conjunto de validação é sempre o das 360 imagens inteiro, então toda linha da tabela é julgada na mesma prova. Só o conjunto de treino encolhe."
    },
    {
      "code": "def first(per_class):\n    \"\"\"The first `per_class` training images of each digit, or all of them.\"\"\"\n    if per_class is None:\n        return torch.arange(len(y))\n    return torch.cat([torch.nonzero(y == d).flatten()[:per_class] for d in range(10)])",
      "note": "O mesmo número de cada dígito, para que um conjunto pequeno nunca fique sem uma classe por azar. `None` quer dizer as 1.077 inteiras."
    },
    {
      "code": "def net(make, xs, ys, v, steps=1020):\n    torch.manual_seed(0)\n    model = make()\n    batches = -(-len(ys) // 32)\n    loop.fit(model, torch.optim.SGD(model.parameters(), lr=0.1), (xs, ys), v,\n             epochs=steps // batches, every=10**9)\n    return loop.evaluate(model, *v)[1]",
      "note": "A receita da aula 9, SGD a 0,1 em lotes de 32, e o mesmo número de passos qualquer que seja o tamanho: 1.077 imagens são 34 lotes, e 30 épocas delas são 1.020 passos. Vinte imagens formam um lote, então recebem 1.020 épocas, e nenhuma rede perde por ter sido parada cedo."
    },
    {
      "code": "print(\"images   logistic   MLP     CNN\")\nfor per_class in (2, 5, 20, None):\n    i = first(per_class)\n    xs, ys = x[i], y[i]\n    logistic = LogisticRegression(max_iter=5000).fit(xs.numpy(), ys.numpy())\n    lr_acc = logistic.score(val[0].numpy(), val[1].numpy())\n    mlp_acc = net(make_mlp, xs, ys, val)\n    cnn_acc = net(cnn.make_cnn, xs.reshape(-1, 1, 8, 8), ys, val_images)\n    print(f\"{len(ys):6d}   {lr_acc:.3f}      {mlp_acc:.3f}   {cnn_acc:.3f}\")",
      "note": "As mesmas imagens vão para os três. A CNN as recebe como grades 1 por 8 por 8, os outros dois como filas de 64."
    }
  ]
}
```

```
PENDING small
```

The last row is a check: 0.950 and 0.978 are lesson 9's and lesson 11's results, from the same
recipe and the same seed. The rows above it are the finding.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 340\" role=\"img\" aria-label=\"Acurácia de validação contra o número de imagens de treino, 20, 50, 200 e 1.077, para três modelos. A regressão logística está à frente com 20 e 50 imagens. A CNN é a última com 20 e 50 e a primeira com 200 e 1.077. A MLP fica perto da regressão logística o tempo todo e termina abaixo dela.\"><text x=\"320\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">PENDING</text></svg>", "caption": "Os mesmos três modelos em quatro tamanhos de conjunto de treino, desenhados a partir das acurácias impressas. As linhas se cruzam entre 50 e 200 imagens."}
```

**With 20 images, the CNN is last, 4.7 points behind logistic regression**, and with 50 it is 7.5
points behind. At 200 it is ahead, by 0.006, which is two images of the 360, and with all 1,077 it
leads by 1.1 points. The lines cross somewhere between 50 and 200 images.

The reason is the number of things each model has to learn. Logistic regression on 64 pixels and 10
classes has 650 weights; the CNN has 38,282. Twenty images cannot pin down 38,282 numbers, and with
1,020 steps on the same twenty the CNN has every chance to memorise them, which is lesson 7's
subject. **A model with more parameters needs more data before its extra capacity is
worth anything**, and before that point the simpler model is not a compromise, it is the better
model.

The MLP is worth a look as well. It never beats logistic regression on these digits: 0.761 against
0.764, 0.842 against 0.861, a tie at 200, and 0.950 against 0.967 with everything. A hidden layer of
32 units gave it more to learn and nothing it could use.

Deep learning's own answer to little data is not to train from nothing. Lesson 13 trained a body on
other digits and gave the new task only a new head, and lesson 17 fine-tuned it. **With a model
pretrained on a large set, a network can learn from twenty examples**, because most of what it needs
was learnt somewhere else. Without one, as here, twenty examples go to the model with the fewest
numbers to fit.
