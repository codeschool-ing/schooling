---
title: Uma ferramenta em três protocolos
version: 1
---

Todo grande fornecedor aceita chamadas de ferramenta, e cada um as escreve de um jeito. O `wires.py` define uma ferramenta, faz uma pergunta e a manda pelos três SDKs que o laboratório tem. **A chamada que cada resposta traz foi escrita pelo curso** como regra para o substituto, e o labllm a devolve no formato de cada fornecedor; os SDKs, os pedidos que eles montaram e os objetos que eles interpretaram são reais.

```python
"""One tool, one question, three providers' SDKs: what each one sends and gets back."""
import json

import anthropic
import openai
from google import genai
from google.genai import types

NAME, DESCRIPTION = "get_order", "Look up one Marginalia order by its id, such as M-1042."
SCHEMA = {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}
QUESTION = "Where is order M-1043?"

a = anthropic.Anthropic().messages.create(
    model="scripted-1", max_tokens=200, messages=[{"role": "user", "content": QUESTION}],
    tools=[{"name": NAME, "description": DESCRIPTION, "input_schema": SCHEMA}])
call = next(b for b in a.content if b.type == "tool_use")
print("anthropic ", a.stop_reason, call.name, json.dumps(call.input), call.id)

o = openai.OpenAI().chat.completions.create(
    model="scripted-1", messages=[{"role": "user", "content": QUESTION}],
    tools=[{"type": "function", "function": {"name": NAME, "description": DESCRIPTION, "parameters": SCHEMA}}])
call = o.choices[0].message.tool_calls[0]
print("openai    ", o.choices[0].finish_reason, call.function.name, call.function.arguments, call.id)

gemini = genai.Client(http_options=types.HttpOptions(base_url="http://127.0.0.1:8600"))
g = gemini.models.generate_content(
    model="scripted-1", contents=QUESTION,
    config=types.GenerateContentConfig(tools=[types.Tool(function_declarations=[
        types.FunctionDeclaration(name=NAME, description=DESCRIPTION, parameters_json_schema=SCHEMA)])]))
call = g.candidates[0].content.parts[0].function_call
print("gemini    ", g.candidates[0].finish_reason.name, call.name, json.dumps(call.args), call.id)
```

```
ana@lab:~/agents$ python wires.py
anthropic  tool_use get_order {"order_id": "M-1043"} toolu_lab_0014_1
openai     tool_calls get_order {"order_id": "M-1043"} call_lab_0015_1
gemini     STOP get_order {"order_id": "M-1043"} fc_lab_0016_1
ana@lab:~/agents$ tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r["path"].split("/")[-1][:28].ljust(28), json.dumps(r["request"]["tools"])[:118]) for r in map(json.loads, sys.stdin)]'
messages                     [{"name": "get_order", "description": "Look up one Marginalia order by its id, such as M-1042.", "input_schema": {"typ
completions                  [{"type": "function", "function": {"name": "get_order", "description": "Look up one Marginalia order by its id, such a
scripted-1:generateContent   [{"functionDeclarations": [{"description": "Look up one Marginalia order by its id, such as M-1042.", "name": "get_ord
```

O primeiro comando mostra o que cada SDK devolveu; o segundo mostra, a partir do log do labllm, como cada um pôs a mesma definição no fio. A ferramenta é idêntica nos três, um nome, uma descrição e um JSON Schema, e só o embrulho muda:

| | Anthropic Messages | OpenAI Chat Completions | Google Gemini |
|---|---|---|---|
| ferramentas no pedido | `tools: [{name, description, input_schema}]` | `tools: [{type: "function", function: {name, description, parameters}}]` | `tools: [{functionDeclarations: [{name, description, parametersJsonSchema}]}]`, que este SDK escreve como `parameters_json_schema` |
| a chamada na resposta | um bloco de conteúdo `tool_use` com `id`, `name`, `input` | `message.tool_calls[]` com `id`, `function.name`, `function.arguments` como **string** JSON | uma parte `functionCall` com `id`, `name`, `args` |
| por que a resposta parou | `stop_reason: "tool_use"` | `finish_reason: "tool_calls"` | `finishReason: "STOP"`; a chamada está nas partes |
| o resultado de volta | um bloco `tool_result` numa mensagem de usuário, com `tool_use_id` | uma mensagem com role `tool` e `tool_call_id` | uma parte `functionResponse` com o `name` e o `id` da chamada |

Dois detalhes dessa tabela causam bugs reais. **Os argumentos da OpenAI chegam como string de JSON**, não como objeto, então o programa precisa interpretá-los, e de vez em quando um modelo produz uma string que não se interpreta; a linha openai acima imprime essa string como ela chegou. **O motivo de término do Gemini não diz que uma ferramenta foi chamada**: uma resposta com chamada de função termina com `STOP`, igual a uma resposta com a resposta final, então um laço que confere o motivo de término, como o `agent.py` confere o `stop_reason`, nunca roda as ferramentas do Gemini. Ele precisa procurar partes `function_call`.

## Por que o curso escreve a maioria dos laços para um protocolo

As aulas 5 a 7 usam o formato da Anthropic, porque os exemplos do laboratório precisam de um formato só e este mantém a chamada e o resultado em dois blocos com nomes claros. Nada do que elas ensinam depende disso: o portão de validação, os erros, os limites e o rastro funcionam igual nos três. As aulas 8 e 10 usam os protocolos da OpenAI e do Google pelos SDKs de agente deles, e a aula 13 mostra o formato do próprio MCP para uma ferramenta, que é o mais próximo do da Anthropic: `name`, `description`, `inputSchema`.
