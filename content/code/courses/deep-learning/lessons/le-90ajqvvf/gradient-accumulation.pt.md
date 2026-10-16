---
title: Acúmulo de gradientes
version: 1
---

A seção de memória mostrou as ativações crescendo com o lote, então o lote é a primeira coisa que uma
placa de vídeo recusa. A aula 6 mostrou que o tamanho do lote também não é livre para mudar: a taxa de
aprendizado e o número de passos foram ajustados com ele. **Quando um lote não cabe, o gradiente desse
lote ainda pode ser calculado, um pedaço por vez.**

O gradiente de uma perda média sobre 128 exemplos é a média dos gradientes deles. Quatro lotes de 32
guardam os mesmos 128 exemplos, e o `backward` soma em `.grad` em vez de substituir, o comportamento que
o `zero_grad` esquecido da aula 9 transformou em bug. Aqui ele é a ferramenta. Salve como
`~/dl/accumulate.py`:

```schooling-example
{
  "language": "python",
  "file": "accumulate.py",
  "parts": [
    {
      "code": "\"\"\"accumulate: one batch of 128, or four of 32 whose gradients add up before the step.\"\"\"\nimport torch\nimport torch.nn.functional as F\n\nimport cnn\nimport tdigits\n\n(x, y), _, _ = tdigits.load(images=True)\nxb, yb = x[:128], y[:128]\n\n\ndef grads(model):\n    return torch.cat([p.grad.flatten() for p in model.parameters()])",
      "note": "`grads` estende o `.grad` de cada parâmetro num único vetor comprido, para que dois gradientes possam ser comparados com uma subtração."
    },
    {
      "code": "torch.manual_seed(0)\nmodel = cnn.make_cnn()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)\n\nopt.zero_grad()\nF.cross_entropy(model(xb), yb).backward()\none = grads(model)",
      "note": "A referência: uma passada para trás sobre um lote de 128 imagens."
    },
    {
      "code": "opt.zero_grad()\nfor i in range(4):\n    part = slice(32 * i, 32 * (i + 1))\n    loss = F.cross_entropy(model(xb[part]), yb[part]) / 4\n    loss.backward()\nfour = grads(model)",
      "note": "As mesmas 128 imagens em quatro lotes de 32, sem `zero_grad` entre eles, então cada `backward` soma em `.grad`, o comportamento que a aula 9 chamou de bug. Cada perda é dividida por 4: `cross_entropy` devolve a média do lote, e quatro médias de 32 somam quatro vezes a média de 128. Num laço de treino, `opt.step()` e `opt.zero_grad()` viriam aqui, depois do quarto lote."
    },
    {
      "code": "print(f\"{one.numel()} gradient entries, the largest {one.abs().max().item():.6f}\")\nprint(f\"largest difference, one batch of 128 against four of 32: {(one - four).abs().max().item():.2e}\")\nprint(\"equal to float32 rounding:\", torch.allclose(one, four, atol=1e-6))\n\nopt.zero_grad()\nfor i in range(4):\n    part = slice(32 * i, 32 * (i + 1))\n    F.cross_entropy(model(xb[part]), yb[part]).backward()\nprint(f\"without the / 4: {(grads(model).norm() / one.norm()).item():.4f} times the gradient\")",
      "note": "A comparação, e depois o mesmo acúmulo sem a divisão."
    }
  ]
}
```

```
ana@vm:~/dl$ python accumulate.py
38282 gradient entries, the largest 0.032093
largest difference, one batch of 128 against four of 32: 5.12e-09
equal to float32 rounding: True
without the / 4: 4.0000 times the gradient
```

**Os dois gradientes são o mesmo.** Entre 38.282 entradas, a maior diferença é 5.12e-09, contra um maior
gradiente de 0.032093. Isso é o arredondamento do float32 somando os mesmos números em outra ordem, e o
`allclose` aceita. Sem a divisão por 4 o gradiente sai 4.0000 vezes grande demais, o que é uma taxa de
aprendizado quatro vezes alta demais com outro nome.

Num laço de treino, o passo e o `zero_grad` saem do laço dos lotes e rodam uma vez a cada quatro lotes:

```python
for i, (x, y) in enumerate(batches):
    loss = F.cross_entropy(model(x), y) / 4
    loss.backward()
    if (i + 1) % 4 == 0:
        opt.step()
        opt.zero_grad()
```

Estas linhas são o padrão, não um programa para rodar; o `accumulate.py` acima é a execução delas.

## O que custa, e onde difere

**O acúmulo economiza memória e mais nada.** A aritmética é a mesma do lote de 128. O tempo é o de
quatro lotes de 32, pelo menos o tempo de um lote de 128 e em geral mais, porque cada lote pequeno
paga sozinho os custos fixos de um passo. O que se economiza são as ativações: a passada para trás de cada
pedaço só precisa dos 32 exemplos daquele pedaço.

Ele é exato para o `cnn.py`, porque nada nessa rede olha através dos exemplos de um lote. A normalização
em lote da aula 8 olha: ela normaliza com a média e a variância do lote que recebe. Quatro pedaços de 32
são normalizados com quatro conjuntos de estatísticas, e o gradiente deixa de ser o de um lote de 128.
A normalização por camada, que trabalha dentro de cada exemplo, não tem esse problema.
