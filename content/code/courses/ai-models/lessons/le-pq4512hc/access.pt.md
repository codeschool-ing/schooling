---
title: Onde o Gemini é vendido
version: 1
---

A mesma busca da aula 2 seção 05, para o Flash 3.5:

```
ana@desk:~/desk$ python sheet.py where gemini-3.5-flash
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
aihubmix/gemini-3.5-flash-lite                       aihubmix                        0.3 2.499999
deepinfra/google/gemini-3.5-flash                    deepinfra                       1.5        9
gemini/gemini-3.5-flash                              gemini                          1.5        9
gemini/gemini-3.5-flash-lite                         gemini                          0.3      2.5
openrouter/google/gemini-3.5-flash                   openrouter                      1.5        9
openrouter/google/gemini-3.5-flash-lite              openrouter                      0.3      2.5
openrouter/google/gemini-3.5-flash-lite:batch        openrouter                     0.15     1.25
openrouter/google/gemini-3.5-flash:batch             openrouter                     0.75      4.5
perplexity/google/gemini-3.5-flash                   perplexity                      1.5        9
perplexity/google/gemini-3.5-flash-lite              perplexity                      0.3      2.5
vertex_ai/gemini-3.5-flash                           vertex_ai                       1.5        9
gemini-3.5-flash                                     vertex_ai-language-models       1.5        9
gemini-3.5-flash-lite                                vertex_ai-language-models       0.3      2.5
vertex_ai/gemini-3.5-flash-lite                      vertex_ai-language-models       0.3      2.5
```

Três grupos, lidos na coluna `provider`.

**O Google, duas vezes.** `gemini` é a Gemini API, acessada com uma chave de API do Google AI Studio.
`vertex_ai` e `vertex_ai-language-models` são o Vertex AI, a plataforma do Google Cloud, acessada com
as credenciais de um projeto de nuvem. **Os preços são idênticos** neste commit. A diferença é a que a
aula 6 seção 04 traçou para o Claude nas nuvens: uma conta, um contrato, regiões e regras de acesso no
Google Cloud, contra uma chave e um cadastro mais simples no AI Studio. A aula 18 chama a Gemini API.

**Revendedores pelo mesmo preço.** OpenRouter, DeepInfra e Perplexity listam o Flash 3.5 pelos mesmos
US$ 1,50 e US$ 9 do Google. Um modelo fechado revendido não tem espaço para cobrar menos que o autor,
como a aula 2 viu com o Claude.

**E um que corta pela metade**: `openrouter/google/gemini-3.5-flash:batch` a US$ 0,75 e US$ 4,50. Não é
uma cópia mais barata. É o nível de lote do Google, acessado por um roteador, ao preço de lote da seção
03.

O `2.499999` do Flash-Lite no `aihubmix` é um lembrete do que a tabela é: um terceiro digitando os
preços de outras pessoas. **Um preço quase igual ao do autor, mas não exatamente, é erro de digitação ou
arredondamento, não desconto**, e a página do autor é onde conferir.
