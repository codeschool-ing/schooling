---
title: Descida do gradiente estocástica, e o ruído de que ela vive
version: 1
---

A aula 2 calculava o gradiente sobre todos os pontos de treino antes de dar um único passo. **Num
conjunto de dados de verdade ninguém faz isso.** Uma rede aprendendo com um milhão de imagens
esperaria um milhão de passadas para a frente e para trás para se mover uma vez. A descida do
gradiente estocástica, SGD na sigla em inglês, pega em vez disso um lote pequeno e aleatório, calcula
o gradiente só nesse lote e dá o passo. O gradiente do lote é uma estimativa do gradiente do conjunto
inteiro, e esta seção mede o quanto ela é boa.

Salve o programa como `~/dl/noise.py`, ao lado do `digits.py` da aula 1 e do `tinynet.py` da aula 3:

```schooling-example
{
  "language": "python",
  "file": "noise.py",
  "parts": [
    {
      "code": "\"\"\"noise: how far one batch's gradient is from the gradient of the whole training set.\"\"\"\nimport numpy as np\n\nimport digits\nfrom tinynet import Linear, ReLU, Net, softmax_cross_entropy\n\n(x, y), _, _ = digits.load()\nrng = np.random.default_rng(0)\nnet = Net(Linear(64, 32, rng), ReLU(), Linear(32, 10, rng))",
      "note": "A rede que todo programa desta aula treina: 64 pixels de entrada, 32 unidades ocultas com ReLU, 10 pontuações de saída, montada com o `tinynet.py` da aula 3 e uma semente fixa."
    },
    {
      "code": "def gradient(idx):\n    \"\"\"The loss on the images in idx, and every gradient flattened into one vector.\"\"\"\n    loss, grad = softmax_cross_entropy(net.forward(x[idx]), y[idx])\n    net.backward(grad)\n    return loss, np.concatenate([g.ravel() for _, g in net.params()])",
      "note": "Uma passada para a frente e uma para trás sobre as imagens de `idx`. `net.params()` devolve cada array de pesos com o seu gradiente, e os gradientes são enfileirados num único vetor longo, para que dois deles possam ser comparados com um número só."
    },
    {
      "code": "full_loss, full = gradient(np.arange(len(y)))\nprint(f\"whole set: loss {full_loss:.4f}  gradient length {np.linalg.norm(full):.4f}\")",
      "note": "O gradiente exato: as 1.077 imagens de treino numa passada. É o que a descida do gradiente da aula 2 seguia, e o que ninguém calcula num conjunto de dados de verdade."
    },
    {
      "code": "order = rng.permutation(len(y))\ncosines, batches, sizes = [], [], []\nfor start in range(0, len(y), 32):\n    idx = order[start:start + 32]\n    loss, g = gradient(idx)\n    cosines.append(g @ full / (np.linalg.norm(g) * np.linalg.norm(full)))\n    batches.append(g)\n    sizes.append(len(idx))\n    if start < 5 * 32:\n        print(f\"batch {start // 32 + 1}: loss {loss:.4f}  length {np.linalg.norm(g):.4f}  \"\n              f\"cosine with the whole {cosines[-1]:.3f}\")\nprint(f\"{len(cosines)} batches: cosine from {min(cosines):.3f} to {max(cosines):.3f}\")",
      "note": "As mesmas imagens cortadas em lotes de 32, numa ordem embaralhada. O cosseno é 1 quando o gradiente de um lote aponta exatamente para onde aponta o do conjunto inteiro, 0 quando está em ângulo reto, e negativo quando aponta morro acima."
    },
    {
      "code": "mean = np.average(batches, axis=0, weights=sizes)\nprint(\"weighted mean of the batch gradients equals the whole:\", np.allclose(mean, full, atol=1e-6))",
      "note": "O gradiente de cada lote é uma média sobre as suas imagens, então os gradientes dos lotes, pesados pelo número de imagens de cada um, voltam a dar o gradiente do conjunto inteiro na média. O último lote tem 21 imagens, e é por isso que os pesos são necessários."
    }
  ]
}
```

```
ana@vm:~/dl$ python noise.py
whole set: loss 2.3051  gradient length 0.6619
batch 1: loss 2.3243  length 1.1441  cosine with the whole 0.771
batch 2: loss 2.2481  length 0.9592  cosine with the whole 0.743
batch 3: loss 2.2744  length 0.8638  cosine with the whole 0.354
batch 4: loss 2.2323  length 0.7266  cosine with the whole 0.572
batch 5: loss 2.3406  length 1.0045  cosine with the whole 0.740
34 batches: cosine from 0.354 to 0.868
weighted mean of the batch gradients equals the whole: True
```

**Nenhum lote concorda com o conjunto inteiro, e todo lote concorda mais ou menos.** Os cossenos vão
de 0,354 a 0,868, o que dá um ângulo de uns 69 graus no pior caso e de 30 no melhor. Os 34 são
positivos, e é isso que importa: um passo pequeno contra qualquer um desses gradientes também baixa
a perda do conjunto inteiro, até contra o do lote 3, que é uma estimativa ruim e ainda assim aponta
morro abaixo.

Os gradientes dos lotes também são mais longos que o exato: entre 0,7266 e 1,1441 nos cinco
impressos, contra 0,6619. O comprimento a mais é ruído. Dentro de um lote de 32, as discordâncias
das suas imagens com as outras 1.045 não se cancelam, e somam uma parte que não aponta para lugar
nenhum em especial.

**A última linha é o motivo de o método funcionar.** Pesados pelos tamanhos, os 34 gradientes de
lote voltam a dar exatamente o gradiente do conjunto inteiro na média. Cada passo erra numa direção
própria, os erros não têm direção preferida, e ao longo de muitos passos eles se cancelam, sobrando
a descida que a aula 2 fazia. Estatísticos chamam uma estimativa assim de não enviesada.

Então a troca é **muitos passos baratos e ruidosos no lugar de poucos exatos**: uma passada pelas
1.077 imagens compra um único passo exato, ou 34 passos com lotes de 32. Duas consequências do ruído
voltam nesta aula:

- **A perda de um lote se mexe mesmo quando a rede não se mexe.** Os cinco lotes acima foram medidos
  com os mesmos pesos e ainda assim deram perdas de 2,2323 a 2,3406. Uma curva de perdas por lote
  oscila só por esse motivo.
- **O ruído não encolhe perto do fundo.** O gradiente exato diminui à medida que os pesos se
  aproximam de um mínimo, e a discordância entre lotes não, então com uma taxa fixa os pesos
  continuam tremendo em volta do mínimo em vez de se acomodar nele. Os agendamentos do fim desta aula
  existem para isso.

O tamanho que um lote deve ter é assunto da aula 6. Esta aula o mantém em 32.
