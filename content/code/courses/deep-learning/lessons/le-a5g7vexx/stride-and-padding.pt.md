---
title: Stride e padding, e o tamanho do que sai
version: 1
---

O tamanho da saída de uma convolução não é algo a descobrir rodando a rede e lendo o erro. **É
aritmética, e depende de três configurações.** O tamanho do kernel `k` é a largura da janela. O stride
`s` é quanto ela anda a cada passo. O padding `p` é quantos anéis de zeros são acrescentados em volta da
imagem antes de começar. Para uma imagem de `n` pixels de largura:

```
out = (n + 2p - k) // s + 1
```

`//` divide e arredonda para baixo. O programa abaixo monta um `nn.Conv2d` de verdade para sete
configurações, roda-o numa imagem 8 por 8 e imprime a resposta da fórmula ao lado da forma que o
PyTorch devolveu. Salve-o como `~/dl/shapes.py`:

```schooling-example
{
  "language": "python",
  "file": "shapes.py",
  "parts": [
    {
      "code": "\"\"\"shapes: what kernel size, stride and padding do to the size of an 8x8 image.\"\"\"\nimport torch\nimport torch.nn as nn\n\nx = torch.zeros(1, 1, 8, 8)",
      "note": "Uma imagem, um canal, 8 por 8. Os valores não importam aqui, só a forma que sai."
    },
    {
      "code": "print(\"kernel  stride  padding  formula  nn.Conv2d output\")\nfor k, s, p in [(3, 1, 0), (3, 1, 1), (5, 1, 0), (5, 1, 2), (3, 2, 1), (3, 2, 0), (2, 2, 0)]:\n    conv = nn.Conv2d(1, 4, kernel_size=k, stride=s, padding=p)\n    formula = (8 + 2 * p - k) // s + 1\n    print(f\"{k:6d}  {s:6d}  {p:7d}  {formula:7d}  {tuple(conv(x).shape)}\")",
      "note": "Sete configurações, cada uma montada como uma camada de verdade com 4 filtros e rodada na imagem. A coluna `formula` é calculada à mão ao lado; `//` é a divisão arredondada para baixo."
    }
  ]
}
```

```
ana@vm:~/dl$ python shapes.py
kernel  stride  padding  formula  nn.Conv2d output
     3       1        0        6  (1, 4, 6, 6)
     3       1        1        8  (1, 4, 8, 8)
     5       1        0        4  (1, 4, 4, 4)
     5       1        2        8  (1, 4, 8, 8)
     3       2        1        4  (1, 4, 4, 4)
     3       2        0        3  (1, 4, 3, 3)
     2       2        0        4  (1, 4, 4, 4)
```

A fórmula e a camada concordam em todas as linhas. Leia-as aos pares:

- **O padding mantém o tamanho.** Um filtro 3 por 3 sem padding dá 6, como na seção anterior; com um
  anel de zeros, dá 8 de novo. Um filtro 5 por 5 precisa de dois anéis. Padding `p = (k - 1) / 2`, com
  stride 1, dá uma saída do tamanho da entrada, e é assim que a rede desta aula mantém os seus mapas em
  8 por 8.
- **O stride reduz.** Com stride 2 a janela para em um pixel sim, outro não, e 8 vira 4.
- **Arredondar para baixo descarta pixels.** Kernel 3, stride 2 e nenhum padding dá 3: a janela para
  nas colunas 0, 2 e 4, e um quarto passo precisaria das colunas 6 a 8, que não existem. **A coluna 7
  nunca é lida.** Nada avisa; uma forma que sai uma unidade menor que o esperado é o sinal.

**A forma tem quatro números, numa ordem fixa**: lote, canais, altura, largura. O lote é 1 porque
entrou uma imagem. Os canais são 4 porque cada camada foi montada com 4 filtros, e cada filtro faz um
mapa próprio. É por isso que o `filter.py` mudou a forma da imagem para `(1, 1, 8, 8)` antes de
entregá-la ao PyTorch: uma imagem, um canal, e a grade.
