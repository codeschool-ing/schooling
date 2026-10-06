---
title: Um modelo menor
version: 1
---

O labllm tem dois modelos, e o segundo, `scripted-mini`, escreve quatro vezes mais rápido: 10 ms por token em vez de 40. A mesma execução, sem mais nenhuma mudança:

```
ana@lab:~/agents$ python cost_run.py scripted-mini
step   input  c.write  c.read  output     ms  stop
   1    2359        0       0      10    335  tool_use
       tool get_order: 1 ms
   2    2520        0       0       8    330  tool_use
       tool search_help: 317 ms
   3    2561        0       0      75    957  end_turn
total    7440        0       0      93   1939
```

**1.939 ms em vez de 4.768.** Os tokens são idênticos, porque o mesmo texto entrou e a mesma resposta, escrita pelo curso, saiu; a diferença está toda na escrita. O pedido da resposta caiu de 3.208 ms para 957.

Com fornecedores de verdade, o modelo menor de uma família é mais rápido e mais barato por token, e menos capaz. Quais tarefas ele aguenta é uma pergunta a responder testando, não supondo, e o padrão de roteamento da aula 2 é onde a resposta rende: mande as perguntas fáceis (*onde está meu pedido?*) para o modelo pequeno e as difíceis para o grande, e decida qual é qual com algo barato. Um roteador que manda noventa por cento do tráfego para um modelo quatro vezes mais rápido deixou o agente mais rápido para noventa por cento dos clientes.

O que um modelo menor não muda é a forma da conta. Ele ainda lê 7.440 tokens para escrever 93. Essa parte é o assunto da próxima seção.
