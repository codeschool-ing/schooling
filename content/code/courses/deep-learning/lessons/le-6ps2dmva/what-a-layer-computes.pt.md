---
title: O que uma camada calcula de fato
version: 1
---

Um diagrama de rede desenha círculos ligados por linhas, uma linha por peso, e sugere que as unidades
trabalham uma por uma. **Não trabalham. Uma camada é um produto de matrizes**, para todas as unidades
e todas as entradas de um lote de uma vez, e é por isso que placas de vídeo, que fazem pouco além
disso, treinam redes tão bem.

Dezesseis unidades olhando 64 pixels têm 64 × 16 pesos. Arrume-os numa matriz `W`, com uma linha por
pixel e uma coluna por unidade, ponha cinco imagens nas linhas de `x`, e `x @ W` é uma matriz 5 por
16: linha *i*, coluna *j* é a imagem *i* vista pela unidade *j*. Some o viés de cada unidade e aplique
a ativação a cada elemento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Um lote de 5 linhas de 64 números é multiplicado por uma matriz de pesos de 64 linhas e 16 colunas, o viés de 16 é somado a cada linha, e o resultado são 5 linhas de 16 números, às quais o ReLU é aplicado elemento a elemento.\"><rect x=\"20\" y=\"80\" width=\"200\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M20 92 L220 92\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M20 104 L220 104\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M20 116 L220 116\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M20 128 L220 128\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">x  (5 × 64)</text><text x=\"120\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">um lote de 5 imagens</text><text x=\"120\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">64 números cada</text><text x=\"245\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">@</text><rect x=\"270\" y=\"30\" width=\"90\" height=\"160\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"315\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">W  (64 × 16)</text><text x=\"315\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">pesos</text><text x=\"315\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">64 entradas × 16 unidades</text><text x=\"385\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">+</text><rect x=\"405\" y=\"103\" width=\"90\" height=\"14\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">b  (16)</text><text x=\"520\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">=</text><rect x=\"545\" y=\"80\" width=\"90\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><path d=\"M545 92 L635 92\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M545 104 L635 104\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M545 116 L635 116\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M545 128 L635 128\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"590\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">z  (5 × 16)</text><text x=\"590\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">16 saídas cada</text><text x=\"590\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">depois ReLU, elemento a elemento</text></svg>", "caption": "Uma camada, um produto de matrizes: cada imagem do lote vezes os pesos de cada unidade, numa única operação."}
```

Salve como `~/dl/layer.py`:

```schooling-example
{
  "language": "python",
  "file": "layer.py",
  "parts": [
    {
      "code": "\"\"\"layer: what one layer does to a batch of five digits.\"\"\"\nimport numpy as np\n\nimport digits\n\n(x, y), _, _ = digits.load()\nbatch = x[:5]\nrng = np.random.default_rng(0)\nW = rng.normal(0, 0.1, (64, 16))\nb = np.zeros(16)",
      "note": "Dezesseis unidades, cada uma com 64 pesos, um por pixel. Empilhados, os pesos são uma matriz 64 por 16 e os vieses um vetor de 16. Começam pequenos e aleatórios, que é de onde o treinamento também parte."
    },
    {
      "code": "z = batch @ W + b\nh = np.maximum(0, z)\nprint(\"batch\", batch.shape, \" W\", W.shape, \" b\", b.shape, \" z\", z.shape, \" h\", h.shape)\nprint(\"parameters:\", W.size + b.size)",
      "note": "A camada inteira são estas duas linhas: um produto de matrizes para todas as unidades e todas as imagens de uma vez, depois ReLU em cada elemento. `b` é somado a cada linha, o que o NumPy chama de broadcasting."
    },
    {
      "code": "print(\"first image, first four units:\", np.round(h[0, :4], 3))\nprint(\"units at zero in the batch:\", int((h == 0).sum()), \"of\", h.size)",
      "note": "Quantas saídas o ReLU zerou. Uma unidade em zero para uma imagem não diz nada sobre ela, e isso é normal."
    },
    {
      "code": "# Two layers with no activation between them are one layer in disguise.\nW2 = rng.normal(0, 0.1, (16, 10))\ntwo = (batch @ W) @ W2\none = batch @ (W @ W2)\nprint(\"two linear layers equal one:\", np.allclose(two, one), \" merged W\", (W @ W2).shape)",
      "note": "Produtos de matrizes são associativos: `(x W) W2` é `x (W W2)`. Sem uma função entre elas, uma segunda camada acrescenta parâmetros e nenhuma capacidade."
    }
  ]
}
```

```
ana@vm:~/dl$ python layer.py
batch (5, 64)  W (64, 16)  b (16,)  z (5, 16)  h (5, 16)
parameters: 1040
first image, first four units: [0.    0.    0.053 0.034]
units at zero in the batch: 52 of 80
two linear layers equal one: True  merged W (64, 10)
```

**Os formatos são a primeira coisa a conferir em qualquer rede**, e a maioria dos erros que você vai
encontrar no PyTorch é um formato que não bateu. `(5, 64) @ (64, 16)` funciona porque os números de
dentro concordam, e o resultado fica com os de fora. A camada tem 64 × 16 + 16 = 1.040 parâmetros, o
número que um framework imprime quando descreve um modelo.

52 das 80 saídas são zero. Com pesos aleatórios, mais ou menos metade das somas sai negativa e o ReLU
as corta, então uma saída esparsa é o estado esperado de uma camada nova, não um defeito.

**A última linha é a razão de as ativações existirem.** `(x @ W) @ W2` e `x @ (W @ W2)` são iguais, e
`W @ W2` é uma única matriz 64 por 10. Uma pilha de camadas sem nada entre elas calcula uma função
linear, qualquer que seja a profundidade, e uma função linear só desenha a única reta em que o
perceptron estava preso. O ReLU entre duas camadas é o que impede o produto de se fundir.
