---
title: A ResNet-18, estágio por estágio
version: 1
---

Um diagrama da ResNet num artigo é uma coluna de cem caixas, e parece complicado. **A rede em si
são quatro repetições de uma ideia**: um estágio de blocos residuais num tamanho, depois a imagem
cai pela metade em altura e largura e o número de canais dobra, e o próximo estágio começa. O
torchvision monta a versão de 18 camadas numa chamada. Salve como `~/dl/resnet.py`:

```schooling-example
{
  "language": "python",
  "file": "resnet.py",
  "parts": [
    {
      "code": "\"\"\"resnet: torchvision's ResNet-18, built empty, and what each stage does to an image.\"\"\"\nimport torch\nfrom torchvision.models import resnet18\n\nmodel = resnet18(weights=None)\nmodel.eval()\nprint(\"parameters:\", sum(p.numel() for p in model.parameters()))",
      "note": "A arquitetura com pesos aleatórios. `weights=None` é o único jeito de montá-la neste curso, porque a máquina em que o curso foi gravado não conseguia baixar os pesos treinados, e as formas e a contagem não dependem deles."
    },
    {
      "code": "x = torch.randn(1, 3, 224, 224)\nwith torch.no_grad():\n    x = model.maxpool(model.relu(model.bn1(model.conv1(x))))\n    print(\"stem    \", tuple(x.shape))",
      "note": "Uma imagem aleatória no tamanho da ImageNet, três canais de cor de 224 por 224. O tronco é uma convolução 7x7 com passo 2 e um max pooling, as quatro linhas que o `forward` roda primeiro."
    },
    {
      "code": "    for name in (\"layer1\", \"layer2\", \"layer3\", \"layer4\"):\n        stage = getattr(model, name)\n        x = stage(x)\n        n = sum(p.numel() for p in stage.parameters())\n        print(f\"{name:8s} {tuple(x.shape)}  {len(stage)} blocks, {n:,d} parameters\")\n    print(\"head    \", tuple(model.fc(model.avgpool(x).flatten(1)).shape))",
      "note": "O torchvision chama os quatro estágios de `layer1` a `layer4`. Cada um é um `Sequential` de blocos, então pode ser chamado sozinho e medido sozinho."
    },
    {
      "code": "print(model.layer2[0])",
      "note": "O primeiro bloco do segundo estágio, onde a imagem encolhe e os canais dobram."
    }
  ]
}
```

```
ana@vm:~/dl$ python resnet.py
parameters: 11689512
stem     (1, 64, 56, 56)
layer1   (1, 64, 56, 56)  2 blocks, 147,968 parameters
layer2   (1, 128, 28, 28)  2 blocks, 525,568 parameters
layer3   (1, 256, 14, 14)  2 blocks, 2,099,712 parameters
layer4   (1, 512, 7, 7)  2 blocks, 8,393,728 parameters
head     (1, 1000)
BasicBlock(
  (conv1): Conv2d(64, 128, kernel_size=(3, 3), stride=(2, 2), padding=(1, 1), bias=False)
  (bn1): BatchNorm2d(128, eps=1e-05, momentum=0.1, affine=True, bias=True, track_running_stats=True)
  (relu): ReLU(inplace=True)
  (conv2): Conv2d(128, 128, kernel_size=(3, 3), stride=(1, 1), padding=(1, 1), bias=False)
  (bn2): BatchNorm2d(128, eps=1e-05, momentum=0.1, affine=True, bias=True, track_running_stats=True)
  (downsample): Sequential(
    (0): Conv2d(64, 128, kernel_size=(1, 1), stride=(2, 2), bias=False)
    (1): BatchNorm2d(128, eps=1e-05, momentum=0.1, affine=True, bias=True, track_running_stats=True)
  )
)
```

**Siga a forma coluna abaixo.** O tronco leva a imagem de 224 por 224 a 56 por 56 de uma vez, com
o seu passo e o seu pooling, e põe 64 canais sobre ela. Cada um dos três estágios seguintes divide o
lado por dois e dobra os canais, para 128, 256 e 512, e os últimos mapas têm 7 por 7. A cabeça tira
a média de cada mapa num número só, e uma camada linear transforma os 512 números em 1.000
pontuações de classe, as classes da ImageNet.

**Os parâmetros não se espalham por igual.** Só a `layer4` tem 8.393.728 dos 11.689.512, porque o
custo de uma convolução 3x3 cresce com os canais de entrada vezes os canais de saída, e esses são
maiores no fim. A imagem é menor ali, então o trabalho por imagem se espalha bem mais por igual que
os pesos. É o contrário da VGG, em que a cabeça densa era a parte cara.

O bloco impresso responde à pergunta que a seção residual deixou aberta: como `x + f(x)` funciona
quando `f` divide a imagem por dois e dobra os canais, e os dois deixam de ter a mesma forma?

- **`conv1` tem `stride=(2, 2)`**, e é ali que a divisão por dois acontece, no caminho do próprio
  bloco.
- **`downsample` é uma convolução 1x1 com passo 2** no atalho, que leva `x` aos mesmos 128 canais e
  ao mesmo tamanho. É o único lugar em que o atalho aprende alguma coisa, e só aparece no primeiro
  bloco de um estágio.
- **Cada convolução é seguida de `BatchNorm2d`** (aula 8), e as convoluções têm `bias=False`,
  porque a normalização subtrai a média e um viés seria cancelado.

As ResNet-18, 34, 50, 101 e 152 diferem no número de blocos por estágio e, da 50 para cima, no
bloco: uma convolução 1x1 estreita os canais, a 3x3 trabalha na versão estreita, e outra 1x1 os
alarga de volta. O artigo chamou isso de gargalo: a 3x3, que é cara, vê menos canais, e a rede pode
ter três camadas num bloco onde a ResNet-18 tem duas.

Tudo isso foi montado com pesos aleatórios. **Os treinados são um download que a máquina da gravação
não conseguia fazer**, então nada aqui foi testado numa fotografia de verdade; a aula 13 mostra como
esses pesos são pedidos e o que eles trazem.
