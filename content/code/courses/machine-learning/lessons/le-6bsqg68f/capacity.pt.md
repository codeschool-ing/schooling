---
title: Quando a equipe só consegue fazer tantas ligações
version: 1
---

Até aqui um crédito podia ser mandado em qualquer quantidade: um e-mail com um código. Mude um fato.
**A equipe de retenção decide que o crédito funciona melhor oferecido por telefone**, e tem gente para
150 ligações por mês. Agora a pergunta não é "quem está acima do corte", e sim "quem são os 150 que
mais valem a ligação", e um corte que escolhe 400 pessoas num mês e 90 no seguinte não serve a quem
monta escalas.

**Um orçamento transforma o corte numa contagem.** Ordene os assinantes de cada mês pela chance e pegue
o topo da lista. Salve isto como `capacity.py`:

```python
# capacity.py
import pandas as pd

from feira import net_value

scores = pd.read_csv("scores.csv")
rank = scores.groupby("snapshot")["chance"].rank(ascending=False, method="first")
print("calls a month   sent   precision   net value")
for calls in [50, 100, 150, 200, 300]:
    send = rank <= calls
    print(f"{calls:13}  {send.sum():5,}  {scores.loc[send, 'churned'].mean():9.3f}"
          f"   R$ {net_value(scores['churned'], send):8,.0f}")
```

`method="first"` desempata pela ordem em que aparecem, para todo mês receber exatamente o número
pedido. Aqui toda ligação ainda custa R$ 40 e vale R$ 144 quando chega a alguém que sai; numa campanha
de telefone de verdade os dois números seriam outros, e o enquadramento é onde eles ficam escritos.

```
ana@lab:~/ml$ python capacity.py
calls a month   sent   precision   net value
           50    300      0.607   R$   14,208
          100    600      0.505   R$   19,632
          150    900      0.460   R$   23,616
          200  1,200      0.415   R$   23,712
          300  1,800      0.342   R$   16,560
```

**Com 150 ligações por mês a lista faz R$ 23.616**, mais do que o corte de equilíbrio, e por um motivo
que vale ver. Uma contagem por mês é imune ao problema de setembro: quando o risco subiu para todos, o
corte deixou passar menos gente do que devia, enquanto os 150 de cima são os 150 de cima seja qual for
o nível das chances. **Uma lista usa só a ordenação, e a ordenação é o que sobreviveu.**

A precisão cai conforme a lista cresce, de 0,607 com 50 ligações para 0,342 com 300. Cada ligação a
mais alcança alguém menos propenso a sair que a anterior, e a lista para de se pagar onde a parte de
quem sai entre as ligações a mais cai abaixo de 0,278: a linha de equilíbrio de novo, em outra forma.
Entre 150 e 200 ligações o dinheiro quase não se mexe, e em 300 já perdeu mais de R$ 7.000. Então os 150
da equipe são um tamanho sensato, e a tabela é o argumento a levar se alguém propuser contratar para
300.

Duas consequências para como julgar um modelo que vai ser usado assim:

- **A calibração deixa de importar para quem recebe a ligação.** Só a ordem é usada. Um modelo com
  chances distorcidas e uma boa ordenação serve tanto quanto um calibrado.
- **A métrica para comparar modelos é o valor do topo da lista**: a precisão entre os 150 primeiros de
  cada mês, ou o dinheiro que eles fazem. A precisão média da aula 10 pesa a curva inteira, e aqui só
  contam as primeiras centenas de lugares.
