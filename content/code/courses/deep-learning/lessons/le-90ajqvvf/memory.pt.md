---
title: O que o treino guarda na memória
version: 1
---

Um modelo salvo é só os pesos dele: o `mlp.pt` da aula 9 guardava 2.410 números. Então é fácil achar que
o treino precisa de mais ou menos tanta memória quanto o arquivo ocupa no disco. **O treino guarda
quatro coisas, e os pesos são só uma delas.**

- Os pesos, 4 bytes cada em float32.
- Os gradientes, um por peso, do mesmo tamanho: o `backward` os preenche e o `step` os lê.
- O estado do otimizador. O SGD simples não guarda nenhum. O SGD com momentum guarda um número por
  peso, e o Adam guarda dois, as médias móveis do gradiente e do quadrado dele que a aula 5 construiu.
- As ativações: o que a passada para a frente guarda para que a passada para trás calcule os produtos
  dela. O backward da aula 3 precisava da entrada de cada camada, e o do PyTorch também precisa.

As três primeiras crescem com o número de parâmetros, e com Adam em float32 somam 16 bytes por
parâmetro. **As ativações crescem com o lote**, porque cada exemplo dele tem as suas. O programa abaixo
conta as quatro à mão para a CNN da aula 11 e depois as mede nos tensores que o PyTorch de fato guarda.
Salve como `~/dl/memory.py`:

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "\"\"\"memory: what training the CNN holds in memory, counted by hand and then measured.\"\"\"\nimport torch\nimport torch.nn.functional as F\n\nimport cnn\nimport tdigits\n\ntorch.manual_seed(0)\nmodel = cnn.make_cnn()\nopt = torch.optim.Adam(model.parameters(), lr=0.001)\n(x, y), _, _ = tdigits.load(images=True)\nn = sum(p.numel() for p in model.parameters())\nprint(f\"{n} parameters, 4 bytes each in float32\")\nprint(f\"by hand:  weights {4 * n:,}  gradients {4 * n:,}  Adam's two buffers {8 * n:,}  bytes\")\n# What backward needs per image: the input, the outputs of the three ReLUs, the pooled maps,\n# the 10 log-probabilities, all float32; where each maximum came from (int64); the label (int64).\nfloats = 64 + 16 * 8 * 8 + 32 * 8 * 8 + 32 * 4 * 4 + 64 + 10\nprint(f\"by hand:  activations {4 * floats + 8 * 32 * 4 * 4 + 8:,} bytes per example\")",
      "note": "A conta à mão, a partir de dois fatos: um float32 ocupa 4 bytes, e o Adam guarda dois números próprios para cada parâmetro. As ativações saem das formas nos comentários do `cnn.py`: os 64 pixels de entrada, 16 e 32 mapas de 8 por 8 saindo dos dois primeiros ReLUs, 32 de 4 por 4 saindo do pooling, 64 saindo do último ReLU e 10 log-probabilidades da perda. O max pooling também guarda qual dos quatro valores era o maior, como um inteiro de 8 bytes."
    },
    {
      "code": "def nbytes(tensors):\n    return sum(t.numel() * t.element_size() for t in tensors)\n\n\nkept = {}\nown = {p.untyped_storage().data_ptr() for p in model.parameters()}\n\n\ndef keep(t):\n    if t.untyped_storage().data_ptr() not in own:\n        kept[t.untyped_storage().data_ptr()] = t.untyped_storage()\n    return t",
      "note": "O autograd chama `keep` para cada tensor que a passada para a frente guarda para a passada para trás. Ela anota cada bloco de memória uma vez só, porque várias operações podem guardar o mesmo tensor, e pula os pesos, que são contados à parte."
    },
    {
      "code": "for batch in (32, 1077):\n    kept.clear()\n    xb, yb = x[:batch].clone(), y[:batch].clone()\n    with torch.autograd.graph.saved_tensors_hooks(keep, lambda t: t):\n        loss = F.cross_entropy(model(xb), yb)\n    opt.zero_grad()\n    loss.backward()\n    opt.step()\n    held = sum(s.nbytes() for s in kept.values())\n    print(f\"batch {batch:4d}: activations kept for backward {held:,} bytes, {held // batch:,} per example\")",
      "note": "`saved_tensors_hooks` entrega cada tensor guardado para `keep` durante a passada para a frente. O lote é copiado com `clone` para ter memória própria; uma fatia de `x` dividiria a memória das 1.077 imagens e contaria todas. Depois, um passo comum do Adam, que cria os buffers do otimizador."
    },
    {
      "code": "grads = nbytes(p.grad for p in model.parameters())\nbuffers = nbytes(s[k] for s in opt.state.values() for k in (\"exp_avg\", \"exp_avg_sq\"))\nprint(f\"measured: weights {nbytes(model.parameters()):,}  gradients {grads:,}  Adam's two buffers {buffers:,}  bytes\")\nprint(f\"a model of 7 billion parameters, by the same rule: {16 * 7e9 / 1e9:.0f} GB before one activation\")",
      "note": "`exp_avg` e `exp_avg_sq` são os nomes que o Adam do PyTorch dá às duas médias móveis da aula 5, uma do gradiente e outra do quadrado dele. A última linha aplica os 16 bytes por parâmetro a um modelo do tamanho de um modelo de linguagem pequeno."
    }
  ]
}
```

```
ana@vm:~/dl$ python memory.py
38282 parameters, 4 bytes each in float32
by hand:  weights 153,128  gradients 153,128  Adam's two buffers 306,256  bytes
by hand:  activations 18,992 bytes per example
batch   32: activations kept for backward 607,748 bytes, 18,992 per example
batch 1077: activations kept for backward 20,454,388 bytes, 18,992 per example
measured: weights 153,128  gradients 153,128  Adam's two buffers 306,256  bytes
a model of 7 billion parameters, by the same rule: 112 GB before one activation
```

**A conta à mão e a medição batem até o byte**: 153.128 bytes de pesos, outro tanto de gradientes, e
306.256 dos buffers do Adam. As ativações dão 18.992 bytes por exemplo nos dois tamanhos de lote, que é
exatamente a conta à mão.

Num lote de 32, as ativações ocupam quase tanto quanto pesos, gradientes e buffers juntos. Num lote de
1.077, ocupam 20.454.388 bytes, contra 153.128 dos pesos. **Numa rede tão pequena, a memória do treino é
o lote.** Numa grande, os parâmetros pesam tanto quanto: a última linha aplica os 16 bytes por parâmetro
a um modelo de 7 bilhões e chega a 112 GB antes de uma única ativação. Um modelo desse tamanho é treinado em várias
placas ao mesmo tempo, com os pesos, os gradientes e o estado do otimizador divididos entre elas.

## Fazendo caber

Quatro remédios são de uso comum, e as duas próximas seções rodam dois deles.

- Menos bytes por número. A próxima seção guarda as ativações da passada para a frente em 16 bits em vez
  de 32.
- Um lote menor que ainda se comporta como um grande, somando os gradientes de vários lotes pequenos
  antes de um passo: a seção depois dela.
- Recalcular em vez de guardar. `torch.utils.checkpoint` joga fora as ativações de dentro de um bloco de
  camadas e roda esse bloco para a frente de novo durante a passada para trás. Troca aritmética extra por
  memória. Não foi executado aqui, porque nada neste curso tem falta de memória.
- Um otimizador mais leve. O SGD com momentum guarda metade do estado do Adam; a aula 5 comparou o que
  cada um faz com o treino.

Numa placa de vídeo a memória é a da própria placa, separada da do computador, e é o limite que decide o
tamanho do lote. O PyTorch informa quanto usou no pico. Estas linhas precisam de uma placa NVIDIA e não
foram executadas neste curso:

```python
torch.cuda.reset_peak_memory_stats()
# ... one training step, with the model and the batch on "cuda" ...
print(torch.cuda.max_memory_allocated() / 2**20, "MiB at the peak")
```

O `nvidia-smi`, rodado num terminal numa máquina dessas, mostra a mesma memória de fora do programa, para
cada processo que usa a placa.
