---
title: Augmentation com as transformações do torchvision
version: 1
---

A aula 7 deslocou os dígitos em um pixel com fatiamento do NumPy, gravou cada cópia deslocada num
conjunto de treino maior e treinou nele. **Para imagens, o torchvision faz isso por você, e de outro
jeito: cada vez que uma imagem é usada, uma transformação sorteia uma mudança aleatória nova.** Nada
é guardado. Numa época de 100 imagens a rede vê 100 variantes que ninguém viu antes, e a época
seguinte vê outras 100.

As transformações ficam em `torchvision.transforms.v2`. Elas recebem um tensor cujas duas últimas
dimensões são altura e largura, que é o que `tdigits.load(images=True)` devolve, então se aplicam aos
dígitos sem conversão nenhuma. Salve isto como `~/dl/augment.py`:

```schooling-example
{
  "language": "python",
  "file": "augment.py",
  "parts": [
    {
      "code": "\"\"\"augment: what torchvision's transforms do to a digit, drawn in characters.\"\"\"\nimport torch\nfrom torchvision.transforms import v2\n\nimport tdigits\n\n(x, y), _, _ = tdigits.load(images=True)",
      "note": "Os dígitos como imagens, formato 1x8x8 cada, do `tdigits.py` da aula 9. `transforms.v2` é o conjunto atual de transformações do torchvision, e trabalha direto sobre tensores."
    },
    {
      "code": "def draw(images):\n    \"\"\"Several 1x8x8 images side by side, ink as characters.\"\"\"\n    for r in range(8):\n        print(\"   \".join(\"\".join(\" .:-=+*#@\"[int(v * 8)] for v in img[0, r].clamp(0, 1))\n                         for img in images))",
      "note": "O desenho que o `look.py` fez na aula 1, para várias imagens numa fileira. O `clamp` mantém dentro dos nove caracteres um valor que a interpolação empurrou para além de 1."
    },
    {
      "code": "torch.manual_seed(0)\njitter = v2.RandomAffine(degrees=15, translate=(0.125, 0.125),\n                         interpolation=v2.InterpolationMode.BILINEAR)\nprint(\"label\", y[0].item(), \"shape\", tuple(x[0].shape), \"- the original, then four draws:\")\ndraw([x[0]] + [jitter(x[0]) for _ in range(4)])",
      "note": "Uma transformação, chamada quatro vezes sobre o mesmo 6. Cada chamada sorteia um ângulo novo entre -15 e 15 graus e um deslocamento novo de até um oitavo da largura, um pixel aqui. A interpolação bilinear mistura pixels vizinhos; o padrão, nearest, quebraria um traço girado em degraus."
    },
    {
      "code": "shift = v2.RandomAffine(degrees=0, translate=(0.25, 0.25))\nbatch = x[:4]\nprint(\"four digits:\", y[:4].tolist())\ndraw(batch)\nprint(\"one call on the batch of four:\")\ndraw(shift(batch))\nprint(\"one call per image:\")\ndraw(torch.stack([shift(img) for img in batch]))",
      "note": "Um deslocamento de até dois pixels, aplicado a um lote de quatro imagens numa chamada só e depois a uma imagem por chamada. As duas coisas não são iguais, e a saída mostra como."
    }
  ]
}
```

```
PENDING augment
```

## Uma transformação, uma imagem diferente a cada chamada

O primeiro bloco é um 6 e quatro chamadas ao mesmo `RandomAffine`. **Nenhuma saiu igual a outra**:
JITTERPT

`RandomAffine` cobre as mudanças que mais importam para imagens pequenas: girar (`degrees`), mover
(`translate`, como fração do tamanho), aproximar (`scale`) e inclinar (`shear`). O resto do módulo
tem as outras que uma fotografia pede, entre elas `RandomResizedCrop` para recortar uma parte
aleatória, `ColorJitter` para brilho e contraste, e `RandomHorizontalFlip`. A próxima seção é sobre
por que esta última é errada para dígitos.

## Um lote recebe um sorteio só

A segunda metade é a armadilha. **Recebendo um lote de quatro imagens numa chamada só, a
transformação sorteou um deslocamento e o aplicou às quatro**: BATCHPT Chamada uma vez por imagem,
cada uma das quatro se moveu do seu jeito.

As transformações v2 tratam tudo o que recebem numa chamada como uma amostra só: uma imagem com a sua
máscara, ou um lote que deve se mover junto. É o comportamento certo para uma figura e os seus
rótulos, e o errado para um lote de treino, em que um deslocamento compartilhado não ensina nada que
uma única imagem deslocada não ensinasse. Por isso o lugar de chamar uma transformação é por imagem,
dentro do `__getitem__` de um `Dataset`, como a aula 10 fez, para que cada imagem sorteie a sua. Os
programas desta aula fazem o mesmo numa linha, com `torch.stack`.
