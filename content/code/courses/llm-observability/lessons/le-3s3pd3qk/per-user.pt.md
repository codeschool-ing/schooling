---
title: Custo por usuário
version: 2
---

A mesma conta, pelo pseudônimo que a aula 2 pôs em todo span raiz:

```
ana@dev:~/obs$ python bill.py --by user --top 6
user               requests    input  output  cost US$  per 1k  share  features
f71cf97066359de1         14     1256     589    0.0061    0.43   4.2%  summary
1c6130a39563f0ad         13     1281     573    0.0058    0.44   4.0%  summary
e01da6591c8e42f4         10     1896     371    0.0054    0.54   3.7%  help/order
71a47489cab1d256          9     1826     301    0.0050    0.56   3.5%  help/order
2b86d5011760317d         11     1739     271    0.0049    0.44   3.4%  help/order
91aa3bdfe71fb999          7     1453     222    0.0045    0.65   3.2%  help/order
total                   311    53240    8005    0.1434    0.46
```

**Os dois usuários que mais gastam não são clientes.** A única funcionalidade deles é `summary`: são
duas das três pessoas da equipe de atendimento, resumindo conversas a semana inteira, 36 pedidos
entre as três. O pseudônimo esconde quem são, que é o trabalho dele, e a coluna de funcionalidades
diz o que são, o que basta. Uma visão de custo por usuário que não mostrasse também o que cada um
fez teria mandado alguém investigar dois clientes que não existem.

Depois deles, os clientes. Nenhum cliente chega a 4% da semana, e os seis usuários que mais gastam,
equipe incluída, somam 22%. É uma curva achatada, e é uma propriedade do tráfego simulado, que
sorteia um usuário para cada pedido. O uso real raramente é achatado. Um punhado de usuários, ou uma
integração que alguém escreveu contra a API, costuma ser uma parte visível da conta, e esse é o
motivo de olhar por usuário:

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
