---
title: A curva que todo planejador deveria conhecer
version: 1
---

A crença mais cara do planejamento é a de que **um time é mais eficiente quando todo mundo está totalmente ocupado**. Parece economia pura: tempo ocioso é pago e não produz nada. Aplicada a um time que recebe trabalho que ele não controla por completo, ela produz exatamente o contrário do que promete, e o motivo é uma curva.

**Salve o programa abaixo como `queue.py`.** Ele não precisa de arquivo de dados: simula uma pessoa que recebe pedidos ao acaso e leva cerca de um dia em cada um, e mede quanto tempo os pedidos esperam antes de o trabalho neles começar, à medida que a pessoa fica mais ocupada.

```schooling-example
{
  "language": "python",
  "file": "queue.py",
  "parts": [
    {
      "code": "\"\"\"queue.py: how long work waits in front of one person, as they get busier.\"\"\"\nimport random\n\nITEMS = 20000\nrng = random.Random(12)\n",
      "note": "**Desta vez não há arquivo de dados.** O programa faz os próprios pedidos: vinte mil para cada nível de ocupação, com semente fixa para a sua rodada bater com a da aula."
    },
    {
      "code": "\nprint(\"busy   waiting before work starts (days)\")\nfor busy in (0.5, 0.6, 0.7, 0.8, 0.9, 0.95):\n    free_at, arrival, total_wait = 0.0, 0.0, 0.0\n",
      "note": "**Seis níveis de ocupação**, de metade do tempo da pessoa a noventa e cinco por cento dele. `busy` é quanto trabalho chega comparado com quanto a pessoa consegue fazer."
    },
    {
      "code": "    for _ in range(ITEMS):\n        arrival += rng.expovariate(busy)               # requests arrive at random\n        start = max(arrival, free_at)                  # wait if the person is busy\n        total_wait += start - arrival\n        free_at = start + rng.expovariate(1.0)         # one day of work, on average\n",
      "note": "**Uma fila em quatro linhas.** Pedidos chegam em momentos aleatórios, num ritmo dado por `busy`. Cada um começa assim que chega ou assim que a pessoa fica livre, o que vier depois, e a diferença é a espera dele. Cada um leva em média um dia de trabalho, às vezes bem menos, às vezes bem mais."
    },
    {
      "code": "    wait = total_wait / ITEMS\n    print(f\"{busy:4.0%}   {wait:5.1f}  {'#' * round(wait * 2)}\")\n",
      "note": "**A espera média em cada nível**, com uma barra de dois `#` por dia."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 queue.py
busy   waiting before work starts (days)
 50%     1.1  ##
 60%     1.5  ###
 70%     2.2  ####
 80%     4.2  ########
 90%     7.3  ###############
 95%    18.4  #####################################
```

## Lendo a curva

Com metade da ocupação, um pedido espera cerca de um dia antes de alguém mexer nele. Com 80%, espera uns quatro. Com 95%, espera dezoito, por um dia de trabalho. **A espera não cresce na proporção da ocupação; ela explode à medida que a ocupação se aproxima de 100%.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 290\" role=\"img\" data-fig=\"l12-curve\" aria-label=\"Uma curva do tempo de espera contra a ocupação de uma pessoa, de 30% a 97%. A curva, ocupação dividida por um menos a ocupação, fica abaixo de dois dias até uns 65% e então sobe forte, passando de 9 dias em 90% e 19 em 95%. Pontos marcam as seis médias simuladas, que ficam perto da curva.\"><path d=\"M60.0 40.0 L60.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 200.0 L640.0 200.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><path d=\"M60.0 160.0 L640.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M60.0 120.0 L640.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">15</text><path d=\"M60.0 80.0 L640.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M60.0 40.0 L640.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">25</text><path d=\"M60.0 240.0 L640.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 236.6 L64.1 236.5 L68.3 236.4 L72.4 236.3 L76.6 236.2 L80.7 236.1 L84.9 236.1 L89.0 236.0 L93.1 235.9 L97.3 235.8 L101.4 235.7 L105.6 235.6 L109.7 235.5 L113.9 235.4 L118.0 235.3 L122.1 235.2 L126.3 235.1 L130.4 235.0 L134.6 234.9 L138.7 234.8 L142.9 234.7 L147.0 234.6 L151.1 234.4 L155.3 234.3 L159.4 234.2 L163.6 234.1 L167.7 234.0 L171.9 233.8 L176.0 233.7 L180.1 233.6 L184.3 233.5 L188.4 233.3 L192.6 233.2 L196.7 233.0 L200.9 232.9 L205.0 232.8 L209.1 232.6 L213.3 232.5 L217.4 232.3 L221.6 232.2 L225.7 232.0 L229.9 231.8 L234.0 231.7 L238.1 231.5 L242.3 231.3 L246.4 231.2 L250.6 231.0 L254.7 230.8 L258.9 230.6 L263.0 230.4 L267.1 230.2 L271.3 230.0 L275.4 229.8 L279.6 229.6 L283.7 229.4 L287.9 229.2 L292.0 229.0 L296.1 228.7 L300.3 228.5 L304.4 228.2 L308.6 228.0 L312.7 227.7 L316.9 227.5 L321.0 227.2 L325.1 226.9 L329.3 226.7 L333.4 226.4 L337.6 226.1 L341.7 225.8 L345.9 225.5 L350.0 225.1 L354.1 224.8 L358.3 224.5 L362.4 224.1 L366.6 223.8 L370.7 223.4 L374.9 223.0 L379.0 222.6 L383.1 222.2 L387.3 221.8 L391.4 221.3 L395.6 220.9 L399.7 220.4 L403.9 219.9 L408.0 219.4 L412.1 218.9 L416.3 218.4 L420.4 217.8 L424.6 217.2 L428.7 216.6 L432.9 216.0 L437.0 215.3 L441.1 214.7 L445.3 214.0 L449.4 213.2 L453.6 212.4 L457.7 211.6 L461.9 210.8 L466.0 209.9 L470.1 209.0 L474.3 208.0 L478.4 207.0 L482.6 205.9 L486.7 204.8 L490.9 203.6 L495.0 202.3 L499.1 200.9 L503.3 199.5 L507.4 198.0 L511.6 196.4 L515.7 194.7 L519.9 192.8 L524.0 190.9 L528.1 188.7 L532.3 186.5 L536.4 184.0 L540.6 181.3 L544.7 178.4 L548.9 175.3 L553.0 171.8 L557.1 168.0 L561.3 163.8 L565.4 159.1 L569.6 153.9 L573.7 148.0 L577.9 141.3 L582.0 133.7 L586.1 124.9 L590.3 114.7 L594.4 102.5 L598.6 88.0 L602.7 70.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"225.7\" cy=\"231.5\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"308.6\" cy=\"227.8\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"391.4\" cy=\"222.0\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"474.3\" cy=\"206.4\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"557.1\" cy=\"181.6\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"598.6\" cy=\"92.4\" r=\"4.5\" fill=\"var(--amber)\"></circle><text x=\"60.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30%</text><text x=\"225.7\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><text x=\"391.4\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">70%</text><text x=\"557.1\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90%</text><text x=\"640.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"350.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quão ocupada a pessoa está: trabalho que chega ÷ trabalho que ela faz</text><text x=\"60.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dias, em média, que um pedido espera antes de começar</text><text x=\"325.1\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a fórmula: ocupação ÷ (1 − ocupação)</text><text x=\"325.1\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">pontos: queue.py</text></svg>", "caption": "A espera é pequena e quase plana por um bom trecho, e depois não é mais. Os últimos dez pontos de ocupação custam mais que os noventa primeiros."}
```

A teoria das filas tem uma fórmula para este caso: a espera média, em unidades do trabalho, é **ocupação ÷ (1 − ocupação)**. Ela dá 1,0, 1,5, 2,3, 4,0, 9,0 e 19,0 para os seis níveis, e a simulação fica perto de cada um; fica abaixo em 90% porque vinte mil pedidos aleatórios ainda são uma amostra, e outra semente cairia em outro ponto em torno de 9. O número exato importa menos que a forma, que toda fila com chegadas aleatórias e trabalho variável compartilha.

## Por que ela explode

Duas coisas juntas produzem a curva: **variabilidade e nenhuma folga**. Os pedidos não chegam de maneira uniforme e o trabalho não leva sempre o mesmo tempo. Com 50% de ocupação, um amontoado de pedidos ou um item longo é absorvido pelo tempo ocioso que vem depois. Com 95% quase não há tempo ocioso para absorver nada, então todo amontoado vira fila, e a fila só esvazia quando a pessoa por acaso tem um período tranquilo, o que com 95% quase nunca acontece.

Tire qualquer uma das causas e a curva se achata. Uma pessoa cujo trabalho chega num cronograma perfeito e leva sempre exatamente um dia consegue operar perto de 100% sem fila nenhuma. Ninguém que trabalha com software tem esse emprego.

## Onde você já a viu

**Bia, em julho.** Ela revisava todos os itens entre as outras tarefas, então a capacidade dela de revisão era pequena e totalmente usada. As aulas 2 e 3 encontraram o resultado: itens esperavam sete dias na coluna de revisão por revisões que levavam uma hora. Era esta curva, com Bia como a pessoa e a fila de revisão como a espera. A correção de 3 de agosto não foi deixar Bia mais rápida. Foi acrescentar capacidade, todo mundo revisando, o que levou a etapa de revisão para bem mais à esquerda na curva.
