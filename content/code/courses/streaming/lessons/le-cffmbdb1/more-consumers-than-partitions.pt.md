---
title: Mais consumidores que partições
version: 1
---

**Uma partição é lida por no máximo um membro de um grupo, então um grupo com mais membros que
partições tem membros sem nada para fazer.** É a surpresa mais comum quando alguém escala um
consumidor: o tópico tem três partições, o programa está lento, alguém roda dez cópias, e sete delas
ficam paradas enquanto as outras três continuam tão lentas quanto antes.

O grupo `shelf` de duas seções atrás tinha quatro membros num tópico de três partições. Perguntado com
os quatro rodando:

@@fence@@

`#PARTITIONS` é 1, 1, 1 e 0. E isto é o que o quarto membro, o `d`, imprimiu entre iniciar e ser
parado, enquanto chegavam dez vendas:

@@fence@@

O `d` entrou, recebeu uma lista vazia, e nunca leu uma mensagem. Ele não estava quebrado; era membro
do grupo, e contava em todo rebalanceamento. **Um membro sem partições é uma reserva**: se um dos
outros três sair, o próximo rebalanceamento pode dar a partição dele ao `d`, e o grupo continua com
três leitores sem ninguém iniciar um.

## Saídas

Só existem três, e vale conhecê-las antes de iniciar a quarta cópia:

| | o que faz | o que custa |
|---|---|---|
| mais partições | deixa mais membros lerem ao mesmo tempo | move chaves, como a lição 3 mostrou; melhor decidir quando o tópico é criado |
| membros mais rápidos | mais trabalho por membro: escritas em lote no destino, menos chamadas por mensagem | tempo de engenharia |
| trabalho dentro de um membro | um consumidor entrega as mensagens a um pool de threads | a ordem por chave só vale se cada chave sempre for para a mesma thread |

A última é como alguns sistemas passam do número de partições, e exige cuidado: duas mensagens do
Recife tratadas por duas threads ao mesmo tempo podem terminar em qualquer ordem, o que desfaz
justamente o que a partição estava mantendo. O número de partições é um teto de leitores em paralelo
**do log**; o que um leitor faz com cada mensagem é problema dele, e risco dele.
