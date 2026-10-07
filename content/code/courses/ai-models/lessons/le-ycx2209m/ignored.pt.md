---
title: Aceito não é obedecido
version: 1
---

A documentação da Anthropic sobre o endpoint compatível dela é invulgarmente franca sobre o que o
formato promete, e vale ler como descrição de toda API compatível, não só desta:

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-05
  62: This compatibility layer is primarily intended to test and compare model capabilities,
      and is not considered a long-term or production-ready solution for most use cases. While
      it is intended to remain fully functional and not have breaking changes, the priority is
      the reliability and effectiveness of the
 184: Most unsupported fields are silently ignored rather than producing errors. These are all
      documented in the following sections.
```

**Ignorados em silêncio.** A requisição é aceita, a resposta volta, e um campo que teria mudado a
resposta em outro lugar não mudou nada. A documentação lista depois os campos um a um. Dois deles
importam para o trabalho que este curso fez:

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-05
 283| response_format
 284| Ignored. For JSON output, use
```

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-05
 293| seed
 294| Ignored
```

`response_format` é como a Chat Completions pede JSON, a contrapartida do `text.format` da aula
16. Mandado aqui, ele é descartado, e o modelo escreve o que o prompt o levar a escrever; um parser mais adiante descobre.
`seed` é um pedido de amostragem repetível, a propriedade que a seção 08 da aula 5 mediu, e aqui não
faz nada.
Mais dois mudam valores em vez de descartá-los, ou tiram um recurso:

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-05
 181: Prompt caching is not supported, but it is supported in the
 276: Between 0 and 1 (inclusive). Values greater than 1 are capped at 1.
```

Uma `temperature` de 1,5 ajustada contra a OpenAI chega como 1,0. O cache da aula 17 não existe por
este endpoint. E a aula 14 achou a mesma forma de lacuna no Ollama, pelo outro lado: um ajuste que a
API própria dele tem e para o qual o formato da OpenAI não tem lugar:

```
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
 386: The OpenAI API does not have a way of setting the context size for a model. If you need
      to change the context size, create a `Modelfile` which looks like:
```

Então a regra para um programa que fala com vários provedores por um formato só:

- **O formato carrega a parte comum.** Mensagens, o nome do modelo, um limite, uma temperatura na
  faixa que todos aceitam, o texto que volta.
- **Todo o resto é por provedor**, e se lê na documentação desse provedor: saída estruturada, cache,
  seeds, janelas de contexto, cabeçalhos de limite, o texto de um erro.
- **A avaliação também é por provedor**, feita pelo caminho que o programa vai de fato usar. Os
  números da aula 5 para um modelo pela API própria não dizem nada certo sobre o mesmo modelo por um
  endpoint compatível que ignora metade da requisição.

O formato é o jeito mais barato de *comparar* provedores, que é para o que a Anthropic diz que o
endpoint dela serve. Se vale *ficar* nele é a troca que a aula 16 pôs diante da API mais nova da
própria OpenAI: alcance contra recursos, decidida com os recursos que você realmente usa escritos.
