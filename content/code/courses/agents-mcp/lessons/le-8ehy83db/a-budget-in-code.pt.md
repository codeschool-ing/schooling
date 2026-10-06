---
title: Um orçamento em código
version: 1
---

Todo limite da seção anterior pertence ao fornecedor. Um programa precisa de limites próprios, decididos pelo que uma resposta vale, e impostos no laço, onde estão os números.

O laço já tem os dois que mais importam. O `cost_run.py` para depois de seis passos, e todo agente deste curso teve um limite de passos; e toda resposta traz `usage`, então o programa sabe depois de cada pedido exatamente quantos tokens a execução usou. Um orçamento são poucas linhas que comparam um com o outro:

- **Um limite de passos**, que todo agente deste curso teve. Ele limita o tempo e o crescimento da conversa.
- **Um orçamento de tokens por execução**: some `input_tokens`, escritas e leituras de cache e `output_tokens` depois de cada pedido, e pare com um desfecho claro quando a soma passar de um teto. O teto vem do trabalho: uma resposta de atendimento que precisa de 50.000 tokens é um laço que deu errado, não uma pergunta difícil.
- **Um orçamento de tempo por execução**, para a pessoa que espera: quando um cliente já esperou dez segundos, um honesto "um colega vai responder por e-mail" é melhor que uma resposta certa em trinta.
- **Um registro por conversa**: o id de execução da auditoria da aula 17, com os totais de tokens e o tempo, para que as conversas caras possam ser achadas e lidas. As médias escondem a conversa que custou cem vezes as outras.

O que um orçamento nunca pode fazer é falhar em silêncio. Uma execução que para por orçamento deve terminar como as execuções travadas da aula 7: com um motivo, uma mensagem que o cliente entenda e um encaminhamento a uma pessoa. Um limite que só corta é um limite que esconde o problema que achou.

Esta é a última aula do curso. Tudo o que um agente faz passa pelos mesmos poucos lugares: o laço, as ferramentas, os pedidos ao modelo, as decisões do hospedeiro, as fronteiras dos servidores. O jeito de conhecer um agente é medi-lo em cada um deles, que é o que toda captura destas dezoito aulas fez.
