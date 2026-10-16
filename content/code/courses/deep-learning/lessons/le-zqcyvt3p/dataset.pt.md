---
title: dataset
version: 1
---

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
