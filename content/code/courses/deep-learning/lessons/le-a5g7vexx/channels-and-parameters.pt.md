---
title: Canais, e quanto custa uma convolução
version: 1
---

Uma camada de convolução não é um filtro. **São muitos filtros lado a lado, e cada um faz um mapa
próprio**, chamado de canal. Dezesseis filtros sobre um dígito dão dezesseis mapas 8 por 8: um pode
acender em bordas esquerdas, outro no fundo de uma volta. A camada seguinte lê então os dezesseis mapas
ao mesmo tempo, e por isso os seus filtros não são 3 por 3, e sim 16 por 3 por 3, uma fatia 3 por 3 por
canal que chega. Uma fotografia colorida é a mesma ideia desde o começo: três canais, vermelho, verde e
azul.

O peso do `nn.Conv2d` tem a forma `(out_channels, in_channels, k, k)`, e os seus parâmetros podem ser
contados à mão. Salve como `~/dl/params.py`:

```schooling-example
{
  "language": "python",
  "file": "params.py",
  "parts": [
    {
      "code": "\"\"\"params: what a convolution costs, against a dense layer giving the same outputs.\"\"\"\nimport torch.nn as nn\n\n\ndef count(layer):\n    return sum(p.numel() for p in layer.parameters())"
    },
    {
      "code": "conv1 = nn.Conv2d(1, 16, kernel_size=3, padding=1)\nprint(\"conv1 weight\", tuple(conv1.weight.shape), \"bias\", tuple(conv1.bias.shape), \"->\", count(conv1))\nprint(\"a Linear from 64 pixels to 16 x 8 x 8 outputs ->\", count(nn.Linear(64, 16 * 8 * 8)))",
      "note": "A primeira camada da rede da próxima seção: 16 filtros sobre uma imagem de 1 canal, com padding para cada mapa de saída continuar 8 por 8. Uma camada densa que produza os mesmos 1.024 números precisa de um peso de cada pixel para cada um deles."
    },
    {
      "code": "conv2 = nn.Conv2d(16, 32, kernel_size=3, padding=1)\nprint(\"conv2 weight\", tuple(conv2.weight.shape), \"bias\", tuple(conv2.bias.shape), \"->\", count(conv2))\nprint(\"a Linear from 16 x 8 x 8 to 32 x 8 x 8 ->\", count(nn.Linear(16 * 8 * 8, 32 * 8 * 8)))",
      "note": "A segunda camada lê os 16 mapas que a primeira fez. Cada um dos seus 32 filtros é 16 por 3 por 3: ele olha o mesmo lugar 3x3 nos 16 mapas ao mesmo tempo."
    },
    {
      "code": "# The same conv1 on a 224 x 224 colour photograph, and the dense layer it would replace.\nphoto = nn.Conv2d(3, 16, kernel_size=3, padding=1)\nprint(\"conv on a 3 x 224 x 224 photo ->\", count(photo))\nprint(\"a Linear doing the same ->\", 3 * 224 * 224 * 16 * 224 * 224 + 16 * 224 * 224)",
      "note": "Uma fotografia tem três canais, vermelho, verde e azul. A camada densa é contada com aritmética em vez de construída, porque construí-la pediria muito mais memória do que a máquina tem."
    }
  ]
}
```

```
ana@vm:~/dl$ python params.py
conv1 weight (16, 1, 3, 3) bias (16,) -> 160
a Linear from 64 pixels to 16 x 8 x 8 outputs -> 66560
conv2 weight (32, 16, 3, 3) bias (32,) -> 4640
a Linear from 16 x 8 x 8 to 32 x 8 x 8 -> 2099200
conv on a 3 x 224 x 224 photo -> 448
a Linear doing the same -> 120847089664
```

**A primeira camada tem 160 parâmetros**: 16 filtros de 1 × 3 × 3 pesos, mais um viés cada. Uma camada
densa que transformasse os mesmos 64 pixels nas mesmas 1.024 saídas precisaria de 66.560. **A segunda
camada tem 4.640**, 32 × 16 × 9 + 32, contra 2.099.200 da densa. Numa fotografia, a diferença deixa de
ser uma proporção e vira um muro: 448 para a convolução, e 120.847.089.664 para uma camada densa, um
número que nenhuma máquina guardaria.

**A contagem não depende do tamanho da imagem.** Os mesmos 448 parâmetros rodam numa fotografia de
qualquer tamanho, porque o filtro é o mesmo em toda posição. Isso é compartilhamento de pesos, e é toda
a economia: uma camada densa paga por cada par de entrada e saída, uma convolução paga por uma janela
pequena.

A economia tem um preço. Uma convolução só consegue combinar pixels próximos, e trata todo lugar da
imagem do mesmo jeito. São duas suposições sobre imagens, e para imagens elas estão certas: um traço é
feito de pixels vizinhos, e um traço é um traço onde quer que seja desenhado. Uma camada densa poderia
aprender a mesma coisa, mas teria de aprendê-la separadamente para cada posição, a partir de exemplos.
