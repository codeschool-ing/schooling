---
title: Escolhendo uma
version: 1
---

A arquitetura mais nova não é automaticamente a certa, e **a melhor na ImageNet não é
automaticamente a melhor nos seus dados**. Os números que decidem isso estão registrados: o
torchvision guarda, ao lado de cada conjunto de pesos treinados, quantos parâmetros a rede tem,
quantas operações uma imagem custa e a acurácia que esses pesos alcançaram. Lê-los não baixa nada.
Salve como `~/dl/card.py`:

```schooling-example
{
  "language": "python",
  "file": "card.py",
  "parts": [
    {
      "code": "\"\"\"card: five architectures as torchvision records them, read without downloading a weight.\"\"\"\nfrom torchvision import models\n\nprint(f\"{'model':20s} {'parameters':>12s} {'GFLOPs':>7s} {'image':>6s} {'top-1 %':>8s}\")"
    },
    {
      "code": "for name in (\"vgg16\", \"resnet18\", \"resnet50\", \"efficientnet_b0\", \"mobilenet_v3_small\"):\n    weights = models.get_model_weights(name).IMAGENET1K_V1\n    meta = weights.meta\n    print(f\"{name:20s} {meta['num_params']:>12,d} {meta['_ops']:>7.2f} \"\n          f\"{weights.transforms().crop_size[0]:>6d} {meta['_metrics']['ImageNet-1K']['acc@1']:>8.1f}\")",
      "note": "`meta` é o que o torchvision registra sobre cada conjunto de pesos: a contagem de parâmetros, os bilhões de operações que uma imagem custa e a acurácia top-1 que esses pesos alcançaram na validação da ImageNet. São números do torchvision, não medidos aqui."
    }
  ]
}
```

```
ana@vm:~/dl$ python card.py
model                  parameters  GFLOPs  image  top-1 %
vgg16                 138,357,544   15.47    224     71.6
resnet18               11,689,512    1.81    224     69.8
resnet50               25,557,032    4.09    224     76.1
efficientnet_b0         5,288,548    0.39    224     77.7
mobilenet_v3_small      2,542,856    0.06    224     67.7
```

GFLOPs são bilhões de operações de ponto flutuante para uma imagem, e top-1 é a porcentagem das
fotografias de validação da ImageNet em que o primeiro palpite acertou. **São números do torchvision
para os próprios pesos treinados, não medições feitas para este curso**, que nunca rodou uma dessas
redes numa fotografia de verdade.

Três coisas para tirar dele:

- **A VGG-16 é o pior negócio do quadro**: mais parâmetros e mais trabalho por imagem, para um top-1
  abaixo do da EfficientNet-B0, que tem 26 vezes menos parâmetros. Ela sobrevive no ensino e em
  código antigo.
- **A EfficientNet-B0 supera a ResNet-50 em acurácia** com um quinto dos parâmetros e menos de um
  décimo das operações. Operações não são tempo, porém: uma convolução depthwise faz pouca conta por
  byte que lê, e numa placa de vídeo uma ResNet muitas vezes termina antes do que a contagem de
  operações sugere. Quanto tempo uma rede leva na sua máquina é algo a medir, e a aula 19 mede.
- **A MobileNet-V3-Small é feita para um orçamento**, 0,06 GFLOPs, e abre mão de uns dez pontos de
  acurácia em relação à EfficientNet-B0 para cumpri-lo.

**E em imagens pequenas, pode ser que nenhuma delas seja a escolha certa.** As cinco foram
projetadas para fotografias de 224 por 224 pixels, e os troncos delas encolhem a imagem depressa.
Os dígitos têm 8 por 8. Este programa treina a ResNet-18 contra o `cnn.py` da aula 11 neles, com o
tronco trocado para receber um canal. Salve como `~/dl/small.py`:

```schooling-example
{
  "language": "python",
  "file": "small.py",
  "parts": [
    {
      "code": "\"\"\"small: ResNet-18 against lesson 11's small CNN, on the 8x8 digits.\"\"\"\nimport time\n\nimport torch\nimport torch.nn as nn\nfrom torchvision.models import resnet18\n\nimport cnn\nimport loop\nimport tdigits\n\n\ndef resnet():\n    model = resnet18(weights=None, num_classes=10)\n    model.conv1 = nn.Conv2d(1, 64, 7, stride=2, padding=3, bias=False)\n    return model",
      "note": "A ResNet-18 com dez saídas e um tronco que recebe um canal de tinta em vez de três de cor. Todo o resto é do torchvision, passo e pooling incluídos."
    },
    {
      "code": "train, val, _ = tdigits.load(images=True)\nfor name, build in ((\"cnn.make_cnn\", cnn.make_cnn), (\"resnet18\", resnet)):\n    torch.manual_seed(0)\n    model = build()\n    print(name, sum(p.numel() for p in model.parameters()), \"parameters\")\n    start = time.perf_counter()\n    loop.fit(model, torch.optim.Adam(model.parameters(), lr=0.001), train, val, epochs=10, every=5)\n    print(f\"  {time.perf_counter() - start:.0f} s\")",
      "note": "O `cnn.py` da aula 11 e a ResNet-18, a mesma semente, o mesmo otimizador, a mesma taxa e dez épocas, pelo `loop.py` da aula 9. O tempo é de relógio, nesta máquina."
    }
  ]
}
```

```
ana@vm:~/dl$ python small.py
cnn.make_cnn 38282 parameters
epoch   5  train loss 0.3023  val loss 0.2438  val acc 0.939
epoch  10  train loss 0.0985  val loss 0.1518  val acc 0.953
  1 s
resnet18 11175370 parameters
epoch   5  train loss 0.2078  val loss 0.2733  val acc 0.931
epoch  10  train loss 0.1344  val loss 0.2077  val acc 0.939
  23 s
```

A ResNet-18 tem 11.175.370 parâmetros contra 38.282 da rede pequena, umas 290 vezes mais, e termina
em 0,939 na validação contra 0,953. Levou 23 segundos para chegar lá, contra 1. O tronco dela divide o
lado por quatro, como os 224 para 56 da seção da ResNet-18 mostraram, então os dígitos chegam ao
primeiro bloco residual como mapas de 2 por 2 e quase toda a maquinaria trabalha sobre quatro
pixels. Uma arquitetura carrega suposições sobre a entrada, e o tamanho da imagem é a primeira
delas.

Uma ordem prática de escolha, para imagens:

1. **Comece do que tem pesos treinados para uma tarefa parecida com a sua.** Treinar a partir de
   pesos aleatórios foi o que esta aula fez, e é a exceção; a aula 13 parte de pesos já treinados,
   e isso pesa mais que a arquitetura.
2. **Uma ResNet é a linha de base**: bem entendida, suportada por toda ferramenta, e sem camadas
   incomuns que deem errado quando ela é exportada.
3. **EfficientNet quando a acurácia por parâmetro importa**, e dá para dar a ela o tamanho de imagem
   para o qual foi escalada.
4. **MobileNet quando o modelo roda num celular** ou em qualquer coisa com um orçamento em
   milissegundos.
5. **Para entradas pequenas ou incomuns, uma rede pequena sua**, como os dígitos mostram.

Os vision transformers, que tratam uma imagem como uma sequência de pedaços, hoje competem com todas
estas quando há muitos dados para treinar. Eles pedem antes o transformer da aula 15.
