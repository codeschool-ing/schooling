---
title: Erro quadrático médio, e o que ele supõe
version: 1
---

A aula 2 usou o erro quadrático médio sem perguntar por quê: eleva cada erro ao quadrado e tira a
média. **Uma perda não é uma medida neutra do quanto o modelo errou. Ela é o alvo do modelo**, e o
quadrado tem opinião: um erro de 10 custa cem vezes um erro de 1, então um modelo treinado com ele faz
muita força para evitar um único erro grande.

Essa é a opinião certa quando os erros grandes são de fato os que importa evitar e o ruído nos alvos é
do tipo comum, simétrico. É a errada quando alguns alvos são raros e extremos por motivos que as
entradas não explicam: uma entrega pega por um temporal, um sensor que falhou por um segundo. O modelo
passa a gastar o esforço com os outliers, à custa de todos os outros.

## Um palpite, três perdas

O que uma perda quer fica mais claro num modelo que só pode prever um número. Salve como
`~/dl/regression_losses.py`:

```schooling-example
{
  "language": "python",
  "file": "regression_losses.py",
  "parts": [
    {
      "code": "\"\"\"regression_losses: the single guess MSE, MAE and Huber each choose, and why.\"\"\"\nimport numpy as np\n\nminutes = np.array([12.0, 13.0, 14.0, 14.0, 15.0, 16.0, 60.0])   # the last one was in a storm\nDELTA = 2.0",
      "note": "Sete tempos de entrega, em minutos. Seis são normais e um levou uma hora, que é a cara de um outlier em dados reais: não é um erro, só é raro. `DELTA` é onde a perda de Huber muda de forma."
    },
    {
      "code": "def mse(e):\n    return e ** 2\n\n\ndef mae(e):\n    return np.abs(e)\n\n\ndef huber(e):\n    return np.where(np.abs(e) <= DELTA, 0.5 * e ** 2, DELTA * (np.abs(e) - 0.5 * DELTA))",
      "note": "Três jeitos de transformar um erro em custo. Ao quadrado, absoluto, e Huber: ao quadrado enquanto o erro é pequeno, depois uma reta com a inclinação que tinha em `DELTA`."
    },
    {
      "code": "guesses = np.arange(0, 60.01, 0.01)\nfor name, loss in ((\"mse\", mse), (\"mae\", mae), (\"huber\", huber)):\n    best = guesses[np.argmin([loss(g - minutes).mean() for g in guesses])]\n    print(f\"{name:5s} best single guess {best:5.2f}\")\nprint(\"mean\", round(minutes.mean(), 2), \"  median\", np.median(minutes))",
      "note": "Um modelo que só pode prever um número, qualquer que seja a entrada. Todo palpite de 0 a 60 é testado em passos de 0,01, e o de menor perda média é aquele para onde o treinamento convergiria."
    },
    {
      "code": "# The pull of each delivery on a guess of 15: the slope of its own loss there.\ne = 15.0 - minutes\nprint(\"error at 15 \", e)\nfor name, pull in ((\"mse\", 2 * e), (\"mae\", np.sign(e)), (\"huber\", np.clip(e, -DELTA, DELTA))):\n    print(f\"{name:5s} pull  \", pull, \"  sum\", pull.sum())",
      "note": "A inclinação da perda de cada ponto em relação ao palpite, que é o que a descida do gradiente soma. Uma soma negativa empurra o palpite para cima, uma positiva para baixo."
    }
  ],
  "output": "ana@vm:~/dl$ python regression_losses.py\nmse   best single guess 20.57\nmae   best single guess 14.00\nhuber best single guess 14.40\nmean 20.57   median 14.0\nerror at 15  [  3.   2.   1.   1.   0.  -1. -45.]\nmse   pull   [  6.   4.   2.   2.   0.  -2. -90.]   sum -78.0\nmae   pull   [ 1.  1.  1.  1.  0. -1. -1.]   sum 2.0\nhuber pull   [ 2.  2.  1.  1.  0. -1. -2.]   sum 3.0"
}
```

**O melhor palpite único do MSE é 20,57 minutos, que é a média, e nenhuma entrega levou nada parecido
com isso.** Seis levaram entre 12 e 16 minutos e uma levou 60, e o palpite fica no meio, errado para as
sete. O erro absoluto (MAE) escolhe 14,00, a mediana: a entrega típica. O de Huber escolhe 14,40, perto
da mediana, porque além do limiar de 2 minutos ele conta um erro do jeito que o MAE conta.

Não é uma peculiaridade de sete números. A constante de menor erro quadrático é sempre a média, e a de
menor erro absoluto é uma mediana. Uma rede treinada com MSE aprende, para cada entrada, a média dos
alvos que viu para entradas parecidas, e uma média é justamente o que um outlier arrasta.

## A força de um ponto

A segunda metade da saída é o motivo. Cada número é a inclinação da perda de uma entrega num palpite de
15, e a descida do gradiente move o palpite contra a soma delas.

No MSE o temporal puxa com -90 e as outras seis juntas puxam com 12. A soma é -78, então o palpite
sobe, na direção do temporal. No MAE cada entrega puxa com 1 ou -1, por mais longe que esteja; a soma é
2 e o palpite desce, na direção do grupo. No Huber a força é o próprio erro, limitado a 2, então o
temporal conta tanto quanto uma entrega comum errada por 2 minutos, e não mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" role=\"img\" aria-label=\"As três perdas do regression_losses.py contra o erro, de -4 a 4. A perda ao quadrado é uma parábola que chega a 16 com erro 4. A de Huber, com limiar 2, segue metade da parábola até o erro 2 e depois sobe em linha reta, chegando a 6 em 4. A perda absoluta é um V que chega a 4.\"><path d=\"M70 260.0 L380 260.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M70 202.5 L380 202.5\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60\" y=\"202.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M70 145.0 L380 145.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><path d=\"M70 87.5 L380 87.5\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60\" y=\"87.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><path d=\"M70 30.0 L380 30.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">16</text><text x=\"70.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-4</text><text x=\"147.5\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">-2</text><text x=\"225.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"302.5\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><text x=\"380.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><text x=\"225.0\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">erro</text><text x=\"60\" y=\"12\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">perda</text><path d=\"M70.0 30.0 L73.9 41.4 L77.8 52.4 L81.6 63.2 L85.5 73.7 L89.4 83.9 L93.2 93.8 L97.1 103.5 L101.0 112.8 L104.9 121.9 L108.8 130.6 L112.6 139.1 L116.5 147.3 L120.4 155.2 L124.2 162.8 L128.1 170.2 L132.0 177.2 L135.9 184.0 L139.8 190.4 L143.6 196.6 L147.5 202.5 L151.4 208.1 L155.2 213.4 L159.1 218.5 L163.0 223.2 L166.9 227.7 L170.8 231.8 L174.6 235.7 L178.5 239.3 L182.4 242.6 L186.2 245.6 L190.1 248.4 L194.0 250.8 L197.9 253.0 L201.8 254.8 L205.6 256.4 L209.5 257.7 L213.4 258.7 L217.2 259.4 L221.1 259.9 L225.0 260.0 L228.9 259.9 L232.8 259.4 L236.6 258.7 L240.5 257.7 L244.4 256.4 L248.2 254.8 L252.1 253.0 L256.0 250.8 L259.9 248.4 L263.8 245.6 L267.6 242.6 L271.5 239.3 L275.4 235.7 L279.2 231.8 L283.1 227.7 L287.0 223.2 L290.9 218.5 L294.8 213.4 L298.6 208.1 L302.5 202.5 L306.4 196.6 L310.2 190.4 L314.1 184.0 L318.0 177.2 L321.9 170.2 L325.8 162.8 L329.6 155.2 L333.5 147.3 L337.4 139.1 L341.2 130.6 L345.1 121.9 L349.0 112.8 L352.9 103.5 L356.8 93.8 L360.6 83.9 L364.5 73.7 L368.4 63.2 L372.2 52.4 L376.1 41.4 L380.0 30.0\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M70.0 173.8 L73.9 176.6 L77.8 179.5 L81.6 182.4 L85.5 185.2 L89.4 188.1 L93.2 191.0 L97.1 193.9 L101.0 196.8 L104.9 199.6 L108.8 202.5 L112.6 205.4 L116.5 208.2 L120.4 211.1 L124.2 214.0 L128.1 216.9 L132.0 219.8 L135.9 222.6 L139.8 225.5 L143.6 228.4 L147.5 231.2 L151.4 234.1 L155.2 236.7 L159.1 239.2 L163.0 241.6 L166.9 243.8 L170.8 245.9 L174.6 247.9 L178.5 249.7 L182.4 251.3 L186.2 252.8 L190.1 254.2 L194.0 255.4 L197.9 256.5 L201.8 257.4 L205.6 258.2 L209.5 258.9 L213.4 259.4 L217.2 259.7 L221.1 259.9 L225.0 260.0 L228.9 259.9 L232.8 259.7 L236.6 259.4 L240.5 258.9 L244.4 258.2 L248.2 257.4 L252.1 256.5 L256.0 255.4 L259.9 254.2 L263.8 252.8 L267.6 251.3 L271.5 249.7 L275.4 247.9 L279.2 245.9 L283.1 243.8 L287.0 241.6 L290.9 239.2 L294.8 236.7 L298.6 234.1 L302.5 231.2 L306.4 228.4 L310.2 225.5 L314.1 222.6 L318.0 219.8 L321.9 216.9 L325.8 214.0 L329.6 211.1 L333.5 208.2 L337.4 205.4 L341.2 202.5 L345.1 199.6 L349.0 196.8 L352.9 193.9 L356.8 191.0 L360.6 188.1 L364.5 185.2 L368.4 182.4 L372.2 179.5 L376.1 176.6 L380.0 173.8\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><path d=\"M70.0 202.5 L73.9 203.9 L77.8 205.4 L81.6 206.8 L85.5 208.2 L89.4 209.7 L93.2 211.1 L97.1 212.6 L101.0 214.0 L104.9 215.4 L108.8 216.9 L112.6 218.3 L116.5 219.8 L120.4 221.2 L124.2 222.6 L128.1 224.1 L132.0 225.5 L135.9 226.9 L139.8 228.4 L143.6 229.8 L147.5 231.2 L151.4 232.7 L155.2 234.1 L159.1 235.6 L163.0 237.0 L166.9 238.4 L170.8 239.9 L174.6 241.3 L178.5 242.8 L182.4 244.2 L186.2 245.6 L190.1 247.1 L194.0 248.5 L197.9 249.9 L201.8 251.4 L205.6 252.8 L209.5 254.2 L213.4 255.7 L217.2 257.1 L221.1 258.6 L225.0 260.0 L228.9 258.6 L232.8 257.1 L236.6 255.7 L240.5 254.2 L244.4 252.8 L248.2 251.4 L252.1 249.9 L256.0 248.5 L259.9 247.1 L263.8 245.6 L267.6 244.2 L271.5 242.8 L275.4 241.3 L279.2 239.9 L283.1 238.4 L287.0 237.0 L290.9 235.6 L294.8 234.1 L298.6 232.7 L302.5 231.2 L306.4 229.8 L310.2 228.4 L314.1 226.9 L318.0 225.5 L321.9 224.1 L325.8 222.6 L329.6 221.2 L333.5 219.8 L337.4 218.3 L341.2 216.9 L345.1 215.4 L349.0 214.0 L352.9 212.6 L356.8 211.1 L360.6 209.7 L364.5 208.2 L368.4 206.8 L372.2 205.4 L376.1 203.9 L380.0 202.5\" stroke=\"var(--paper-dim)\" stroke-width=\"2.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M400 70 L428 70\" stroke=\"var(--amber)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"436\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">ao quadrado: cresce com o quadrado</text><path d=\"M400 98 L428 98\" stroke=\"var(--phosphor)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"436\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">Huber: ao quadrado, depois uma reta</text><path d=\"M400 126 L428 126\" stroke=\"var(--paper-dim)\" stroke-width=\"2.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"436\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">absoluta: uma reta desde o zero</text></svg>", "caption": "Depois do limiar, a de Huber cresce como a perda absoluta, então um outlier custa na proporção do seu erro, e não do quadrado dele."}
```

**Elevar ao quadrado é o que deixa o MSE sensível, e limitar a inclinação é tudo o que o Huber faz.**
Abaixo do limiar ele é metade do erro quadrático, suave no zero, onde o MAE tem um bico; acima, uma
reta. Três leituras práticas:

- O MSE serve quando um erro grande é mesmo pior na proporção do seu quadrado, e quando os extremos
  são casos reais que você quer prever, e não acidentes.
- O MAE serve quando o que importa é o caso típico. A inclinação dele tem o mesmo tamanho para qualquer
  erro, então não diminui conforme o modelo se aproxima, e isso deixa os últimos passos do treinamento
  aos solavancos.
- O Huber fica entre os dois. O limiar dele é um ajuste nas unidades do alvo, e os 2 minutos daqui são
  uma escolha, não uma lei.
