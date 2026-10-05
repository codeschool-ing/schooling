---
title: A série o, e para onde foi o raciocínio
version: 1
---

Por um tempo a OpenAI vendeu raciocínio como uma linha separada: a **série o**, modelos ajustados para
trabalhar um problema antes de responder (o terceiro tipo da aula 1 seção 03). A tabela ainda dá
preço a eles:

```
ana@desk:~/desk$ sheet compare o1 o3 o3-mini o4-mini
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
o1                                              200,000   100000       15       60  VFSCRP
o3                                              200,000   100000        2        8  VFSCRP
o3-mini                                         200,000   100000      1.1      4.4  .FSCR.
o4-mini                                         200,000   100000      1.1      4.4  VFSCRP
```

E data a maioria:

```
ana@desk:~/desk$ sheet retiring --provider openai | grep -E "  o[0-9]"
2026-10-23  o1                                                 openai
2026-10-23  o1-2024-12-17                                      openai
2026-10-23  o3-mini                                            openai
2026-10-23  o3-mini-2025-01-31                                 openai
2026-10-23  o4-mini                                            openai
2026-10-23  o4-mini-2025-04-16                                 openai
2026-12-11  o3-2025-04-16                                      openai
```

**o1, o3-mini e o4-mini estão listados para aposentadoria em 23 de outubro de 2026**, dezoito dias depois
do dia em que isto foi gravado; a versão datada do o3 vem em dezembro. Uma linha de modelos lançada
como categoria própria está terminando como um conjunto de entradas numa lista de descontinuação.

## Para onde ele foi

Para dentro dos próprios modelos GPT. Toda entrada GPT-5 e GPT-6 da seção 02 traz um `R`, e o
raciocínio agora é uma **configuração da requisição**, não uma escolha de modelo. O SDK da OpenAI, que é
gerado a partir da especificação da própria API da OpenAI, lista os valores que essa configuração pode
ter:

```
ana@desk:~/desk$ python -c "import typing, openai.types.shared.reasoning_effort as r; print(typing.get_args(r.ReasoningEffort)[0])"
typing.Literal['none', 'minimal', 'low', 'medium', 'high', 'xhigh', 'max']
```

Sete níveis, de `none` a `max`. A tabela registra quais um modelo aceita e qual ele usa quando a
requisição não diz nada:

```
ana@desk:~/desk$ sheet show gpt-5.4-mini | grep -E "reasoning"
default_reasoning_effort                   none
supports_minimal_reasoning_effort          False
supports_none_reasoning_effort             True
supports_reasoning                         True
supports_xhigh_reasoning_effort            True
```

```
ana@desk:~/desk$ sheet show gpt-5.5 | grep -E "reasoning"
supports_minimal_reasoning_effort          False
supports_none_reasoning_effort             True
supports_reasoning                         True
supports_xhigh_reasoning_effort            True
```

O `gpt-5.4-mini` usa por padrão **nenhum raciocínio**, e aceita `none`, não `minimal`, e vai até
`xhigh`. A tabela não registra padrão para o `gpt-5.5`, o que já é informação: é mais uma coisa a
conferir na página do provedor antes de depender dela.

## Por que isso importa para escolher

- **Raciocínio é cobrado como saída.** O trabalho do modelo são tokens que ele escreve, e eles são
  cobrados pelo preço de saída, você os veja ou não. A aula 4 seção 05 viu a saída ser de 5% a 25% da
  conta de rascunho da ana; um modelo raciocinando em `high` antes de cada rascunho mudaria essa
  fatia, e a latência da aula 4 seção 06 junto.
- **A configuração faz parte do candidato.** O `gpt-5.4-mini` em `none` e em `high` são duas linhas
  na avaliação da aula 5, como a aula 6 disse do esforço do Claude. Registre em toda execução.
- **Para as tarefas da ana, comece por baixo.** Classificar cinco rótulos e copiar um número de
  pedido não exigem raciocínio; o padrão `none` é onde começar, e um nível mais alto só se justifica
  consertando casos que os casos mostram que ele conserta.
