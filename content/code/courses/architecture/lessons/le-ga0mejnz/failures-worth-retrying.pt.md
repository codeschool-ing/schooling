---
title: Que falhas merecem uma segunda tentativa
version: 1
---

A maioria das falhas entre serviços é **transitória**: uma conexão derrubada por um balanceador de carga
que estava sendo trocado, um serviço que respondeu `503` enquanto reiniciava, um banco que recusou uma
conexão durante um failover de poucos segundos. Tentar de novo um instante depois costuma funcionar, e
um retry é o jeito mais barato de escondê-las de quem está esperando.

Algumas falhas são **permanentes** para aquela requisição: a requisição está malformada, o pedido não
existe, o cliente não pode vê-lo. Tentar de novo recebe a mesma resposta, e toda tentativa custa alguma
coisa ao serviço. O código de status diz qual é qual, e é a primeira coisa que uma política de retry lê:

| resposta | tentar de novo? | por quê |
| --- | --- | --- |
| conexão recusada ou derrubada, falha de DNS | sim | o outro lado não estava lá por um momento |
| timeout | sim, se a operação for idempotente | a requisição pode ter sido feita; veja abaixo |
| `503 Service Unavailable` | sim | o próprio serviço diz isso, às vezes com `Retry-After` |
| `429 Too Many Requests` | sim, depois do `Retry-After` que ele dá | ele pediu para você ir mais devagar; a aula 12 é sobre dizer isso |
| `500 Internal Server Error` | talvez, uma vez | pode ser um defeito que falha toda vez |
| `400`, `401`, `403`, `404`, `409`, `422` | não | a mesma requisição vai receber a mesma resposta |

## Um timeout não é uma falha, é uma incógnita

A linha que pede cuidado é o timeout. Quando uma chamada dá timeout, **quem chamou não sabe se ela
aconteceu**: a requisição pode nunca ter chegado, pode ainda estar rodando, ou pode ter terminado um
milissegundo depois de quem chamou parar de ouvir. Tentar de novo uma leitura é inofensivo. Tentar de
novo "cobre este cartão" pode cobrá-lo duas vezes.

A aula 7 é a resposta, e vale para todo retry, não só para mensagens: **uma operação que vai ser tentada
de novo tem de ser idempotente**, seja por natureza ("defina o estoque como 12"), seja com uma chave de
idempotência que quem chama manda de novo em cada tentativa, para o serviço reconhecer a repetição. Uma
política de retry numa chamada que não é idempotente é uma política de cobrança dupla que ainda não
aconteceu.

E depois que a última tentativa falha, quem chamou ainda tem de fazer alguma coisa: mostrar um erro sobre
o qual a pessoa consiga agir, usar uma alternativa como um valor em cache, ou pôr o trabalho numa fila
para ser feito depois. "Tentar de novo" nunca é o plano inteiro; é a primeira linha de um.
