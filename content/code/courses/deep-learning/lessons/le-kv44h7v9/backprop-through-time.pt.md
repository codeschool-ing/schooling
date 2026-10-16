---
title: Retropropagação no tempo, e o gradiente que some
version: 1
---

Treinar uma RNN não pede algoritmo novo. **Desenrolada, ela é uma rede profunda, e a retropropagação da
aula 3 passa por ela sem mudança.** O nome disso, retropropagação no tempo, diz só que as camadas da rede
desenrolada são os passos da sequência. Os pesos são compartilhados, então o gradiente de cada peso é a
soma do que cada passo contribui.

O problema está na palavra *profunda*. Uma sequência de 50 passos se desenrola em 50 camadas, e a aula 3
mostrou o que acontece com um gradiente descendo uma pilha profunda de sigmoids: ele encolhe camada a
camada. Aqui acontece o mesmo. Para descobrir quanto a última saída depende de cada entrada, o programa
abaixo pede ao autograd o gradiente em relação à própria entrada. Salve como `~/dl/bptt.py`:

```schooling-example
{
  "language": "python",
  "file": "bptt.py",
  "parts": [
    {
      "code": "\"\"\"bptt: how much the last output of a recurrent layer depends on each input before it.\"\"\"\nimport sys\n\nimport torch\nimport torch.nn as nn\n\ncell = sys.argv[1]\ntorch.manual_seed(0)\nif cell == \"rnn\":\n    layer = nn.RNN(8, 32, batch_first=True)\nelse:\n    layer = nn.LSTM(8, 32, batch_first=True)\n    if len(sys.argv) > 2:\n        with torch.no_grad():\n            layer.bias_hh_l0[32:64] += float(sys.argv[2])",
      "note": "O primeiro argumento escolhe a camada, `rnn` ou `lstm`; o segundo, para uma LSTM, é um número somado a um dos vieses dela. Esse segundo argumento é para a próxima seção, e esta só roda `rnn`."
    },
    {
      "code": "x = torch.randn(1, 50, 8, requires_grad=True)\nout, _ = layer(x)\nout[0, -1].sum().backward()\nsize = x.grad[0].norm(dim=1)",
      "note": "Uma sequência de 50 passos, com `requires_grad` na própria entrada. Depois do `backward`, `x.grad` guarda, para cada passo, quanto a última saída se moveria se a entrada daquele passo se movesse: o gradiente, resumido num comprimento por passo."
    },
    {
      "code": "for back in (0, 1, 2, 5, 10, 20, 30, 49):\n    print(f\"{cell}  {back:2d} steps back  gradient {size[49 - back]:.1e}\")"
    }
  ]
}
```

```
ana@vm:~/dl$ python bptt.py rnn
rnn   0 steps back  gradient 1.6e+00
rnn   1 steps back  gradient 6.8e-01
rnn   2 steps back  gradient 4.5e-01
rnn   5 steps back  gradient 6.5e-02
rnn  10 steps back  gradient 3.4e-03
rnn  20 steps back  gradient 6.2e-06
rnn  30 steps back  gradient 1.2e-08
rnn  49 steps back  gradient 2.9e-14
```

**A entrada do último passo move a saída com um gradiente de 1.6; a entrada 49 passos atrás, com
2.9e-14.** Dez passos atrás ele vale 3.4e-03, quase quinhentas vezes menor que no fim, e vinte passos
atrás vale 6.2e-06. O que quer que o primeiro símbolo de uma sequência dissesse, a atualização que ele
manda aos pesos é pequena demais para mudar alguma coisa.

A razão é um produto. Voltar um passo multiplica o gradiente por `W_hh` e pela inclinação do `tanh`, que
é no máximo 1 e menor onde quer que a unidade esteja longe de zero. Cinquenta fatores assim, cada um um
pouco abaixo de 1 em tamanho, dão um número muito perto de zero. Se os pesos fossem grandes, o mesmo
produto cresceria, e um gradiente que explode joga os pesos longe num único passo. Esse caso tem um
remédio bruto e eficaz, cortar o comprimento do gradiente num teto antes do passo, que o PyTorch oferece
como `torch.nn.utils.clip_grad_norm_`. **O caso do encolhimento não tem remédio assim**, porque um
gradiente de 1e-14 não carrega direção que valha a pena ampliar.

Então uma RNN simples aprende o que fica a poucos passos e é cega para o que fica a cinquenta, não por
falta de memória para guardar, mas porque o treino nunca lhe diz para guardar. A saída não foi um
otimizador melhor. Foi uma célula diferente.
