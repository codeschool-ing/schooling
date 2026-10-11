---
title: Um filtro, deslizado à mão
version: 1
---

A rede da aula 9 lê um dígito como 64 números numa fila, e a ordem dessa fila não significa nada para
ela. **Embaralhe os pixels de toda imagem do mesmo jeito fixo e uma camada densa consegue aprender
exatamente tão bem**, porque o embaralhamento só reordena as linhas da sua matriz de pesos. Nada nela
sabe que o pixel 3 fica ao lado do pixel 4, ou que o pixel 11 fica logo abaixo do pixel 3. O que ela
aprende sobre traços e cantos precisa vir dos dados, separadamente para cada lugar da grade.

Uma convolução parte da suposição contrária: **o que importa numa imagem é uma vizinhança pequena, e a
mesma coisa pode aparecer em qualquer lugar.** Ela pega um filtro, também chamado de kernel, de 3 por 3
pesos, pousa-o num pedaço 3 por 3 da imagem, multiplica os nove pares e soma. Essa soma é um número da
saída. Depois o filtro anda um pixel e faz de novo, com os mesmos nove pesos, até visitar todo lugar
onde cabe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"À esquerda, o dígito 8 por 8 com os seus valores de tinta. Uma janela 3 por 3 sobre o canto superior esquerdo está contornada, e uma segunda janela, uma coluna à direita, está tracejada. No meio, o filtro: menos um, zero e mais um em cada linha. À direita, a saída 6 por 6, em que a primeira janela deu 21 e a segunda deu 32.\"><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">PENDING</text></svg>", "caption": "O filtro pousa num pedaço 3 por 3, multiplica, soma e escreve um número. Uma coluna à direita, faz de novo. Cabem trinta e seis posições, então a saída é 6 por 6."}
```

O programa abaixo faz isso com dois laços, no primeiro dígito de treino. Ele precisa do `digits.py` da
aula 1 ao lado. Salve-o como `~/dl/filter.py`:

```schooling-example
{
  "language": "python",
  "file": "filter.py",
  "parts": [
    {
      "code": "\"\"\"filter: a 3x3 edge filter slid over one digit, by hand.\"\"\"\nimport numpy as np\n\nimport digits\n\n(x, y), _, _ = digits.load()\nimage = (x[0] * 16).reshape(8, 8).astype(int)\nprint(\"label\", y[0])\nprint(image)",
      "note": "A primeira imagem de treino, a que a aula 1 desenhou em caracteres, de volta à escala de 0 a 16, para que todo número abaixo seja inteiro."
    },
    {
      "code": "kernel = np.array([[-1, 0, 1],\n                   [-1, 0, 1],\n                   [-1, 0, 1]])",
      "note": "O filtro: nove pesos. Ele soma a coluna da direita e subtrai a da esquerda, então responde quanto a tinta cresce da esquerda para a direita."
    },
    {
      "code": "out = np.zeros((6, 6), dtype=int)\nfor i in range(6):\n    for j in range(6):\n        out[i, j] = (image[i:i + 3, j:j + 3] * kernel).sum()\nprint(out)",
      "note": "A convolução inteira. Recorta o pedaço 3x3 na linha `i`, coluna `j`, multiplica pelo filtro elemento a elemento, soma os nove produtos. Uma janela de 3 pixels cabe em 6 posições ao longo de 8 pixels, então a resposta é 6 por 6."
    },
    {
      "code": "import torch\nimport torch.nn.functional as F\n\nt = F.conv2d(torch.tensor(image, dtype=torch.float32).reshape(1, 1, 8, 8),\n             torch.tensor(kernel, dtype=torch.float32).reshape(1, 1, 3, 3))\nprint(\"PyTorch agrees:\", bool((t.reshape(6, 6).int().numpy() == out).all()))",
      "note": "A mesma imagem e o mesmo filtro pela função do próprio PyTorch. Ela quer quatro dimensões para cada um, que a próxima seção explica, e devolve os mesmos 36 números."
    }
  ]
}
```

```
PENDING filter
```

O dígito é um 6: um traço descendo pelas colunas 2 e 3, e uma volta embaixo. **O filtro subtrai a
coluna da esquerda da coluna da direita**, então é positivo onde a tinta começa e negativo onde ela
termina, lendo da esquerda para a direita. A primeira coluna da saída, de 21 a 48, é a borda esquerda
desse traço; a terceira, de -5 a -34, é a borda direita. Onde o pedaço está em branco, ou tingido por
igual, os dois lados se cancelam e a resposta fica perto de zero. Nove pesos acharam uma borda vertical
em toda altura da imagem, e achariam uma em qualquer outra coluna também.

**A saída é 6 por 6, não 8 por 8**, porque uma janela de 3 pixels tem 6 lugares onde parar ao longo de
8 pixels. A próxima seção diz como manter o tamanho, e como reduzi-lo de propósito.

A última linha confere os laços contra o `F.conv2d` do PyTorch, e os 36 números batem. Um detalhe do
nome: na matemática, uma convolução espelha o filtro antes de deslizá-lo, e o que os laços fazem, sem
espelhar, se chama correlação cruzada. As bibliotecas de deep learning calculam a segunda e a chamam de
convolução. Como a rede aprende os seus filtros, um filtro espelhado simplesmente é aprendido ao
contrário, e nada mais muda.
