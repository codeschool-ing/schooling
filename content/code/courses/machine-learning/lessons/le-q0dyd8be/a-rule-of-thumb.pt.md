---
title: A regra que uma pessoa escreveria
version: 1
---

Uma constante é o piso. A barra que um modelo tem de passar para valer a construção é mais alta: **a
melhor regra que alguém que conhece o negócio escreveria numa linha.** Se um assinante que pula três
caixas num trimestre tem muita chance de sair, a equipe de retenção não precisa de modelo, precisa
dessa frase.

O primeiro passo é olhar uma coluna contra o alvo, só nos meses de treino. Depois, escrever algumas
regras candidatas, medir cada uma nos meses de treino, ficar com a melhor, e só então olhar o teste.
Salve isto como `rule.py`:

```python
# rule.py
from feira import by_time, load_churn, net_value

train, test = by_time(load_churn())

RULES = {
    "skips_90d >= 3": lambda d: d["skips_90d"] >= 3,
    "complaints_90d >= 2": lambda d: d["complaints_90d"] >= 2,
    "rating_90d < 3.6": lambda d: d["rating_90d"] < 3.6,
    "skips >= 3 and complaints >= 1": lambda d: (d["skips_90d"] >= 3) & (d["complaints_90d"] >= 1),
    "tenure_months <= 2": lambda d: d["tenure_months"] <= 2,
}
print("on the months it may learn from:")
for name, rule in RULES.items():
    send = rule(train)
    print(f"  {name:32} {send.sum():5,} credits  R$ {net_value(train['churned'], send):>8,.0f}")

best = max(RULES, key=lambda name: net_value(train["churned"], RULES[name](train)))
send = RULES[best](test)
print(f"best rule: {best}")
print(f"on the test months: {send.sum():,} credits, "
      f"{(send & (test['churned'] == 1)).sum()} to leavers, "
      f"net value R$ {net_value(test['churned'], send):,.0f}")
```

```
ana@lab:~/ml$ python rule.py
on the months it may learn from:
  skips_90d >= 3                   2,355 credits  R$  -32,280
  complaints_90d >= 2              1,848 credits  R$  -33,024
  rating_90d < 3.6                 3,172 credits  R$   -2,896
  skips >= 3 and complaints >= 1     468 credits  R$    2,448
  tenure_months <= 2               5,852 credits  R$ -166,400
best rule: skips >= 3 and complaints >= 1
on the test months: 270 credits, 71 to leavers, net value R$ -576
```

Quatro das cinco regras **perdem dinheiro nos próprios meses em que foram escolhidas**. Cada uma
separa pessoas que saem mais que a média, e isso não basta: um crédito só se paga quando mais de 40 ÷
144, uns 28%, de quem o recebe estava para sair. `skips_90d >= 3` acha um grupo cuja taxa é várias
vezes a média e ainda manda a maior parte dos créditos para quem ia ficar.

A única regra que deu um pouco de dinheiro nos meses de treino, **R$ 2.448**, combina duas condições
e manda só 468 créditos. Nos seis meses que nunca viu, ela manda 270 e perde **R$ 576**. Essa é a
regra que uma pessoa teria escrito, escolhida com honestidade, e ela não vale nada.

Duas coisas a levar disso, e as duas duram além desta aula:

- **Uma regra escolhida nos dados está ajustada a eles.** A melhor de cinco é em parte a melhor e em
  parte a mais sortuda, e a sorte não viaja. O mesmo acontece com um modelo de mil parâmetros, só
  que mais, e a aula 3 é como mantê-lo honesto.
- **A barra agora está clara.** *Não mandar a ninguém* é R$ 0, e a melhor regra que alguém escreveu é
  mais ou menos R$ 0. Tudo o que um modelo ganhar nos meses de teste é dinheiro que uma frase não
  achou.
