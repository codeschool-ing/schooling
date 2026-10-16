---
title: A taxa de aprendizado acima de tudo
version: 1
---

Escolher o otimizador parece a grande decisão, e é a menor. **Se você pode ajustar uma configuração
só, ajuste a taxa de aprendizado.** Esta seção varre dez taxas para cada um dos três otimizadores, na
mesma rede e nos mesmos dados: 30 execuções de 20 épocas cada. Depois compara o que a escolha do
otimizador comprou com o que a escolha da taxa fez. Salve como `~/dl/sweep.py`:

```schooling-example
{
  "language": "python",
  "file": "sweep.py",
  "parts": [
    {
      "code": "\"\"\"sweep: ten learning rates for each of three optimisers, 20 epochs each.\"\"\"\nimport numpy as np\n\nimport digits\nimport optim\nfrom fit import fit\nfrom tinynet import Linear, ReLU, Net\n\nRATES = [0.0001, 0.0003, 0.001, 0.003, 0.01, 0.03, 0.1, 0.3, 1.0, 3.0]\ntrain, val, _ = digits.load()",
      "note": "Dez taxas, cada uma cerca de três vezes a anterior, de 0,0001 a 3. Uma taxa se procura nesse tipo de escala, porque o que importa é a ordem de grandeza dela."
    },
    {
      "code": "print(\"rate      \" + \"\".join(f\"{r:>7g}\" for r in RATES))\nfor name in (\"SGD\", \"Momentum\", \"Adam\"):\n    row = []\n    for lr in RATES:\n        rng = np.random.default_rng(0)\n        net = Net(Linear(64, 32, rng), ReLU(), Linear(32, 10, rng))\n        opt = getattr(optim, name)(net.params(), lr)",
      "note": "Toda execução parte dos mesmos pesos, sorteados com a semente 0, então a única diferença entre duas execuções é o otimizador e a taxa. `getattr(optim, name)` escolhe a classe pelo nome."
    },
    {
      "code": "        with np.errstate(all=\"ignore\"):\n            history = fit(net, opt, train, val, epochs=20, every=100)\n        row.append(history[-1][3])\n    print(f\"{name:<10}\" + \"\".join(f\"{acc:7.3f}\" for acc in row))",
      "note": "Uma taxa alta demais joga a rede tão longe que a probabilidade do dígito certo arredonda para zero, o logaritmo dela é menos infinito, e o NumPy reclama disso. `errstate` cala esses avisos, e a acurácia na tabela diz o que aconteceu. `every=100` deixa o `fit` calado durante as 20 épocas."
    }
  ]
}
```

```
ana@vm:~/dl$ python sweep.py
rate       0.0001 0.0003  0.001  0.003   0.01   0.03    0.1    0.3      1      3
SGD         0.136  0.164  0.311  0.506  0.839  0.925  0.956  0.964  0.981  0.111
Momentum    0.308  0.506  0.825  0.919  0.956  0.969  0.978  0.950  0.100  0.111
Adam        0.592  0.889  0.933  0.964  0.964  0.969  0.894  0.133  0.111  0.111
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Acurácia de validação contra taxa de aprendizado, num eixo logarítmico de 0,0001 a 3, para três otimizadores. Cada curva sobe de perto do acaso nas taxas minúsculas até um pico em torno de 0,97 ou 0,98, e volta ao acaso quando a taxa é alta demais. O Adam tem o pico entre 0,003 e 0,03, o momentum em 0,1 e o SGD simples em 1, então os três picos têm quase a mesma altura e ficam a um fator de dez ou mais um do outro.\"><path d=\"M80 260 L640 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 260 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.0</text><text x=\"70\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M80 145.0 L640 145.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1.0</text><path d=\"M80 30.0 L640 30.0\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"80.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0001</text><text x=\"139.6785048788546\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0003</text><text x=\"205.08037378028635\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.001</text><text x=\"264.7588786591409\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.003</text><text x=\"330.1607475605727\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.01</text><text x=\"389.8392524394273\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.03</text><text x=\"455.241121340859\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><text x=\"514.9196262197137\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><text x=\"580.3214951211454\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"640.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"360.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">taxa de aprendizado</text><text x=\"88\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">acurácia de validação depois de 20 épocas</text><path d=\"M80 237.0 L640 237.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"646\" y=\"237.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">acaso</text><path d=\"M80.0 228.7 L139.7 222.3 L205.1 188.5 L264.8 143.6 L330.2 67.0 L389.8 47.2 L455.2 40.1 L514.9 38.3 L580.3 34.4 L640.0 234.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"80.0\" cy=\"228.72\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"139.6785048788546\" cy=\"222.28\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"205.08037378028635\" cy=\"188.47\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"264.7588786591409\" cy=\"143.62\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"330.1607475605727\" cy=\"67.03\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"389.8392524394273\" cy=\"47.25\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"455.241121340859\" cy=\"40.120000000000005\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"514.9196262197137\" cy=\"38.28\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"580.3214951211454\" cy=\"34.370000000000005\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"640.0\" cy=\"234.47\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><text x=\"580.3214951211454\" y=\"22.370000000000005\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">SGD</text><path d=\"M80.0 189.2 L139.7 143.6 L205.1 70.2 L264.8 48.6 L330.2 40.1 L389.8 37.1 L455.2 35.1 L514.9 41.5 L580.3 237.0 L640.0 234.5\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"80.0\" cy=\"189.16\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"139.6785048788546\" cy=\"143.62\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"205.08037378028635\" cy=\"70.25\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"264.7588786591409\" cy=\"48.629999999999995\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"330.1607475605727\" cy=\"40.120000000000005\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"389.8392524394273\" cy=\"37.129999999999995\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"455.241121340859\" cy=\"35.06\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"514.9196262197137\" cy=\"41.5\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"580.3214951211454\" cy=\"237.0\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><circle cx=\"640.0\" cy=\"234.47\" r=\"3\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1\"></circle><text x=\"455.241121340859\" y=\"13.060000000000002\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Momentum</text><path d=\"M80.0 123.8 L139.7 55.5 L205.1 45.4 L264.8 38.3 L330.2 38.3 L389.8 37.1 L455.2 54.4 L514.9 229.4 L580.3 234.5 L640.0 234.5\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"80.0\" cy=\"123.84\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"139.6785048788546\" cy=\"55.53\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"205.08037378028635\" cy=\"45.41\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"264.7588786591409\" cy=\"38.28\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"330.1607475605727\" cy=\"38.28\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"389.8392524394273\" cy=\"37.129999999999995\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"455.241121340859\" cy=\"54.379999999999995\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"514.9196262197137\" cy=\"229.41\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"580.3214951211454\" cy=\"234.47\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"640.0\" cy=\"234.47\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><text x=\"389.8392524394273\" y=\"25.129999999999995\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Adam</text></svg>", "caption": "A tabela do `sweep.py` desenhada: o mesmo morro três vezes, com quase a mesma altura, em três taxas diferentes."}
```

**A taxa mexeu no resultado uns 87 pontos; o otimizador mexeu uns um.** Ao longo de qualquer linha, a
taxa leva a rede do acaso ao topo: o SGD vai de 0,136 em 0,0001 a 0,981 em 1, e desce a 0,111 em 3.
Comparando as melhores taxas de cada um, os três otimizadores chegam a 0,981, 0,978 e 0,969. Uma rede
treinada com o otimizador errado numa taxa boa ganha de uma treinada com o otimizador certo numa taxa
ruim, e com folga.

**Cada otimizador tem a sua melhor taxa num lugar diferente.** O SGD simples tem o pico em 1, o
momentum em 0,1 e o Adam em 0,03. O deslocamento de dez vezes do momentum é o que o `optim.py`
previa: um gradiente estável faz a velocidade dele dez vezes o gradiente, então o mesmo passo pede um
décimo da taxa. A taxa do Adam mede outra coisa, o tamanho de um passo. Então **uma taxa não viaja de
um otimizador para outro**: o SGD no padrão do Adam, 0,001, chega a 0,311, e o Adam no 0,1 do
momentum chega a 0,894.

**Alta demais falha de repente, baixa demais falha devagar.** Toda linha termina num penhasco. O
momentum vai de 0,978 em 0,1 a 0,950 em 0,3 e a 0,100 em 1, que é uma rede chutando entre dez
dígitos. Na outra ponta, o SGD em 0,0001 não está quebrado. Ele ainda não chegou, e mais épocas o
levariam mais longe, a um custo que ninguém precisa pagar.

**E um padrão é um ponto de partida.** O Adam em 0,001, o padrão que quase toda biblioteca traz, dá
0,933 aqui, onde 0,03 dá 0,969.

Duas coisas para levar como método:

- **Procure a taxa numa escala de razões**, cada valor umas três vezes o anterior, como faz `RATES`.
  0,01 e 0,02 são vizinhos; 0,0001 e 0,0002 são tão vizinhos quanto.
- **A melhor taxa fica um ou dois degraus abaixo da primeira que quebra.** O SGD tem o pico em 1 e
  quebra em 3, o momentum tem o pico em 0,1 e quebra em 1, e o Adam tem o pico em 0,03 e quebra em 0,3.

Um limite honesto. São execuções únicas, uma semente cada, de uma rede pequena. Uma diferença de um
ponto ou menos entre duas células pode vir do embaralhamento tão facilmente quanto da configuração, e
a próxima seção mostra uma diferença assim. A aula 18 mede o quanto uma semente sozinha move estes
números.
