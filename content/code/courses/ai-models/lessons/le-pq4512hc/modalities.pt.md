---
title: Mais que texto na entrada, e a web como ferramenta
version: 1
---

A outra linha que distingue a família é o que ela aceita. A entrada do Flash 3.5:

```
ana@desk:~/desk$ python sheet.py show gemini/gemini-3.5-flash | grep -E "^(supported_|input_cost_per_audio|search_context|google_maps)"
google_maps_grounding_cost_per_query       0.014
input_cost_per_audio_token                 1.5e-06
input_cost_per_audio_token_priority        2.7e-06
search_context_cost_per_query              {'search_context_size_low': 0.014, 'search_context_size_medium': 0.014, 'search_context_size_high': 0.014}
supported_endpoints                        ['/v1/chat/completions', '/v1/completions', '/v1/batch']
supported_modalities                       ['text', 'image', 'audio', 'video']
supported_output_modalities                ['text']
```

**Quatro tipos de entrada, um tipo de saída.** Texto, imagem, áudio e vídeo entram; texto sai. O áudio
tem preço próprio por token, US$ 1,50 o milhão no Flash 3.5, o mesmo US$ 1,50 do texto nesta faixa,
que é a tabela registrando que áudio é tokenizado e cobrado como qualquer outra entrada. Para a
Lantern Books isso abre tarefas que ninguém pediu ainda, uma mensagem de voz classificada como um
e-mail ou a foto de um livro danificado anexada a um pedido de reembolso, e deixa as tarefas de texto
exatamente onde estavam. O `multimodal`, mais adiante na trilha `ai`, é onde imagem, áudio e
vídeo viram o assunto.

## Ancoragem é cobrada por consulta

Mais duas linhas registram ferramentas que o modelo pode usar enquanto responde, com preço por uso e
não por token:

- `search_context_cost_per_query`: ancorar (*grounding*) uma resposta numa busca na web, **US$
  0,014 por consulta**, seja qual for a quantidade de contexto pedida;
- `google_maps_grounding_cost_per_query`: o mesmo para dados de mapa, pelo mesmo preço.

Uma requisição ancorada custa os tokens **mais** a consulta. A 400 requisições por dia seriam US$ 5,60
por dia, US$ 168 por mês, só em buscas, muitas vezes os US$ 8,02 em que a aula 4 precificou toda a
tarefa de rascunho da ana. Ancoragem é a resposta para a primeira lacuna da aula 1 seção 10, fatos
públicos depois do corte, e as tarefas da ana não têm essa lacuna. **Um recurso cobrado por uso é um
recurso para ligar por tarefa**, não por conta.

## A última linha

`supported_endpoints` lista `/v1/chat/completions`, o caminho no formato da OpenAI. A tabela está
dizendo que o Gemini também pode ser chamado no formato que a aula 20 ensina, além de pela API do
próprio Google na aula 18.
