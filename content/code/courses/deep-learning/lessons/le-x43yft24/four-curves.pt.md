---
title: Quatro curvas que deram errado, reconhecidas pela forma
version: 1
---

Quando uma execução decepciona, o reflexo é mudar alguma coisa e rodar de novo: mais épocas, outra
taxa, uma rede maior. **A curva quase sempre diz qual dessas é a mudança certa**, e cada falha comum
desenha uma forma diferente. Esta seção produz quatro delas de propósito, a partir de quatro mudanças
na execução da seção anterior, para que você as reconheça numa execução que não era para falhar.

Salve isto como `~/dl/four.py`. O caso a rodar é dado na linha de comando:

```schooling-example
{
  "language": "python",
  "file": "four.py",
  "parts": [
    {
      "code": "\"\"\"four: four runs that each go wrong in a different way. Name the case on the command line.\"\"\"\nimport sys\n\nimport numpy as np\n\nimport digits\nfrom fit import fit\nfrom optim import SGD\nfrom tinynet import Linear, Net, ReLU\n\n(x, y), val, _ = digits.load()\n\n\ndef make(hidden):\n    rng = np.random.default_rng(0)\n    return Net(Linear(64, hidden, rng), ReLU(), Linear(hidden, 10, rng))",
      "note": "A mesma rede do resto da aula, com a largura da camada oculta como argumento."
    },
    {
      "code": "case = sys.argv[1]\nif case == \"small\":\n    net = make(2)\n    fit(net, SGD(net.params(), 0.1), (x, y), val, epochs=40, every=4)",
      "note": "Duas unidades ocultas em vez de 64. Toda imagem precisa passar por dois números no caminho até as dez classes."
    },
    {
      "code": "elif case == \"few\":\n    net = make(64)\n    fit(net, SGD(net.params(), 0.5), (x[:150], y[:150]), val, epochs=150, every=10)",
      "note": "A rede inteira em só 150 das 1.077 imagens de treino, por 150 épocas. O conjunto de validação é o de sempre, 360."
    },
    {
      "code": "elif case == \"fast\":\n    net = make(64)\n    fit(net, SGD(net.params(), 1.5), (x, y), val, epochs=30, every=2)",
      "note": "Tudo como sempre, menos a taxa: 1,5, quinze vezes o 0,1 que funciona."
    },
    {
      "code": "elif case == \"shuffled\":\n    order = np.random.default_rng(1).permutation(len(y))\n    net = make(64)\n    fit(net, SGD(net.params(), 0.1), (x, y[order]), val, epochs=80, every=8)",
      "note": "Um bug plantado de propósito: os rótulos são embaralhados e as imagens não, então cada imagem passa a carregar o rótulo de outra. O conjunto de validação fica correto."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 470\" role=\"img\" aria-label=\"Quatro pequenos gráficos das perdas de treino e de validação por época, das quatro execuções do four.py. Duas unidades ocultas: as duas perdas altas e próximas, ainda caindo devagar, 1,03 e 1,08 na época 40. 150 imagens de treino: a perda de treino cai até 0,003 enquanto a de validação para em cerca de 0,23 e sobe devagar, uma distância grande. Taxa 1,5: as duas perdas caem por quatro épocas, saltam na época 6 e depois ficam paradas em cerca de 2,31. Rótulos embaralhados: a perda de treino cai devagar de 2,26 a 1,91 enquanto a de validação sobe de 2,32 a 2,53.\"><text x=\"190.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">duas unidades ocultas</text><path d=\"M70 190 L350 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 190 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"64\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"64\" y=\"115.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"64\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"350\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><text x=\"70\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"210.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">época</text><path d=\"M98.0 52.0 L126.0 70.4 L154.0 82.2 L182.0 90.4 L210.0 95.7 L238.0 100.3 L266.0 103.6 L294.0 107.4 L322.0 109.2 L350.0 112.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M98.0 53.1 L126.0 69.1 L154.0 79.9 L182.0 87.4 L210.0 93.4 L238.0 97.4 L266.0 100.0 L294.0 104.5 L322.0 105.5 L350.0 108.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"530.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">150 imagens de treino</text><path d=\"M410 190 L690 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 190 L410 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"404\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"404\" y=\"115.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.25</text><text x=\"404\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><text x=\"690\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><text x=\"410\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"550.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">época</text><path d=\"M428.7 127.2 L447.3 172.2 L466.0 179.9 L484.7 184.0 L503.3 185.8 L522.0 186.8 L540.7 187.4 L559.3 187.8 L578.0 188.1 L596.7 188.4 L615.3 188.5 L634.0 188.6 L652.7 188.8 L671.3 188.9 L690.0 189.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M428.7 91.0 L447.3 107.9 L466.0 117.7 L484.7 120.5 L503.3 119.9 L522.0 120.3 L540.7 120.2 L559.3 119.8 L578.0 118.8 L596.7 119.3 L615.3 118.5 L634.0 118.4 L652.7 117.4 L671.3 117.1 L690.0 117.3\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"190.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">taxa 1,5</text><path d=\"M70 405 L350 405\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 405 L70 255\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"64\" y=\"405.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"64\" y=\"330.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.25</text><text x=\"64\" y=\"255.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2.5</text><text x=\"350\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"70\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"210.0\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">época</text><path d=\"M88.7 305.2 L107.3 320.2 L126.0 265.6 L144.7 284.5 L163.3 276.6 L182.0 266.2 L200.7 266.1 L219.3 266.3 L238.0 266.1 L256.7 266.1 L275.3 266.2 L294.0 265.9 L312.7 266.1 L331.3 266.1 L350.0 266.1\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M88.7 305.6 L107.3 313.4 L126.0 289.6 L144.7 263.5 L163.3 258.8 L182.0 264.9 L200.7 265.4 L219.3 265.4 L238.0 265.8 L256.7 266.2 L275.3 265.8 L294.0 266.0 L312.7 266.2 L331.3 266.5 L350.0 265.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"530.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rótulos embaralhados</text><path d=\"M410 405 L690 405\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 405 L410 255\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"404\" y=\"405.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"404\" y=\"330.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.5</text><text x=\"404\" y=\"255.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"690\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">80</text><text x=\"410\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"550.0\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">época</text><path d=\"M438.0 291.8 L466.0 294.1 L494.0 295.9 L522.0 298.0 L550.0 299.7 L578.0 301.5 L606.0 303.6 L634.0 305.8 L662.0 307.4 L690.0 309.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M438.0 288.9 L466.0 287.8 L494.0 286.8 L522.0 284.1 L550.0 284.7 L578.0 283.8 L606.0 282.2 L634.0 281.9 L662.0 278.7 L690.0 278.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M200 452 L226 452\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"232\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">perda de treino</text><path d=\"M400 452 L426 452\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"432\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">perda de validação</text></svg>", "caption": "As quatro execuções do `four.py`, cada uma desenhada a partir das próprias linhas impressas, cada uma na sua escala vertical. É a forma que as distingue."}
```

## Pequena demais: as duas linhas altas, e juntas

```
ana@vm:~/dl$ python four.py small
epoch   4  train loss 1.8396  val loss 1.8257  val acc 0.372
epoch   8  train loss 1.5941  val loss 1.6126  val acc 0.428
epoch  12  train loss 1.4369  val loss 1.4674  val acc 0.467
epoch  16  train loss 1.3279  val loss 1.3680  val acc 0.475
epoch  20  train loss 1.2569  val loss 1.2886  val acc 0.494
epoch  24  train loss 1.1957  val loss 1.2352  val acc 0.531
epoch  28  train loss 1.1522  val loss 1.1995  val acc 0.558
epoch  32  train loss 1.1019  val loss 1.1399  val acc 0.586
epoch  36  train loss 1.0774  val loss 1.1270  val acc 0.619
epoch  40  train loss 1.0290  val loss 1.0825  val acc 0.608
```

Depois de 40 épocas a perda de treino está em **1,0290 e a de validação em 1,0825**, e a acurácia é
0,608, onde a rede de 64 unidades passou de 0,93 em dez épocas. As duas linhas estão próximas, então a
rede vai quase tão mal nas imagens em que treinou quanto nas novas. **Isso é underfitting**: o modelo
não consegue representar a tarefa, e dois números no meio da rede não carregam o que dez dígitos
precisam. As duas perdas ainda descem, mas devagar, e mais épocas nesse ritmo levariam muito tempo
para chegar a algum lugar. O conserto é capacidade, uma rede mais larga ou mais profunda, antes de mais
treino.

## Imagens de menos: as linhas se separam

```
ana@vm:~/dl$ python four.py few
epoch  10  train loss 0.2094  val loss 0.3300  val acc 0.911
epoch  20  train loss 0.0595  val loss 0.2738  val acc 0.928
epoch  30  train loss 0.0335  val loss 0.2409  val acc 0.928
epoch  40  train loss 0.0199  val loss 0.2317  val acc 0.922
epoch  50  train loss 0.0141  val loss 0.2338  val acc 0.925
epoch  60  train loss 0.0107  val loss 0.2323  val acc 0.922
epoch  70  train loss 0.0087  val loss 0.2327  val acc 0.922
epoch  80  train loss 0.0073  val loss 0.2341  val acc 0.922
epoch  90  train loss 0.0063  val loss 0.2372  val acc 0.922
epoch 100  train loss 0.0054  val loss 0.2358  val acc 0.922
epoch 110  train loss 0.0049  val loss 0.2385  val acc 0.922
epoch 120  train loss 0.0046  val loss 0.2386  val acc 0.925
epoch 130  train loss 0.0039  val loss 0.2421  val acc 0.922
epoch 140  train loss 0.0037  val loss 0.2431  val acc 0.922
epoch 150  train loss 0.0034  val loss 0.2423  val acc 0.919
```

**A perda de treino vai a 0,0034** enquanto a de validação para em 0,2317 na época 40 e depois sobe
devagar, até 0,2423 na época 150. A acurácia de validação fica entre 0,919 e 0,928 da época 20 em
diante. Com só 150 imagens, a rede as aprende quase perfeitamente e não aprende mais nada que sirva
para outras. **Isso é overfitting**: uma distância que só aumenta, com a perda de validação virando
para cima.

A acurácia não caiu enquanto a perda subia, e o motivo está no que cada uma mede. A acurácia só pergunta se o
dígito certo teve a maior nota. A perda pergunta também o quanto a rede estava segura, e uma rede que
continua treinando em 150 imagens fica cada vez mais confiante, inclusive nas imagens de validação que
erra. **Perda de validação subindo com acurácia parada é uma rede ficando confiante demais**, e é o
aviso mais cedo dos dois. Os remédios são o assunto da aula 7.

## Uma taxa alta demais: desce, salta, e fica plana

```
ana@vm:~/dl$ python four.py fast
epoch   2  train loss 1.6638  val loss 1.6560  val acc 0.358
epoch   4  train loss 1.4140  val loss 1.5263  val acc 0.578
epoch   6  train loss 2.3233  val loss 1.9234  val acc 0.217
epoch   8  train loss 2.0086  val loss 2.3585  val acc 0.097
epoch  10  train loss 2.1405  val loss 2.4366  val acc 0.106
epoch  12  train loss 2.3139  val loss 2.3357  val acc 0.106
epoch  14  train loss 2.3154  val loss 2.3270  val acc 0.089
epoch  16  train loss 2.3119  val loss 2.3275  val acc 0.086
epoch  18  train loss 2.3143  val loss 2.3204  val acc 0.106
epoch  20  train loss 2.3154  val loss 2.3141  val acc 0.111
epoch  22  train loss 2.3140  val loss 2.3194  val acc 0.086
epoch  24  train loss 2.3185  val loss 2.3163  val acc 0.086
epoch  26  train loss 2.3151  val loss 2.3138  val acc 0.092
epoch  28  train loss 2.3150  val loss 2.3082  val acc 0.117
epoch  30  train loss 2.3147  val loss 2.3298  val acc 0.097
```

Por quatro épocas esta execução aprende: a acurácia de validação chega a 0,578. Na época 6 a perda de
treino salta para 2,3233, e a partir da época 12 as duas perdas ficam **planas, entre 2,30 e 2,34**.
Esse nível não é arbitrário. Uma rede que dá a mesma probabilidade a cada uma das dez classes tem
entropia cruzada de −ln(1/10) = ln 10 ≈ 2,303, a perda de quem não sabe nada, como a aula 4 calculou.
Um passo foi grande o bastante para jogar os pesos num lugar de onde nunca voltaram, e da época 8 em
diante a acurácia de validação fica entre 0,086 e 0,117, que é o acaso.

**Uma curva que cai e depois salta é uma taxa alta demais.** Baixe a taxa, ou acrescente o warm-up da
aula 5, antes de mexer em qualquer outra coisa.

## Um bug: o treino melhora e a validação não

```
ana@vm:~/dl$ python four.py shuffled
epoch   8  train loss 2.2636  val loss 2.3225  val acc 0.125
epoch  16  train loss 2.2190  val loss 2.3447  val acc 0.111
epoch  24  train loss 2.1814  val loss 2.3635  val acc 0.086
epoch  32  train loss 2.1396  val loss 2.4186  val acc 0.100
epoch  40  train loss 2.1054  val loss 2.4054  val acc 0.103
epoch  48  train loss 2.0694  val loss 2.4232  val acc 0.106
epoch  56  train loss 2.0277  val loss 2.4564  val acc 0.097
epoch  64  train loss 1.9849  val loss 2.4628  val acc 0.114
epoch  72  train loss 1.9513  val loss 2.5259  val acc 0.100
epoch  80  train loss 1.9098  val loss 2.5312  val acc 0.094
```

**A perda de treino cai, devagar e sem parar, de 2,2636 para 1,9098**, então o laço está fazendo
alguma coisa. A perda de validação sobe de 2,3225 para 2,5312, e a acurácia de validação fica entre
0,086 e 0,125 a execução inteira. Com os rótulos embaralhados, não há nada a aprender sobre dígitos. A
rede está decorando qual rótulo arbitrário vai com qual imagem, o que uma rede com mais de 4.000 pesos
consegue fazer para 1.077 imagens com tempo, e essa memória não serve para nada em imagens que ela não
viu.

**Acurácia de validação no acaso enquanto a perda de treino cai aponta para os dados, não para o
modelo.** Os rótulos, a ordem de uma divisão, um pré-processamento aplicado a um conjunto e não ao
outro: são essas coisas que produzem esta forma, e nenhuma mudança de taxa ou de rede as conserta. A
primeira coisa a conferir é um punhado de imagens impressas ao lado dos rótulos, como o `look.py` da
aula 1 fez.

## As quatro, lado a lado

| forma | o que é | primeira coisa a mudar |
| --- | --- | --- |
| as duas perdas altas, juntas, lentas | underfitting | o tamanho da rede |
| perda de treino perto de zero, a de validação virando para cima | overfitting | os dados ou a regularização (aula 7) |
| cai, salta, depois plana perto de 2,30 | taxa alta demais | a taxa, ou um warm-up |
| perda de treino cai, acurácia de validação em 0,1 | bug nos dados | os rótulos e o pipeline |
