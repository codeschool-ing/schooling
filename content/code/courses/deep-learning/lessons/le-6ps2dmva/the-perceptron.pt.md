---
title: O perceptron, e a reta que ele não consegue dobrar
version: 1
---

A imagem com que a maioria das pessoas chega é um cérebro: neurônios, sinapses, algo que pensa. **O
que está na tela é aritmética.** Uma unidade multiplica cada entrada por um peso, soma os produtos e
um viés, e aplica uma função fixa ao resultado. A biologia deu o nome e quase nada além disso.

A primeira unidade que aprendeu os próprios pesos foi o perceptron de Frank Rosenblatt, em 1958. A
função dele é um degrau: responde 1 se a soma passa de zero, e 0 caso contrário. A regra de
aprendizado cabe em três linhas, e o programa abaixo a roda em duas tabelas-verdade. Salve-o como
`~/dl/perceptron.py`:

```schooling-example
{
  "language": "python",
  "file": "perceptron.py",
  "parts": [
    {
      "code": "\"\"\"perceptron: Rosenblatt's learning rule on two tiny truth tables.\"\"\"\nimport numpy as np\n\nX = np.array([[0, 0], [0, 1], [1, 0], [1, 1]])\nTABLES = {\"AND\": np.array([0, 0, 0, 1]), \"XOR\": np.array([0, 1, 1, 0])}",
      "note": "Quatro entradas, e duas respostas a aprender a partir delas. AND é 1 só quando as duas entradas são 1; XOR é 1 quando exatamente uma delas é."
    },
    {
      "code": "for name, y in TABLES.items():\n    w, b = np.zeros(2), 0.0\n    for epoch in range(1, 21):\n        mistakes = 0\n        for x, target in zip(X, y):\n            out = 1 if x @ w + b > 0 else 0",
      "note": "A unidade: multiplica cada entrada pelo seu peso, soma o viés e responde 1 se a soma passar de zero. Uma época é uma passada pelos quatro exemplos, e o programa permite vinte."
    },
    {
      "code": "            if out != target:\n                w += (target - out) * x\n                b += target - out\n                mistakes += 1\n        if mistakes == 0:\n            break",
      "note": "A regra de aprendizado. Num erro, `target - out` vale +1 ou -1, e os pesos andam na direção da entrada quando a resposta devia ter sido 1, e para longe dela quando devia ter sido 0. Uma resposta certa não muda nada."
    },
    {
      "code": "    state = \"learnt\" if mistakes == 0 else \"still wrong\"\n    outputs = [1 if x @ w + b > 0 else 0 for x in X]\n    print(f\"{name}: {state} after {epoch} epochs, w={w} b={b}, \"\n          f\"outputs {outputs}, wanted {y.tolist()}\")"
    }
  ]
}
```

```
ana@vm:~/dl$ python perceptron.py
AND: learnt after 6 epochs, w=[2. 1.] b=-2.0, outputs [0, 0, 0, 1], wanted [0, 0, 0, 1]
XOR: still wrong after 20 epochs, w=[-1.  0.] b=1.0, outputs [1, 1, 0, 0], wanted [0, 1, 1, 0]
```

**O AND foi aprendido em seis passadas**, com pesos 2 e 1 e viés -2: a soma passa de zero só quando
as duas entradas são 1. **O XOR continuava errado depois de vinte**, e continuaria depois de duas mil.
A regra não é lenta no XOR. Ela não consegue terminar.

## Por que não consegue

A soma `w1·x1 + w2·x2 + b` vale zero ao longo de uma reta no plano das duas entradas. Tudo de um lado
dela recebe 1, tudo do outro recebe 0. Então uma única unidade só consegue responder perguntas cujos
1s e 0s uma reta consiga separar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 270\" role=\"img\" aria-label=\"Dois gráficos das quatro entradas. No AND só (1,1) é 1, e uma reta o separa dos três 0s. No XOR, (0,1) e (1,0) são 1s numa diagonal e (0,0) e (1,1) são 0s na outra, e nenhuma reta põe os dois 1s de um lado e os dois 0s do outro.\"><text x=\"160\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\" font-weight=\"600\">AND</text><path d=\"M70 200 L270 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 200 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"230\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"50\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"50\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"278\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">x1</text><text x=\"70\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">x2</text><circle cx=\"70\" cy=\"200\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><circle cx=\"70\" cy=\"60\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><circle cx=\"230\" cy=\"200\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><circle cx=\"230\" cy=\"60\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><path d=\"M120 40 L270 150\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"170\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">uma reta separa o 1 dos 0s</text><text x=\"480\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\" font-weight=\"600\">XOR</text><path d=\"M390 200 L590 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M390 200 L390 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"390\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"550\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"370\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"370\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><text x=\"598\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">x1</text><text x=\"390\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">x2</text><circle cx=\"390\" cy=\"200\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><circle cx=\"390\" cy=\"60\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"550\" cy=\"200\" r=\"9\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><circle cx=\"550\" cy=\"60\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></circle><path d=\"M420 40 L560 185\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"565\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" fill=\"var(--amber)\">?</text><text x=\"490\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">nenhuma reta sozinha os separa</text></svg>", "caption": "O AND pode ser desenhado com uma reta no espaço das entradas, e o XOR não. Uma unidade sozinha desenha exatamente uma reta."}
```

O AND passa nesse teste. O XOR não passa: os 1s dele ficam numa diagonal e os 0s na outra, e toda
reta que põe os dois 1s de um lado leva um 0 junto. Em 1969, o livro *Perceptrons*, de Minsky e
Papert, provou isso e mais sobre o que camadas únicas não conseguem calcular, e o interesse pela área
minguou por mais de uma década.

**A saída já era conhecida: mais de uma camada.** O que faltava era uma regra para treiná-las, porque
a regra do perceptron precisa saber o que cada unidade deveria ter respondido, e uma unidade no meio
de uma rede não tem um alvo próprio. A aula 3 é essa regra. A última seção desta aula mostra a
resposta de duas camadas ao XOR com os pesos escritos à mão, o que prova que o arranjo consegue antes
que alguma regra o aprenda.
