---
title: A inclinação diz para que lado é a descida
version: 1
---

Parado em `w = 2`, com uma perda de 1,0562, há duas perguntas: para que lado andar, e quanto. **A
inclinação da perda naquele ponto responde a primeira.** Se a perda cai quando `w` cresce, a
inclinação é negativa e andar para a direita é descer. O tamanho dela diz quão íngreme o terreno é
ali.

Uma inclinação pode ser medida sem cálculo nenhum. Empurre `w` por uma quantidade pequena `h` e veja
quanto a perda se mexe: essa razão é uma **diferença finita**. Ela também pode ser calculada. Para
um ponto, a perda é `(w*x - y)²`, que se expande em `w²x² - 2wxy + y²`, e a derivada disso em `w` é
`2wx² - 2xy`, ou `2x(w*x - y)`. A perda é a média sobre os pontos, então a inclinação dela é a média
das inclinações deles. Salve como `~/dl/slope.py`, que faz as duas coisas:

```schooling-example
{
  "language": "python",
  "file": "slope.py",
  "parts": [
    {
      "code": "# slope.py: the slope of the loss at w, measured two ways and worked out\nimport numpy as np\n\nfrom points import x, y"
    },
    {
      "code": "def loss(w):\n    return np.mean((w * x - y) ** 2)",
      "note": "A perda do `loss.py`, como função do peso: um número entra, um número sai."
    },
    {
      "code": "def slope(w):\n    return np.mean(2 * x * (w * x - y))",
      "note": "A derivada calculada acima, 2x(wx - y) para cada ponto, com a média dos dez porque a perda é a média deles."
    },
    {
      "code": "h = 0.001\nfor w in [0.0, 2.0, 3.0, 4.0]:\n    one_sided = (loss(w + h) - loss(w)) / h\n    centred = (loss(w + h) - loss(w - h)) / (2 * h)\n    print(f\"w {w}   one-sided {one_sided:+.6f}   centred {centred:+.6f}   formula {slope(w):+.6f}\")",
      "note": "Duas medidas e a fórmula em quatro pesos. A diferença de um lado só empurra `w` para cima; a centrada empurra para os dois lados e divide pela distância entre eles."
    }
  ]
}
```

```
ana@vm:~/dl$ python slope.py
w 0.0   one-sided -2.637415   centred -2.637800   formula -2.637800
w 2.0   one-sided -1.097415   centred -1.097800   formula -1.097800
w 3.0   one-sided -0.327415   centred -0.327800   formula -0.327800
w 4.0   one-sided +0.442585   centred +0.442200   formula +0.442200
```

**A medida centrada e a fórmula concordam em todos os dígitos impressos.** A de um lado só erra pelos
mesmos 0,000385 em todos os pesos, porque mede a inclinação no meio do caminho entre `w` e `w + h`,
e não em `w`. A aula 3 usa a versão centrada para conferir as inclinações de uma rede inteira, e é
por isso que vale ver a diferença uma vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 330\" role=\"img\" aria-label=\"Uma curva da perda contra o peso de 0 a 5: uma parábola que cai de 4,79 em w = 0 até um fundo de 0,274 em w = 3,43 e sobe até 1,23 em w = 5. Seis pontos marcam os pesos que o loss.py imprimiu. Uma tangente em w = 0 desce íngreme, uma tangente em w = 4 sobe suave, e no fundo a curva é plana.\"><path d=\"M70 280 L600 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L70 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"176.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"282.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"388.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"494.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"600.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"56\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"56\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"56\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"56\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><text x=\"56\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"56\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><text x=\"335.0\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o peso w</text><text x=\"60\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a perda</text><path d=\"M70.0 40.4 L75.3 47.0 L80.6 53.4 L85.9 59.8 L91.2 66.0 L96.5 72.2 L101.8 78.2 L107.1 84.2 L112.4 90.1 L117.7 95.9 L123.0 101.5 L128.3 107.1 L133.6 112.6 L138.9 118.0 L144.2 123.3 L149.5 128.5 L154.8 133.6 L160.1 138.6 L165.4 143.5 L170.7 148.3 L176.0 153.0 L181.3 157.7 L186.6 162.2 L191.9 166.6 L197.2 171.0 L202.5 175.2 L207.8 179.3 L213.1 183.4 L218.4 187.3 L223.7 191.2 L229.0 194.9 L234.3 198.6 L239.6 202.2 L244.9 205.6 L250.2 209.0 L255.5 212.3 L260.8 215.4 L266.1 218.5 L271.4 221.5 L276.7 224.4 L282.0 227.2 L287.3 229.9 L292.6 232.5 L297.9 235.0 L303.2 237.4 L308.5 239.7 L313.8 241.9 L319.1 244.0 L324.4 246.1 L329.7 248.0 L335.0 249.8 L340.3 251.6 L345.6 253.2 L350.9 254.7 L356.2 256.2 L361.5 257.5 L366.8 258.8 L372.1 259.9 L377.4 261.0 L382.7 262.0 L388.0 262.8 L393.3 263.6 L398.6 264.3 L403.9 264.9 L409.2 265.3 L414.5 265.7 L419.8 266.0 L425.1 266.2 L430.4 266.3 L435.7 266.3 L441.0 266.2 L446.3 266.0 L451.6 265.7 L456.9 265.4 L462.2 264.9 L467.5 264.3 L472.8 263.6 L478.1 262.9 L483.4 262.0 L488.7 261.0 L494.0 260.0 L499.3 258.8 L504.6 257.6 L509.9 256.2 L515.2 254.8 L520.5 253.2 L525.8 251.6 L531.1 249.9 L536.4 248.0 L541.7 246.1 L547.0 244.1 L552.3 242.0 L557.6 239.8 L562.9 237.5 L568.2 235.1 L573.5 232.6 L578.8 230.0 L584.1 227.3 L589.4 224.5 L594.7 221.6 L600.0 218.6\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"40.41\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"176.0\" cy=\"153.05\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"282.0\" cy=\"227.19\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"388.0\" cy=\"262.83\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"494.0\" cy=\"259.97\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><circle cx=\"600.0\" cy=\"218.61\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><path d=\"M70.0 40.409999999999854 L149.5 139.32749999999984\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M409.2 277.6579999999999 L578.8 242.28199999999987\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"88.0\" y=\"44.409999999999854\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">inclinação -2,64 em w = 0</text><text x=\"499.3\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">inclinação +0,44 em w = 4</text><path d=\"M504.6 193.0 L494.0 251.96999999999986\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"433.12420000000003\" cy=\"266.3187285674999\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"419.8\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">fundo: inclinação 0</text><path d=\"M409.2 193.0 L433.12420000000003 258.3187285674999\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"186.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">os seis pesos do loss.py</text><path d=\"M184.0 114.0 L178.0 147.05\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "A perda de um peso é uma parábola. As linhas tracejadas são a inclinação dela em dois pesos; no fundo, a inclinação é zero."}
```

**Leia os sinais.** Em 0, 2 e 3 a inclinação é negativa, então a perda cai quando `w` cresce; em 4 é
positiva, então o fundo fica abaixo de 4. O tamanho diminui conforme o fundo se aproxima, de
-2,637800 em 0 para -0,327800 em 3, e no fundo é zero. É isso que um fundo é: o lugar onde o terreno
é plano.

**A fórmula é o que o treino usa, e a medida é como você a confere.** Uma medida custa dois passos
para a frente por peso, então uma rede com um milhão de pesos precisaria de dois milhões de passos
para um conjunto de inclinações. Uma fórmula dá todas as inclinações com um passo para a frente e um
para trás, e a aula 3 mostra como obtê-la para uma rede de qualquer profundidade.
