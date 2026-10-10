---
title: O que funcionou, lado a lado
version: 1
---

Cada seção mediu uma cura contra a execução do `overfit.py`, mas com um laço diferente, então os números
não são bem comparáveis. Este programa roda todas pelo mesmo laço, acrescenta um controle que só muda a
semente, e depois junta as quatro curas. Salve como `~/dl/compare.py`:

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "\"\"\"compare: every cure on the same 100 images, alone and together, and then more data.\"\"\"\nimport small\nfrom decay import SGDDecay\nfrom dropout import wide_dropout\nfrom fit import evaluate, fit\nfrom shift import shifted",
      "note": "Os arquivos desta própria aula, importados. O `if __name__ == \"__main__\":` em cada um é o que impede que os experimentos deles rodem de novo aqui."
    },
    {
      "code": "def run(net, decay=0.0, shift=False, early=False, seed=0, n=100):\n    \"\"\"300 epochs of SGD at 0.2; the final weights, or the best epoch's with early stopping.\"\"\"\n    train, val = small.data(n)\n    if shift:\n        train = shifted(*train)\n    opt = SGDDecay(net.params(), lr=0.2, decay=decay)\n    best_loss, best_epoch = float(\"inf\"), 0\n    for epoch in range(1, 301):\n        loss = fit(net, opt, train, val, epochs=1, seed=seed * 1000 + epoch, every=2)[0][2]\n        if loss < best_loss:\n            best_loss, best_epoch = loss, epoch\n            best = [p.copy() for p, _ in net.params()]\n        elif early and epoch - best_epoch == 20:\n            break\n    if early:\n        for (p, _), saved in zip(net.params(), best):\n            p[...] = saved\n        epoch = best_epoch\n    return epoch, *evaluate(net, *val)",
      "note": "Uma função para toda execução: SGD com decaimento opcional, um conjunto de treino opcionalmente cinco vezes maior, e o laço da melhor época do `early.py`, que só para e restaura quando `early` está ligado. Sem ele, a execução vai às 300 épocas e guarda os últimos pesos."
    },
    {
      "code": "runs = [\n    (\"nothing\", lambda: run(small.wide())),\n    (\"nothing, seed 1\", lambda: run(small.wide(seed=1), seed=1)),\n    (\"weight decay 0.001\", lambda: run(small.wide(), decay=0.001)),\n    (\"dropout 0.5\", lambda: run(wide_dropout(0.5))),\n    (\"early stopping\", lambda: run(small.wide(), early=True)),\n    (\"shifted images\", lambda: run(small.wide(), shift=True)),\n    (\"all four\", lambda: run(wide_dropout(0.5), decay=0.001, shift=True, early=True)),\n    (\"all 1,077 images\", lambda: run(small.wide(), n=1077)),\n]\nprint(f\"{'':20s} {'epoch':>5s} {'val loss':>9s} {'val acc':>8s}\")\nfor name, go in runs:\n    epoch, loss, acc = go()\n    print(f\"{name:20s} {epoch:5d} {loss:9.4f} {acc:8.3f}\", flush=True)",
      "note": "Oito execuções. A segunda só muda a semente, que fixa os pesos iniciais e a ordem dos lotes: ela mede quanto o acaso sozinho move esses números. A última não usa cura nenhuma e usa o conjunto de treino inteiro do `digits.py`, dez vezes mais imagens."
    }
  ]
}
```

```
PENDING compare
```

**Leia o controle primeiro.** Mudar só a semente moveu a acurácia de 0,900 para 0,908 e a perda de 0,3305
para 0,3112. Uma cura sozinha que mova os números menos que isso não mostrou que fez alguma coisa, porque
o acaso sozinho os move até ali. A aula 18 mede essa dispersão em cinco sementes, e é esse o hábito que
esta tabela pede.

| execução | o que mudou | contra `nothing` |
| --- | --- | --- |
| weight decay 0.001 | pesos puxados para zero | perda 0,3006 e acurácia 0,906, as duas dentro do que a semente move |
| dropout 0.5 | metade das unidades ocultas desligada a cada passo | acurácia 0,919, mas perda subindo para 0,3766 |
| early stopping | os pesos da época 33 | perda 0,2926 e acurácia 0,911, em 53 épocas |
| shifted images | cinco vezes mais imagens de treino | acurácia 0,933, a melhor sozinha, com perda 0,3441 |
| all four | tudo isso junto | **perda 0,2439 e acurácia 0,944**, guardada da época 53 |

**Juntas elas fizeram o que nenhuma fez sozinha.** A combinação tem a menor perda e a maior acurácia da
tabela, 0,944 contra 0,900, que são 16 imagens a mais em 360 e quatro vezes o que a semente moveu. As
curas agem em coisas diferentes: o aumento dá mais exemplos, o dropout e o decaimento deixam a rede menos
capaz de decorá-los, e a parada antecipada guarda o momento antes de a confiança crescer.

**O que não se transfere é a ordem.** Neste problema, com 100 imagens, o aumento fez mais e o decaimento
menos. Com um milhão de imagens, outra rede ou outra taxa de aprendizado, a ordem pode mudar, e os valores
escolhidos aqui, 0.001, 0.5 e paciência 20, foram testados, não sabidos. O que se transfere é o método: uma
linha de base, uma mudança por vez, um controle para o acaso, e o conjunto de validação como juiz.

**E a cura mais forte não está na tabela:** mais dados de verdade. Com todas as 1.077 imagens de treino,
toda aula até aqui chegou a uma acurácia de validação bem acima de tudo isto, sem cura nenhuma. Cada
técnica desta aula é um jeito de fazer com menos dados o que mais dados fazem sozinhos.
