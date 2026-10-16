---
title: dataloader
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "batches.py",
  "parts": [
    {
      "code": "\"\"\"batches: what a DataLoader hands out, how many times, and in what order.\"\"\"\nimport torch\nfrom torch.utils.data import DataLoader, default_collate\n\nfrom dset import Digits\n\ntrain = Digits(\"train\")\nloader = DataLoader(train, batch_size=32, shuffle=True)\nxb, yb = next(iter(loader))\nprint(\"one batch:\", tuple(xb.shape), tuple(yb.shape), \" first labels:\", yb[:6].tolist())",
      "note": "Um `DataLoader` embrulha um dataset e é percorrido como uma lista de lotes. O `iter` começa uma época e o `next` pega o primeiro lote: 32 imagens empilhadas num tensor só, e 32 rótulos."
    },
    {
      "code": "sizes = [len(yb) for _, yb in loader]\nprint(\"batches:\", len(loader), \" first\", sizes[0], \" last\", sizes[-1], \" images:\", sum(sizes))\nprint(\"with drop_last:\", len(DataLoader(train, batch_size=32, drop_last=True)), \"batches\")",
      "note": "Uma época inteira, contada. `len(loader)` é o número de lotes, e `drop_last=True` descarta o lote curto do fim."
    },
    {
      "code": "xb, yb = default_collate([train[0], train[1], train[2]])\nprint(\"collate of 3 items:\", tuple(xb.shape), yb.tolist())",
      "note": "O `default_collate` é a função que transforma uma lista de itens num lote. O carregador a chama para cada lote; aqui ela é chamada à mão com três itens."
    },
    {
      "code": "for seed in (0, 0, 1):\n    loader = DataLoader(train, batch_size=32, shuffle=True, generator=torch.Generator().manual_seed(seed))\n    first, second = [next(iter(loader))[1][:6].tolist() for epoch in range(2)]\n    print(f\"seed {seed}: epoch 1 starts {first}, epoch 2 starts {second}\")",
      "note": "Cada `iter` novo é uma época nova, com um embaralhamento novo. Um gerador com semente fixa faz a sequência de embaralhamentos ser a mesma de uma execução para a outra."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "ltrain.py",
  "parts": [
    {
      "code": "\"\"\"ltrain: lesson 9's training run again, with a DataLoader doing the batching.\"\"\"\nimport torch\nimport torch.nn.functional as F\nfrom torch.utils.data import DataLoader\n\nimport loop\nimport tdigits\nfrom dset import Digits\nfrom mlp import make_mlp\n\ntorch.manual_seed(0)\n_, val, _ = tdigits.load()\nloader = DataLoader(Digits(\"train\"), batch_size=32, shuffle=True,\n                    generator=torch.Generator().manual_seed(0))\nmodel = make_mlp()\nopt = torch.optim.SGD(model.parameters(), lr=0.1)",
      "note": "A mesma rede, a mesma taxa e o mesmo tamanho de lote do `train.py` da aula 9, com o `mlp.py` e o `loop.py` daquela aula. Só o corte em lotes passa para o carregador."
    },
    {
      "code": "for epoch in range(1, 31):\n    for xb, yb in loader:\n        loss = F.cross_entropy(model(xb), yb)\n        opt.zero_grad()\n        loss.backward()\n        opt.step()\n    if epoch % 5 == 0:\n        print(f\"epoch {epoch:3d}  val loss %.4f  val acc %.3f\" % loop.evaluate(model, *val))",
      "note": "O `for` sobre o carregador substitui o `randperm` e o fatiamento do `loop.fit`. As cinco linhas de dentro são as da aula 9, sem mudança."
    }
  ]
}
```
