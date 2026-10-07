---
title: A mesma ideia em outra API
version: 2
---

Todo provedor com que este curso fala tem chamada de funções, e a ideia é a mesma em todo lugar:
**ferramentas descritas por JSON Schema, uma resposta que pede uma, um resultado devolvido com um
id**. Os formatos mudam, e as diferenças são onde o código escrito para uma API quebra em outra.

## As chat completions da OpenAI

As mesmas ferramentas, embrulhadas no formato da OpenAI, contra o endpoint OpenAI do Ollama:

```schooling-example
{
  "language": "python",
  "file": "openai_stock.py",
  "parts": [
    {
      "code": "\"\"\"The same round trip through OpenAI's chat completions: the arguments arrive as a string.\"\"\"\nimport json\nimport sys\n\nimport openai\n\nfrom shop_tools import FUNCTIONS, TOOLS\n\n"
    },
    {
      "code": "tools = [{\"type\": \"function\", \"function\": {\"name\": t[\"name\"], \"description\": t[\"description\"],\n                                           \"parameters\": t[\"input_schema\"]}} for t in TOOLS]\nclient = openai.OpenAI()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**Os mesmos `TOOLS`, embrulhados** no formato que esta API espera."
    },
    {
      "code": "while True:\n    r = client.chat.completions.create(model=\"llama3.2:3b\", messages=messages, tools=tools, temperature=0)\n    choice = r.choices[0]\n    print(\"<- finish_reason:\", choice.finish_reason)\n    messages.append(choice.message.model_dump(exclude_none=True))\n    if not choice.message.tool_calls:\n        print(\"  \", choice.message.content)\n        break\n",
      "note": "**`finish_reason` diz por que a resposta parou**; `tool_calls` quer dizer que o modelo quer uma função."
    },
    {
      "code": "    for call in choice.message.tool_calls:\n        print(\"   arguments:\", repr(call.function.arguments))\n        out = FUNCTIONS[call.function.name](**json.loads(call.function.arguments))\n        messages.append({\"role\": \"tool\", \"tool_call_id\": call.id, \"content\": json.dumps(out)})\n",
      "note": "**Os argumentos são uma string.** O `json.loads` é trabalho do seu código, e o resultado volta como mensagem `tool` ligada pelo `tool_call_id`."
    }
  ]
}
```

```
ana@dev:~/shop$ python openai_stock.py "Is LAMP-02 in stock?"
<- finish_reason: tool_calls
   arguments: '{"sku":"LAMP-02"}'
<- finish_reason: stop
   The LAMP-02 is currently in stock. It has 4 units available, and the unit price is $21,000.
```

Mesma pergunta, mesma ferramenta, mesma resposta, $21,000 incluídos. **Os argumentos são a
diferença**: o `repr` mostra aspas em volta deles porque chegam como uma string de JSON, não como um objeto. O código precisa
chamar `json.loads` ele mesmo, e uma string pode falhar na leitura de um jeito que um objeto já
lido não falha. Sem o modo estrito, uma string malformada é uma possibilidade real, e ela pertence
ao mesmo caminho de erro que uma falha de esquema.

## Lado a lado

| | Anthropic Messages | OpenAI chat completions |
| --- | --- | --- |
| definição da ferramenta | `name`, `description`, `input_schema` | `{"type": "function", "function": {..., "parameters"}}` |
| o modelo quer uma ferramenta | `stop_reason: "tool_use"` | `finish_reason: "tool_calls"` |
| a chamada | um bloco `tool_use` em `content` | uma entrada em `message.tool_calls` |
| os argumentos | `input`, um objeto | `function.arguments`, uma string |
| o resultado | um bloco `tool_result` numa mensagem `user` | uma mensagem com `role: "tool"` |
| a ligação | `tool_use_id` | `tool_call_id` |

A API Gemini do Google segue o mesmo desenho com nomes próprios: uma declaração de função com um
esquema, uma parte `functionCall` na resposta, uma parte `functionResponse` devolvida. O Ollama
não serve endpoint do Gemini, então esta aula não mostra captura dela.

## Mantenha suas ferramentas num formato só

O `openai_stock.py` não definiu as ferramentas de novo. Ele converteu o `TOOLS`, que está no formato
da Anthropic, com uma list comprehension. **Tenha uma definição de cada ferramenta, e converta na
borda.** Duas cópias se afastam, e o afastamento aparece como um modelo que obedece a uma descrição
que você já mudou no outro arquivo.
