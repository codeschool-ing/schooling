---
title: Pré-treinar um corpo que valha a pena emprestar
version: 1
---

A augmentation estica os dados que você tem. **A transferência de aprendizado pega emprestado de
dados que você não tem**: uma rede treinada numa tarefa já guarda filtros que respondem a traços,
cantos e laços, e uma segunda tarefa que precisa das mesmas peças pode partir deles. A imagem de
costume é uma rede treinada com milhões de fotografias, emprestada a alguém que tem algumas centenas;
a última seção desta aula mostra essa versão, que este laboratório não consegue baixar.

Este curso faz a sua própria. **Os dígitos de 0 a 4 fazem o papel da tarefa antiga e grande, e os
dígitos de 5 a 9 o da nova e pequena.** Uma rede treinada nas cinco primeiras classes nunca viu um 7,
então o que ela levar para as outras cinco tem de ser algo geral sobre caligrafia. Salve como
`~/dl/pretrain.py`:

```schooling-example
{
  "language": "python",
  "file": "pretrain.py",
  "parts": [
    {
      "code": "\"\"\"pretrain: a CNN trained on the digits 0 to 4 only, saved as base.pt.\"\"\"\nimport torch\n\nimport cnn\nimport loop\nimport tdigits",
      "note": "A CNN do `cnn.py` da aula 11, o laço do `loop.py` da aula 9, e os dígitos como imagens do `tdigits.py`."
    },
    {
      "code": "def first_five(x, y):\n    \"\"\"Only the images labelled 0 to 4, so the labels are still 0 to 4.\"\"\"\n    keep = y < 5\n    return x[keep], y[keep]\n\n\ntrain, val, _ = tdigits.load(images=True)\ntrain, val = first_five(*train), first_five(*val)\nprint(\"train\", len(train[1]), \"images, val\", len(val[1]), \"images, labels\", sorted(set(train[1].tolist())))",
      "note": "Metade das classes, tanto da divisão de treino quanto da de validação. A de teste continua sem ser lida, como desde a aula 1. Os dígitos de 5 a 9 ficam guardados para a próxima seção, onde são a tarefa nova."
    },
    {
      "code": "torch.manual_seed(0)\nmodel = cnn.make_cnn(5)\nopt = torch.optim.Adam(model.parameters(), lr=1e-3)\nloop.fit(model, opt, train, val, epochs=20, every=5)",
      "note": "Cinco saídas, uma por classe. A semente fixa os pesos iniciais e o `loop.fit` fixa a ordem dos lotes, então a mesma máquina grava o mesmo arquivo toda vez."
    },
    {
      "code": "torch.save(model.state_dict(), \"base.pt\")\nprint(\"saved base.pt:\", sum(p.numel() for p in model.parameters()), \"parameters\")",
      "note": "O `state_dict`, como a aula 9 salvou um: os tensores por nome, não o código. Quem o carrega monta `cnn.make_cnn(5)` primeiro e despeja os números dentro."
    }
  ]
}
```

```
PENDING pretrain
```

528 imagens de treino e 180 de validação, com rótulos de 0 a 4. Depois de 20 épocas a rede acerta
0,989 das imagens de validação, e já estava em 0,967 depois de 5. O programa grava os pesos em
`base.pt`, e o `ls` mostra o arquivo:

```
PENDING pretrain
```

O arquivo guarda os 37.957 parâmetros de `cnn.make_cnn(5)`, como um `state_dict`. **Guarde-o**: a
próxima seção pega emprestado dele, e a aula 17 também.

## O que são um corpo e uma cabeça

Um classificador são duas partes com trabalhos diferentes. **O corpo transforma uma imagem em
características**: aqui as duas convoluções, o pooling e a primeira camada linear, terminando em 64
números por imagem. **A cabeça transforma características nas classes de uma tarefa**: aqui a última
`Linear(64, 5)`, com uma saída por dígito de 0 a 4. A cabeça é quem conhece os rótulos da tarefa. O
corpo, no caso ideal, só conhece aquilo de que imagens desse tipo são feitas.

Essa é a ideia inteira da transferência de aprendizado: manter o corpo, jogar a cabeça fora e treinar
uma cabeça nova para os rótulos novos. Se o corpo conhece de fato só *aquilo de que dígitos são
feitos*, ou conhece *a cara de 0 a 4*, é uma pergunta que a próxima seção responde com uma execução.
