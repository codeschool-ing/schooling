---
title: Determinismo, e onde ele acaba
version: 1
---

A semente 0, duas vezes, deu a mesma rede até o último bit. Isso valeu numa máquina, com um conjunto
de bibliotecas e com um número de threads, e **cada uma dessas é uma condição, não uma garantia.** O
motivo é uma aritmética da qual todo programa daqui depende sem dizer.

## A soma depende da ordem

A soma em ponto flutuante arredonda a cada passo, então o agrupamento de uma soma muda o resultado.
Salve como `~/dl/order.py`:

```schooling-example
{
  "language": "python",
  "file": "order.py",
  "parts": [
    {
      "code": "\"\"\"order: the same numbers, added in a different order.\"\"\"\nimport torch\n\nprint((0.1 + 0.2) + 0.3, 0.1 + (0.2 + 0.3))",
      "note": "Três números, dois agrupamentos. Na aritmética exata são iguais; em ponto flutuante cada soma arredonda, e os arredondamentos diferem."
    },
    {
      "code": "x = torch.randn(1_000_000, generator=torch.Generator().manual_seed(0))\nfor n in (1, 2, 4):\n    torch.set_num_threads(n)\n    print(f\"{n} thread(s): sum {x.sum().item()!r}\")",
      "note": "Um milhão de números, fixados por uma semente, somados com uma, duas e quatro threads. Mais threads quer dizer a soma cortada em mais pedaços, somados separadamente e depois combinados."
    }
  ]
}
```

```
PENDING order
```

`0.6000000000000001` contra `0.6` é a história inteira numa linha. O milhão de números deu, com
quatro threads, uma soma diferente da que deu com uma ou duas, diferindo na quarta casa decimal de um
número perto de -1561. **Cada thread soma a sua parte, e as partes são combinadas depois**, então o
número de threads decide o agrupamento. Nenhuma das respostas está errada; são dois arredondamentos da
mesma soma exata.

## E o treino?

Salve como `~/dl/threads.py`:

```schooling-example
{
  "language": "python",
  "file": "threads.py",
  "parts": [
    {
      "code": "\"\"\"threads: one seed, trained on one thread and on four.\"\"\"\nimport torch\n\nimport exp\n\nconfig = {\"hidden\": 32, \"lr\": 0.01, \"epochs\": 10, \"batch_size\": 32}\nmodels = {}\nfor n in (1, 4):\n    torch.set_num_threads(n)\n    models[n], acc = exp.run(config, 0)\n    print(f\"{n} thread(s): val acc {acc:.4f}\")",
      "note": "A mesma configuração e a mesma semente do `seeds.py`, treinadas duas vezes. A única coisa que muda é quantas threads o PyTorch pode usar."
    },
    {
      "code": "gap = max((p - q).abs().max().item()\n          for p, q in zip(models[1].parameters(), models[4].parameters()))\nprint(\"largest difference between the two sets of weights:\", gap)",
      "note": "A maior distância entre qualquer peso de uma rede e o mesmo peso da outra. Zero quer dizer idênticos até o último bit."
    }
  ]
}
```

```
PENDING threads
```

Nesta rede, **uma thread e quatro deram pesos idênticos**, uma diferença de `0.0`. As operações dela
são pequenas, 32 imagens por 64 entradas de cada vez, e nenhuma foi agrupada de outro jeito com
quatro threads. Uma rede mais larga num lote maior é dividida, e uma diferença no último dígito num
passo cresce, ao longo de milhares de passos, até virar uma segunda casa decimal diferente, que é o
que a aula 1 disse para esperar entre duas máquinas. É por isso que o `track.py` registra `threads`.

## Pedir ao PyTorch que recuse

`torch.use_deterministic_algorithms(True)` diz ao PyTorch para usar só operações que dão o mesmo
resultado toda vez, e para levantar um erro em qualquer operação que não tenha uma versão assim.
**No processador isso não muda nada aqui**: toda operação que este curso usa já tem uma. Faz
diferença numa placa de vídeo, onde algumas operações somam as partes na ordem em que o hardware
termina cada uma, e essa ordem muda de uma execução para outra mesmo na mesma máquina.

Os ajustes que o PyTorch documenta para uma execução reproduzível numa placa de vídeo são estes.
**Não foram executados para este curso**, que não tem placa:

```python
import os
os.environ["CUBLAS_WORKSPACE_CONFIG"] = ":4096:8"   # before CUDA is first used

import torch
torch.manual_seed(0)
torch.use_deterministic_algorithms(True)
torch.backends.cudnn.benchmark = False
```

A primeira linha fixa como a biblioteca de matrizes organiza o trabalho. A última impede o cuDNN de
cronometrar vários algoritmos e escolher o mais rápido, o que pode escolher outro na execução
seguinte. O preço é velocidade: a versão determinística de uma operação muitas vezes é mais lenta, às
vezes muito mais.

O que esses ajustes nunca entregam são os mesmos números em outro hardware ou em outras versões das
bibliotecas. Dentro de uma máquina, eles tornam uma execução repetível. Entre máquinas, **a dispersão
das seções anteriores é a medida honesta**: um resultado que só vale na semente 0 de uma máquina
nunca foi um resultado.
