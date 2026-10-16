---
title: Quando uma rede mais profunda treina pior
version: 1
---

A VGG foi de 11 camadas para 19 e melhorou a cada passo, então o próximo passo óbvio era 30, depois
50. **Não funcionou, e o motivo não era overfitting.** Overfitting é uma rede que aprende bem demais
o conjunto de treino e falha em dados novos. O que acontecia depois de umas vinte camadas era o
contrário: a rede mais profunda ia pior **nas próprias imagens de treino**. Uma rede mais profunda
sempre pode copiar uma mais rasa, com as camadas extras deixando a entrada passar sem mudança, então
uma perda de treino pior quer dizer que o otimizador não achou uma solução que existe. O artigo da
ResNet chamou isso de problema da degradação.

Ele aparece nos dígitos. O módulo abaixo monta o mesmo tipo de rede em qualquer profundidade: uma
primeira convolução, uma pilha de blocos no estilo da VGG com duas convoluções 3x3 e uma cabeça
pequena. Salve como `~/dl/deep.py`:

```schooling-example
{
  "language": "python",
  "file": "deep.py",
  "parts": [
    {
      "code": "\"\"\"deep: plain and residual convolutional networks of any depth, for 1x8x8 digits.\"\"\"\nimport torch.nn as nn\n\n\nclass Plain(nn.Module):\n    \"\"\"Two 3x3 convolutions, each followed by ReLU.\"\"\"\n\n    def __init__(self, width):\n        super().__init__()\n        self.conv1 = nn.Conv2d(width, width, 3, padding=1)\n        self.conv2 = nn.Conv2d(width, width, 3, padding=1)\n        self.relu = nn.ReLU()\n\n    def forward(self, x):\n        return self.relu(self.conv2(self.relu(self.conv1(x))))",
      "note": "Um bloco de duas convoluções, o padrão da VGG no tamanho dos dígitos. O padding 1 mantém todo mapa em 8 por 8, e a largura fica em 16 canais do começo ao fim, então dá para empilhar blocos na profundidade que quiser."
    },
    {
      "code": "def make(layers, block=Plain, width=16, classes=10):\n    \"\"\"A stem convolution, (layers - 2) / 2 blocks, and a linear head: `layers` weight layers in all.\"\"\"\n    blocks = [block(width) for _ in range((layers - 2) // 2)]\n    return nn.Sequential(\n        nn.Conv2d(1, width, 3, padding=1), nn.ReLU(),\n        *blocks,\n        nn.AdaptiveAvgPool2d(1), nn.Flatten(),\n        nn.Linear(width, classes),\n    )",
      "note": "A profundidade é contada como os artigos contam, em camadas que têm pesos. Uma primeira convolução leva o único canal de tinta a 16, os blocos vêm depois, e a cabeça tira a média de cada mapa num número só e lê os 16 números com uma camada linear. Entre as execuções, só `layers` muda."
    }
  ]
}
```

E um programa que a treina com 4, 8, 12 e 20 camadas, com todo o resto fixo. Salve como
`~/dl/depth.py`:

```schooling-example
{
  "language": "python",
  "file": "depth.py",
  "parts": [
    {
      "code": "\"\"\"depth: the same network at four depths, trained the same way, with or without skips.\"\"\"\nimport sys\n\nimport torch\n\nimport deep\nimport loop\nimport tdigits\n\nblock = getattr(deep, sys.argv[1])\ntrain, val, _ = tdigits.load(images=True)",
      "note": "O nome do bloco vem da linha de comando, `Plain` aqui e `Residual` na próxima seção. Os dígitos chegam como imagens 1x8x8 pelo `tdigits.py` da aula 9."
    },
    {
      "code": "for layers in (4, 8, 12, 20):\n    torch.manual_seed(0)\n    model = deep.make(layers, block)\n    opt = torch.optim.Adam(model.parameters(), lr=0.003)\n    history = loop.fit(model, opt, train, val, epochs=20, every=20)",
      "note": "Quatro profundidades, cada uma da mesma semente, com o mesmo otimizador, a mesma taxa e o mesmo número de épocas. O `loop.py` da aula 9 as treina e imprime a última época."
    },
    {
      "code": "    print(f\"{layers} layers, {sum(p.numel() for p in model.parameters())} parameters\")\n    print(\"  train loss by epoch:\", \" \".join(f\"{h[1]:.2f}\" for h in history))",
      "note": "A perda de treino de cada época numa linha. É a perda nas imagens com que a rede aprende, o número que diz se o otimizador está chegando a algum lugar."
    }
  ]
}
```

```
ana@vm:~/dl$ python depth.py Plain
epoch  20  train loss 0.2585  val loss 0.3467  val acc 0.894
4 layers, 4970 parameters
  train loss by epoch: 2.31 2.29 2.22 1.95 1.63 1.33 1.07 0.97 0.77 0.66 0.57 0.51 0.43 0.40 0.38 0.33 0.32 0.32 0.28 0.26
epoch  20  train loss 0.0783  val loss 0.1454  val acc 0.944
8 layers, 14250 parameters
  train loss by epoch: 2.31 2.17 1.86 1.68 1.46 1.24 1.06 0.81 0.71 0.53 0.39 0.32 0.29 0.27 0.23 0.11 0.12 0.14 0.08 0.08
epoch  20  train loss 0.3691  val loss 0.6342  val acc 0.828
12 layers, 23530 parameters
  train loss by epoch: 2.32 2.31 2.30 2.30 2.21 2.02 1.69 1.50 1.23 1.15 1.24 0.92 0.86 0.77 0.70 0.61 0.55 0.48 0.45 0.37
epoch  20  train loss 2.3013  val loss 2.3078  val acc 0.086
20 layers, 42090 parameters
  train loss by epoch: 2.31 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30 2.30
```

Leia primeiro as contagens de parâmetros. Ir de 4 camadas para 20 os multiplica por mais de oito,
de 4.970 para 42.090, então a rede profunda tem toda a chance de se ajustar ao conjunto de treino.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 320\" role=\"img\" aria-label=\"Um gráfico de linhas da perda de treino contra a época, de 1 a 20, para a rede comum com 4, 8, 12 e 20 camadas. 4 camadas: de 2,31 a 0,26; 8 camadas: de 2,31 a 0,08; 12 camadas: de 2,32 a 0,37; 20 camadas: de 2,31 a 2,30.\"><path d=\"M70 260 L510 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 30 L70 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M66 260.0 L70 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M66 212.08333333333331 L70 212.08333333333331\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"212.08333333333331\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M66 164.16666666666666 L70 164.16666666666666\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"164.16666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0</text><path d=\"M66 116.25 L70 116.25\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"116.25\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.5</text><path d=\"M66 68.33333333333331 L70 68.33333333333331\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"62\" y=\"68.33333333333331\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2.0</text><path d=\"M70.0 260 L70.0 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M162.6315789473684 260 L162.6315789473684 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"162.6315789473684\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M278.42105263157896 260 L278.42105263157896 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"278.42105263157896\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M394.2105263157895 260 L394.2105263157895 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"394.2105263157895\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">15</text><path d=\"M510.0 260 L510.0 264\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"510.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><text x=\"290.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">época</text><text x=\"30\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">perda de treino</text><path d=\"M70.0 38.6 L93.2 40.5 L116.3 47.2 L139.5 73.1 L162.6 103.8 L185.8 132.5 L208.9 157.5 L232.1 167.0 L255.3 186.2 L278.4 196.8 L301.6 205.4 L324.7 211.1 L347.9 218.8 L371.1 221.7 L394.2 223.6 L417.4 228.4 L440.5 229.3 L463.7 229.3 L486.8 233.2 L510.0 235.1\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><path d=\"M70.0 38.6 L93.2 52.0 L116.3 81.8 L139.5 99.0 L162.6 120.1 L185.8 141.2 L208.9 158.4 L232.1 182.4 L255.3 192.0 L278.4 209.2 L301.6 222.6 L324.7 229.3 L347.9 232.2 L371.1 234.1 L394.2 238.0 L417.4 249.5 L440.5 248.5 L463.7 246.6 L486.8 252.3 L510.0 252.3\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70.0 37.7 L93.2 38.6 L116.3 39.6 L139.5 39.6 L162.6 48.2 L185.8 66.4 L208.9 98.0 L232.1 116.2 L255.3 142.1 L278.4 149.8 L301.6 141.2 L324.7 171.8 L347.9 177.6 L371.1 186.2 L394.2 192.9 L417.4 201.5 L440.5 207.3 L463.7 214.0 L486.8 216.9 L510.0 224.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M70.0 38.6 L93.2 39.6 L116.3 39.6 L139.5 39.6 L162.6 39.6 L185.8 39.6 L208.9 39.6 L232.1 39.6 L255.3 39.6 L278.4 39.6 L301.6 39.6 L324.7 39.6 L347.9 39.6 L371.1 39.6 L394.2 39.6 L417.4 39.6 L440.5 39.6 L463.7 39.6 L486.8 39.6 L510.0 39.6\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M530 50 L556 50\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"564\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">4</text><text x=\"580\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">camadas</text><path d=\"M530 74 L556 74\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"564\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">8</text><text x=\"580\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">camadas</text><path d=\"M530 98 L556 98\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"564\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">12</text><text x=\"580\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">camadas</text><path d=\"M530 122 L556 122\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"564\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20</text><text x=\"580\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">camadas</text></svg>", "caption": "Perda de treino por época da rede comum em quatro profundidades, da captura acima."}
```

**Até 8 camadas, a profundidade ajuda.** A rede de 8 camadas termina com perda de treino de 0,08
contra 0,26 da de 4, e chega a 0,944 na validação contra 0,894. **Depois de 8, piora.** A rede de
12 camadas fica em 2,30 nas quatro primeiras épocas antes de começar a se mexer, e termina em 0,37,
uma perda de treino pior que a da rede de 4 camadas, que tem menos de um quarto dos parâmetros dela. A
rede de 20 camadas nem começa. A perda fica em 2,30, a perda de uma rede que dá a mesma
probabilidade a cada um dos dez dígitos, e a acurácia é 0,086, um único chute fixo para toda imagem.

Duas coisas sobre esta execução valem ser ditas com todas as letras:

- **É a perda de treino que falha**, então nem mais dados nem regularização, os remédios da aula 7,
  ajudam. Eles combatem uma distância entre treino e validação, e a rede de 20 camadas não tem
  distância a fechar: as duas perdas estão paradas.
- **Estas redes não têm normalização**, e isso torna a falha extrema. No artigo da ResNet as redes
  comuns tinham batch normalization (aula 8) e ainda treinavam, só que pior: a rede comum de 34
  camadas terminou com erro de treino maior que a de 18. A forma é a mesma, e a próxima seção
  mostra o que travava o otimizador.
