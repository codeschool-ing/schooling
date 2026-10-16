---
title: Uma RNN escrita à mão
version: 1
---

Uma rede recorrente soa como um tipo novo de máquina. **É a camada da aula 1 dentro de um laço `for`**,
com uma entrada a mais: o que o laço calculou no passo anterior. No passo *t* ela lê a entrada `x_t` e o
estado anterior `h_{t-1}`, e escreve um estado novo:

`h_t = tanh(x_t W_ih + h_{t-1} W_hh + b)`

O estado é um vetor de tamanho fixo, cinco números no programa abaixo, e é a memória inteira da rede.
O que a sequência disse antes do passo *t* só chega ao passo *t* através dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 240\" role=\"img\" aria-label=\"Uma RNN desenrolada em quatro passos. Quatro caixas iguais com o rótulo RNN ficam em fila, cada uma lendo uma entrada de baixo, de x0 a x3. Uma seta leva o estado de cada caixa para a próxima, começando de um estado zero à esquerda, e cada caixa entrega o seu estado para cima como saída, de h0 a h3. O último estado, h3, é o que um modelo que lê a sequência inteira usa.\"><text x=\"320\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">a mesma célula, com os mesmos pesos, em todo passo</text><text x=\"40\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper-dim)\">0</text><path d=\"M52 120 L92 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M84.6 123.1 L92 120 L84.6 116.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"95\" y=\"95\" width=\"80\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">RNN</text><path d=\"M135 195 L135 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M138.1 155.4 L135 148 L131.9 155.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"135\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x0</text><path d=\"M135 95 L135 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M138.1 69.4 L135 62 L131.9 69.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"135\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h0</text><path d=\"M175 120 L227 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M219.6 123.1 L227 120 L219.6 116.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"230\" y=\"95\" width=\"80\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">RNN</text><path d=\"M270 195 L270 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M273.1 155.4 L270 148 L266.9 155.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"270\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x1</text><path d=\"M270 95 L270 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M273.1 69.4 L270 62 L266.9 69.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"270\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h1</text><path d=\"M310 120 L362 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M354.6 123.1 L362 120 L354.6 116.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"365\" y=\"95\" width=\"80\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"405\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">RNN</text><path d=\"M405 195 L405 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M408.1 155.4 L405 148 L401.9 155.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"405\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x2</text><path d=\"M405 95 L405 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M408.1 69.4 L405 62 L401.9 69.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"405\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h2</text><path d=\"M445 120 L497 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M489.6 123.1 L497 120 L489.6 116.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500\" y=\"95\" width=\"80\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">RNN</text><path d=\"M540 195 L540 148\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M543.1 155.4 L540 148 L536.9 155.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">x3</text><path d=\"M540 95 L540 62\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M543.1 69.4 L540 62 L536.9 69.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"540\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">h3</text><text x=\"201\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">estado</text><text x=\"125\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">entrada</text></svg>", "caption": "Uma RNN é uma célula aplicada uma vez por passo. Desenrolada, parece uma rede profunda cujas camadas todas compartilham os mesmos pesos."}
```

O programa monta a `nn.RNN` do PyTorch, roda, e depois calcula a mesma coisa com a fórmula num laço.
Salve como `~/dl/rnn_by_hand.py`:

```schooling-example
{
  "language": "python",
  "file": "rnn_by_hand.py",
  "parts": [
    {
      "code": "\"\"\"rnn_by_hand: what nn.RNN computes, written as a loop over time.\"\"\"\nimport torch\nimport torch.nn as nn\n\ntorch.manual_seed(0)\nrnn = nn.RNN(input_size=3, hidden_size=5, batch_first=True)\nx = torch.randn(2, 4, 3)\nout, h_last = rnn(x)\nprint(\"out\", tuple(out.shape), \" h_last\", tuple(h_last.shape))",
      "note": "Duas sequências de quatro passos, três atributos por passo. `batch_first=True` pede o lote no primeiro eixo; sem isso, as camadas recorrentes do PyTorch esperam o tempo primeiro. A camada devolve duas coisas: o estado depois de cada passo, e o estado depois do último."
    },
    {
      "code": "W_ih, W_hh = rnn.weight_ih_l0, rnn.weight_hh_l0\nb = rnn.bias_ih_l0 + rnn.bias_hh_l0\nh = torch.zeros(2, 5)\nsteps = []\nfor t in range(4):\n    h = torch.tanh(x[:, t] @ W_ih.T + h @ W_hh.T + b)\n    steps.append(h)\nmine = torch.stack(steps, dim=1)",
      "note": "A RNN inteira é a linha de dentro do laço. O novo estado mistura a entrada deste passo e o estado anterior, cada um pela sua matriz, e passa a soma por `tanh`. O estado começa em zero, e as mesmas duas matrizes servem a todos os passos."
    },
    {
      "code": "print(\"the loop equals nn.RNN:\", torch.allclose(mine, out, atol=1e-6))\nprint(\"the last output is the final state:\", torch.equal(out[:, -1], h_last[0]))\nprint(\"parameters:\", sum(p.numel() for p in rnn.parameters()),\n      \"=\", W_ih.numel(), \"+\", W_hh.numel(), \"+ 2 biases of\", b.numel())\nprint(\"the same 50 parameters read a sequence of 40:\", tuple(rnn(torch.randn(2, 40, 3))[0].shape))",
      "note": "O PyTorch guarda dois vieses onde um bastaria, e é por isso que a contagem tem dois de cinco. A última linha dá à camada uma sequência dez vezes mais longa, e nada precisa mudar: os pesos pertencem ao passo, não a uma posição."
    }
  ]
}
```

```
ana@vm:~/dl$ python rnn_by_hand.py
out (2, 4, 5)  h_last (1, 2, 5)
the loop equals nn.RNN: True
the last output is the final state: True
parameters: 50 = 15 + 25 + 2 biases of 5
the same 50 parameters read a sequence of 40: (2, 40, 5)
```

**O laço e a `nn.RNN` concordam**, então não há mais nada escondido dentro da camada: dois produtos de
matrizes, um viés e um `tanh`, uma vez por passo. A versão do PyTorch é um laço compilado sobre os mesmos
passos, mais rápido e com a mesma aritmética.

`out` tem um estado para cada passo, `(2, 4, 5)`, e `h_last` só o último, com um primeiro eixo de 1 que
conta camadas. **O estado final é o resumo da sequência inteira**, e um modelo que precisa responder uma
pergunta sobre uma sequência, como a classe a que ela pertence, em geral lê esse estado e mais nada. Um
modelo que rotula cada passo, como um etiquetador que marca cada palavra como substantivo ou verbo, lê o
`out` inteiro.

A camada tem 50 parâmetros: 15 em `W_ih`, 25 em `W_hh` e dois vieses de 5. **Nenhum deles depende do
comprimento**, e é por isso que a última linha lê uma sequência de 40 passos com os mesmos pesos que leram
4. Isso resolve o problema da camada densa da seção anterior. E torna o desenho desenrolado acima
literalmente verdadeiro: quatro passos de uma RNN são uma rede de quatro camadas que compartilham os
pesos, e treiná-la é fazer a retropropagação pelas quatro, que é a próxima seção.
