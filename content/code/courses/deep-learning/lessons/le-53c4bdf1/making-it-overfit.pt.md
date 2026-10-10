---
title: Fazendo uma rede sobreajustar, de propósito
version: 1
---

O sobreajuste costuma ser imaginado como uma curva que vira: o treino vai bem, e então a acurácia de
validação começa a cair. **Nestes dígitos a acurácia quase não se mexe, e quem vira é a perda.** Para ver
isso com clareza é preciso uma rede que sobreajuste muito, então esta seção constrói uma de propósito e
cada seção seguinte tenta curá-la.

A receita é a mesma contra a qual `machine-learning` alertou: muito mais parâmetros do que exemplos.
Pegue só as primeiras 100 das 1.077 imagens de treino, mantenha as 360 imagens de validação para que a
medida continue honesta, e dê à rede duas camadas ocultas de 512 unidades. Salve como `~/dl/small.py`:

```schooling-example
{
  "language": "python",
  "file": "small.py",
  "parts": [
    {
      "code": "\"\"\"small: 100 training images, and a network far too big for them.\"\"\"\nimport numpy as np\n\nimport digits\nfrom tinynet import Linear, Net, ReLU",
      "note": "Todo o resto desta aula importa este arquivo, e assim cada execução parte dos mesmos dados e da mesma rede."
    },
    {
      "code": "def data(n=100):\n    \"\"\"The first n training images, and the whole validation set.\"\"\"\n    (x, y), val, _ = digits.load()\n    return (x[:n], y[:n]), val",
      "note": "As primeiras 100 das 1.077 imagens de treino do `digits.py` da aula 1, umas dez de cada dígito. A validação continua inteira, com 360, então a medida é tão boa quanto antes e só o treino passa fome."
    },
    {
      "code": "def wide(seed=0):\n    \"\"\"64 inputs, two hidden layers of 512 units, 10 outputs.\"\"\"\n    rng = np.random.default_rng(seed)\n    return Net(Linear(64, 512, rng), ReLU(),\n               Linear(512, 512, rng), ReLU(),\n               Linear(512, 10, rng))",
      "note": "Duas camadas ocultas de 512 unidades, montadas com o `tinynet.py` da aula 3. A semente fixa os pesos iniciais, então uma execução com a mesma semente parte da mesma rede."
    }
  ]
}
```

Depois treine por 300 épocas com o `fit` e o `SGD` da aula 5. Salve como `~/dl/overfit.py`:

```schooling-example
{
  "language": "python",
  "file": "overfit.py",
  "parts": [
    {
      "code": "\"\"\"overfit: the wide network on 100 images, for 300 epochs.\"\"\"\nimport small\nfrom fit import evaluate, fit\nfrom optim import SGD\n\ntrain, val = small.data()\nnet = small.wide()\nprint(\"parameters:\", sum(p.size for p, _ in net.params()))",
      "note": "A rede e os dados do `small.py`, e uma contagem de todos os pesos e vieses dela."
    },
    {
      "code": "history = fit(net, SGD(net.params(), lr=0.2), train, val, epochs=300, every=20)\nprint(\"train acc\", evaluate(net, *train)[1])\nbest = min(history, key=lambda h: h[2])\nprint(f\"lowest val loss {best[2]:.4f} at epoch {best[0]}\")",
      "note": "SGD simples com taxa 0,2 pelo `fit` da aula 5, imprimindo a cada 20 épocas. No fim, a acurácia nas próprias imagens de treino, e a época de menor perda de validação, lida do histórico que o `fit` devolve."
    }
  ]
}
```

```
PENDING overfit
```

**301.066 parâmetros para 100 imagens** são uns três mil números por exemplo, o bastante para guardar
cada figura em vez de aprender como é um 3. E é o que ela faz: a acurácia de treino é 1,0, e a perda de
treino termina em 0,0010, trezentas vezes menor que na época 20.

A perda de validação conta outra história. Ela é mínima na época 40, em 0,2942, e dali sobe quase toda
vez que é impressa, até 0,3281 na época 300. A acurácia de validação, nas mesmas 260 épocas, oscila entre
0,900 e 0,908 e termina onde estava.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Dois gráficos da execução impressa acima, a cada vigésima época. À esquerda, a perda de treino cai de 0,0300 na época 20 para 0,0010 na época 300. À direita, na sua própria escala, a perda de validação cai até 0,3100 na época 20 e depois sobe até 0,3300 na época 300.\"><text x=\"210\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">perda de treino</text><path d=\"M90 240 L330 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 40 L90 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"84\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.000</text><path d=\"M90 240.0 L330 240.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.018</text><path d=\"M90 140.0 L330 140.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"84\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.035</text><path d=\"M90 40.0 L330 40.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"90.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"170.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"250.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"330.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><text x=\"210.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">época</text><path d=\"M106.0 68.6 L330.0 234.3\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"106.0\" cy=\"68.6\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"330.0\" cy=\"234.3\" r=\"2.5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><text x=\"550\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">perda de validação</text><path d=\"M430 240 L670 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M430 40 L430 240\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"424\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.290</text><path d=\"M430 240.0 L670 240.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"424\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.310</text><path d=\"M430 140.0 L670 140.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"424\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.330</text><path d=\"M430 40.0 L670 40.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"430.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"510.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"590.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"670.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><text x=\"550.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">época</text><path d=\"M446.0 140.0 L670.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"446.0\" cy=\"140.0\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"670.0\" cy=\"40.0\" r=\"2.5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"446.0\" cy=\"140.0\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><text x=\"446.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">menor: 20</text></svg>", "caption": "A mesma execução em duas escalas. A perda de treino continua caindo até quase nada; a de validação chega ao fundo cedo e passa o resto da execução subindo."}
```

**Os dois números estão certos, e medem coisas diferentes.** A acurácia só pergunta se a maior saída é o
dígito certo. A entropia cruzada, a perda da aula 4, também pergunta quanta probabilidade foi para o
dígito certo. Depois da época 40 a rede continua empurrando suas saídas para a certeza, tanto nas imagens
de treino que decorou quanto nas imagens de validação que erra, e uma resposta errada e confiante custa
mais perda que uma insegura. As cerca de 35 imagens de validação que ela erra não mudam, mas ela as erra
com mais convicção a cada época.

É esse o sobreajuste em que esta aula trabalha: uma perda de treino indo a zero, uma diferença de uns dez
pontos entre a acurácia de treino e a de validação, e uma perda de validação que subiu depois da época
40. A aula 6 mostrou como ler essa forma numa curva. As próximas quatro seções são quatro maneiras de
mudá-la, cada uma medida contra esta execução.
