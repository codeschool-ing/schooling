---
title: O laço de treino, escrito uma vez
version: 1
---

Toda aula daqui até o fim treina por dois módulos pequenos, do jeito que as aulas 5 a 8 treinaram
pelo `fit.py`. **Eles são curtos de propósito**: um laço de treino tem umas vinte linhas, e uma
biblioteca que as esconde esconde as cinco que decidem se o treino funciona.

O primeiro transforma os dígitos da aula 1 em tensores. Salve-o como `~/dl/tdigits.py`:

```schooling-example
{
  "language": "python",
  "file": "tdigits.py",
  "parts": [
    {
      "code": "\"\"\"tdigits: lesson 1's digits as PyTorch tensors, flat for a dense network or as 1x8x8 images.\"\"\"\nimport torch\n\nimport digits",
      "note": "Os dígitos divididos pelo `digits.py` da aula 1, então as mesmas 1.077, 360 e 360 imagens, agora como tensores."
    },
    {
      "code": "def load(images=False, seed=0):\n    \"\"\"Train, validation and test sets as (inputs, labels) pairs of tensors.\"\"\"\n    sets = []\n    for x, y in digits.load(seed):\n        x = torch.from_numpy(x)\n        if images:\n            x = x.reshape(-1, 1, 8, 8)\n        sets.append((x, torch.from_numpy(y)))\n    return sets",
      "note": "O `from_numpy` divide a memória com os arrays, então nada é copiado. `images=True` dispõe cada linha de 64 como um canal de 8 por 8, o formato que uma convolução lê na aula 11; uma rede densa recebe as linhas planas."
    }
  ]
}
```

O segundo é o próprio laço, com uma avaliação ao lado. Salve-o como `~/dl/loop.py`:

```schooling-example
{
  "language": "python",
  "file": "loop.py",
  "parts": [
    {
      "code": "\"\"\"loop: the PyTorch training loop every lesson from 9 on runs, written out once.\"\"\"\nimport torch\nimport torch.nn.functional as F",
      "note": "O `torch.nn.functional`, importado como `F`, guarda as operações que não têm pesos próprios, a perda entre elas."
    },
    {
      "code": "def evaluate(model, x, y):\n    \"\"\"Mean loss and accuracy on a whole set, in evaluation mode and without gradients.\"\"\"\n    model.eval()\n    with torch.no_grad():\n        logits = model(x)\n        loss = F.cross_entropy(logits, y).item()\n        acc = (logits.argmax(dim=1) == y).float().mean().item()\n    model.train()\n    return loss, acc",
      "note": "O `model.eval()` passa as camadas que se comportam diferente no treino, como dropout e normalização em lote, para o comportamento de avaliação, e o `torch.no_grad()` desliga o registro. O `.item()` transforma um tensor de um número num float do Python. O modelo volta ao modo de treino antes de retornar."
    },
    {
      "code": "def fit(model, opt, train, val, epochs, batch_size=32, seed=0, every=1):\n    \"\"\"Shuffle, cut into batches, one optimiser step per batch; report every `every` epochs.\"\"\"\n    x, y = train\n    g = torch.Generator().manual_seed(seed)\n    history = []\n    model.train()\n    for epoch in range(1, epochs + 1):\n        order = torch.randperm(len(y), generator=g)\n        total = 0.0\n        for start in range(0, len(y), batch_size):\n            idx = order[start:start + batch_size]\n            loss = F.cross_entropy(model(x[idx]), y[idx])\n            opt.zero_grad()\n            loss.backward()\n            opt.step()\n            total += loss.item() * len(idx)\n        val_loss, val_acc = evaluate(model, *val)\n        history.append((epoch, total / len(y), val_loss, val_acc))\n        if epoch % every == 0:\n            print(f\"epoch {epoch:3d}  train loss {total / len(y):.4f}  \"\n                  f\"val loss {val_loss:.4f}  val acc {val_acc:.3f}\")\n    return history",
      "note": "O mesmo formato do `fit.py` da aula 5: embaralha com um gerador de semente fixa, corta em lotes de 32, um passo por lote. Dentro, as cinco linhas que todo laço de treino do PyTorch tem: passo para a frente e perda, `zero_grad` para esvaziar o `.grad` de cada parâmetro, `backward` para preenchê-los, `step` para mover os pesos. O total acumulado usa `.item()`, então guarda um número e não um tensor com seu registro preso."
    }
  ]
}
```

## As cinco linhas

Dentro do laço de lotes do `fit` ficam as linhas que todo programa de treino em PyTorch tem, em
alguma arrumação:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 210\" role=\"img\" aria-label=\"As cinco linhas de um passo de treino como um ciclo, com o que cada uma muda: o passo para a frente constrói o registro de operações, a perda reduz o lote a um número, o zero_grad esvazia o .grad de cada parâmetro, o backward os preenche a partir do registro, e o step move os pesos usando o .grad. Depois, o lote seguinte recomeça no passo para a frente.\"><rect x=\"10\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"71.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">logits = model(x)</text><text x=\"71.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">constrói o registro</text><path d=\"M132 75 L146 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M138.6 78.1 L146 75 L138.6 71.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"148\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"209.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">F.cross_entropy(…)</text><text x=\"209.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">um número</text><path d=\"M270 75 L284 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M276.6 78.1 L284 75 L276.6 71.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"286\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"347.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">opt.zero_grad()</text><text x=\"347.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">esvazia todo .grad</text><path d=\"M408 75 L422 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M414.6 78.1 L422 75 L414.6 71.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"424\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"485.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">loss.backward()</text><text x=\"485.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">preenche todo .grad</text><path d=\"M546 75 L560 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M552.6 78.1 L560 75 L552.6 71.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"562\" y=\"40\" width=\"122\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"623.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">opt.step()</text><text x=\"623.0\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">move os pesos</text><text x=\"71.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1</text><text x=\"209.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2</text><text x=\"347.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">3</text><text x=\"485.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">4</text><text x=\"623.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">5</text><path d=\"M623.0 110 L623.0 150 L71.0 150 L71.0 114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M71.0 120 L71.0 112\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M74.1 119.4 L71.0 112 L67.9 119.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"350\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">próximo lote</text></svg>", "caption": "Um passo de treino, cinco linhas. Tire a terceira e a quarta soma os gradientes deste lote aos de todos os lotes anteriores."}
```

**A ordem delas é toda a dificuldade.** O `zero_grad` tem de vir antes do `backward`, porque o
`backward` soma no `.grad`; e o `step` tem de vir depois dele, porque o `step` lê o `.grad`. Onde o
`zero_grad` fica antes disso é livre: o `loop.py` o chama depois da perda, e muitos programas o
chamam primeiro. O que o otimizador faz no `step` é assunto da aula 5. O `torch.optim.SGD` subtrai a
taxa vezes o gradiente, como o `optim.SGD` fazia, e guarda uma referência aos parâmetros que recebeu,
então nada é passado a ele a cada passo.

## A primeira execução

Salve como `~/dl/train.py` e rode:

```schooling-example
{
  "language": "python",
  "file": "train.py",
  "parts": [
    {
      "code": "\"\"\"train: the MLP on the digits, with PyTorch's own SGD and the loop from loop.py.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\ntorch.manual_seed(0)\ntrain, val, _ = tdigits.load()\nmodel = make_mlp()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)",
      "note": "A semente fixa os pesos iniciais, então a execução é a mesma toda vez numa máquina. O otimizador recebe os parâmetros uma vez e guarda uma referência a eles; o `torch.optim.Adam` entraria no mesmo lugar com a mesma chamada."
    },
    {
      "code": "loop.fit(model, opt, train, val, epochs=30, every=5)\ntorch.save(model.state_dict(), \"mlp.pt\")",
      "note": "Trinta épocas, uma linha a cada cinco. A última linha grava os pesos treinados num arquivo, e a seção sobre salvar os lê de volta."
    }
  ]
}
```

```
ana@vm:~/dl$ python train.py
epoch   5  train loss 0.7931  val loss 0.6755  val acc 0.872
epoch  10  train loss 0.3170  val loss 0.3068  val acc 0.922
epoch  15  train loss 0.2154  val loss 0.2290  val acc 0.933
epoch  20  train loss 0.1661  val loss 0.2004  val acc 0.936
epoch  25  train loss 0.1374  val loss 0.1638  val acc 0.944
epoch  30  train loss 0.1205  val loss 0.1461  val acc 0.950
```

**A acurácia de validação chega a 0.950 depois de 30 épocas**, e a perda de treino cai em toda
linha, de 0.7931 na época 5 para 0.1205. É um SGD simples com taxa 0.1 numa rede de 2.410
parâmetros, então o número é uma linha de base para comparar, e não um teto.

A execução também deixou `mlp.pt` em `~/dl`, o arquivo que a última seção lê. A aula 10 troca o
fatiamento de `order` por um `DataLoader`, e a aula 11 treina uma rede convolucional com este mesmo
`fit`.
