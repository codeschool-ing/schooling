---
title: Um número ou vários
version: 2
---

Com quatro tipos de métrica na mesa, a tentação é combiná-las: tanto para formato, tanto para
acurácia, um pouco para tom, uma nota só para comparar versões. **Uma nota ponderada única deixa uma
métrica esconder outra**, e dois prompts que já estão no disco mostram como. Aqui está o
`v3-examples.txt` sobre as mesmas setenta mensagens:

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3-all.jsonl
70 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3-all.jsonl
ana@lab:~/triage$ pl check runs/v3-all.jsonl
check      pass  fail
json         69     1
fields       69     1
labels       69     1
category     53    17
urgency      42    28
all          42    28
ana@lab:~/triage$ python3 confusion.py runs/v3-all.jsonl
expected    billing delivery  returns  account    other    (bad)   recall
billing          10        0        1        4        1        0     0.62
delivery          0       11        2        0        0        1     0.79
returns           2        2       12        0        0        0     0.75
account           1        1        0       10        2        0     0.71
other             0        0        0        0       10        0     1.00
precision      0.77     0.79     0.80     0.71     0.77

accuracy 53/70 = 0.76
```

Por todos os totais, o `v3` é o prompt melhor: 53 categorias certas contra 45, 42 respostas
aprovadas em todas as verificações contra as 26 do `v6` na aula 7, os mesmos 69 de 70 em formato.
Qualquer nota construída com isso o escolheria, e na maior parte da matriz ele merece vencer:
revocação de billing de 0,25 para 0,62, precisão de returns de 0,48 para 0,80.

Uma célula foi para o outro lado. **A precisão de billing caiu de 1,00 para 0,77**: o `v3` manda à
equipe de cobrança treze chamados, três dos quais não são dela, onde o `v6` mandava quatro e os
quatro eram. Se a equipe de cobrança trabalha a fila à mão, é um preço justo por seis mensagens de
cobrança a mais chegando até ela. Se alguma coisa age automaticamente a partir do rótulo billing, um
formulário de reembolso, um estorno, os três são o número que importa e os totais não. **Nenhuma das
escolhas está errada; escondê-la dentro de um número só está.**

## Lado a lado, com travas

Relate as métricas uma ao lado da outra, sempre as mesmas:

- formato, como uma taxa própria;
- acurácia, e revocação e precisão para os rótulos de que alguém depende;
- as células caras pelo nome, como urgência alta classificada como normal;
- falhas das regras de tom, e as contagens de segurança nas duas direções.

Onde uma métrica não pode piorar, faça dela uma **trava** em vez de um peso: uma versão que
classifica mais uma mensagem urgente como normal é recusada, aconteça o que acontecer com a
acurácia. Uma trava é um limite numa métrica só, então não pode ser recomprada por um ganho em outro
lugar. A aula 14 guarda esses números ao lado de cada versão do prompt, para que uma mudança seja
julgada contra todos eles de uma vez.
