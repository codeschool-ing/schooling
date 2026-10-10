---
title: O primeiro treino
version: 1
---

A aula 1 terminou com uma rede de duas camadas cujos pesos foram escritos à mão, porque nada ainda
conseguia encontrá-los. **Agora algo consegue.** O laço abaixo é tudo o que treinar é: prever, medir
a perda e o seu gradiente, passá-lo de volta, e mover cada peso um pouco contra o próprio gradiente.
Não há objeto otimizador nem framework, e cada linha é uma que você já viu. Salve como
`~/dl/train.py`:

```schooling-example
{
  "language": "python",
  "file": "train.py",
  "parts": [
    {
      "code": "\"\"\"train: tinynet learns the digits, with the plainest loop there is.\"\"\"\nimport numpy as np\n\nimport digits\nimport tinynet\n\n(x_train, y_train), (x_val, y_val), _ = digits.load()\nrng = np.random.default_rng(0)\nnet = tinynet.Net(tinynet.Linear(64, 64, rng), tinynet.ReLU(), tinynet.Linear(64, 10, rng))\nlr, batch = 0.1, 32",
      "note": "Uma rede de 64 entradas, 64 unidades ocultas e 10 saídas, uma por dígito. A taxa é 0,1, e o gradiente é calculado em 32 imagens por vez; as aulas 5 e 6 tratam desses dois números."
    },
    {
      "code": "for epoch in range(1, 21):\n    order = rng.permutation(len(y_train))\n    total = 0.0\n    for start in range(0, len(order), batch):\n        rows = order[start:start + batch]\n        loss, grad = tinynet.softmax_cross_entropy(net.forward(x_train[rows]), y_train[rows])\n        net.backward(grad)\n        for value, gradient in net.params():\n            value -= lr * gradient\n        total += loss * len(rows)\n    accuracy = (net.forward(x_val).argmax(axis=1) == y_val).mean()\n    print(f\"epoch {epoch:2d}  train loss {total / len(y_train):.4f}  val accuracy {accuracy:.3f}\")",
      "note": "Cada época embaralha o conjunto de treino e o percorre de 32 em 32 imagens. Cada lote é um forward pass, a perda e o seu gradiente, um backward pass e um passo. `value -= lr * gradient` muda os arrays dentro das camadas, no lugar. Depois da época, a rede prevê as 360 imagens de validação, e a maior das dez saídas é a resposta dela."
    }
  ]
}
```

```
ana@vm:~/dl$ python train.py
epoch  1  train loss 1.8299  val accuracy 0.714
epoch  2  train loss 1.0593  val accuracy 0.864
epoch  3  train loss 0.6628  val accuracy 0.858
epoch  4  train loss 0.4799  val accuracy 0.917
epoch  5  train loss 0.3816  val accuracy 0.914
epoch  6  train loss 0.3263  val accuracy 0.925
epoch  7  train loss 0.2856  val accuracy 0.925
epoch  8  train loss 0.2565  val accuracy 0.936
epoch  9  train loss 0.2317  val accuracy 0.928
epoch 10  train loss 0.2127  val accuracy 0.939
epoch 11  train loss 0.1972  val accuracy 0.944
epoch 12  train loss 0.1813  val accuracy 0.947
epoch 13  train loss 0.1715  val accuracy 0.942
epoch 14  train loss 0.1621  val accuracy 0.944
epoch 15  train loss 0.1550  val accuracy 0.950
epoch 16  train loss 0.1450  val accuracy 0.956
epoch 17  train loss 0.1413  val accuracy 0.953
epoch 18  train loss 0.1327  val accuracy 0.958
epoch 19  train loss 0.1270  val accuracy 0.956
epoch 20  train loss 0.1238  val accuracy 0.953
```

**De pesos aleatórios a 0,953 dos dígitos de validação em vinte épocas.** A primeira época já chega a
0,714, contra o 0,1 que uma rede chutando ao acaso marcaria. A perda de treino cai a cada época, de
1,8299 para 0,1238. A acurácia de validação quase sempre sobe, chega ao pico de 0,958 na época 18 e
termina em 0,953.

Repare no que fez o trabalho. A rede tem 64 × 64 + 64 + 64 × 10 + 10 = 4.810 números, e o programa
nunca diz quanto nenhum deles deveria valer. Cada um foi movido, 34 vezes por época, pela sua parte
da culpa na perda sobre 32 imagens. **Essa parte é o gradiente, e o backpropagation é o que tornou
barato calcular 4.810 deles de uma vez.**

Três escolhas deste laço foram feitas sem argumento, e as próximas três aulas o fornecem:

- **a perda**, que a aula 4 explica e compara com outras;
- **a taxa de 0,1 e o passo simples**, que a aula 5 troca por melhores e mostra como escolher;
- **o lote de 32 e as vinte épocas**, que a aula 6 mede, junto com como ler uma curva de validação que
  desce além de subir, como esta fez da época 2 para a 3.

O conjunto de teste não foi tocado, e não será até que uma aula tenha um modelo final a relatar.
