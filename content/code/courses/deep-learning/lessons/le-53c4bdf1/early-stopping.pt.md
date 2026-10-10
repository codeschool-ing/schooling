---
title: Parada antecipada, guardando os melhores pesos
version: 1
---

A cura mais barata não precisa de camada nova nem de termo novo na perda. O `overfit.py` já a imprimiu:
a perda de validação foi mínima na época 40, e cada época depois disso deixou a rede pior naquilo para
que ela serve. **A parada antecipada guarda os pesos da melhor época e para o treino quando fica claro
que o melhor já passou.**

As duas metades importam, e a segunda é a que as pessoas esquecem. Parar quando a perda não melhora há
algum tempo encerra a execução tarde, por definição, depois que esse "algum tempo" passou. Se você
guardar a rede como está, guarda os pesos dessas últimas épocas piores. Os melhores precisam ser salvos
quando acontecem, como cópia, e postos de volta no fim.

Salve como `~/dl/early.py`:

```schooling-example
{
  "language": "python",
  "file": "early.py",
  "parts": [
    {
      "code": "\"\"\"early: one epoch at a time, keeping the weights of the best one.\"\"\"\nimport small\nfrom fit import evaluate, fit\nfrom optim import SGD\n\ntrain, val = small.data()\nnet = small.wide()\nopt = SGD(net.params(), lr=0.2)\nbest_loss, best_epoch, patience = float(\"inf\"), 0, 20",
      "note": "A mesma rede, os mesmos dados e o mesmo otimizador do `overfit.py`. `patience` é quantas épocas sem um novo melhor o laço aceita esperar."
    },
    {
      "code": "for epoch in range(1, 301):\n    _, _, loss, acc = fit(net, opt, train, val, epochs=1, seed=epoch, every=2)[0]\n    if loss < best_loss:\n        best_loss, best_epoch = loss, epoch\n        best = [p.copy() for p, _ in net.params()]\n    elif epoch - best_epoch == patience:\n        print(f\"stopped at epoch {epoch}: no improvement for {patience} epochs\")\n        break\nprint(f\"last epoch {epoch}  val loss {loss:.4f}  val acc {acc:.3f}\")",
      "note": "O `fit` uma época por vez, cada uma com sua semente de embaralhamento, para o laço olhar a perda de validação depois de cada época. O histórico tem uma linha, e o terceiro e o quarto campos são a perda e a acurácia de validação. `every=2` numa execução de uma época não imprime nada. Um novo melhor é copiado, porque `net.params()` devolve os próprios arrays que o otimizador continua mudando."
    },
    {
      "code": "for (p, _), saved in zip(net.params(), best):\n    p[...] = saved\nloss, acc = evaluate(net, *val)\nprint(f\"best epoch {best_epoch}  val loss {loss:.4f}  val acc {acc:.3f}\")",
      "note": "Parar é metade. A outra metade devolve os arrays salvos, no lugar, para que a rede que você guarda seja a da melhor época e não a da última."
    }
  ]
}
```

```
PENDING early
```

A execução treina época por época com suas próprias sementes de embaralhamento, então suas épocas não são
as mesmas do `overfit.py`, e a menor perda veio na época 33 em vez da 40. Ela esperou as 20 épocas de
paciência e parou na 53, onde a perda de validação era 0,2996. Devolver os pesos salvos dá 0,2926, com
acurácia 0,911, contra 0,3281 e 0,903 da rede que treinou as 300 épocas. E levou 53 épocas de trabalho em
vez de 300.

**A paciência é uma troca.** A perda de validação é ruidosa de uma época para a outra, então uma paciência
de 1 para na primeira época de azar; uma paciência de 100 aqui teria ido até o fim. Vinte é uma primeira
escolha comum para uma execução de algumas centenas de épocas.

**A cópia é a linha fácil de errar.** `best = [p for p, _ in net.params()]` sem `.copy()` guarda
referências aos próprios arrays que o otimizador continua mudando, então no fim "os melhores pesos" são os
últimos e a restauração não faz nada, em silêncio. Os números então bateriam exatamente com os da última
época, e é assim que se percebe.

A parada antecipada usa o conjunto de validação para escolher quando parar, então é mais uma decisão
ajustada àquelas 360 imagens. O conjunto de teste que o `digits.py` separou na aula 1 continua intocado, e
é ele que mede a rede que você finalmente guarda.
