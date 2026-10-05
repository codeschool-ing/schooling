---
title: O que saber antes de usar
version: 1
---

Duas linhas da tabela da Anthropic, e duas linhas da tabela do LiteLLM, dizem quase tudo o que é
particular desta família.

```
ana@desk:~/desk$ python lab/card.py all Thinking "Default effort" "Context window" "Max output"
# https://platform.claude.com/docs/en/about-claude/models/overview, read 2026-10-05
Claude Fable 5.1
  Thinking                    Adaptive (always on)
  Default effort              high
  Context window              1M tokens
  Max output                  128K tokens
Claude Opus 5.5
  Thinking                    Adaptive (always on)
  Default effort              medium
  Context window              1M tokens
  Max output                  128K tokens
Claude Sonnet 5.5
  Thinking                    Adaptive
  Default effort              high
  Context window              1M tokens
  Max output                  128K tokens
Claude Haiku 4.5
  Thinking                    Extended
  Default effort              Not supported
  Context window              200K tokens
  Max output                  64K tokens
```

## Raciocínio e esforço

**Thinking** é o raciocínio da aula 1 seção 03: o modelo escreve o caminho antes de responder. A
tabela distingue três tipos. No Fable e no Opus ele é *adaptive* e *always on*: o modelo decide quanto
pensar, e sempre pensa um pouco. No Sonnet a tabela diz adaptativo, sem o
always on. O Haiku tem o
raciocínio *extended*, mais antigo, que a requisição liga e para o qual define um orçamento.

**Effort** (esforço) é uma segunda configuração dos modelos novos: o quanto o modelo se dedica a uma
resposta, de low a max. Os padrões diferem, `high` no Fable e no Sonnet e
`medium` no Opus, e o Haiku não suporta. A aula 17 mostra onde ele entra numa requisição. Para
escolher, a consequência é que **o custo e a latência de um modelo dependem de uma configuração**, e
uma avaliação precisa registrar o esforço com que rodou, como a seção 08 da aula 5 registrou a
temperatura.

## O cache tem uma estrutura de preço

A aula 4 precificou o rascunho da ana com cache. A tabela diz quanto esse cache custa no Haiku 4.5:

```
ana@desk:~/desk$ sheet show claude-haiku-4-5 | grep -E "^(input_cost_per_token|cache|prompt_cache|output_cost_per_token)"
cache_creation_input_token_cost            1.25e-06
cache_creation_input_token_cost_above_1hr  2e-06
cache_creation_input_token_cost_batches    6.25e-07
cache_read_input_token_cost                1e-07
cache_read_input_token_cost_batches        5e-08
input_cost_per_token                       1e-06
input_cost_per_token_batches               5e-07
output_cost_per_token                      5e-06
output_cost_per_token_batches              2.5e-06
prompt_cache_min_tokens                    4096
```

Lendo por milhão de tokens: a entrada custa **US$ 1**, gravar o cache custa **US$ 1,25** (um quarto a
mais), mantê-lo gravado por uma hora em vez de cinco minutos custa **US$ 2** para gravar, e ler de
volta custa **US$ 0,10**, um décimo. Então um prefixo em cache paga a gravação depois de um reuso e
custa um décimo do preço em todo reuso depois disso. O **mínimo** é a armadilha: no Haiku 4.5 um
prefixo menor que 4.096 tokens não entra em cache. No Sonnet 5.5:

```
ana@desk:~/desk$ sheet show claude-sonnet-5-5 | grep -E "^prompt_cache_min"
prompt_cache_min_tokens                    512
```

512. A política de 5.000 tokens da ana passa nos dois. Uma equipe que pusesse em cache um prompt de
sistema de 2.000 tokens veria o Sonnet guardando e o Haiku cobrando preço cheio em silêncio, e quem
avisaria seria a conta, não um erro.

## O resto, rápido

- **Lote** corta pela metade todo preço acima (as linhas `_batches`), para trabalho que pode esperar
  horas.
- **Visão e uso de ferramentas** são suportados por todos os modelos da tabela, nas palavras da
  própria página, e o `VFSCRP` da tabela do LiteLLM acrescenta saída estruturada, cache, raciocínio
  e entrada de PDF para os quatro.
- A API da Anthropic aparece na aula 17, onde ficam o formato da requisição, o cabeçalho de versão e
  os parâmetros que o SDK de fato aceita.
