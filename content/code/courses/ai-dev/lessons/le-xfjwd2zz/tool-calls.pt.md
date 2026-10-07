---
title: Chamadas de ferramenta num stream
version: 2
---

As chamadas de ferramenta da aula 8 também vêm em streaming. O texto chega como deltas de texto, e
**os argumentos de uma chamada chegam como pedaços de JSON**, em eventos `input_json_delta`, tantos
ou tão poucos quanto o servidor quiser. O `tool_stream.py` imprime cada pedaço e diz se tudo até ali
já é JSON válido.

```python
"""A tool call, streamed: its arguments arrive as pieces of JSON that do not parse until the end."""
import json

import anthropic

TOOLS = [{"name": "get_stock", "description": "Units in stock and unit price in cents for one product, by its SKU.",
          "input_schema": {"type": "object", "properties": {"sku": {"type": "string"}}, "required": ["sku"]}}]
model = anthropic.Anthropic()
with model.messages.stream(model="llama3.2:3b", max_tokens=300, tools=TOOLS,
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
'{"sku":"LAMP-02"}' parses
get_stock {'sku': 'LAMP-02'}
```

**Um pedaço, e ele é lido.** O Ollama manda os argumentos de uma chamada inteiros, num único
`input_json_delta`, depois que o modelo terminou de escrevê-los. A API da Anthropic os manda em
pedaços conforme são escritos, e um pedaço como `'{"sku": "LAM'` é meia string dentro de meio objeto,
que nenhum leitor de JSON consegue entender. Um código escrito contra um servidor encontra o outro no
dia em que o provedor muda, então ele tem de estar certo para os dois: só depois do último pedaço
existe um objeto completo, e o SDK o entrega como `input` na mensagem que monta no fim, como quer que
ele tenha chegado.

## O que decorre disso

- **Não rode nada até o bloco estar completo.** Um host que agisse sobre um argumento parcial
  consultaria `LAM`, ou pior, reembolsaria um valor cujos últimos dígitos não tinham chegado. Espere
  o `content_block_stop`, ou use a mensagem final.
- **Valide como na aula 8.** Uma chamada em streaming é conferida contra o esquema exatamente como
  uma que chegou inteira. Os pedaços mudam quando os argumentos chegam, não o que eles precisam ser.
- **Ainda dá para mostrar progresso.** Uma página pode dizer "consultando o estoque…" assim que o
  `content_block_start` dá o nome da ferramenta, antes de qualquer argumento chegar. É uma mensagem
  sobre o que está acontecendo, e não precisa de nada lido.
