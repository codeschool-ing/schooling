---
title: Uma proporção: que parte das cobranças falha
version: 1
---

O payments é instruído a falhar a cada vigésima cobrança, com o arquivo de falhas que a aula 1 usou
para latência:

```
ana@obs:~/shop$ echo '{"fail_every": 20}' > faults/payments.json
```

Um minuto e meio depois, a taxa de respostas do payments por código de status:

```
ana@obs:~/shop$ ./promq 'sum by (code) (rate(http_server_requests_total{job="payments"}[1m]))'
code=200  4.266666666666666
code=503  0.2222222222222222
```

**Uma taxa de erros é o número errado para alertar**, e o motivo está nesta saída. 0,22 falha por
segundo é alarmante a cinco requisições por segundo e nada a cinco mil. A mesma taxa de falhas quer
dizer coisas diferentes com tráfegos diferentes. O que continua com sentido é a **fração**: falhas
divididas pelo total. O PromQL divide um vetor por outro desde que os labels casem, e dois `sum()`
sem `by` não têm label nenhum, então casam:

```
ana@obs:~/shop$ ./promq 'sum(rate(http_server_requests_total{job="payments", code=~"5.."}[1m])) / sum(rate(http_server_requests_total{job="payments"}[1m]))'
  0.049504950495049514
```

**0,0495, cerca de uma cobrança em vinte**, que é o que foi pedido. Essa forma, *eventos ruins sobre
todos os eventos, cada um um `sum(rate(...))` na mesma janela*, é a expressão mais usada neste
curso. A aula 15 a chama de SLI e constrói sobre ela o objetivo de disponibilidade da loja, e o
alerta no fim desta aula dispara sobre ela.

Dois detalhes a tornam confiável. As duas metades usam **a mesma janela**, aqui um minuto, senão a
proporção compara dois períodos diferentes. E o código é casado com `=~"5.."`, todo erro de
servidor, não `="503"`. O alerta não deve depender de qual erro de servidor a próxima falha calhar
de devolver.
