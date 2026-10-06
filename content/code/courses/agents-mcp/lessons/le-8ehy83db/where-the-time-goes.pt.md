---
title: Para onde vai o tempo
version: 1
---

A mesma execução, lida pelo tempo. De 4.768 ms:

- **O pedido 3 levou 3.208 ms**, porque escreveu a resposta de 75 tokens. No labllm isso dá 200 ms mais 75 × 40 ms, e a medida bate por poucos milissegundos. Com um fornecedor de verdade a forma é a mesma: a saída sai um token por vez, então uma resposta longa é uma resposta lenta.
- **Os pedidos 1 e 2 levaram cerca de 600 ms cada**, para 10 e 8 tokens de saída: quase tudo é o tempo antes do primeiro token.
- **O `search_help` levou 348 ms**, o modelo de embeddings de `embeddings-vectors` codificando a consulta; o `get_order` levou 1 ms.

Tokens de entrada não custam tempo no labllm, que só os conta. Um fornecedor de verdade também gasta tempo lendo um prompt longo, então o primeiro token dele chega mais tarde conforme o prompt cresce, e esse é um dos pontos em que o labllm é mais simples do que aquilo que representa.

A conta dá três regras para um agente mais rápido, em ordem de efeito:

1. **Menos passos.** Cada pedido paga o tempo até o primeiro token, e cada um reenvia a conversa inteira. Um plano que precisa de duas chamadas de ferramenta não deve levar cinco turnos (aula 5).
2. **Saída mais curta onde a saída não é o produto.** Uma chamada de ferramenta é curta; um resumo interno para outro agente não precisa ser prosa.
3. **Um modelo menor onde ele basta**, a próxima seção.

O streaming não encurta o trabalho, mas muda o que a pessoa espera: as primeiras palavras aparecem depois do tempo até o primeiro token, e não depois da resposta inteira. Num chat de atendimento, é a diferença entre três segundos de silêncio e uma resposta que começa na hora.
