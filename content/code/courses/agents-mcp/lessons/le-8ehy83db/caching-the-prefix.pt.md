---
title: Pondo o prefixo em cache
version: 1
---

A maior parte de cada pedido era texto que o fornecedor tinha acabado de ler. Os fornecedores oferecem **cache de prompt** exatamente para isso: marque o fim de um prefixo que não muda (`cache_control` na API da Anthropic), e o fornecedor o guarda por pouco tempo, de modo que os pedidos seguintes que começam pelo mesmo prefixo o leem do cache. Leituras do cache são cobradas bem abaixo da entrada comum, e a primeira escrita um pouco acima; os multiplicadores exatos estão na página do fornecedor. O labllm segue a mesma regra: um prefixo marcado de 1.024 tokens ou mais é escrito uma vez e lido por 300 segundos.

O `--cache` marca o fim do bloco de políticas. Duas execuções, uma depois da outra:

```
ana@lab:~/agents$ python cost_run.py scripted-1 --cache
step   input  c.write  c.read  output     ms  stop
   1      12     2347       0      10    632  tool_use
       tool get_order: 1 ms
   2     173        0    2347       8    570  tool_use
       tool search_help: 314 ms
   3     214        0    2347      75   3209  end_turn
total     399     2347    4694      93   4726
ana@lab:~/agents$ python cost_run.py scripted-1 --cache
step   input  c.write  c.read  output     ms  stop
   1      12        0    2347      10    634  tool_use
       tool get_order: 1 ms
   2     173        0    2347       8    570  tool_use
       tool search_help: 332 ms
   3     214        0    2347      75   3209  end_turn
total     399        0    7041      93   4747
```

Na primeira execução, o pedido 1 **escreveu** 2.347 tokens no cache e os pedidos 2 e 3 os **leram**, então só 399 tokens da execução inteira foram entrada comum. A segunda execução, dentro dos 300 segundos, leu o prefixo já no primeiro pedido: **nenhuma escrita**, 7.041 tokens lidos. O total é o mesmo, 7.440 tokens, nos dois casos; o que muda é como eles são cobrados.

O cache se guia pelo **prefixo exato**, desde o primeiro byte. A ordem é ferramentas, depois prompt de sistema, depois mensagens, então qualquer coisa que mude perto da frente o quebra para tudo o que vem depois. O `--stamp` põe a hora do pedido bem no topo do prompt de sistema, o que parece inofensivo:

```
ana@lab:~/agents$ python cost_run.py scripted-1 --cache --stamp
step   input  c.write  c.read  output     ms  stop
   1      12     2358       0      10    637  tool_use
       tool get_order: 1 ms
   2     173     2358       0       8    577  tool_use
       tool search_help: 381 ms
   3     214     2358       0      75   3210  end_turn
total     399     7074       0      93   4806
```

Todo pedido escreveu o prefixo de novo, **7.074 tokens escritos e nenhum lido**: mais caro que não usar cache nenhum, já que escritas custam mais que entrada comum. Uma data, um id de pedido, o nome de um usuário no topo de um prompt de sistema: cada um transforma um cache num custo. Ponha o que muda **depois** do que não muda, e mantenha a lista de ferramentas numa ordem fixa (a revisão 2026-07-28 do MCP pede aos servidores que devolvam as ferramentas numa ordem determinística por esse motivo). O ADK da aula 10 avisou do mesmo efeito pelo outro lado: toda transferência entre agentes muda o prompt de sistema e as ferramentas, então o prefixo começa do zero.
