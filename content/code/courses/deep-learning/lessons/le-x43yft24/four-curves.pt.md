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
{"svg": "<svg viewBox=\"0 0 700 470\" role=\"img\" aria-label=\"Quatro pequenos gráficos das perdas de treino e de validação por época, das quatro execuções do four.py. Duas unidades ocultas: as duas perdas altas e próximas, ainda caindo devagar, 1,03 e 1,08 na época 40. 150 imagens de treino: a perda de treino cai até 0,003 enquanto a de validação para em cerca de 0,23 e sobe devagar, uma distância grande. Taxa 1,5: as duas perdas caem por quatro épocas, saltam na época 6 e depois ficam paradas em cerca de 2,31. Rótulos embaralhados: a perda de treino cai devagar de 2,26 a 1,91 enquanto a de validação sobe de 2,32 a 2,53.\"><text x=\"190.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">duas unidades ocultas</text><path d=\"M70 190 L350 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 190 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">150 imagens de treino</text><path d=\"M410 190 L690 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 190 L410 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"190.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">taxa 1,5</text><path d=\"M70 405 L350 405\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 405 L70 255\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530.0\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rótulos embaralhados</text><path d=\"M410 405 L690 405\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 405 L410 255\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M200 452 L226 452\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"232\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">perda de treino</text><path d=\"M400 452 L426 452\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"432\" y=\"452\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">perda de validação</text></svg>", "caption": "As quatro execuções do `four.py`, cada uma desenhada a partir das próprias linhas impressas, cada uma na sua escala vertical. É a forma que as distingue."}
```

## Pequena demais: as duas linhas altas, e juntas

```
PENDING small
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
PENDING few
```

**A perda de treino vai a 0,0034** enquanto a de validação para em 0,2317 na época 40 e depois sobe
devagar, até 0,2423 na época 150. A acurácia de validação fica entre 0,919 e 0,928 da época 20 em
diante. Com só 150 imagens, a rede as aprende quase perfeitamente e não aprende mais nada que sirva
para outras. **Isso é overfitting**: uma distância que só aumenta, com a perda de validação virando
para cima.

A acurácia não caiu enquanto a perda subia, e vale ler isso com cuidado. A acurácia só pergunta se o
dígito certo teve a maior nota. A perda pergunta também o quanto a rede estava segura, e uma rede que
continua treinando em 150 imagens fica cada vez mais confiante, inclusive nas imagens de validação que
erra. **Perda de validação subindo com acurácia parada é uma rede ficando confiante demais**, e é o
aviso mais cedo dos dois. Os remédios são o assunto da aula 7.

## Uma taxa alta demais: desce, salta, e fica plana

```
PENDING fast
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
PENDING shuffled
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
