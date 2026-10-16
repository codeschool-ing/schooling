---
title: Poucos dados
version: 1
---

Os dígitos são onde as redes se deram bem neste curso: a CNN da aula 11 chegou a 0,978 no conjunto
de validação. **Isso com 1.077 imagens de treino.** A pergunta desta seção é o que acontece com a
classificação quando há muito menos, que é o caso normal de um problema novo: uma empresa começando a
rotular os próprios documentos tem vinte deles, não mil.

O programa treina três modelos com 2, 5 e 20 imagens de cada dígito, e depois com as 1.077:
regressão logística, a MLP da aula 9, do seu `mlp.py`, e a CNN da aula 11, do `cnn.py`. Ele precisa
desses dois arquivos, do `tdigits.py` e do `loop.py` da aula 9 e do `digits.py` da aula 1 ao lado.
Salve como `~/dl/small.py`:

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
ana@vm:~/dl$ python small.py
images   logistic   MLP     CNN
    20   0.764      0.761   0.717
    50   0.861      0.842   0.786
   200   0.922      0.922   0.928
  1077   0.967      0.950   0.978
```

A última linha é uma conferência: 0,950 e 0,978 são os resultados das aulas 9 e 11, com a mesma
receita e a mesma semente. As linhas acima dela são a descoberta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 340\" role=\"img\" aria-label=\"Acurácia de validação contra o número de imagens de treino, 20, 50, 200 e 1.077, para três modelos. A regressão logística está à frente com 20 e 50 imagens. A CNN é a última com 20 e 50 e a primeira com 200 e 1.077. A MLP fica perto da regressão logística o tempo todo e termina abaixo dela.\"><path d=\"M90 290 L530 290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 290 L90 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 290.0 L530 290.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"290.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.7</text><path d=\"M90 206.6666666666666 L530 206.6666666666666\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"206.6666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M90 123.33333333333331 L530 123.33333333333331\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"123.33333333333331\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.9</text><path d=\"M90 40.0 L530 40.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0</text><text x=\"90.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"188.84219987169183\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">50</text><text x=\"338.38467537239444\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><text x=\"520.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1,077</text><text x=\"305.0\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">imagens de treino (escala log)</text><text x=\"80\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">acurácia de validação</text><path d=\"M90.0 236.7 L188.8 155.8 L338.4 105.0 L520.0 67.5\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"90.0\" cy=\"236.66666666666663\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"188.84219987169183\" cy=\"155.83333333333331\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"338.38467537239444\" cy=\"104.99999999999994\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><circle cx=\"520.0\" cy=\"67.50000000000003\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"538\" y=\"67.50000000000003\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">logistic</text><path d=\"M90.0 239.2 L188.8 171.7 L338.4 105.0 L520.0 81.7\" stroke=\"var(--paper-dim)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"239.16666666666663\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></circle><circle cx=\"188.84219987169183\" cy=\"171.66666666666669\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></circle><circle cx=\"338.38467537239444\" cy=\"104.99999999999994\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></circle><circle cx=\"520.0\" cy=\"81.66666666666669\" r=\"4\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></circle><text x=\"538\" y=\"93.66666666666669\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">MLP</text><path d=\"M90.0 275.8 L188.8 218.3 L338.4 100.0 L520.0 58.3\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"275.8333333333333\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"188.84219987169183\" cy=\"218.33333333333326\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"338.38467537239444\" cy=\"99.99999999999994\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"520.0\" cy=\"58.33333333333334\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"538\" y=\"46.33333333333334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">CNN</text></svg>", "caption": "Os mesmos três modelos em quatro tamanhos de conjunto de treino, desenhados a partir das acurácias impressas. As linhas se cruzam entre 50 e 200 imagens."}
```

**Com 20 imagens, a CNN fica em último, 4,7 pontos atrás da regressão logística**, e com 50 fica 7,5
pontos atrás. Com 200 ela está à frente, por 0,006, que são duas imagens das 360, e com as 1.077
lidera por 1,1 ponto. As linhas se cruzam em algum lugar entre 50 e 200 imagens.

A razão é a quantidade de coisas que cada modelo precisa aprender. A regressão logística sobre 64
pixels e 10 classes tem 650 pesos; a CNN tem 38.282. Vinte imagens não conseguem fixar 38.282
números, e com 1.020 passos sobre as mesmas vinte a CNN tem toda chance de decorá-las, que é o
assunto da aula 7. **Um modelo com mais parâmetros precisa de mais dados antes que a capacidade
extra valha alguma coisa**, e antes desse ponto o modelo mais simples não é um meio-termo, é o
modelo melhor.

A MLP também merece uma olhada. Ela nunca vence a regressão logística nesses dígitos: 0,761 contra
0,764, 0,842 contra 0,861, empate com 200, e 0,950 contra 0,967 com tudo. Uma camada oculta de 32
unidades lhe deu mais para aprender e nada que ela pudesse usar.

A resposta do próprio deep learning para poucos dados não é treinar do zero. A aula 13 treinou um
corpo em outros dígitos e deu à tarefa nova só uma cabeça nova, e a aula 17 fez o ajuste fino dele.
**Com um modelo pré-treinado num conjunto grande, uma rede consegue aprender com vinte exemplos**,
porque a maior parte do que ela precisa foi aprendida em outro lugar. Sem um, como aqui, vinte
exemplos ficam com o modelo que tem menos números a ajustar.
