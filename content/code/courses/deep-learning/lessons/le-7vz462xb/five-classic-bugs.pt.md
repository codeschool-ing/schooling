---
title: Cinco erros clássicos, cada um executado
version: 1
---

Um laço de treino com um erro dentro raramente para. **A maioria dos erros abaixo roda até o fim e
imprime números**, e são os números que precisam ser lidos. Cada um abaixo é comum, e cada um foi
executado, então o sintoma é uma transcrição e não uma descrição. Salve como `~/dl/bugs.py`:

```schooling-example
{
  "language": "python",
  "file": "bugs.py",
  "parts": [
    {
      "code": "\"\"\"bugs: the training loop with one classic mistake in it, named on the command line.\"\"\"\nimport sys\n\nimport numpy as np\nimport torch\nimport torch.nn as nn\nimport torch.nn.functional as F\n\nimport tdigits\nfrom mlp import make_mlp\n\nbug = sys.argv[1]\ntorch.manual_seed(0)\n(x, y), (x_val, y_val), _ = tdigits.load()\nmodel = make_mlp()\nif bug == \"eval\":\n    model = nn.Sequential(model[0], model[1], nn.Dropout(0.5), model[2])\nif bug == \"labels\":\n    y = y.reshape(-1, 1)\nopt = torch.optim.SGD(model.parameters(), lr=0.1)",
      "note": "A mesma rede, os mesmos dados e a mesma taxa do `train.py`. Dois erros precisam de algo preparado antes: o caso `eval` põe dropout na rede, porque o modo de avaliação só muda uma rede que tenha uma camada afetada por ele, e o caso `labels` dá a cada rótulo uma dimensão própria."
    },
    {
      "code": "for epoch in range(1, 11):\n    order = torch.randperm(len(y))\n    losses = []\n    for start in range(0, len(y), 32):\n        idx = order[start:start + 32]\n        logits = model(x[idx])\n        if bug == \"softmax\":\n            logits = F.softmax(logits, dim=1)\n        loss = F.cross_entropy(logits, y[idx])\n        if bug != \"zero_grad\":\n            opt.zero_grad()\n        loss.backward()\n        opt.step()\n        losses.append(loss if bug == \"item\" else loss.item())\n    if epoch % 5 == 0:\n        print(f\"epoch {epoch:2d}  train loss {np.mean(losses):.4f}\")",
      "note": "O laço do `loop.py`, escrito no lugar por dez épocas, com um `if` onde cada erro entra. Qualquer outro nome na linha de comando, `none` por exemplo, o roda corretamente."
    },
    {
      "code": "if bug == \"eval\":\n    for _ in range(2):\n        logits = model(x_val)\n        acc = (logits.argmax(dim=1) == y_val).float().mean().item()\n        print(f\"no eval(), no no_grad():  val acc {acc:.3f}  recorded {logits.requires_grad}\")\nmodel.eval()\nwith torch.no_grad():\n    logits = model(x_val)\nacc = (logits.argmax(dim=1) == y_val).float().mean().item()\nprint(f\"eval() and no_grad():  val acc {acc:.3f}  recorded {logits.requires_grad}\")",
      "note": "A acurácia de validação, medida do jeito certo no fim de toda execução. No caso `eval`, ela é medida antes duas vezes do jeito errado, no modo de treino e com o registro ligado."
    }
  ]
}
```

Primeiro o laço correto, para ter com o que comparar:

```
ana@vm:~/dl$ python bugs.py none
epoch  5  train loss 0.7894
epoch 10  train loss 0.3120
eval() and no_grad():  val acc 0.914  recorded False
```

## 1. Esquecer o `zero_grad`

```
ana@vm:~/dl$ python bugs.py zero_grad
epoch  5  train loss 2.6018
epoch 10  train loss 3.8694
eval() and no_grad():  val acc 0.200  recorded False
```

**A perda sobe, de 2.6018 na época 5 para 3.8694 na época 10, e a acurácia termina em 0.200.** Sem o
`zero_grad`, cada `backward` soma aos gradientes de todos os lotes anteriores, então o `step` move os
pesos pela soma de todos os gradientes até ali. O passo cresce a cada lote até o treino ser jogado de
um lado para o outro em vez de guiado. Com uma taxa menor, o mesmo erro pode parecer uma curva lenta,
quase normal, que é o caso mais difícil de perceber.

## 2. Softmax antes da perda

```
ana@vm:~/dl$ python bugs.py softmax
epoch  5  train loss 2.2955
epoch 10  train loss 2.2804
eval() and no_grad():  val acc 0.194  recorded False
```

**A perda fica perto de 2.3, em 2.2955 e depois 2.2804, e a acurácia termina em 0.194.** O `F.cross_entropy` recebe as pontuações
brutas, os logits, e aplica o softmax ele mesmo. Recebendo probabilidades, ele aplica um segundo
softmax a números que estão todos entre 0 e 1, e o resultado fica perto de igual entre as dez
classes, diga a rede o que disser. O gradiente que chega aos pesos é espremido na mesma medida, e o
treino quase não anda. Uma última camada com `nn.Softmax` faz o mesmo estrago, de forma menos
visível.

## 3. Avaliar no modo de treino, com o registro ligado

```
ana@vm:~/dl$ python bugs.py eval
epoch  5  train loss 1.2932
epoch 10  train loss 0.8318
no eval(), no no_grad():  val acc 0.742  recorded True
no eval(), no no_grad():  val acc 0.728  recorded True
eval() and no_grad():  val acc 0.908  recorded False
```

Esta rede tem dropout, que a aula 7 escreveu à mão: no modo de treino ele zera metade das unidades
ocultas ao acaso. **Medida duas vezes no modo de treino, a mesma rede nas mesmas imagens marcou 0.742
e depois 0.728**, e as duas abaixo do 0.908 que ela marca no modo de avaliação. Uma nota que muda sem
que nada tenha mudado é o sintoma. Uma rede com normalização em lote, assunto da aula 8, sofre mais,
já que cada avaliação no modo de treino também mexe nas suas estatísticas acumuladas.

A segunda metade do erro imprime `recorded True`. Sem `torch.no_grad()`, cada operação da avaliação
foi registrada, para um passo para trás que nunca vem. Isso custa memória e tempo e mais nada, então
só aparece quando o conjunto de validação é grande.

## 4. Guardar a perda como tensor

```
ana@vm:~/dl$ python bugs.py item
Traceback (most recent call last):
  File "/home/ana/dl/bugs.py", line 38, in <module>
    print(f"epoch {epoch:2d}  train loss {np.mean(losses):.4f}")
                                          ^^^^^^^^^^^^^^^
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/numpy/_core/fromnumeric.py", line 3862, in mean
    return _methods._mean(a, axis=axis, dtype=dtype,
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/numpy/_core/_methods.py", line 116, in _mean
    arr = asanyarray(a)
          ^^^^^^^^^^^^^
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/torch/_tensor.py", line 1255, in __array__
    return self.numpy()
           ^^^^^^^^^^^^
RuntimeError: Can't call numpy() on Tensor that requires grad. Use tensor.detach().numpy() instead.
```

`losses.append(loss)` guardou a perda de cada lote como tensor, junto com o seu registro. O treino
rodou, e foi o primeiro relatório, na época 5, que falhou: o NumPy não consegue transformar em array um tensor que pede
gradiente, e diz para fazer `detach()` antes. **Escreva `loss.item()` onde quer que uma perda seja
guardada para relatório.** O erro é a versão de sorte. `total += loss` não levanta nada, soma o
registro de cada lote numa cadeia que só cresce, e segura todos eles na memória até a época acabar.

## 5. Rótulos no formato errado

```
ana@vm:~/dl$ python bugs.py labels
Traceback (most recent call last):
  File "/home/ana/dl/bugs.py", line 31, in <module>
    loss = F.cross_entropy(logits, y[idx])
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/dl/.venv/lib/python3.12/site-packages/torch/nn/functional.py", line 3561, in cross_entropy
    return torch._C._nn.cross_entropy_loss(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
RuntimeError: 0D or 1D target tensor expected, multi-target not supported
```

O `F.cross_entropy` quer um número de classe por exemplo, formato `[32]`, e os rótulos eram
`[32, 1]`. Este para no primeiro lote, com uma mensagem que aponta o alvo. **A versão silenciosa
deste erro mora na regressão**, onde as previsões saem como coluna e os alvos como linha:

```
ana@vm:~/dl$ python -c "import torch, torch.nn.functional as F; y = torch.arange(4.0); print(F.mse_loss(y.reshape(-1, 1), y), F.mse_loss(y, y))"
<string>:1: UserWarning: Using a target size (torch.Size([4])) that is different to the input size (torch.Size([4, 1])). This will likely lead to incorrect results due to broadcasting. Please ensure they have the same size.
tensor(2.5000) tensor(0.)
```

As quatro previsões são iguais aos quatro alvos, então a perda devia ser 0, e é 2.5. O `F.mse_loss`
fez broadcasting de `[4, 1]` contra `[4]` para `[4, 4]`, comparou cada previsão com cada alvo e só
avisou. Treinar com essa perda roda até o fim e aprende a coisa errada. Imprimir os formatos dos dois
argumentos de uma perda na primeira vez que ela roda custa uma linha e elimina a família inteira.
