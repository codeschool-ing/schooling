---
title: Autograd, conferido contra a aula 3
version: 1
---

A aula 3 calculou à mão os gradientes de uma rede 2-2-1: o passo para a frente, depois a regra da
cadeia escrita peso por peso, depois o `tinynet.py` fazendo o mesmo para qualquer pilha de camadas.
**O PyTorch faz essa parte por você**, e o jeito de confiar nele é dar a ele a mesma rede e comparar.
Salve como `~/dl/autograd.py`:

```schooling-example
{
  "language": "python",
  "file": "autograd.py",
  "parts": [
    {
      "code": "\"\"\"autograd: lesson 3's 2-2-1 network again, with PyTorch working out the gradients.\"\"\"\nimport torch\n\nx = torch.tensor([1.0, 2.0])\ny = 1.0\nW1 = torch.tensor([[0.5, -0.5],\n                   [0.25, 0.25]], requires_grad=True)\nb1 = torch.tensor([0.0, -1.0], requires_grad=True)\nW2 = torch.tensor([1.5, 1.0], requires_grad=True)\nb2 = torch.tensor(0.25, requires_grad=True)",
      "note": "A mesma entrada, o mesmo alvo e os mesmos pesos do `byhand.py` da aula 3. `requires_grad=True` marca os quatro tensores cujos gradientes se quer; a entrada e o alvo são dados e não levam marca."
    },
    {
      "code": "out = torch.relu(x @ W1 + b1) @ W2 + b2\nL = (out - y) ** 2\nprint(\"out\", out.item(), \" L\", L.item())\nprint(\"recorded:\", L.grad_fn.name(), \"<-\", L.grad_fn.next_functions[0][0].name())",
      "note": "O passo para a frente é escrito como aritmética comum. Como algumas das entradas estão marcadas, cada operação também se registra, e `grad_fn` é a última entrada desse registro: o quadrado, que aponta para a subtração anterior."
    },
    {
      "code": "L.backward()\nprint(\"dW2\", W2.grad.tolist(), \" db2\", b2.grad.item())\nprint(\"dW1\", W1.grad.tolist(), \" db1\", b1.grad.tolist())",
      "note": "Uma chamada percorre o registro de trás para a frente, aplicando a regra da cadeia em cada passo, e deixa o gradiente de cada tensor marcado no seu `.grad`. Nada aqui foi escrito à mão."
    },
    {
      "code": "L = (torch.relu(x @ W1 + b1) @ W2 + b2 - y) ** 2\nL.backward()\nprint(\"again, not zeroed: dW2\", W2.grad.tolist())",
      "note": "Um segundo passo para a frente e para trás, com os mesmos pesos. O `backward` soma no `.grad` em vez de substituí-lo, então o gradiente sai dobrado."
    },
    {
      "code": "with torch.no_grad():\n    out = torch.relu(x @ W1 + b1) @ W2 + b2\nprint(\"under no_grad:\", out.requires_grad, out.grad_fn)",
      "note": "Dentro de `torch.no_grad()` nada é registrado: o resultado não tem `grad_fn` e não pode ser derivado. É assim que se faz uma previsão quando nenhum passo de treino vem depois."
    }
  ]
}
```

```
ana@vm:~/dl$ python autograd.py
out 1.75  L 0.5625
recorded: PowBackward0 <- SubBackward0
dW2 [1.5, 0.0]  db2 1.5
dW1 [[2.25, 0.0], [4.5, 0.0]]  db1 [2.25, 0.0]
again, not zeroed: dW2 [3.0, 0.0]
under no_grad: False None
```

**Os números são os da aula 3.** A saída é 1.75 contra um alvo de 1, a perda 0.5625, o gradiente de
`W2` é `[1.5, 0.0]` e o de `W1` é `[[2.25, 0.0], [4.5, 0.0]]`, com a coluna da direita zerada porque
o ReLU da segunda unidade oculta estava desligado. Nada no programa diz como derivar um produto, um
ReLU ou um quadrado.

## O que ele registra

Autograd não é derivação simbólica e não lê o programa. **Ele observa a aritmética enquanto ela
roda.** Cada operação sobre um tensor que pede gradiente cria um pequeno registro de si mesma, com o
que precisa para o seu próprio passo para trás: o produto de matrizes guarda as entradas, o ReLU
guarda quais elementos eram positivos. Os registros apontam para os anteriores, e `grad_fn` é o
último: `PowBackward0`, o quadrado, apontando para `SubBackward0`, a subtração.

O `backward()` percorre essa cadeia a partir do fim, que é exatamente o que o `Net.backward` fazia ao
percorrer as camadas ao contrário. Como o registro é feito enquanto o código roda, um `if` ou um laço
num passo para a frente não precisa de nada especial: o que rodou é o que é derivado.

## Duas consequências

**Gradientes se somam.** O segundo `backward` deixou `W2.grad` em `[3.0, 0.0]`, o dobro do primeiro.
Ele soma em vez de substituir, o que é útil quando um passo é dividido em vários lotes, e é por isso
que um laço de treino esvazia todo `.grad` antes de cada `backward`. Três seções adiante, o primeiro
de cinco erros mostra o que acontece quando não esvazia.

**Registrar custa memória, então dá para desligar.** Dentro de `torch.no_grad()` o resultado não tem
`grad_fn` e `requires_grad` é `False`. Medir uma rede num conjunto de validação se faz assim, porque
nada vai ser derivado e os registros seriam construídos para ninguém.

`.item()` e `.tolist()` no programa transformam tensores em números comuns do Python para imprimir.
Um tensor que pede gradiente se recusa a virar um array do NumPy diretamente, por um motivo que o
quarto desses erros mostra.
