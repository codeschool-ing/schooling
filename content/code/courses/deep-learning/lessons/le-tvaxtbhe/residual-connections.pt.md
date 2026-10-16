---
title: Conexões residuais, e o gradiente que elas deixam passar
version: 1
---

O argumento da seção anterior era que camadas extras sempre poderiam aprender a deixar a entrada
passar sem mudança. **Isso acaba sendo difícil de aprender para uma pilha de convoluções**: a
identidade é um ajuste exato de milhares de pesos, e nada no treino mira nele. Kaiming He e colegas
mudaram a pergunta em 2015. Em vez de pedir a saída a um bloco, peça **uma correção da entrada**, e
some a entrada de volta:

```
output = relu(x + f(x))
```

Se as convoluções não aprendem nada útil, `f(x)` pode ficar perto de zero e o bloco deixa `x`
passar, que é o ajuste fácil de achar. Se aprendem algo, isso é somado ao que já estava lá.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"Um bloco residual desenhado da esquerda para a direita. A entrada x entra, passa por uma convolução 3 por 3, um ReLU e uma segunda convolução 3 por 3, que juntos dão f(x). Uma segunda linha leva x em volta deles sem mudança. As duas se encontram num sinal de mais, seguido de um ReLU. Uma nota diz que, se as convoluções não aprendem nada, f(x) é zero e o bloco deixa x passar.\"><text x=\"30\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper)\">x</text><path d=\"M42 130 L90 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M82.6 133.1 L90 130 L82.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"90\" y=\"110\" width=\"100\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"140.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">conv 3x3</text><rect x=\"230\" y=\"110\" width=\"80\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ReLU</text><rect x=\"350\" y=\"110\" width=\"100\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"400.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">conv 3x3</text><path d=\"M190 130 L230 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M222.6 133.1 L230 130 L222.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M310 130 L350 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M342.6 133.1 L350 130 L342.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 130 L506 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M498.6 133.1 L506 130 L498.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"520\" cy=\"130\" r=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"520\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">+</text><path d=\"M534 130 L574 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M566.6 133.1 L574 130 L566.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"574\" y=\"110\" width=\"80\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"614\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ReLU</text><path d=\"M654 130 L684 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M676.6 133.1 L684 130 L676.6 126.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"270\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">caminho comum: f(x)</text><path d=\"M60 130 L60 50 L520 50 L520 108\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M520 100 L520 116\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M516.9 108.6 L520 116 L523.1 108.6\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"290\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">o atalho: x sem mudança</text><text x=\"350\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Se as convoluções não aprendem nada, f(x) é 0 e o bloco deixa x passar.</text></svg>", "caption": "Um bloco residual: duas convoluções calculam uma correção, e a entrada é somada de volta a ela."}
```

Em código é uma linha. Acrescente esta classe ao fim do `~/dl/deep.py`:

```schooling-example
{
  "language": "python",
  "file": "deep.py",
  "parts": [
    {
      "code": "class Residual(Plain):\n    \"\"\"The same two convolutions, with the input added back before the last ReLU.\"\"\"\n\n    def forward(self, x):\n        return self.relu(x + self.conv2(self.relu(self.conv1(x))))",
      "note": "Acrescente isto ao fim do `deep.py`. A classe herda as duas convoluções de `Plain`, então tem exatamente os mesmos parâmetros, e muda uma linha: `x +` antes do segundo ReLU. O atalho em si não aprende nada."
    }
  ]
}
```

O bloco tem as mesmas duas convoluções e a mesma contagem de parâmetros de `Plain`, então a
comparação é justa: o mesmo programa, as mesmas sementes, e o atalho como única mudança.

```
ana@vm:~/dl$ python depth.py Residual
epoch  20  train loss 0.2515  val loss 0.2521  val acc 0.925
4 layers, 4970 parameters
  train loss by epoch: 2.31 2.28 2.18 1.85 1.49 1.18 0.96 0.83 0.67 0.62 0.51 0.46 0.40 0.34 0.33 0.28 0.30 0.26 0.26 0.25
epoch  20  train loss 0.0671  val loss 0.1190  val acc 0.956
8 layers, 14250 parameters
  train loss by epoch: 2.31 2.21 1.90 1.70 1.45 1.13 0.81 0.56 0.40 0.44 0.34 0.24 0.19 0.17 0.16 0.16 0.11 0.09 0.13 0.07
epoch  20  train loss 0.0369  val loss 0.0952  val acc 0.964
12 layers, 23530 parameters
  train loss by epoch: 2.32 2.30 2.10 1.42 0.96 0.61 0.42 0.36 0.25 0.23 0.21 0.22 0.15 0.07 0.09 0.12 0.10 0.12 0.12 0.04
epoch  20  train loss 0.0851  val loss 0.1853  val acc 0.942
20 layers, 42090 parameters
  train loss by epoch: 2.31 2.27 2.15 1.82 1.63 1.27 1.02 0.65 0.47 0.36 0.25 0.21 0.15 0.19 0.16 0.24 0.15 0.13 0.10 0.09
```

**Com os atalhos, toda profundidade treina.** A rede residual de 12 camadas termina com perda de
treino de 0,04 e acurácia de validação de 0,964, a melhor das oito execuções. A de 20 camadas, que
como rede comum ficou em 2,30 por vinte épocas, termina em 0,09 e 0,942. Ela não é melhor que a de
12 camadas com 1.077 imagens e vinte épocas, e os atalhos não prometem isso; prometem que acrescentar
camadas deixa de impedir o treino. As contagens de parâmetros são as mesmas das redes comuns, linha
a linha.

O motivo está no gradiente. Antes de qualquer treino, dê um lote às duas redes de 20 camadas, rode
uma passada para trás e meça o gradiente que chega a cada bloco. Salve como `~/dl/grads.py`:

```schooling-example
{
  "language": "python",
  "file": "grads.py",
  "parts": [
    {
      "code": "\"\"\"grads: how much gradient reaches each block of a 20-layer network, before any training.\"\"\"\nimport torch\nimport torch.nn.functional as F\n\nimport deep\nimport tdigits\n\n(x, y), _, _ = tdigits.load(images=True)"
    },
    {
      "code": "for block in (deep.Plain, deep.Residual):\n    torch.manual_seed(0)\n    model = deep.make(20, block)\n    F.cross_entropy(model(x[:32]), y[:32]).backward()",
      "note": "As duas redes partem da mesma semente, então os pesos são idênticos; só o passo para a frente muda. Um lote de 32, uma passada para trás, nenhum passo do otimizador."
    },
    {
      "code": "    norms = [m.conv1.weight.grad.norm().item() for m in model if isinstance(m, deep.Plain)]\n    print(f\"{block.__name__:8s} block 1 to 9:\", \" \".join(f\"{n:.0e}\" for n in norms))",
      "note": "O tamanho do gradiente na primeira convolução de cada um dos nove blocos, da ponta da entrada à ponta da saída. `Residual` é subclasse de `Plain`, então o mesmo teste acha os blocos das duas."
    }
  ]
}
```

```
ana@vm:~/dl$ python grads.py
Plain    block 1 to 9: 2e-09 2e-09 3e-08 1e-07 1e-06 7e-06 5e-05 6e-04 4e-03
Residual block 1 to 9: 2e-02 5e-02 7e-02 5e-02 7e-02 9e-02 7e-02 1e-01 6e-02
```

**Na rede comum o gradiente encolhe em quase todo bloco no caminho de volta**, de três a
quinze vezes na maioria deles, e o primeiro bloco recebe um gradiente mais de um milhão de vezes menor que o do
último. Os pesos dele
quase não se mexem, os blocos seguintes leem algo perto de ruído, e a pilha inteira trava: os
gradientes que desaparecem da aula 3, agindo numa rede de verdade. Na rede residual todo bloco
recebe um gradiente do mesmo tamanho. A soma copia o gradiente da saída direto para a entrada,
porque a derivada de `x + f(x)` em relação a `x` é 1 mais o que `f` contribuir, então sempre há um
caminho de volta em que nada é multiplicado até sumir.

Essa é toda a mudança da ResNet. O resto da arquitetura são as pilhas de convoluções 3x3 da VGG com
batch normalization, e a próxima seção desmonta a versão do torchvision.
