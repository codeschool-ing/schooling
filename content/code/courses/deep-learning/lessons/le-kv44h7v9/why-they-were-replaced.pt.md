---
title: Por que foram substituídas
version: 1
---

Durante a maior parte dos anos 2010, a LSTM foi a resposta para quase todo problema que tivesse uma
sequência, do reconhecimento de fala à tradução. Desde 2017 esse lugar passou ao transformer, e a
explicação de costume, que transformers simplesmente acertam mais, deixa de fora a razão que mais pesou.
**Uma rede recorrente não consegue calcular o passo 50 antes de calcular o passo 49.** Cada passo precisa
do estado que o anterior escreveu, então os passos de uma sequência acontecem um depois do outro, por mais
hardware que esteja esperando.

Um lote não tem esse problema. Sessenta e quatro sequências lado a lado são sessenta e quatro linhas
independentes do mesmo produto de matrizes, e um processador consegue fazê-las juntas. O programa abaixo
lê o mesmo número de símbolos dos dois jeitos, e depois sequências mais longas. Salve como
`~/dl/timing.py`:

```schooling-example
{
  "language": "python",
  "file": "timing.py",
  "parts": [
    {
      "code": "\"\"\"timing: the same number of symbols, read side by side or one after another.\"\"\"\nimport time\n\nimport torch\nimport torch.nn as nn\n\ntorch.set_num_threads(1)\ntorch.manual_seed(0)\nlstm = nn.LSTM(16, 64, batch_first=True)",
      "note": "Uma thread de novo, para que a comparação seja entre dois jeitos de arrumar o trabalho e não entre dois jeitos de dividi-lo."
    },
    {
      "code": "def ms(batch, length, repeat=30):\n    \"\"\"The fastest of `repeat` forward passes, in milliseconds.\"\"\"\n    x = torch.randn(batch, length, 16)\n    best = float(\"inf\")\n    with torch.no_grad():\n        for _ in range(repeat):\n            start = time.perf_counter()\n            lstm(x)\n            best = min(best, time.perf_counter() - start)\n    return best * 1000",
      "note": "A mais rápida de trinta execuções, porque qualquer outra coisa na máquina só pode deixar uma execução mais lenta, nunca mais rápida. Só a passada para a frente é medida; um passo de treino soma uma passada para trás que percorre os mesmos passos ao contrário, também um de cada vez."
    },
    {
      "code": "shapes = ((64, 50), (1, 3200), (64, 100), (64, 200))\ntimes = [ms(batch, length) for batch, length in shapes]\nfor (batch, length), t in zip(shapes, times):\n    print(f\"{batch:2d} x {length:4d} steps = {batch * length:5d} symbols\"\n          f\"  {t:5.1f} ms  x{t / times[0]:.1f}\")",
      "note": "As duas primeiras linhas leem os mesmos 3.200 símbolos, como 64 sequências lado a lado ou como uma só, longa. As duas últimas mantêm o lote e alongam as sequências. A última coluna é cada tempo dividido pelo da primeira linha."
    }
  ]
}
```

```
ana@vm:~/dl$ python timing.py
64 x   50 steps =  3200 symbols    1.9 ms  x1.0
 1 x 3200 steps =  3200 symbols    4.5 ms  x2.4
64 x  100 steps =  6400 symbols    3.7 ms  x1.9
64 x  200 steps = 12800 symbols    6.7 ms  x3.6
```

Os tempos são os da máquina do curso e os seus vão ser outros; **o que se compara são as razões.** As duas
primeiras linhas são os mesmos 3.200 símbolos, e lê-los como uma sequência de 3.200 passos levou 3,2 vezes
o tempo de lê-los como 64 sequências de 50. As duas fizeram as mesmas multiplicações. A longa as fez 3.200
vezes com uma linha cada, e o lote as fez 50 vezes com 64 linhas cada, e um produto maior sai mais barato
que muitos pequenos. As duas últimas linhas mostram a outra metade: dobrar o comprimento dobrou o tempo,
2,0 e depois 3,9 vezes a primeira linha, porque cada passo a mais é mais uma volta do laço.

Isso foi uma thread num processador. **Uma placa de vídeo deixa a diferença bem maior**, porque roda
milhares de multiplicações de uma vez: o lote a ocupa, e uma única sequência longa deixa quase toda ela
parada enquanto o laço gira. Isso não foi executado neste curso, que não tem placa de vídeo, mas a
aritmética das duas primeiras linhas é a razão. Treinar com um volume grande de texto significa sequências
longas, e um modelo cuja velocidade é ditada pelo comprimento da sequência, e não pelo tamanho do hardware,
não fica mais rápido quando o hardware fica.

A segunda razão está na tabela da seção anterior. **Tudo o que uma rede recorrente sabe do passado precisa
caber num estado de tamanho fixo**, reescrito a cada passo. O primeiro símbolo de uma sequência de 50 só
chega ao fim se 49 reescritas o deixarem em paz. Um transformer deixa cada posição olhar diretamente para
todas as outras, então o primeiro símbolo fica a um passo do último qualquer que seja o comprimento. A
aula 15 constrói um e o roda na mesma tarefa de lembrar.

As redes recorrentes não sumiram. **O custo delas por passo é constante**: ler mais um símbolo custa o
mesmo no símbolo 10 e no símbolo 10.000, e o estado é tudo o que precisa ser guardado. Onde os dados chegam
uma amostra por vez e precisam de resposta na hora, um teclado que prevê a próxima palavra ou um sensor
num aparelho pequeno, essa é exatamente a propriedade desejada. Algumas arquiteturas recentes, os modelos
de espaço de estados como o Mamba, de 2023, mantêm um estado com esse custo constante por passo e são
construídas para que o treino ainda percorra a sequência inteira em paralelo.
