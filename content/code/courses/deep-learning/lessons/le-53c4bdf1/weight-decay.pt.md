---
title: Decaimento de pesos, uma penalidade L2 no passo
version: 1
---

Uma rede que decorou o conjunto de treino em geral fez isso com pesos grandes: um peso grande faz uma
saída balançar muito com uma pequena mudança num pixel, e é isso que é preciso para dar a cada uma de 100
imagens a sua própria resposta. **O decaimento de pesos faz o próprio tamanho custar alguma coisa.** Ele
soma à perda uma penalidade para cada peso, proporcional ao seu quadrado:

`loss + decay / 2 × (sum of every weight squared)`

Você nunca calcula essa soma durante o treino. O gradiente dela em relação a um peso `w` é `decay × w`,
então a penalidade só soma `decay × w` a cada gradiente, e cada passo puxa cada peso um pouco para zero,
além do que os dados pedirem. O nome *L2* vem do tamanho ao quadrado dos pesos, e *decaimento* vem do que
esse puxão faz com um peso que os dados deixam de defender.

É uma mudança no otimizador, três linhas numa subclasse do `SGD` da aula 5. Salve como `~/dl/decay.py`:

```schooling-example
{
  "language": "python",
  "file": "decay.py",
  "parts": [
    {
      "code": "\"\"\"decay: SGD with weight decay, the L2 penalty folded into the step.\"\"\"\nfrom optim import SGD",
      "note": "Parte do `SGD` do `optim.py` da aula 5 e muda um método."
    },
    {
      "code": "class SGDDecay(SGD):\n    def __init__(self, params, lr, decay):\n        super().__init__(params, lr)\n        self.decay = decay\n\n    def step(self):\n        for p, g in self.params:\n            if p.ndim == 2:\n                g += self.decay * p\n            p -= self.lr * g",
      "note": "A penalidade `decay / 2 × w²` somada à perda tem gradiente `decay × w`, então somá-lo ao gradiente é a mudança inteira. `p.ndim == 2` separa as matrizes de pesos e deixa os vieses em paz: um viés desloca uma unidade e não deixa a rede mais flexível. `g += …` escreve no próprio array do gradiente, que o próximo backward sobrescreve de qualquer jeito."
    },
    {
      "code": "if __name__ == \"__main__\":\n    import small\n    from fit import evaluate, fit\n\n    train, val = small.data()\n    for decay in (0.0, 0.001, 0.01, 0.1):\n        net = small.wide()\n        fit(net, SGDDecay(net.params(), lr=0.2, decay=decay), train, val, epochs=300, every=1000)\n        weights = sum(float((p ** 2).sum()) for p, _ in net.params() if p.ndim == 2)\n        loss, acc = evaluate(net, *val)\n        print(f\"decay {decay:<6}  val loss {loss:.4f}  val acc {acc:.3f}  \"\n              f\"sum of squared weights {weights:7.1f}\")",
      "note": "Quatro execuções que só diferem no `decay`, cada uma numa rede nova com a mesma semente. `every=1000` deixa o `fit` calado, e a última coluna mede o tamanho final dos pesos."
    }
  ]
}
```

```
PENDING decay
```

**A última coluna é o mecanismo, medido.** Sem decaimento, os pesos ao quadrado somam 2122,6; com 0,001
chegam a 1335,8, com 0,01 a 88,5, e com 0,1 a 16,5.

A primeira coluna diz se ajudou. Com 0,001 a perda de validação termina em 0,2975 em vez de 0,3281, quase
tão baixa quanto a melhor época do `overfit.py`, enquanto a acurácia vai de 0,903 para 0,897, duas
imagens em 360. Com 0,01 o puxão é forte o bastante para atrapalhar: perda 0,4468, acurácia 0,869. Com 0,1
a rede já não consegue ajustar nem o próprio conjunto de treino, e a acurácia cai para 0,386.

**O decaimento é um botão com um precipício de um lado.** Pouco não faz nada e demais para o aprendizado,
e o valor certo depende da rede, dos dados e da taxa de aprendizado; por isso ele é achado testando alguns
valores no conjunto de validação, como aqui. Valores entre 0,0001 e 0,01 são onde a maioria das buscas
começa.

Um detalhe para quando você o encontrar num framework. Somar `decay × w` ao gradiente é o mesmo que uma
penalidade L2 para o SGD simples, mas não para o Adam, cuja escala por parâmetro, da aula 5, reescala a
penalidade também. O `AdamW` do PyTorch aplica o decaimento direto nos pesos, fora dessa escala, e é a
versão a usar com Adam.
