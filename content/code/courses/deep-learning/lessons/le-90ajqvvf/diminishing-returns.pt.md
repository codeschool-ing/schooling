---
title: Retornos decrescentes
version: 1
---

A última pergunta sobre custo é o que ele compra. Mais treino raramente deixa uma rede pior, então é
fácil continuar pagando por ele. **Cada duplicação do trabalho compra menos que a anterior**, e a
pergunta útil é quando a próxima duplicação deixa de valer o preço.

Há dois jeitos de gastar mais com a rede da aula 9: mais épocas sobre as mesmas imagens, ou mais imagens.
O programa abaixo faz os dois, e depois gasta uma quantidade fixa de aritmética de jeitos diferentes. Ele
usa o `digits.py` da aula 1 e o `tdigits.py`, o `loop.py` e o `mlp.py` da aula 9. Salve como
`~/dl/returns.py`:

```schooling-example
{
  "language": "python",
  "file": "returns.py",
  "parts": [
    {
      "code": "\"\"\"returns: what more epochs, and more data, buy lesson 9's MLP.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\n(x, y), val, _ = tdigits.load()\n\n\ndef run(images, epochs):\n    \"\"\"Lesson 9's recipe on the first `images` training images; the history of every epoch.\"\"\"\n    torch.manual_seed(0)\n    model = make_mlp()\n    opt = torch.optim.SGD(model.parameters(), lr=0.1)\n    return loop.fit(model, opt, (x[:images], y[:images]), val, epochs, every=epochs + 1)",
      "note": "Toda execução é a da aula 9: a mesma semente, SGD a 0,1, lotes de 32. Só mudam o número de imagens de treino e o número de épocas. O `digits.py` embaralhou as imagens antes de dividi-las, então as 135 primeiras são 135 ao acaso. `every=epochs + 1` deixa o `fit` calado."
    },
    {
      "code": "print(\"more epochs, all 1,077 images\")\nlast = None\nfor epoch, _, val_loss, val_acc in run(1077, 128):\n    if epoch in (1, 2, 4, 8, 16, 32, 64, 128):\n        gain = \"\" if last is None else f\"  {100 * (val_acc - last):+.1f} points\"\n        print(f\"  {epoch:3d} epochs  {epoch * 1077:7,d} examples seen  val acc {val_acc:.3f}{gain}\")\n        last = val_acc",
      "note": "Uma execução de 128 épocas, lida a cada duplicação. Cada linha tem o dobro da aritmética da linha de cima, e a última coluna é o que essa duplicação comprou, em pontos percentuais."
    },
    {
      "code": "print(\"more images, 30 epochs\")\nlast = None\nfor images in (135, 270, 540, 1077):\n    val_acc = run(images, 30)[-1][3]\n    gain = \"\" if last is None else f\"  {100 * (val_acc - last):+.1f} points\"\n    print(f\"  {images:4d} images  {images * 30:7,d} examples seen  val acc {val_acc:.3f}{gain}\")\n    last = val_acc\n\nprint(\"the same arithmetic as 1,077 images for 30 epochs, spent on fewer images\")\nfor images, epochs in ((270, 120), (135, 240)):\n    print(f\"  {images:4d} images for {epochs} epochs: val acc {run(images, epochs)[-1][3]:.3f}\")",
      "note": "Depois o outro jeito de gastar mais: as mesmas 30 épocas sobre o dobro de imagens a cada vez. As duas últimas execuções gastam exatamente a aritmética da execução completa, 1.077 imagens por 30 épocas, num quarto e num oitavo das imagens, passando por elas mais vezes."
    }
  ]
}
```

```
ana@vm:~/dl$ python returns.py
more epochs, all 1,077 images
    1 epochs    1,077 examples seen  val acc 0.336
    2 epochs    2,154 examples seen  val acc 0.719  +38.3 points
    4 epochs    4,308 examples seen  val acc 0.839  +11.9 points
    8 epochs    8,616 examples seen  val acc 0.914  +7.5 points
   16 epochs   17,232 examples seen  val acc 0.939  +2.5 points
   32 epochs   34,464 examples seen  val acc 0.956  +1.7 points
   64 epochs   68,928 examples seen  val acc 0.964  +0.8 points
  128 epochs  137,856 examples seen  val acc 0.969  +0.6 points
more images, 30 epochs
   135 images    4,050 examples seen  val acc 0.861
   270 images    8,100 examples seen  val acc 0.903  +4.2 points
   540 images   16,200 examples seen  val acc 0.931  +2.8 points
  1077 images   32,310 examples seen  val acc 0.950  +1.9 points
the same arithmetic as 1,077 images for 30 epochs, spent on fewer images
   270 images for 120 epochs: val acc 0.942
   135 images for 240 epochs: val acc 0.922
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 360\" role=\"img\" aria-label=\"Acurácia de validação da rede da aula 9 contra o número de exemplos de treino que ela viu, numa escala que dobra. Uma linha soma épocas sobre todas as 1.077 imagens, de 4 a 128 épocas; as subidas encolhem a cada duplicação e ela achata perto do topo. A outra linha soma imagens a 30 épocas, de 135 a 1.077, e ainda sobe forte quando as imagens acabam. Duas marcas mostram execuções que gastam a aritmética de 1.077 imagens por 30 épocas num quarto e num oitavo das imagens; as duas ficam abaixo da execução completa.\"><path d=\"M70 257.5 L650 257.5\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"257.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.84</text><path d=\"M70 192.49999999999994 L650 192.49999999999994\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"192.49999999999994\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.88</text><path d=\"M70 127.49999999999989 L650 127.49999999999989\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"127.49999999999989\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.92</text><path d=\"M70 62.50000000000003 L650 62.50000000000003\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"62.50000000000003\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.96</text><path d=\"M81.87086196820171 30 L81.87086196820171 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"81.87086196820171\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4,308</text><path d=\"M192.7945780752896 30 L192.7945780752896 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"192.7945780752896\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8,616</text><path d=\"M303.71829418237746 30 L303.71829418237746 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"303.71829418237746\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">17,232</text><path d=\"M414.64201028946536 30 L414.64201028946536 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"414.64201028946536\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">34,464</text><path d=\"M525.5657263965535 30 L525.5657263965535 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"525.5657263965535\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">68,928</text><path d=\"M636.4894425036414 30 L636.4894425036414 290\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"636.4894425036414\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">137,856</text><path d=\"M70 290 L650 290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 30 L70 290\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360.0\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">exemplos vistos, dobrando a cada linha da grade</text><text x=\"30\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">acurácia de validação</text><path d=\"M81.9 259.1 L192.8 137.2 L303.7 96.6 L414.6 69.0 L525.6 56.0 L636.5 47.9\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"81.9\" cy=\"259.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"192.8\" cy=\"137.2\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"303.7\" cy=\"96.6\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"414.6\" cy=\"69.0\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"525.6\" cy=\"56.0\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"636.5\" cy=\"47.9\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"630.4894425036414\" y=\"31.87500000000003\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">todas as 1.077 imagens, mais épocas</text><path d=\"M72.0 223.4 L182.9 155.1 L293.8 109.6 L404.3 78.8\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"7 4\"></path><circle cx=\"72.0\" cy=\"223.4\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><circle cx=\"182.9\" cy=\"155.1\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><circle cx=\"293.8\" cy=\"109.6\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><circle cx=\"404.3\" cy=\"78.8\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></circle><text x=\"196.9116807418736\" y=\"185.12499999999991\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">30 épocas, mais imagens</text><rect x=\"400.8\" y=\"87.8\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"414.8\" y=\"91.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">270 × 120</text><rect x=\"400.8\" y=\"120.2\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"414.8\" y=\"124.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">135 × 240</text><text x=\"414.7591129560494\" y=\"146.2499999999999\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a mesma aritmética em menos imagens</text></svg>", "caption": "Cada duplicação das épocas compra menos que a anterior. Somar imagens ainda compensava quando as imagens acabaram."}
```

## Épocas

**As duplicações das épocas rendem menos a cada vez.** De 4 para 8 épocas a acurácia subiu de 0,839 para
0,914, 7,5 pontos. As três duplicações seguintes compraram 2,5, 1,7 e 0,8 ponto, e a última, de 64 para
128 épocas, comprou 0,6, por tanta aritmética quanto todas as épocas anteriores juntas. A receita de 30
épocas da aula 9 fica entre as 16 e as 32 desta tabela, no ponto em que os ganhos já ficaram pequenos.

## Imagens

**Mais imagens ainda compensavam quando acabaram.** A 30 épocas, ir de 135 para 270 imagens comprou 4,2
pontos, e as duas duplicações seguintes 2,8 e 1,9. A última delas é mais do que a duplicação equivalente
das épocas comprou. A curva aponta mais dígitos como a próxima coisa que vale a pena pagar, e as 1.077 do
conjunto de treino são todas as que existem.

As duas últimas linhas gastam a aritmética da execução completa, 1.077 imagens por 30 épocas, em menos
imagens vistas mais vezes. **As duas ficam abaixo dela**: 0,942 com um quarto das imagens e 0,922
com um oitavo. Passar de novo por um conjunto pequeno vale menos que ver exemplos novos, porque a rede
aprende os exemplos que tem em vez dos dígitos que eles representam, o sobreajuste da aula 7.

## Onde parar

Modelos grandes mostram a mesma forma, medida ao longo de muito mais duplicações. Estudos de modelos de
linguagem desde 2020 acharam a perda caindo de forma suave como uma potência da computação, dos dados e do
tamanho do modelo. Numa escala que dobra, isso é uma curva cujos ganhos encolhem a cada passo e não chegam
a zero, então a curva sozinha nunca diz para parar. **A decisão é econômica**: a
próxima duplicação custa tanto quanto tudo o que se gastou até ali, e compra menos que a anterior. Se 0,6
ponto vale isso depende de quanto o ponto vale para quem usa o modelo, e esse número não está em
nenhuma captura.

O que as curvas dizem é onde o dinheiro rende mais. Quando as épocas já achataram e as imagens não, o
próximo orçamento é dos dados, coletados ou rotulados, não de uma execução mais longa nem de uma placa
maior. A aula 20 faz a pergunta pelo outro lado: quando os dados são poucos, se uma rede era o modelo
certo.
