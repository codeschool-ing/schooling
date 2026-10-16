---
title: MobileNet e EfficientNet, e a convolução dividida em duas
version: 1
---

A ResNet respondeu como ir mais fundo. **A pergunta seguinte veio dos celulares**: como ter a mesma
acurácia com menos operações, num processador com uma bateria atrás. A resposta em que MobileNet e
EfficientNet se apoiam é parar de pedir que um filtro faça dois trabalhos.

Uma convolução 3x3 completa de 32 canais para 64 faz duas coisas ao mesmo tempo. Olha uma vizinhança
de 3 por 3, e mistura os 32 canais de entrada em cada uma das 64 saídas. Paga pelas duas juntas: 3 ×
3 × 32 × 64 pesos. **Uma convolução separável em profundidade faz uma depois da outra.** Primeiro
uma convolução depthwise dá a cada canal de entrada o seu próprio filtro 3x3 e não mistura nada, 3 ×
3 × 32 pesos. Depois uma convolução pointwise 1x1 mistura os canais em cada pixel e não olha
vizinhança nenhuma, 32 × 64 pesos. Salve como `~/dl/separable.py`:

```schooling-example
{
  "language": "python",
  "file": "separable.py",
  "parts": [
    {
      "code": "\"\"\"separable: a 3x3 convolution against its depthwise separable version, and where the second one is used.\"\"\"\nimport torch\nimport torch.nn as nn\nfrom torchvision.models import efficientnet_b0, mobilenet_v3_small\n\n\ndef params(m):\n    return sum(p.numel() for p in m.parameters())"
    },
    {
      "code": "full = nn.Conv2d(32, 64, 3, padding=1, bias=False)\ndepthwise = nn.Conv2d(32, 32, 3, padding=1, groups=32, bias=False)\npointwise = nn.Conv2d(32, 64, 1, bias=False)",
      "note": "`groups=32` divide os 32 canais de entrada em 32 grupos de um, então cada canal ganha o seu filtro 3x3 e nada se mistura entre canais. A convolução 1x1 depois os mistura, um pixel por vez. Sem viés, como nas redes que usam isso."
    },
    {
      "code": "x = torch.randn(1, 32, 56, 56)\nprint(\"full 3x3:  \", params(full), \"parameters, output\", tuple(full(x).shape))\nprint(\"depthwise: \", params(depthwise), \"parameters, output\", tuple(depthwise(x).shape))\nprint(\"pointwise: \", params(pointwise), \"parameters, output\", tuple(pointwise(depthwise(x)).shape))\nprint(\"separable: \", params(depthwise) + params(pointwise), \"parameters\")",
      "note": "A mesma entrada pelos dois caminhos, para conferir que o par termina na mesma forma da convolução completa."
    },
    {
      "code": "for build in (mobilenet_v3_small, efficientnet_b0):\n    convs = [m for m in build(weights=None).modules() if isinstance(m, nn.Conv2d)]\n    dw = sum(1 for c in convs if c.groups > 1 and c.groups == c.in_channels)\n    one = sum(1 for c in convs if c.kernel_size == (1, 1))\n    print(f\"{build.__name__}: {len(convs)} convolutions, {dw} depthwise, {one} 1x1\")",
      "note": "Toda convolução das duas redes, separada em depthwise (um grupo por canal de entrada), 1x1 e o que sobrar."
    }
  ]
}
```

```
ana@vm:~/dl$ python separable.py
full 3x3:   18432 parameters, output (1, 64, 56, 56)
depthwise:  288 parameters, output (1, 32, 56, 56)
pointwise:  2048 parameters, output (1, 64, 56, 56)
separable:  2336 parameters
mobilenet_v3_small: 52 convolutions, 11 depthwise, 40 1x1
efficientnet_b0: 81 convolutions, 16 depthwise, 64 1x1
```

O par chega à mesma forma de saída com 2.336 parâmetros contra 18.432, quase oito vezes menos, e as
multiplicações por pixel caem na mesma proporção. **Não é a mesma função.** Uma convolução completa
pode aprender um padrão 3x3 diferente para cada par de canais; a separável não pode, e é uma aposta
de que raramente precisa. As redes que fazem a aposta compensam com largura e profundidade compradas
com a economia.

As duas últimas linhas mostram até onde isso vai. Das 52 convoluções da MobileNet-V3-Small, 11 são
depthwise e 40 são 1x1; a que sobra é a primeira convolução, que lê os três canais de cor. A
EfficientNet-B0 é igual: 81 convoluções, 16 depthwise, 64 delas 1x1, e uma convolução completa na
entrada. As duas também usam um ramo pequeno que reescala cada canal por um peso aprendido, chamado
squeeze-and-excitation, que responde por algumas dessas camadas 1x1.

**A EfficientNet acrescentou uma segunda ideia, o escalonamento composto.** Uma rede que funciona num
tamanho pode crescer de três jeitos: mais camadas, mais canais por camada ou imagens maiores. Antes
da EfficientNet, um artigo costumava escolher um. **A tese da EfficientNet é que os três devem
crescer juntos**, em proporções fixas: se uma rede ganha mais camadas, também precisa de mais canais
para levar o que elas acham, e uma imagem maior precisa das duas coisas para ser coberta. Os autores
procuraram uma rede pequena boa, a B0, e depois escalaram os três de uma vez por um único
coeficiente para chegar da B1 à B7. Salve como `~/dl/scaling.py`:

```schooling-example
{
  "language": "python",
  "file": "scaling.py",
  "parts": [
    {
      "code": "\"\"\"scaling: EfficientNet-B0 to B7, built empty, and the three things that grow together.\"\"\"\nfrom torchvision import models\n\nprint(f\"{'model':16s} {'blocks':>6s} {'width':>6s} {'image':>6s} {'parameters':>12s}\")"
    },
    {
      "code": "for i in range(8):\n    name = f\"efficientnet_b{i}\"\n    model = getattr(models, name)(weights=None)\n    blocks = sum(len(stage) for stage in model.features[1:-1])\n    width = model.features[-1][0].in_channels",
      "note": "A profundidade é o número de blocos entre a primeira convolução e a última, e a largura é o número de canais em que os blocos terminam. As duas são lidas da rede montada."
    },
    {
      "code": "    image = models.get_model_weights(name).IMAGENET1K_V1.transforms().crop_size[0]\n    params = sum(p.numel() for p in model.parameters())\n    print(f\"{name:16s} {blocks:6d} {width:6d} {image:6d} {params:12,d}\")",
      "note": "Os pesos treinados de cada modelo vêm com a transformação atrás da qual foram treinados, e o tamanho do recorte dela é a resolução da imagem. Pedir a transformação lê o registro do próprio torchvision e não baixa nada."
    }
  ]
}
```

```
ana@vm:~/dl$ python scaling.py
model            blocks  width  image   parameters
efficientnet_b0      16    320    224    5,288,548
efficientnet_b1      23    320    240    7,794,184
efficientnet_b2      23    352    288    9,109,994
efficientnet_b3      26    384    300   12,233,232
efficientnet_b4      32    448    380   19,341,616
efficientnet_b5      39    512    456   30,389,784
efficientnet_b6      45    576    528   43,040,704
efficientnet_b7      55    640    600   66,347,960
```

**Leia as colunas de cima para baixo: as três crescem a cada passo.** Da B0 à B7 os blocos vão de 16
a 55, a largura final de 320 canais a 640, a imagem de 224 pixels a 600, e os parâmetros de
5.288.548 a 66.347.960. Nenhuma cresce sozinha. A coluna da imagem é a que as pessoas esquecem: a B7
foi treinada com imagens de 600 por 600, e dar a ela 224 por 224 joga fora boa parte daquilo para
que ela foi escalada.

A EfficientNet-B0 tem menos da metade dos parâmetros da ResNet-18, e a última seção põe a acurácia
das duas lado a lado.
