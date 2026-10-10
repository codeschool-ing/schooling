---
title: Uma perda é um número só
version: 1
---

Dez erros são dez números, e dez números não dizem se `w = 3` é melhor que `w = 2`: uns podem
diminuir enquanto outros crescem. **O treino precisa de um número que caia quando as previsões
melhoram.** Esse número é a **perda** (*loss*). A primeira a conhecer é o **erro quadrático médio**:
eleve cada erro ao quadrado e tire a média.

O quadrado faz dois serviços. Faz todo erro contar como uma quantidade positiva, então uma previsão
1,03 alta demais e outra 1,03 baixa demais não se cancelam numa nota perfeita. E faz um erro grande
contar muito mais que um pequeno: um erro de 2 custa quatro vezes o que custa um erro de 1. A aula 4
mostra quando esse segundo serviço é o que você não quer.

À mão, em `w = 2`, com os erros que o `forward.py` imprimiu: o primeiro é -1,03 e o quadrado dele é
1,0609. Eleve os dez ao quadrado, some, divida por dez. Salve como `~/dl/loss.py`, que faz essa soma
primeiro e depois calcula a perda em seis pesos:

```python
# loss.py: mean squared error, one number for how wrong a weight is
import numpy as np

from points import x, y


def loss(w):
    return np.mean((w * x - y) ** 2)


errors = 2 * x - y
print("squared errors at w = 2:", (errors ** 2).round(4))
print(f"sum {np.sum(errors ** 2):.4f}   mean {np.mean(errors ** 2):.4f}")
for w in [0, 1, 2, 3, 4, 5]:
    print(f"w {w}   loss {loss(w):.4f}")
```

```
ana@vm:~/dl$ python loss.py
squared errors at w = 2: [1.0609 0.9409 1.2769 1.0404 0.7921 1.1449 1.5876 1.4161 0.7396 0.5625]
sum 10.5619   mean 1.0562
w 0   loss 4.7918
w 1   loss 2.5390
w 2   loss 1.0562
w 3   loss 0.3434
w 4   loss 0.4006
w 5   loss 1.2278
```

Os quadrados somam 10,5619 e a média deles é 1,0562, que é a perda em `w = 2` na terceira linha da
tabela. **Descendo a tabela, a perda cai de 4,7918 em `w = 0`, chega ao ponto mais baixo entre 3 e
4 e volta a subir.** 0,3434 em 3 contra 0,4006 em 4 põe o melhor peso entre os dois, mais perto
de 3.

**Para este modelo, a curva é uma parábola.** Cada ponto contribui com `(w*x - y)²`, que é uma
função do segundo grau em `w`, e uma soma de funções do segundo grau é uma só. A próxima seção a
desenha. A perda de uma rede tem uma dimensão por peso e mais de um vale, mas a pergunta que se faz
a ela é a mesma: onde ela é mais baixa?

Seis tentativas estreitaram a resposta a um intervalo de uma unidade, e mais tentativas o
estreitariam mais. É um bom jeito de procurar um peso e um jeito sem esperança de procurar muitos.
Dez valores candidatos para cada um dos 1.040 parâmetros da camada da aula 1 dão 10 elevado a 1.040
avaliações. O que falta é uma direção, não uma grade.
