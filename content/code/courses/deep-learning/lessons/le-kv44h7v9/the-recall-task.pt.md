---
title: "A tarefa de lembrar: até onde cada uma alcança"
version: 1
---

Um gradiente que chega a 49 passos atrás é uma promessa, não um resultado. **Para ver o que cada célula
de fato aprende, é preciso uma tarefa cuja resposta seja conhecida e cuja dificuldade seja um número só:
a distância a que a resposta está.** Esta é a mais simples que existe. Chega uma sequência de símbolos
aleatórios, e no fim o modelo precisa dizer qual era o primeiro. Tudo o que fica no meio é ruído.

A tarefa é um arquivo à parte, `~/dl/seqtask.py`, porque a aula 15 treina um transformer nela mesma:

```schooling-example
{
  "language": "python",
  "file": "seqtask.py",
  "parts": [
    {
      "code": "\"\"\"seqtask: a sequence task with a known answer: remember the first symbol until the end.\"\"\"\nimport torch\n\nSYMBOLS = 8",
      "note": "A aula 15 usa este arquivo de novo, sem mudança, para que um transformer enfrente exatamente a tarefa que a RNN e a LSTM enfrentam aqui."
    },
    {
      "code": "def batch(n, length, generator):\n    \"\"\"n sequences of `length` random symbols; the label of each is its first symbol.\"\"\"\n    x = torch.randint(0, SYMBOLS, (n, length), generator=generator)\n    return x, x[:, 0].clone()",
      "note": "Todo símbolo depois do primeiro é ruído, e a resposta é pedida depois do último, então o modelo precisa carregar três bits de informação pela sequência inteira. O gerador torna os dados reproduzíveis, e eles não acabam: todo lote é novo."
    }
  ]
}
```

Um modelo que não aprendeu nada acerta um símbolo em oito, então o acaso dá 0,125, e um modelo que
resolveu a tarefa dá 1,000. O comprimento decide quantos passos o primeiro símbolo precisa atravessar. O
programa abaixo treina uma RNN e uma LSTM, do mesmo tamanho e com os mesmos dados, em três comprimentos.
Salve como `~/dl/recall.py`:

```schooling-example
{
  "language": "python",
  "file": "recall.py",
  "parts": [
    {
      "code": "\"\"\"recall: an RNN and an LSTM, trained to name the first symbol of a sequence at the end of it.\"\"\"\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\n\nimport seqtask\n\ntorch.set_num_threads(1)",
      "note": "Uma thread, de propósito. Cada passo de uma camada recorrente pequena é trabalho de menos para dividir entre quatro processadores, e uma thread evita que a execução fique lenta quando outra coisa na máquina está ocupada."
    },
    {
      "code": "class Reader(nn.Module):\n    \"\"\"Embed each symbol, read the sequence, and predict from the state after the last step.\"\"\"\n\n    def __init__(self, cell, hidden=64):\n        super().__init__()\n        self.embed = nn.Embedding(seqtask.SYMBOLS, 16)\n        if cell == \"rnn\":\n            self.rnn = nn.RNN(16, hidden, batch_first=True)\n        else:\n            self.rnn = nn.LSTM(16, hidden, batch_first=True)\n            with torch.no_grad():\n                self.rnn.bias_hh_l0[hidden:2 * hidden] += 1.0\n        self.out = nn.Linear(hidden, seqtask.SYMBOLS)\n\n    def forward(self, x):\n        h, _ = self.rnn(self.embed(x))\n        return self.out(h[:, -1])",
      "note": "O mesmo modelo para as duas células: um embedding de 16, uma camada recorrente de 64 e uma camada densa que lê só o último estado. A porta de esquecimento da LSTM começa com 1 somado ao viés, o ponto de partida comum desde 2015, que a deixa mais perto de guardar do que de esquecer."
    },
    {
      "code": "def train(cell, length, steps=3000, seed=0):\n    torch.manual_seed(seed)\n    model = Reader(cell)\n    opt = torch.optim.Adam(model.parameters(), lr=3e-3)\n    data = torch.Generator().manual_seed(seed)\n    x_test, y_test = seqtask.batch(1000, length, torch.Generator().manual_seed(1234))\n    scores = []",
      "note": "Adam a 0,003, 3.000 passos de 64 sequências novas cada. O conjunto de teste são 1.000 sequências de um gerador próprio, então nenhuma sequência de teste é uma em que o modelo treinou, a não ser pelo acaso de sortear os mesmos símbolos."
    },
    {
      "code": "    for step in range(1, steps + 1):\n        x, y = seqtask.batch(64, length, data)\n        loss = F.cross_entropy(model(x), y)\n        opt.zero_grad()\n        loss.backward()\n        opt.step()\n        if step % 1000 == 0:\n            with torch.no_grad():\n                scores.append((model(x_test).argmax(dim=1) == y_test).float().mean().item())\n    return scores",
      "note": "As cinco linhas do laço da aula 9, com um lote novo sorteado a cada passo em vez de uma época sobre um conjunto fixo. A acurácia nas sequências de teste é medida a cada 1.000 passos."
    },
    {
      "code": "print(\"accuracy on 1,000 new sequences after 1,000, 2,000 and 3,000 steps (chance is 0.125)\")\nfor length in (5, 20, 50):\n    for cell in (\"rnn\", \"lstm\"):\n        scores = \"  \".join(f\"{s:.3f}\" for s in train(cell, length))\n        print(f\"{cell:4s}  length {length:2d}   {scores}\", flush=True)",
      "note": "Seis execuções: as duas células em três comprimentos, com a mesma semente, os mesmos dados e o mesmo número de passos. Chutar entre oito símbolos dá 0,125."
    }
  ]
}
```

```
ana@vm:~/dl$ time python recall.py
accuracy on 1,000 new sequences after 1,000, 2,000 and 3,000 steps (chance is 0.125)
rnn   length  5   1.000  1.000  1.000
lstm  length  5   1.000  1.000  1.000
rnn   length 20   0.134  0.416  0.482
lstm  length 20   1.000  1.000  1.000
rnn   length 50   0.122  0.136  0.118
lstm  length 50   0.120  0.122  0.144

real	2m2.026s
user	2m0.139s
sys	0m0.700s
```

As seis execuções levaram 2 minutos e 2 segundos na máquina do curso, numa thread.

| comprimento | RNN depois de 3.000 passos | LSTM depois de 3.000 passos |
| --- | --- | --- |
| 5 | 1,000 | 1,000 |
| 20 | 0,482 | 1,000 |
| 50 | 0,118 | 0,144 |

**No comprimento 5 as duas acertam tudo já depois dos primeiros mil passos**: quatro passos atrás é perto
o bastante para o gradiente de uma RNN. **No comprimento 20 a diferença é a célula.** A LSTM estava
perfeita na primeira medida, depois de 1.000 passos. A RNN estava no acaso nesse ponto, 0,134, e chegou a
0,482 no fim, acertando menos da metade das sequências. O gradiente dela alcança vinte passos atrás, fraco,
e o aprendizado é lento na mesma proporção.

**No comprimento 50 nenhuma aprendeu** em 3.000 passos. A RNN nunca saiu do acaso. A LSTM terminou em
0,144, um pouco acima do acaso, o que pode ser o começo do aprendizado ou ruído em 1.000 sequências de
teste, e esta execução não tem como dizer qual. Mais passos, um viés de esquecimento maior ou uma taxa de
aprendizado menor talvez a levassem adiante. Nada disso foi tentado aqui, então esta aula afirma só o
que mediu: **com o mesmo orçamento, a LSTM alcançou 20 passos atrás e não 50.**

**Uma tarefa cuja dificuldade é um botão só é o jeito mais barato de comparar arquiteturas.** A resposta
é conhecida, os dados não custam nada, e o botão mostra onde cada uma para. A aula 15 gira o mesmo botão
com o mesmo arquivo, os mesmos passos e os mesmos comprimentos, num modelo que não carrega estado nenhum
de um passo para o outro.
