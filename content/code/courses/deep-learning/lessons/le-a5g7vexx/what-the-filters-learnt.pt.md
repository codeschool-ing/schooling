---
title: O que os filtros aprenderam
version: 1
---

O `filter.py` usou um filtro que alguém escreveu. A primeira camada da rede tem dezesseis, e **ninguém
escreveu nenhum deles**: começaram como números aleatórios pequenos, e o gradiente os moveu, passo a
passo, na direção do que fazia a perda cair. O `compare.py` salvou os pesos treinados em `cnn.pt`. Este
programa os lê de volta e imprime a primeira camada. Salve como `~/dl/filters.py`:

```schooling-example
{
  "language": "python",
  "file": "filters.py",
  "parts": [
    {
      "code": "\"\"\"filters: the sixteen 3x3 filters of the first layer, before and after training.\"\"\"\nimport torch\n\nimport cnn\n\ntorch.manual_seed(0)\nstart = cnn.make_cnn()[0].weight.detach()\nnet = cnn.make_cnn()\nnet.load_state_dict(torch.load(\"cnn.pt\"))\nw = net[0].weight.detach()\nprint(f\"largest weight: {start.abs().max():.2f} at the start, {w.abs().max():.2f} after training\")",
      "note": "A mesma semente do `compare.py` remonta a rede exatamente como o treino a recebeu, então `start` guarda os filtros antes do primeiro passo. `net` recebe os pesos salvos, e `net[0]` é a primeira convolução."
    },
    {
      "code": "w = w.reshape(16, 3, 3)\nfor first in range(0, 16, 4):\n    group = range(first, first + 4)\n    print(\"   \".join(f\"filter {i}\".ljust(17) for i in group).rstrip())\n    for row in range(3):\n        print(\"   \".join(\" \".join(f\"{v:5.2f}\" for v in w[i, row]) for i in group))",
      "note": "O peso é 16 por 1 por 3 por 3; tirando o canal de tamanho 1, sobram dezesseis grades 3x3, impressas de quatro em quatro, lado a lado."
    }
  ]
}
```

```
PENDING filters
```

**Os filtros andaram bastante desde onde começaram.** O PyTorch inicia uma camada cujas unidades leem 9
entradas cada com pesos entre -1/3 e 1/3, que é o 0,33 da primeira linha; depois do treino, o maior é
0,57. Desenhados como grades, com uma cor para pesos acima de zero e outra para pesos abaixo, os números
impressos ficam assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Os dezesseis filtros 3 por 3 da primeira camada depois do treino, desenhados como grades de quadrados em duas fileiras de oito. Cada quadrado tem a cor do seu peso: uma cor para pesos positivos e outra para negativos, mais forte para valores maiores. Vários filtros têm uma faixa de um sinal ao lado de uma faixa do outro, que é uma borda em algum ângulo.\"><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">PENDING</text></svg>", "caption": "Os dezesseis filtros da primeira camada depois de 30 épocas, desenhados a partir dos pesos impressos. Ninguém escolheu esses padrões; o gradiente escolheu."}
```

Vários deles são detectores de borda do tipo que o `filter.py` usou, em ângulos que ninguém pediu. **O
filtro 8 é positivo ao longo do topo e da esquerda e negativo no canto de baixo à direita**: ele
responde onde a tinta de um traço fica acima e à esquerda de um espaço em branco, uma borda diagonal. O
filtro 15 fica perto de zero na linha de cima e positivo abaixo dela, então responde pela borda de cima
de um traço horizontal. O filtro 6 tem os pesos mais negativos na linha do meio e os maiores positivos
nos cantos e na linha de baixo: uma linha em branco entre dois traços, como o meio de uma volta,
combinaria com ele.

**Leia isso como palpite, não como achado.** Em imagens 8 por 8, um filtro 3 por 3 cobre um pedaço
grande do dígito, e alguns dos dezesseis não se parecem com nada em particular. A segunda camada combina
os dezesseis mapas por meio de 4.640 pesos, e o que a rede usa é essa combinação, não um filtro
sozinho. Em fotografias grandes, os filtros da primeira camada são muito mais arrumados: a rede de
Krizhevsky, Sutskever e Hinton, em 2012, desenhou os seus 96 filtros da primeira camada, e eles são
bordas orientadas e manchas de cor, aprendidas só a partir de imagens.
