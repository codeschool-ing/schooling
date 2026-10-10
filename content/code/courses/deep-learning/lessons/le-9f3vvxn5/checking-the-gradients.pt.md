---
title: Conferindo os gradientes
version: 1
---

Um erro num backward pass não derruba nada. **Ele devolve arrays do formato certo, cheios de números
plausíveis, e o treino segue com eles**, sem nada na tela dizendo que estão errados. O forward pass pode ser conferido contra o que a rede prevê. O backward pass só pode ser
conferido contra a definição de inclinação, que é a cutucada da aula 2.

Então o método lento da primeira seção fica, como teste. Suba um peso por um `h` minúsculo, depois
desça, meça a perda nas duas vezes e divida a diferença por `2h`. Faça isso para cada peso e compare
com o que o `backward` produziu. A comparação é um **erro relativo**, a diferença dividida pelo
tamanho dos dois números, porque uma diferença de 0,001 não é nada num gradiente de 50 e é tudo num
gradiente de 0,001. Salve como `~/dl/gradcheck.py`:

```schooling-example
{
  "language": "python",
  "file": "gradcheck.py",
  "parts": [
    {
      "code": "\"\"\"gradcheck: tinynet's backward against finite differences, on eight digits.\"\"\"\nimport numpy as np\n\nimport digits\nimport tinynet\n\n(x_train, y_train), _, _ = digits.load()\ny = y_train[:8]",
      "note": "Oito imagens de treino bastam. A conferência é sobre a aritmética, não sobre aprender alguma coisa."
    },
    {
      "code": "def build(dtype):\n    \"\"\"A 64-16-10 network whose weights and gradients are kept in the given precision.\"\"\"\n    rng = np.random.default_rng(0)\n    net = tinynet.Net(tinynet.Linear(64, 16, rng), tinynet.ReLU(), tinynet.Linear(16, 10, rng))\n    for layer in net.layers[::2]:\n        for k in layer.params:\n            setattr(layer, k, getattr(layer, k).astype(dtype))\n            setattr(layer, \"d\" + k, np.zeros_like(getattr(layer, k)))\n    return net",
      "note": "O `tinynet` treina em `float32`. Isto cria a mesma rede em outra precisão, trocando cada array e o seu gradiente. A semente é a mesma, então as duas precisões partem dos mesmos pesos."
    },
    {
      "code": "def compare(net, x):\n    \"\"\"The relative error between backward's gradient and a finite difference, for every weight.\"\"\"\n    _, grad = tinynet.softmax_cross_entropy(net.forward(x), y)\n    net.backward(grad)\n    errors = []\n    for value, analytic in net.params():\n        for i in np.ndindex(value.shape):\n            old = value[i]\n            value[i] = old + 1e-5\n            up = tinynet.softmax_cross_entropy(net.forward(x), y)[0]\n            value[i] = old - 1e-5\n            down = tinynet.softmax_cross_entropy(net.forward(x), y)[0]\n            value[i] = old\n            numeric = (up - down) / 2e-5\n            errors.append(abs(analytic[i] - numeric) / max(abs(analytic[i]) + abs(numeric), 1e-12))\n    return np.array(errors)",
      "note": "Um backward pass dá todos os gradientes. Depois, cada um dos 1.210 pesos é mexido para cima e para baixo em 0,00001, e a mudança na perda é medida. O erro é relativo: uma diferença de 0,001 não significa nada num gradiente de 50 e significa tudo num gradiente de 0,001."
    },
    {
      "code": "def report(label, errors):\n    print(f\"{label:32s} worst {errors.max():.1e}, above 1e-4: {(errors > 1e-4).sum()} of {errors.size}\")\n\n\nfor dtype in (np.float64, np.float32):\n    report(f\"{dtype.__name__}, tinynet as written\", compare(build(dtype), x_train[:8].astype(dtype)))",
      "note": "A mesma conferência nas duas precisões, com o código exatamente como o `tinynet.py` o tem."
    },
    {
      "code": "tinynet.ReLU.backward = lambda self, grad: grad\nreport(\"float64, ReLU backward forgotten\", compare(build(np.float64), x_train[:8].astype(np.float64)))",
      "note": "Um bug plantado de propósito: um ReLU cujo backward esquece a máscara e deixa todo gradiente passar. O forward pass não muda, então a perda é exatamente a mesma de antes."
    }
  ]
}
```

```
ana@vm:~/dl$ python gradcheck.py
float64, tinynet as written      worst 1.8e-08, above 1e-4: 0 of 1210
float32, tinynet as written      worst 1.0e+00, above 1e-4: 663 of 1210
float64, ReLU backward forgotten worst 1.0e+00, above 1e-4: 704 of 1210
```

**Em float64, o pior dos 1.210 pesos discorda em 1.8e-08**, e nenhum passa de 1e-4. O backward pass
do `tinynet` está certo. Uma regra prática comum lê um erro relativo por volta de 1e-7 ou abaixo como
correto, e qualquer coisa acima de 1e-4 como bug.

**Em float32, o mesmo código correto falha na conferência em 663 pesos.** O defeito está na
conferência, não no código. Uma cutucada de 0,00001 muda a perda no sétimo ou oitavo dígito, e o
float32 guarda só uns sete, então a diferença finita é quase toda arredondamento. **Com o bug
plantado, o float64 aponta 704 pesos errados**, aqueles cujo gradiente teve de passar por um ReLU que
deveria tê-lo barrado. Em float32, o código quebrado e o correto parecem igualmente quebrados, e é por
isso que a conferência sempre roda em float64. O treino depois volta ao float32, onde o arredondamento
é pequeno demais para importar.

Três hábitos fazem a conferência valer a pena:

- **Mantenha-a pequena.** Poucas imagens e poucas unidades. Ela faz dois forward passes por peso, 2.420 para
  esta rede, onde o backward pass fez um.
- **Rode-a antes do treino, não durante.** Ela testa código, então roda uma vez sempre que o backward de uma
  camada é escrito ou alterado. As aulas 7 e 8 escrevem camadas novas para o `tinynet`, e é assim que
  se testa cada uma.
- **Cuidado com as quinas.** O ReLU não tem inclinação exatamente no zero. Um peso cuja cutucada faz
  alguma soma cruzar o zero pode discordar com razão, e uma entrada ruim isolada ali não é bug. Nenhuma
  discordou aqui.
