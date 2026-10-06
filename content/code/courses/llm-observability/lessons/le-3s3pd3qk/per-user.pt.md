---
title: Custo por usuário
version: 1
---

A mesma conta, pelo pseudônimo que a aula 2 pôs em todo span raiz:

```
ana@lab:~/obs$ python bill.py --by user --top 6
user               requests    input  output  cost US$  per 1k  share  features
a1461432bd4296ff         51     3807    2583    0.0251    0.49   3.0%  summary
3bfa9e105a50c997         38     2812    1919    0.0185    0.49   2.2%  summary
3baf8d13359269fa         35     2469    1740    0.0166    0.47   2.0%  summary
6a49ed68660c8f52         23     4583     752    0.0132    0.58   1.6%  help/order
d36cba1f26b7cec0         21     4611     731    0.0132    0.63   1.6%  help/order
78ec3ac003d867c4         23     4342     554    0.0126    0.55   1.5%  help/order
total                  1345   281072   46663    0.8228    0.61
```

**Os três usuários que mais gastam não são clientes.** A única funcionalidade deles é `summary`: são a
equipe de atendimento, três pessoas resumindo conversas a semana inteira, 124 pedidos entre elas. O
pseudônimo esconde quem são, que é o trabalho dele, e a coluna de funcionalidades diz o que são, o que
basta. Uma visão de custo por usuário que não mostrasse também o que cada um fez teria mandado alguém
investigar três clientes que não existem.

Depois deles, os clientes. Nenhum cliente chega a 2% da semana, e os seis usuários que mais gastam,
equipe incluída, somam 11,9%. É uma curva achatada, e é uma propriedade do tráfego simulado, que
sorteia um usuário para cada pedido. O uso real raramente é achatado. Um punhado de usuários, ou uma
integração que alguém escreveu contra a API, costuma ser uma parte visível da conta, e esse é o motivo
de olhar por usuário:

- **uma conta usando muito mais que qualquer outra** é ou o melhor cliente ou alguém automatizando o
  assistente, e a diferença importa;
- **um limite por usuário** (a última seção) precisa primeiro do número por usuário;
- **um ponto fora da curva em custo costuma ser um ponto fora da curva em comportamento**: a mesma
  pergunta feita quarenta vezes, uma conversa que nunca termina, um prompt que alguém está sondando.

## Por que um pseudônimo basta

Nada disso precisou da identidade do usuário. A contagem funciona com qualquer valor estável, que é o
que o HMAC da aula 2 fornece. Quando o número numa linha precisa mesmo de uma pessoa, um caso de
atendimento ou uma conta a suspender, quem tem a chave resolve aquela linha, e ninguém mais precisa ver
o resto.
