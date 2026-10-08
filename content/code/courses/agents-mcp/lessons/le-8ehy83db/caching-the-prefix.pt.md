---
title: Pondo o prefixo em cache
version: 2
---

A maior parte de cada pedido era texto que o modelo tinha acabado de ler. Os fornecedores hospedados oferecem **cache de prompt** exatamente para isso: marque o fim de um prefixo que não muda (`cache_control` na API da Anthropic), e o fornecedor o guarda por pouco tempo, de modo que os pedidos seguintes que começam pelo mesmo prefixo o leem do cache. Leituras do cache são cobradas bem abaixo da entrada comum, e a primeira escrita um pouco acima; os multiplicadores exatos, e por quanto tempo um prefixo fica guardado, estão na página do fornecedor.

O Ollama faz algo parecido por conta própria. Enquanto um modelo continua carregado, ele guarda o que calculou para os últimos prompts que leu, e um pedido novo que começa pelos mesmos tokens pula essa parte. Esse era o 847 da seção 02. Rode a mesma pergunta de novo, e depois mais uma vez com `--cache`, que marca o fim do bloco de políticas do jeito da Anthropic:

```
ana@lab:~/agents$ python cost_run.py llama3.2:3b
step   input  c.write  c.read  output     ms  stop
   1     162        0     847      18   3955  tool_use
       tool search_help {"query": "Order status M-1043"}: 155 ms
   2      73        0     847      35   4893  end_turn
total     235        0    1694      53   9003
ana@lab:~/agents$ python cost_run.py llama3.2:3b --cache
step   input  c.write  c.read  output     ms  stop
   1     162        0     847      17   3473  tool_use
       tool get_order {"order_id": "M-1043"}: 1 ms
   2     184        0     847      62   8801  end_turn
total     346        0    1694      79  12275
```

As duas execuções reaproveitaram os 847 tokens em **todos** os pedidos, o primeiro inclusive, porque a execução anterior os tinha deixado lá. O `--cache` não mudou nada: o Ollama aceita `cache_control` e o ignora, já que reaproveita o que coincidir de qualquer jeito. Repare também no modelo: uma execução buscou na central de ajuda, a outra consultou o pedido. Mesma pergunta, mesmo prompt, dois caminhos diferentes; a aula 1 disse que as palavras iam variar, e aqui variou a escolha da ferramenta.

O reaproveitamento se guia pelo **prefixo exato**, desde o primeiro token, no Ollama como no cache de um fornecedor. Qualquer coisa que mude perto da frente o quebra para tudo o que vem depois. O `--stamp` põe a hora do pedido bem no topo do prompt de sistema, o que parece inofensivo:

```
ana@lab:~/agents$ python cost_run.py llama3.2:3b --cache --stamp
step   input  c.write  c.read  output     ms  stop
   1    1004        0      15      17  11039  tool_use
       tool search_help {"query": "order M-1043"}: 164 ms
   2     905        0      21     245  36714  end_turn
total    1909        0      36     262  47917
```

O reaproveitamento caiu para 15 e 21 tokens, e os dois pedidos leram o prompt inteiro de novo: **1.909 tokens lidos**, contra 235 e 346 nas execuções acima, e 47.917 ms, a execução mais lenta desta aula. Com um fornecedor hospedado o mesmo erro se paga também em dinheiro: todo pedido escreve o prefixo de novo e não lê nada dele, o que custa mais do que não usar cache nenhum. Uma data, um id de pedido, o nome de um usuário no topo de um prompt de sistema: cada um transforma um cache num custo. Ponha o que muda **depois** do que não muda, e mantenha a lista de ferramentas numa ordem fixa (a revisão 2026-07-28 do MCP pede aos servidores que devolvam as ferramentas numa ordem determinística por esse motivo). O ADK da aula 10 avisou do mesmo efeito pelo outro lado: toda transferência entre agentes muda o prompt de sistema e as ferramentas, então o prefixo começa do zero.
