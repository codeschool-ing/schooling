---
title: Logits grandes, nan e log-sum-exp
version: 1
---

No papel, o softmax é a exponencial de cada logit dividida pela soma das exponenciais. **Digitada
exatamente assim, a fórmula falha com números que uma rede produz de verdade.** Um logit é uma
pontuação sem limite, e a exponencial de um logit grande não cabe num float.

Salve como `~/dl/stable.py`. Ele usa o `tinynet.py` da aula 3:

```schooling-example
{
  "language": "python",
  "file": "stable.py",
  "parts": [
    {
      "code": "\"\"\"stable: one cross-entropy computed three ways, on logits a network can produce.\"\"\"\nimport numpy as np\n\nfrom tinynet import softmax_cross_entropy\n\n\ndef naive(logits, y):\n    p = np.exp(logits) / np.exp(logits).sum(axis=1, keepdims=True)\n    return -np.log(p[np.arange(len(y)), y]).mean()",
      "note": "A fórmula exatamente como se escreve no papel. `np.exp(1000)` passa muito do maior float, então vira infinito, e infinito dividido por infinito é `nan`."
    },
    {
      "code": "def log_sum_exp(logits, y):\n    z = logits - logits.max(axis=1, keepdims=True)\n    return (np.log(np.exp(z).sum(axis=1)) - z[np.arange(len(y)), y]).mean()",
      "note": "A perda sem nunca formar uma probabilidade. Menos o log de um softmax é o log da soma das exponenciais menos o logit certo, e depois do deslocamento a maior exponencial é `exp(0) = 1`, então a soma é pelo menos 1 e o log dela nunca é menos infinito."
    },
    {
      "code": "print(\"largest float32\", np.finfo(np.float32).max, \"= exp of\", np.log(np.finfo(np.float32).max))\ny = np.array([0])                                                # class 0 is right in both\nlarge = np.array([[1000.0, 998.0, 990.0]], dtype=np.float32)\nfar_wrong = np.array([[0.0, 120.0, 0.0]], dtype=np.float32)\nfor name, logits in ((\"large\", large), (\"far wrong\", far_wrong)):\n    loss, grad = softmax_cross_entropy(logits, y)\n    print(f\"{name:9s}  naive {naive(logits, y):.4f}   tinynet {loss:.4f}\"\n          f\"   log-sum-exp {log_sum_exp(logits, y):.4f}   tinynet's gradient {np.round(grad[0], 3)}\")",
      "note": "Primeiro o teto: o maior número que o `float32` guarda, e o logit cuja exponencial chega nele. Depois dois casos em `float32`, a precisão em que a rede treina: logits grandes e próximos entre si, e uma rede que dá à classe errada 120 a mais que à certa."
    }
  ],
  "output": "ana@vm:~/dl$ python stable.py\n/home/ana/dl/stable.py:8: RuntimeWarning: overflow encountered in exp\n  p = np.exp(logits) / np.exp(logits).sum(axis=1, keepdims=True)\n/home/ana/dl/stable.py:8: RuntimeWarning: invalid value encountered in divide\n  p = np.exp(logits) / np.exp(logits).sum(axis=1, keepdims=True)\n/home/ana/dl/tinynet.py:66: RuntimeWarning: divide by zero encountered in log\n  loss = -np.log(p[rows, y]).mean()\n/home/ana/dl/stable.py:9: RuntimeWarning: divide by zero encountered in log\n  return -np.log(p[np.arange(len(y)), y]).mean()\nlargest float32 3.4028235e+38 = exp of 88.72284\nlarge      naive nan   tinynet 0.1270   log-sum-exp 0.1270   tinynet's gradient [-0.119  0.119  0.   ]\nfar wrong  naive inf   tinynet inf   log-sum-exp 120.0000   tinynet's gradient [-1.  1.  0.]"
}
```

A primeira linha é o teto. **O `float32` não guarda nada acima de 3,4 × 10³⁸, que é a exponencial de
88,72**, então um logit de 89 já estoura. Com logits perto de 1.000 a versão ingênua devolve `nan` e
dois avisos pelo caminho: as exponenciais estouraram para infinito, e infinito dividido por infinito
não tem valor. Nada interrompe o programa. Uma perda `nan` gera um gradiente `nan`, e uma única
atualização com ele transforma em `nan` todo peso que toca.

Os quatro avisos ficam acima de todas as linhas impressas porque a captura escreveu num arquivo, e o
Python segura a saída comum até o fim quando não está imprimindo num terminal. No seu terminal cada
aviso aparece logo antes da linha a que pertence.

**A versão do tinynet dá 0,1270 porque a primeira linha dela subtrai o maior logit de todos.** O
softmax não muda quando o mesmo número é subtraído de todos os logits, porque esse número vira um
fator `exp(-m)` em cima e embaixo da fração, e se cancela. Depois do deslocamento a maior exponencial é
`exp(0) = 1`, e nada pode estourar.

O segundo caso é o problema oposto. A rede deu a uma classe errada uma pontuação 120 acima da certa.
Depois do deslocamento, a exponencial da classe certa é `exp(-120)`, menor que o menor `float32`, então
vira 0, o log dela é menos infinito, e tanto a perda ingênua quanto a do tinynet imprimem `inf`. **O
gradiente do tinynet continua certo**: `[-1, 1, 0]` é exatamente `p` menos o alvo one-hot, então o
treinamento corrige o erro como deve. Só a perda relatada fica inútil, e a perda média de qualquer lote
que contenha essa imagem também dá `inf`.

**O log-sum-exp nunca forma a probabilidade, então nenhuma das duas falhas acontece.** Menos o log de
um softmax é o log da soma das exponenciais, menos o logit certo. Calculada depois do deslocamento, a
soma é pelo menos 1, o log dela é pelo menos 0, e a perda sai 120,0000, a resposta certa.

**É por isso que os frameworks querem logits, e não probabilidades.** A entropia cruzada do PyTorch,
que a aula 9 apresenta, recebe as pontuações cruas e faz o log-sum-exp ela mesma. Aplicar um softmax
antes e entregar o resultado a ela é um dos bugs clássicos que a aula 9 roda de propósito.
