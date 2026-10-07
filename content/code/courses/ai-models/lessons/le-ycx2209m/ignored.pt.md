---
title: Aceito não é obedecido
version: 1
---

A documentação da Anthropic sobre o endpoint compatível dela é invulgarmente franca sobre o que o
formato promete, e vale ler como descrição de toda API compatível, não só desta:

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-07
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
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-07
 283| response_format
 284| Ignored. For JSON output, use
```

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-07
 293| seed
 294| Ignored
```

`response_format` é como a Chat Completions pede JSON, a contrapartida do `text.format` da aula
16. Mandado aqui, ele é descartado, e o modelo escreve o que o prompt o levar a escrever; um parser
    mais adiante descobre. `seed` é um pedido de amostragem repetível, a propriedade que a seção 08
    da aula 5 mediu, e aqui não faz nada. Mais dois mudam valores em vez de descartá-los, ou tiram
    um recurso:

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-07
 181: Prompt caching is not supported, but it is supported in the
 276: Between 0 and 1 (inclusive). Values greater than 1 are capped at 1.
```

Uma `temperature` de 1,5 ajustada contra a OpenAI chega como 1,0. O cache da aula 17 não existe por
este endpoint.

A Anthropic escreve a lista dela. Um servidor que não escreve não é por isso um servidor que
obedece a tudo, e o único jeito de descobrir é mandar um campo e olhar o que mudou. O `limit.py`
pede ao Ollama um resumo de uma frase de um e-mail, limitado a oito tokens, duas vezes: uma com o
limite sob o nome que a Chat Completions sempre teve, e outra sob o nome que a biblioteca da OpenAI
agora recomenda:

```python
import json

from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:11434/v1", api_key="ollama")
case = [json.loads(line) for line in open("cases/triage.jsonl")][0]

# the same limit, under the old name and under the name OpenAI's reference now uses
for field in ("max_tokens", "max_completion_tokens"):
    r = client.chat.completions.create(model="llama3.2:3b", temperature=0, messages=[
        {"role": "user", "content": "Summarise this e-mail in one sentence: " + case["text"]}], **{field: 8})
    print(f"{field:22} 8 -> {r.usage.completion_tokens:3} tokens, finish_reason {r.choices[0].finish_reason}")
```

```
ana@desk:~/desk$ python limit.py
max_tokens             8 ->   8 tokens, finish_reason length
max_completion_tokens  8 ->  37 tokens, finish_reason stop
```

O primeiro limite valeu: oito tokens e `length`, o modelo cortado. O segundo foi **aceito e
ignorado**: nenhum erro, e o modelo escreveu a frase inteira. A documentação do nome antigo na
própria biblioteca diz por que um programa mandaria o novo. O `chatdoc.py` a imprime:

```python
import re
import sys

import openai.resources.chat.completions.completions as module

# the docstring of Completions.create, as the installed library carries it
source = open(module.__file__).read()
for name in sys.argv[1:]:
    m = re.search(rf"^ {{10}}{name}: .*?(?=\n\n {{10}}\w+: )", source, re.S | re.M)
    print(re.sub(r"(?m)^ {10}", "", m.group(0)) if m else f"{name}: not documented")
```

```
ana@desk:~/desk$ python chatdoc.py max_tokens
max_tokens: The maximum number of [tokens](https://platform.openai.com/tokenizer) that can
    be generated in the chat completion. This value can be used to control
    [costs](https://openai.com/api/pricing/) for text generated via API.

    This value is now deprecated in favor of `max_completion_tokens`, and is not
    compatible with
    [o-series models](https://developers.openai.com/api/docs/guides/reasoning).
```

Então um programa escrito pela referência atual da OpenAI, apontado para o Ollama, fica sem limite
de saída, e nada avisa; os tetos de custo da aula 21 dependem exatamente desse campo. E a aula 14
achou a mesma forma de lacuna no Ollama pelo outro lado, um ajuste que a API própria dele tem e para
o qual o formato da OpenAI não tem lugar:

```
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
 386: The OpenAI API does not have a way of setting the context size for a model. If you need
      to change the context size, create a `Modelfile` which looks like:
```

Então a regra para um programa que fala com vários provedores por um formato só:

- **O formato carrega a parte comum.** Mensagens, o nome do modelo, um limite, uma temperatura na
  faixa que todos aceitam, o texto que volta.
- **Todo o resto é por provedor**, e se lê na documentação desse provedor, e depois se confere
  mandando: saída estruturada, cache, seeds, limites de saída, janelas de contexto, cabeçalhos de
  limite, o texto de um erro.
- **A avaliação também é por provedor**, feita pelo caminho que o programa vai de fato usar. Os
  números da aula 5 para um modelo pela API própria não dizem nada certo sobre o mesmo modelo por um
  endpoint compatível que ignora metade da requisição.

O formato é o jeito mais barato de *comparar* provedores, que é para o que a Anthropic diz que o
endpoint dela serve. Se vale *ficar* nele é a troca que a aula 16 pôs diante da API mais nova da
própria OpenAI: alcance contra recursos, decidida com os recursos que você realmente usa escritos.
