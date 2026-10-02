---
title: Chamadas de ferramenta num stream
version: 1
---

As chamadas de ferramenta da aula 8 também vêm em streaming. O texto chega como deltas de texto, e
**os argumentos de uma chamada chegam como pedaços de JSON**, em eventos `input_json_delta`. O
`tool_stream.py` imprime cada pedaço e diz se tudo até ali já é JSON válido.

```python
"""A tool call, streamed: its arguments arrive as pieces of JSON that do not parse until the end."""
import json

import anthropic

TOOLS = [{"name": "get_stock", "description": "Units in stock and unit price in cents for one product, by its SKU.",
          "input_schema": {"type": "object", "properties": {"sku": {"type": "string"}}, "required": ["sku"]}}]
model = anthropic.Anthropic()
with model.messages.stream(model="scripted-1", max_tokens=300, tools=TOOLS,
                           messages=[{"role": "user", "content": "Is LAMP-02 in stock?"}]) as stream:
    sofar = ""
    for event in stream:
        if event.type == "content_block_delta" and event.delta.type == "input_json_delta":
            sofar += event.delta.partial_json
            try:
                json.loads(sofar)
                parses = "parses"
            except json.JSONDecodeError:
                parses = "does not parse yet"
            print(f"{event.delta.partial_json!r:16} {parses}")
    call = stream.get_final_message().content[-1]
print(call.name, call.input)
```

```
ana@dev:~/shop$ python tool_stream.py
'{"sku": "LAM'   does not parse yet
'P-02"}'         parses
get_stock {'sku': 'LAMP-02'}
```

**O primeiro pedaço não é lido.** É meia string dentro de meio objeto, e nenhum leitor de JSON
consegue entendê-lo. Só depois do último pedaço existe um objeto completo, e o SDK o entrega como
`input` na mensagem que monta no fim.

## O que decorre disso

- **Não rode nada até o bloco estar completo.** Um host que agisse sobre um argumento parcial
  consultaria `LAM`, ou pior, reembolsaria um valor cujos últimos dígitos não tinham chegado. Espere
  o `content_block_stop`, ou use a mensagem final.
- **Valide como na aula 8.** Uma chamada em streaming é conferida contra o esquema exatamente como
  uma que chegou inteira. Os pedaços mudam quando os argumentos chegam, não o que eles precisam ser.
- **Ainda dá para mostrar progresso.** Uma página pode dizer "consultando o estoque…" assim que o
  `content_block_start` dá o nome da ferramenta, antes de qualquer argumento chegar. É uma mensagem
  sobre o que está acontecendo, e não precisa de nada lido.
