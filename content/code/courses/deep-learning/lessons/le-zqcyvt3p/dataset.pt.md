---
title: Um Dataset responde a uma pergunta
version: 1
---

O `fit` da aula 9 guardava o conjunto de treino inteiro em dois tensores e recortava lotes deles
com `order[start:start + batch_size]`. Isso funciona para 1.077 imagens de 64 números `float32`
cada, que dão 275.712 bytes. **Deixa de funcionar no dia em que os dados são uma pasta de fotos**:
um milhão de arquivos não cabe na memória, cada um precisa ser aberto e decodificado, e a maioria
dos programas de treino ainda muda um pouco cada imagem antes de usá-la.

O PyTorch divide esse trabalho em dois. Um **`Dataset`** sabe quantos itens existem e como produzir
o item número `i`, e mais nada. Um **`DataLoader`**, assunto da próxima seção, decide quais itens
vão juntos, em que ordem, e quem faz o trabalho. O dataset não sabe nada de lotes, e o carregador
não sabe nada de arquivos.

Eis o conjunto dos dígitos como um dataset. Salve como `~/dl/dset.py`; ele lê os números pelo
`tdigits.py` da aula 9, e todo programa desta aula o importa:

```schooling-example
{
  "language": "python",
  "file": "dset.py",
  "parts": [
    {
      "code": "\"\"\"dset: lesson 1's digits as a PyTorch Dataset, with an optional transform applied to each image as it is read.\"\"\"\nfrom torch.utils.data import Dataset\n\nimport tdigits",
      "note": "Um `Dataset` é a classe que o carregador do PyTorch sabe ler. Este tira os números do `tdigits.py`, o módulo que a aula 9 mostrou, então as imagens são as mesmas 1.077, 360 e 360."
    },
    {
      "code": "class Digits(Dataset):\n    def __init__(self, split=\"train\", transform=None):\n        sets = dict(zip((\"train\", \"val\", \"test\"), tdigits.load()))\n        self.x, self.y = sets[split]\n        self.transform = transform\n\n    def __len__(self):\n        return len(self.y)\n\n    def __getitem__(self, i):\n        img = self.x[i]\n        if self.transform is not None:\n            img = self.transform(img)\n        return img, self.y[i]",
      "note": "Dois métodos fazem um dataset: `__len__` diz quantos itens existem, e `__getitem__` devolve o item `i` como um par (imagem, rótulo). A transformação, quando existe, roda dentro do `__getitem__`, uma vez por imagem a cada leitura."
    }
  ]
}
```

**Dois métodos são o contrato inteiro.** O `__len__` devolve 1.077 para o conjunto de treino, e o
`__getitem__(i)` devolve uma imagem e o seu rótulo. De onde o item vem é assunto do próprio dataset:
aqui é uma linha de um tensor que já está na memória, e numa pasta de fotos seria um arquivo aberto
e decodificado na hora. O argumento `transform` é o lugar do trabalho feito em cada imagem quando
ela é lida, e a seção sobre uma transformação lenta o preenche.

Depois leia-o à mão, do jeito que um carregador vai ler. Salve como `~/dl/firstset.py`:

```schooling-example
{
  "language": "python",
  "file": "firstset.py",
  "parts": [
    {
      "code": "\"\"\"firstset: the Dataset read by hand, one item at a time, the way a DataLoader reads it.\"\"\"\nimport torch\nfrom torch.utils.data import TensorDataset\n\nimport tdigits\nfrom dset import Digits",
      "note": "O `TensorDataset` é o dataset do próprio PyTorch para tensores que já estão na memória. Ele está aqui para ser comparado com o `Digits`."
    },
    {
      "code": "train = Digits(\"train\")\nimg, label = train[0]\nprint(\"length:\", len(train), \" item 0:\", tuple(img.shape), img.dtype, \" label\", label.item())\nx, y = tdigits.load()[0]\nsame = TensorDataset(x, y)\nprint(\"TensorDataset:\", len(same), \" same item 0:\", torch.equal(same[0][0], img))",
      "note": "`len(train)` chama o `__len__`, e `train[0]` chama o `__getitem__(0)`. O item é uma imagem de 64 pixels e o seu rótulo, não um lote."
    },
    {
      "code": "try:\n    train[1077]\nexcept IndexError as e:\n    print(\"item 1077:\", e)",
      "note": "Pedir além do fim levanta `IndexError`, que é o que uma sequência do Python também faz."
    }
  ]
}
```

```
PENDING firstset
```

O item 0 é uma imagem de 64 pixels, `float32`, com o rótulo 6: um item, não um lote. O
`TensorDataset` do próprio PyTorch embrulha tensores que já estão na memória, e o item 0 dele é a
mesma imagem, então para dados como os dígitos uma classe própria ainda não compra nada. Ela começa a
se pagar quando o `__getitem__` tem trabalho a fazer. Pedir o item 1077 levanta `IndexError`, como
uma lista faria.

Esse tipo de dataset se chama **estilo mapa**: qualquer índice, em qualquer ordem. O PyTorch também
tem um `IterableDataset`, que só entrega itens um depois do outro, para dados que chegam como um
fluxo e não podem ser indexados. Tudo neste curso é estilo mapa.
