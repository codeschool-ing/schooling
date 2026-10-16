---
title: Precisão mista
version: 1
---

Guardar um número em 16 bits em vez de 32 soa como cortar a exatidão pela metade, e cortar pela metade a
exatidão de cada peso soa como uma rede pior. **Não é nada disso que acontece.** Um número de 16 bits
perde algo específico, que depende do formato, e a precisão mista mantém em 32 bits exatamente os números
que não podem pagar essa perda.

Há dois formatos de 16 bits em uso, e eles perdem coisas diferentes. Salve como `~/dl/precision.py`:

```schooling-example
{
  "language": "python",
  "file": "precision.py",
  "parts": [
    {
      "code": "\"\"\"precision: three ways to store a number in 16 or 32 bits, and what each one loses.\"\"\"\nimport torch\n\nfor dtype in (torch.float32, torch.bfloat16, torch.float16):\n    f = torch.finfo(dtype)\n    one = torch.tensor(1.0, dtype=dtype)",
      "note": "`torch.finfo` descreve um tipo de ponto flutuante: o tamanho em bits, o maior número que ele guarda, o menor que guarda com precisão total, e `eps`, a distância entre 1 e o próximo número que ele consegue representar."
    },
    {
      "code": "    print(f\"{str(dtype):15} {f.bits} bits  largest {f.max:.3g}  smallest {f.tiny:.3g}  \"\n          f\"step after 1: {f.eps:.3g}\")\n    print(f\"{'':15} 1 + 0.001 = {(one + 0.001).item():.6g}   \"\n          f\"70000 -> {torch.tensor(70000.0, dtype=dtype).item():.6g}   \"\n          f\"1e-6 * 1e-3 -> {(torch.tensor(1e-6, dtype=dtype) * 1e-3).item():.3g}\")",
      "note": "Três testes pequenos em cada tipo. Uma atualização pequena num peso de 1, um valor grande demais para um dos tipos, e um produto tão pequeno quanto os gradientes no fundo de uma rede podem ser."
    }
  ]
}
```

```
PENDING precision
```

**O bfloat16 mantém o alcance do float32 e abre mão da precisão.** O maior número dele é 3.39e+38, tão
grande quanto o do float32, mas o passo de 1 até o próximo número que ele consegue guardar é 0.00781,
então 1 + 0,001 volta como 1. Um peso de 1 que recebe uma atualização de 0,001 não se mexe nada. É por
isso que os próprios pesos ficam em float32, e só a aritmética das passadas para a frente e para trás roda
em 16 bits.

**O float16 mantém mais precisão e abre mão do alcance.** Ele arredonda 1 + 0,001 para 1.00098, mas o
maior número dele é 6.55e+04, então 70000 vira `inf`, e 1e-6 × 1e-3 vira 0. Gradientes no fundo de uma
rede podem ser pequenos assim, e em float16 eles somem. O remédio é um scaler, mostrado no fim desta
seção.

## bfloat16 no processador

O `torch.autocast` decide, operação por operação, o que roda em 16 bits: produtos de matrizes e
convoluções rodam, e as operações que precisam do alcance ou da precisão, entre elas o softmax e o
logaritmo dentro da perda, ficam em float32. O programa abaixo treina a CNN da aula 11 por dez épocas dos
dois jeitos. Salve como `~/dl/mixed.py`:

```schooling-example
{
  "language": "python",
  "file": "mixed.py",
  "parts": [
    {
      "code": "\"\"\"mixed: lesson 11's CNN trained in float32, then with bfloat16 autocast, on the processor.\"\"\"\nimport time\n\nimport torch\nimport torch.nn.functional as F\n\nimport cnn\nimport loop\nimport tdigits\n\ntrain, val, _ = tdigits.load(images=True)"
    },
    {
      "code": "def fit(model, low, epochs=10, batch_size=32):\n    \"\"\"loop.fit's recipe, with the forward pass and the loss under autocast when `low` is set.\"\"\"\n    x, y = train\n    opt = torch.optim.SGD(model.parameters(), lr=0.1)\n    g = torch.Generator().manual_seed(0)\n    for epoch in range(epochs):\n        order = torch.randperm(len(y), generator=g)\n        for start in range(0, len(y), batch_size):\n            idx = order[start:start + batch_size]\n            with torch.autocast(\"cpu\", dtype=torch.bfloat16, enabled=low):\n                logits = model(x[idx])\n                loss = F.cross_entropy(logits, y[idx])\n            opt.zero_grad()\n            loss.backward()\n            opt.step()\n    return logits.dtype",
      "note": "O laço do `loop.py` da aula 9, com uma mudança: a passada para a frente e a perda rodam dentro de `torch.autocast`, um novo a cada lote. Dentro dele, o PyTorch faz os produtos de matrizes e as convoluções em bfloat16 e mantém em float32 as operações que precisam do alcance ou da precisão, como o softmax dentro da perda. `backward`, `zero_grad` e `step` ficam do lado de fora."
    },
    {
      "code": "for name, low in ((\"float32\", False), (\"bfloat16\", True)):\n    torch.manual_seed(0)\n    model = cnn.make_cnn()\n    start = time.perf_counter()\n    computed = fit(model, low)\n    seconds = time.perf_counter() - start\n    val_loss, val_acc = loop.evaluate(model, *val)\n    print(f\"{name:8}  {seconds:5.1f} s  val loss {val_loss:.4f}  val acc {val_acc:.3f}  \"\n          f\"weights {next(model.parameters()).dtype}, outputs {computed}\")",
      "note": "A mesma semente, a mesma rede e dez épocas em cada modo. As duas são avaliadas depois em float32 com o `evaluate` da aula 9, então a comparação é entre os pesos que os dois treinos produziram. A linha também diz em que tipo os pesos ficaram guardados e em que tipo as saídas da rede saíram."
    }
  ]
}
```

```
PENDING mixed
```

**A acurácia é a mesma, 0,969 dos dois jeitos**, e a perda de validação mudou na terceira casa, de 0,1291
para 0,1322. Os pesos ficaram em `torch.float32` nas duas execuções, enquanto as saídas da rede saíram em
`torch.bfloat16` com o autocast. Os segundos foram medidos enquanto outros programas dividiam os
processadores, então leia-os como uma ordem: TIMESENTENCE

Numa placa de vídeo a resposta é outra, e é por causa dela que a precisão mista existe. As placas NVIDIA
recentes têm unidades que multiplicam matrizes de 16 bits várias vezes mais rápido que as de 32, e cada
número em 16 bits é metade dos bytes a mover entre a memória da placa e essas unidades. Um modelo grande
treinado em float32 numa placa dessas deixa a maior parte dessa velocidade sem uso. Isso não foi executado
neste curso.

## A armadilha: autocast em volta do laço inteiro

É tentador pôr um único `autocast` em volta do laço de treino que já existe, para que o `loop.py` não
precise mudar. Salve como `~/dl/trap.py`:

```schooling-example
{
  "language": "python",
  "file": "trap.py",
  "parts": [
    {
      "code": "\"\"\"trap: autocast wrapped around the whole training loop, on lesson 9's MLP.\"\"\"\nimport torch\n\nimport loop\nimport tdigits\nfrom mlp import make_mlp\n\ntrain, val, _ = tdigits.load()\ntorch.manual_seed(0)\nmodel = make_mlp()\nbefore = model[0].weight.detach().clone()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)",
      "note": "O MLP e a receita da aula 9, e uma cópia dos pesos da primeira camada antes do treino, para ver depois se eles se mexeram."
    },
    {
      "code": "with torch.autocast(\"cpu\", dtype=torch.bfloat16):\n    loop.fit(model, opt, train, val, epochs=3)\nprint(f\"largest change in a first-layer weight: {(model[0].weight - before).abs().max().item():.4f}\")",
      "note": "O atalho tentador: um único `autocast` em volta de todo o `loop.fit`, para que nada dentro do laço precise mudar."
    }
  ]
}
```

```
PENDING trap
```

**A perda de treino é 2,3230 nas três épocas, até a quarta casa**, e a acurácia fica em 0,039, enquanto
a última linha mostra que os pesos se mexeram. A rede não aprendeu nada que a passada para a frente dela
conseguisse ver. O autocast guarda a cópia de 16 bits que faz de cada peso enquanto o bloco dele durar,
para que um peso usado duas vezes seja convertido uma só. Em volta do laço inteiro o bloco nunca termina,
e toda passada para a frente, por três épocas, roda em cópias dos pesos iniciais. **O autocast vai em
volta da passada para a frente e da perda de um lote**, como o `mixed.py` o põe, para que cada lote
comece um bloco novo.

## float16 numa placa de vídeo, com um scaler

Nas placas NVIDIA o formato de 16 bits de costume tem sido o float16, que roda rápido em placas mais
antigas que não têm bfloat16. O alcance pequeno dele é tratado por um `GradScaler`. Ele multiplica a
perda por um fator grande antes do `backward`, para que gradientes pequenos fiquem acima do ponto em que
o float16 os arredonda para 0, e divide os gradientes pelo mesmo fator antes do passo. Se um gradiente
estourou para `inf`, ele pula aquele passo e baixa o fator. Isto precisa de uma placa NVIDIA e não foi
executado neste curso:

```python
scaler = torch.amp.GradScaler("cuda")
for x, y in batches:
    x, y = x.to("cuda"), y.to("cuda")
    with torch.autocast("cuda", dtype=torch.float16):
        loss = F.cross_entropy(model(x), y)
    opt.zero_grad()
    scaler.scale(loss).backward()
    scaler.step(opt)
    scaler.update()
```

Com bfloat16 o scaler não é necessário, porque o alcance dele é o do float32.
