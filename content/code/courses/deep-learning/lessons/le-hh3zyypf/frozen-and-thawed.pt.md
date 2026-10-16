---
title: Congelado e descongelado, um tensor por vez
version: 1
---

A aula 13 congelou o corpo inteiro do `base.pt` e treinou uma cabeça nova por cima. **Fine-tuning é
o mesmo começo com parte do corpo também liberada para aprender**, e a decisão desta aula é quanto.
Antes de treinar qualquer coisa, vale ver exatamente o que "congelado" quer dizer no PyTorch,
porque duas crenças comuns sobre isso estão erradas.

A primeira é que `model.eval()` congela um modelo. Não congela: o modo de avaliação muda o
comportamento de algumas camadas, entre elas dropout e batch normalization, e não tem nada a ver
com gradientes. A segunda é que uma camada congelada é algo que o otimizador conhece. Não é:
**congelar é uma marca em cada tensor de parâmetros, `requires_grad`, e o otimizador só enxerga os
tensores que recebeu.** O programa abaixo mostra as duas coisas. Ele precisa do `base.pt` da aula
13 em `~/dl`; se você o apagou, rode de novo o `pretrain.py` da aula 13, que grava o mesmo arquivo.
Salve como `~/dl/freeze.py`:

```schooling-example
{
  "language": "python",
  "file": "freeze.py",
  "parts": [
    {
      "code": "\"\"\"freeze: which parameters of base.pt learn, and how the optimiser is told.\"\"\"\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\n\nimport cnn\nimport tdigits\n\nmodel = cnn.make_cnn(5)\nmodel.load_state_dict(torch.load(\"base.pt\"))\nmodel[8] = nn.Linear(64, 5)\nfor p in model[:6].parameters():\n    p.requires_grad = False",
      "note": "O `base.pt` da aula 13, despejado no `cnn.make_cnn(5)` da aula 11, com uma cabeça nova para os dígitos de 5 a 9. `model[:6]` são as seis primeiras camadas: as duas convoluções, os ReLUs delas, o pooling e o flatten. Só as convoluções têm parâmetros, e cada tensor delas recebe a marca."
    },
    {
      "code": "for name, p in model.named_parameters():\n    print(f\"{name:9s} {str(tuple(p.shape)):15s} {p.numel():6d}  requires_grad={p.requires_grad}\")\nprint(\"learns\", sum(p.numel() for p in model.parameters() if p.requires_grad),\n      \"of\", sum(p.numel() for p in model.parameters()))",
      "note": "O `named_parameters` devolve cada tensor com o nome dele, que é a posição da camada no `Sequential` seguida de `weight` ou `bias`. São os mesmos nomes que o `base.pt` guarda."
    },
    {
      "code": "(x, y), _, _ = tdigits.load(images=True)\nfive = y >= 5\nmodel.eval()\nloss = F.cross_entropy(model(x[five][:32]), y[five][:32] - 5)\nloss.backward()\nprint(\"gradients after backward, in eval mode:\",\n      [name for name, p in model.named_parameters() if p.grad is not None])",
      "note": "Um lote de 32 imagens de 5 a 9, ida e volta, com o modelo em modo de avaliação de propósito. A lista dá o nome de todo tensor que recebeu um gradiente."
    },
    {
      "code": "opt = torch.optim.Adam([\n    {\"params\": model[6].parameters(), \"lr\": 1e-4},\n    {\"params\": model[8].parameters(), \"lr\": 1e-3},\n])\nfor i, group in enumerate(opt.param_groups):\n    print(f\"group {i}: {len(group['params'])} tensors, lr {group['lr']}\")\nbefore = [p.clone() for p in model.parameters()]\nopt.step()\nprint(\"changed by one step:\",\n      [not torch.equal(b, p) for b, p in zip(before, model.parameters())])",
      "note": "Um otimizador que recebe dois grupos de parâmetros em vez de uma lista: a camada de 512 para 64 a 1e-4 e a cabeça nova a 1e-3. As convoluções congeladas não estão em nenhum. Um passo, e cada um dos oito tensores é comparado com a cópia de antes."
    }
  ]
}
```

```
ana@vm:~/dl$ python freeze.py
0.weight  (16, 1, 3, 3)      144  requires_grad=False
0.bias    (16,)               16  requires_grad=False
2.weight  (32, 16, 3, 3)    4608  requires_grad=False
2.bias    (32,)               32  requires_grad=False
6.weight  (64, 512)        32768  requires_grad=True
6.bias    (64,)               64  requires_grad=True
8.weight  (5, 64)            320  requires_grad=True
8.bias    (5,)                 5  requires_grad=True
learns 33157 of 37957
gradients after backward, in eval mode: ['6.weight', '6.bias', '8.weight', '8.bias']
group 0: 2 tensors, lr 0.0001
group 1: 2 tensors, lr 0.001
changed by one step: [False, False, False, False, True, True, True, True]
```

## Lendo a saída

**A tabela é a rede como o otimizador poderia vê-la.** Cada tensor tem um nome, um formato e uma
contagem, e os quatro das convoluções dizem `requires_grad=False`. Juntos eles guardam 4.800 dos
37.957 parâmetros; a camada de 512 para 64 e a cabeça nova guardam os outros 33.157, que é a linha
`learns 33157 of 37957`.

**O backward pula por completo um tensor congelado.** Depois de um lote, a lista de tensores com
gradiente traz `6.weight`, `6.bias`, `8.weight` e `8.bias`, e mais nada. As convoluções foram usadas
na ida, então o gradiente ainda passou *por* elas no caminho de volta, mas nada foi guardado *para*
elas. Essa é toda a economia: nenhum gradiente para um tensor congelado, e portanto nenhuma memória
para ele e nada para o otimizador mover. O modelo ficou em modo de avaliação o tempo todo e os
gradientes chegaram mesmo assim, o que encerra a primeira crença.

**Um otimizador pode ter vários grupos de parâmetros, cada um com a própria taxa.** Em vez de uma
lista, o `torch.optim.Adam` recebeu dois dicionários, e `param_groups` os devolve: dois tensores a
`0.0001` e dois a `0.001`. O passo então mudou exatamente esses quatro tensores e deixou os quatro
primeiros como o `base.pt` os tinha, que é a última linha.

Daí saem dois hábitos, e todo programa desta aula os mantém:

- **Dê ao otimizador só os tensores que aprendem**, com
  `[p for p in model.parameters() if p.requires_grad]` ou com grupos explícitos. O Adam pularia de
  qualquer jeito um tensor cujo gradiente é `None`, mas uma lista que diz o que aprende é uma lista
  que você confere lendo.
- **Ponha as marcas antes de montar o otimizador**, e troque uma camada antes de pôr as marcas: uma
  camada criada com `nn.Linear` já nasce com `requires_grad=True`, e é por isso que a cabeça nova
  aprende sem ninguém ligá-la.

O modo de avaliação importa num caso, e ele é o espelho da primeira crença. A batch normalization,
que a aula 8 construiu, guarda uma média e uma variância acumuladas que são buffers e não
parâmetros, e em modo de treino ela as atualiza não importa o que `requires_grad` diga. **Então
congelar um corpo que tem batch normalization também quer dizer manter essas camadas em modo de
avaliação**, senão as estatísticas aprendidas nos dados antigos derivam na direção dos lotes novos.
O `cnn.make_cnn` não tem essa camada, então nada nesta aula depende disso, mas a ResNet da aula 12
põe uma depois de cada convolução.
