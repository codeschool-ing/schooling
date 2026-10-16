---
title: Sim ou não, e vários rótulos ao mesmo tempo
version: 1
---

O softmax responde *qual destas classes?*, e as probabilidades dele somam 1 por construção: subir uma
abaixa as outras. **Nem toda pergunta tem exatamente uma resposta.** Uma pergunta de sim ou não tem
duas, e uma fotografia pode mostrar um cachorro, uma bola e grama ao mesmo tempo.

**Para uma pergunta de sim ou não, uma saída, uma sigmoid e a entropia cruzada binária.** A sigmoid da
aula 1 transforma o logit único em `p`, a probabilidade de sim. A perda é `-log p` quando a resposta é
sim e `-log(1 - p)` quando é não. É a entropia cruzada das seções anteriores com duas classes, escrita
com uma saída em vez de duas.

**Para vários rótulos ao mesmo tempo, uma saída dessas por rótulo, cada uma julgada sozinha.** O
programa abaixo faz três perguntas sobre cada dígito: é par, é maior que 4, e tem uma volta fechada,
como o 0, o 6, o 8 e o 9. Salve como `~/dl/multilabel.py`:

```schooling-example
{
  "language": "python",
  "file": "multilabel.py",
  "parts": [
    {
      "code": "\"\"\"multilabel: three yes-or-no questions about every digit, answered at once.\"\"\"\nimport numpy as np\n\nimport digits\nfrom tinynet import Linear, ReLU, Net\n\nQUESTIONS = (\"even\", \"above 4\", \"has a loop\")\n\n\ndef answers(y):\n    \"\"\"Three 0-or-1 targets per image: one column per question.\"\"\"\n    return np.stack([y % 2 == 0, y > 4, np.isin(y, [0, 6, 8, 9])], axis=1).astype(np.float32)",
      "note": "Os rótulos saem do dígito: um 8 é par, maior que 4 e tem uma volta fechada, então o alvo dele é `[1, 1, 1]`, e um 3 é `[0, 0, 0]`. Nada diz que uma imagem tem exatamente um sim."
    },
    {
      "code": "def sigmoid_bce(logits, t):\n    \"\"\"Binary cross-entropy on every output, from logits; its mean and its gradient.\"\"\"\n    p = 1 / (1 + np.exp(-logits))\n    loss = np.maximum(logits, 0) - logits * t + np.log1p(np.exp(-np.abs(logits)))\n    return loss.mean(), (p - t) / t.size",
      "note": "Cada saída tem a sua própria sigmoid e o seu próprio `-log p` ou `-log(1 - p)`. A linha da perda é essa fórmula rearranjada para que o `exp` só veja números negativos, o mesmo truque da seção anterior. O gradiente é de novo `p - t`."
    },
    {
      "code": "(x, y), (xv, yv), _ = digits.load()\nt, tv = answers(y), answers(yv)\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 32, rng), ReLU(), Linear(32, 3, rng))\nfor epoch in range(30):\n    order = rng.permutation(len(y))\n    for start in range(0, len(y), 32):\n        idx = order[start:start + 32]\n        loss, grad = sigmoid_bce(net.forward(x[idx]), t[idx])\n        net.backward(grad)\n        for p, g in net.params():\n            p -= 0.5 * g",
      "note": "O laço de treinamento simples da aula 3, com três saídas em vez de dez e a perda nova no lugar do `softmax_cross_entropy`. Nada mais na rede muda."
    },
    {
      "code": "p = 1 / (1 + np.exp(-net.forward(xv).astype(np.float64)))\nprint(\"val loss\", round(float(sigmoid_bce(net.forward(xv), tv)[0]), 4))\nfor j, q in enumerate(QUESTIONS):\n    print(f\"{q:10s} val accuracy {((p[:, j] > 0.5) == tv[:, j]).mean():.3f}\")\nfor digit in (3, 8):\n    i = int(np.argmax(yv == digit))\n    print(f\"a {digit}:\", dict(zip(QUESTIONS, np.round(p[i], 3).tolist())), \" sum\", round(p[i].sum(), 3))",
      "note": "Cada saída é lida sozinha, como sim acima de 0,5. As últimas linhas mostram duas imagens de validação e quanto somam as três probabilidades delas."
    }
  ],
  "output": "ana@vm:~/dl$ python multilabel.py\nval loss 0.1042\neven       val accuracy 0.956\nabove 4    val accuracy 0.969\nhas a loop val accuracy 0.964\na 3: {'even': 0.0, 'above 4': 0.0, 'has a loop': 0.0}  sum 0.0\na 8: {'even': 0.957, 'above 4': 0.979, 'has a loop': 0.76}  sum 2.697"
}
```

Cada pergunta é respondida certo para entre 95,6% e 96,9% das imagens de validação. Os dois dígitos
do fim mostram o que um softmax não teria como dizer. O 3 recebe quase nada nas três perguntas, e as
saídas dele somam 0,0. O 8 recebe três sins, que somam 2,697. **Nenhuma das duas somas é erro: as
saídas são probabilidades independentes, e o total delas não quer dizer nada.**

Dois detalhes vêm da entropia cruzada. **O gradiente é de novo `p - t`**, porque a inclinação do log
cancela a da sigmoid exatamente como cancela a do softmax. E a linha da perda nunca tira a exponencial
de um número positivo, que é o truque da seção anterior rearranjado para uma sigmoid. O PyTorch junta
as duas coisas no `BCEWithLogitsLoss`, que recebe logits pelo mesmo motivo que a entropia cruzada dele.

O 0,5 que transforma uma probabilidade num sim é uma escolha, e não parte da perda. Quando um rótulo é
raro, um limiar mais baixo para ele, escolhido no conjunto de validação, encontra mais casos ao preço
de mais alarmes falsos. Essa troca pertence à métrica, que é o assunto da última seção.
