---
title: Para onde vai o tempo
version: 2
---

A mesma execução, lida pelo tempo. De 19.242 ms:

- **O pedido 1 levou 10.447 ms** para escrever 16 tokens. Quase tudo isso foi leitura: 994 tokens de ferramentas, políticas e pergunta, que uma CPU percorre antes de escrever qualquer coisa.
- **O pedido 2 levou 8.629 ms**, e leu só 65 tokens novos. Neste, quase tudo foi escrever a resposta de 67 tokens, um token por vez, então uma resposta longa é uma resposta lenta.
- **O `search_help` levou 166 ms**, o modelo `all-minilm` no Ollama codificando a consulta; o `get_order` de uma execução posterior levou 1 ms.

A segunda execução da seção 05 fez a mesma pergunta logo depois, e o primeiro pedido dela levou **3.955 ms em vez de 10.447**: leu 162 tokens e reaproveitou 847. Ler um prompt longo não sai de graça, e numa máquina sem uma GPU grande é a maior parte da espera. Um fornecedor hospedado lê mais rápido, mas a forma é a mesma: o primeiro token chega mais tarde conforme o prompt cresce.

A conta dá três regras para um agente mais rápido, em ordem de efeito:

1. **Menos passos.** Cada pedido paga o tempo até o primeiro token, e cada um reenvia a conversa inteira. Um plano que precisa de duas chamadas de ferramenta não deve levar cinco turnos (aula 5).
2. **Saída mais curta onde a saída não é o produto.** Uma chamada de ferramenta é curta; um resumo interno para outro agente não precisa ser prosa.
3. **Um modelo menor onde ele basta**, a próxima seção.

O streaming não encurta o trabalho, mas muda o que a pessoa espera: as primeiras palavras aparecem depois do tempo até o primeiro token, e não depois da resposta inteira. Num chat de atendimento, é a diferença entre dez segundos de silêncio e uma resposta que começa assim que a leitura termina.
