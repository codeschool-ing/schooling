---
title: Quanto tráfego basta para julgar
version: 1
---

Mais duas rodadas, nos mesmos 10%, com cem requisições cada:

```
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 100 5001
backend    requests errors    rate
blue             92      0    0.0%
green             8      0    0.0%
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 100 6001
backend    requests errors    rate
blue             89      0    0.0%
green            11      1    9.1%
ana@laptop:~/shipquote$ sed -i 's/"blue": 90, "green": 10/"blue": 100, "green": 0/' ~/envs/routes.json
```

Na primeira, a green atendeu 8 requisições sem erro e pareceu perfeita. Na segunda atendeu 11 e
falhou uma: 9,1%, o que parece uma catástrofe. O release era o mesmo nas duas, e o bug também.
**Nenhum dos dois números diz nada**, porque nenhum se apoia em requisições suficientes.

## A conta

A green falha um pedido em vinte deste mix, uma taxa de 5%. A chance de uma requisição dar certo é
então 0,95, e a chance de *n* requisições seguidas darem todas certo é 0,95 multiplicado por ele
mesmo *n* vezes:

| requisições na green | chance de não ver erro nenhum |
| --- | --- |
| 8 | 66% |
| 20 | 36% |
| 50 | 8% |
| 102 | 0,5% |

Com oito requisições, um canário com este bug parece limpo duas vezes em três. Para ter 95% de chance
de ver ao menos um erro, a green precisa de 59 requisições, porque 0,95 elevado a 59 fica logo abaixo
de 0,05. Um bug que falha uma requisição em mil precisa de umas três mil.

## O que decorre disso

- **Espere por uma contagem, não por um relógio.** "Dez minutos a 10%" é uma quantidade diferente de
  evidência ao meio-dia e às três da manhã. O `ops/canary.py` se recusa a julgar um lado que
  respondeu menos de 50 requisições, e avisa quando segue em frente.
- **Um serviço pequeno precisa de uma parte maior, ou de uma espera mais longa.** Um canário a 1% de
  um serviço que recebe dez requisições por minuto vê uma requisição a cada dez minutos.
- **Um erro também não é veredito.** Os 9,1% acima foram uma falha só. Uma regra que para em
  qualquer erro para releases bons por azar, e é por isso que a regra do laboratório compara taxas
  quando já há respostas bastantes para comparar.

Bugs raros são os que o canário tem menos chance de pegar, e os que mais vezes chegam a todo mundo.
Isso não é motivo para pular o canário; é o motivo de a aula 11 insistir num caminho de volta rápido
para o que ele deixa passar.
