---
title: O DataLoader: lotes, embaralhamento e colagem
version: 1
---

Um `DataLoader` pega um dataset e o transforma em algo que um laço `for` consegue percorrer, um lote
por vez. **Tudo o que o `fit` fazia com `randperm` e fatiamento na aula 9 agora é trabalho dele**:
escolher a ordem, cortá-la em lotes, pedir cada item ao dataset e empilhar os itens em tensores.
Salve isto como `~/dl/batches.py`:

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

```
PENDING batches
```

## Lotes, e o curto no fim

**Um lote são 32 itens empilhados numa nova primeira dimensão**: imagens `(32, 64)` e rótulos
`(32,)`, os formatos que o `fit` recortava à mão. Uma época são 34 lotes, 33 de 32 imagens e um
último de 21, que somam de volta 1.077. `drop_last=True` descarta o lote curto e deixa 33.

O lote curto não faz mal para os dígitos, já que a perda é uma média sobre o que o lote tiver.
O `drop_last` importa onde uma camada precisa de um lote cheio, ou onde um lote de um só exemplo
quebraria algo, como a normalização em lote da aula 8 quebra quando tem um único exemplo para tirar
a média. Com `shuffle=True`, as imagens descartadas são outras a cada época.

## Colagem

O carregador pede 32 itens ao dataset, um por um, recebe uma lista de 32 pares `(imagem, rótulo)` e
entrega a lista a uma **função de colagem** (*collate*). A padrão, `default_collate`, empilha as
imagens num tensor e os rótulos em outro, que é o que a chamada com três itens imprimiu: `(3, 64)` e
três rótulos. Ela só funciona quando todo item tem o mesmo formato. Fotos de tamanhos diferentes, ou
frases de comprimentos diferentes, precisam de uma `collate_fn` própria que as preencha ou corte para
um tamanho só antes de empilhar.

## Ordem

Cada `iter(loader)` novo é uma época nova, com um embaralhamento novo: a época 2 começa com outros
rótulos que a época 1. **Um gerador com semente fixa faz a sequência de embaralhamentos se repetir**
de uma execução para a outra, como mostram as duas linhas `seed 0`, e uma semente diferente dá uma
sequência diferente. É o mesmo trabalho que o `fit` da aula 9 dava ao próprio gerador.

## A execução da aula 9, com um carregador

O laço de treino quase não muda. Salve como `~/dl/ltrain.py`; ele usa o `mlp.py` e o `loop.py` da
aula 9:

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

```
PENDING ltrain
```

**As cinco linhas dentro do laço são as da aula 9, intactas**; só mudou de onde vêm os lotes. A
execução chega a uma acurácia de validação de 0,956 e uma perda de 0,1464, contra 0,950 e 0,1461 da
aula 9. Perto, e não igual, porque o carregador tira os embaralhamentos do gerador do seu próprio
jeito, então a mesma semente dá outra sequência de lotes. As duas execuções são igualmente
corretas. Nenhum dos números vale mais que o outro, e a aula 18 mede o quanto duas sementes de uma
mesma configuração ficam distantes.
