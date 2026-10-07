---
title: OpenAI, Azure e o resto
version: 1
---

O modelo que a ana precificou na aula 4, por todas as rotas que a tabela conhece:

```
ana@desk:~/desk$ python sheet.py where gpt-5.4-mini
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
aihubmix/gpt-5.4-mini                                aihubmix                       0.75      4.5
azure/eu/gpt-5.4-mini                                azure                         0.825     4.95
azure/gpt-5.4-mini                                   azure                          0.75      4.5
azure/gpt-5.4-mini-2026-03-17                        azure                          0.75      4.5
azure/us/gpt-5.4-mini                                azure                         0.825     4.95
azure_ai/gpt-5.4-mini                                azure_ai                       0.75      4.5
azure_ai/gpt-5.4-mini-2026-03-17                     azure_ai                       0.75      4.5
gpt-5.4-mini                                         openai                         0.75      4.5
gpt-5.4-mini-2026-03-17                              openai                         0.75      4.5
openrouter/openai/gpt-5.4-mini                       openrouter                     0.75      4.5
openrouter/openai/gpt-5.4-mini:batch                 openrouter                    0.375     2.25
perplexity/openai/gpt-5.4-mini                       perplexity                     0.75      4.5
```

**A API da própria OpenAI**, com o apelido `gpt-5.4-mini` e o datado `gpt-5.4-mini-2026-03-17`, a
US$ 0,75 e US$ 4,50.

**A Microsoft Azure**, duas vezes: `azure` é a Azure OpenAI e `azure_ai` é o catálogo de modelos da
Azure, os dois pelo preço da OpenAI na rota global. As rotas `eu/` e `us/` da Azure custam **10% a
mais**, US$ 0,825 e US$ 4,95: o mesmo adicional regional que o Bedrock cobrou pelo Claude na aula 2
seção 07, pela mesma garantia sobre onde as requisições são processadas. Para uma loja europeia com
um contrato que diga isso, é a linha a ler.

**Roteadores e revendedores** pelo mesmo preço, e a rota `:batch` do OpenRouter pela metade, que é o
nível de lote da OpenAI acessado por um roteador, como com o Gemini na aula 7.

## Três APIs num endereço

```
ana@desk:~/desk$ python sheet.py show gpt-5.4-mini | grep supported_endpoints
supported_endpoints                        ['/v1/chat/completions', '/v1/batch', '/v1/responses']
```

A tabela lista três endpoints para este modelo. `/v1/chat/completions` é o formato que a maior parte
do setor copiou, assunto da aula 20. `/v1/responses` é a API mais nova da OpenAI, assunto da aula
16, e é sobre ela que os recursos novos da OpenAI são construídos. `/v1/batch` é para onde vai um
arquivo de requisições no nível de metade do preço.

**Para a ana, a escolha entre elas é sobretudo de portabilidade.** O harness de avaliação dela na
aula 5 já fala Chat Completions, e também falam a Mistral, o Ollama e o OpenRouter. Código escrito
contra a Responses API ganha os recursos novos da OpenAI e perde esse alcance. A aula 16 mostra o
que a Responses API acrescenta, para a troca ser feita conhecendo os dois lados.
