---
title: Uma ferramenta em três protocolos
version: 2
---

Todo grande fornecedor aceita chamadas de ferramenta, e cada um as escreve de um jeito. O `wires.py` define uma ferramenta, faz uma pergunta e a manda de três jeitos para o mesmo `llama3.2:3b`: pelo SDK da Anthropic, pelo da OpenAI, e para o `/api/chat` do próprio Ollama só com a biblioteca padrão. O Ollama responde a cada um no formato daquela API, então as três respostas só diferem no embrulho.

```python
"""One tool, one question, three wire formats: Anthropic's, OpenAI's and Ollama's own."""
import json
import os
import urllib.request

import anthropic
import openai

NAME, DESCRIPTION = "get_order", "Look up one Marginalia order by its id, such as M-1042."
SCHEMA = {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}
QUESTION = "Where is order M-1043?"

a = anthropic.Anthropic().messages.create(
    model="llama3.2:3b", max_tokens=200, messages=[{"role": "user", "content": QUESTION}],
    tools=[{"name": NAME, "description": DESCRIPTION, "input_schema": SCHEMA}])
call = next(b for b in a.content if b.type == "tool_use")
print("anthropic ", a.stop_reason, call.name, json.dumps(call.input), call.id)

o = openai.OpenAI().chat.completions.create(
    model="llama3.2:3b", messages=[{"role": "user", "content": QUESTION}],
    tools=[{"type": "function", "function": {"name": NAME, "description": DESCRIPTION, "parameters": SCHEMA}}])
call = o.choices[0].message.tool_calls[0]
print("openai    ", o.choices[0].finish_reason, call.function.name, call.function.arguments, call.id)

body = {"model": "llama3.2:3b", "stream": False, "messages": [{"role": "user", "content": QUESTION}],
        "tools": [{"type": "function", "function": {"name": NAME, "description": DESCRIPTION, "parameters": SCHEMA}}]}
req = urllib.request.Request(os.environ["OLLAMA_API_BASE"] + "/api/chat", json.dumps(body).encode(),
                             {"Content-Type": "application/json"})
n = json.load(urllib.request.urlopen(req))
call = n["message"]["tool_calls"][0]
print("ollama    ", n["done_reason"], call["function"]["name"], json.dumps(call["function"]["arguments"]), call.get("id"))
```

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435 OPENAI_BASE_URL=http://127.0.0.1:11435/v1 OLLAMA_API_BASE=http://127.0.0.1:11435
ana@lab:~/agents$ python wires.py
anthropic  tool_use get_order {"order_id": "M-1043"} call_oeyqxw0z
openai     tool_calls get_order {"order_id":"M-1043"} call_em8p21jq
ollama     stop get_order {"order_id": "M-1043"} call_yvigs7hi
ana@lab:~/agents$ python -c 'import json; [print(r["path"].ljust(22), json.dumps(r["request"]["tools"])[:118]) for r in map(json.loads, open("requests.jsonl"))]'
/v1/messages           [{"name": "get_order", "description": "Look up one Marginalia order by its id, such as M-1042.", "input_schema": {"typ
/v1/chat/completions   [{"type": "function", "function": {"name": "get_order", "description": "Look up one Marginalia order by its id, such a
/api/chat              [{"type": "function", "function": {"name": "get_order", "description": "Look up one Marginalia order by its id, such a
```

Com o gravador da aula 1 na frente dos três, o primeiro comando mostra o que cada resposta trouxe e o segundo mostra como cada pedido pôs a mesma definição no fio. A ferramenta é idêntica nos três, um nome, uma descrição e um JSON Schema, e só o embrulho muda. A API Gemini do Google é a quarta coluna da tabela e não foi rodada aqui, porque nada nesta máquina a fala; o formato dela vem da documentação do Google:

| | Anthropic Messages | OpenAI Chat Completions | Ollama `/api/chat` | Google Gemini (não rodado) |
|---|---|---|---|---|
| ferramentas no pedido | `tools: [{name, description, input_schema}]` | `tools: [{type: "function", function: {name, description, parameters}}]` | igual ao da OpenAI | `tools: [{functionDeclarations: [{name, description, parametersJsonSchema}]}]` |
| a chamada na resposta | um bloco de conteúdo `tool_use` com `id`, `name`, `input` | `message.tool_calls[]` com `id`, `function.name`, `function.arguments` como **string** JSON | `message.tool_calls[]` com `function.arguments` como **objeto** | uma parte `functionCall` com `id`, `name`, `args` |
| por que a resposta parou | `stop_reason: "tool_use"` | `finish_reason: "tool_calls"` | `done_reason: "stop"`; a chamada está na mensagem | `finishReason: "STOP"`; a chamada está nas partes |
| o resultado de volta | um bloco `tool_result` numa mensagem de usuário, com `tool_use_id` | uma mensagem com role `tool` e `tool_call_id` | uma mensagem com role `tool` | uma parte `functionResponse` com o `name` e o `id` da chamada |

Dois detalhes dessa tabela causam bugs reais. **Os argumentos da OpenAI chegam como string de JSON**, não como objeto, então o programa precisa interpretá-los, e um modelo pode produzir uma string que não se interpreta; a linha openai acima imprime essa string como ela chegou. **Dois dos quatro motivos de término não dizem que uma ferramenta foi chamada**: a API do próprio Ollama termina uma resposta com chamada como `stop`, e a do Gemini como `STOP`, igual a uma resposta com a resposta final. Um laço que confere o motivo de término, como o `agent.py` confere o `stop_reason`, nunca roda as ferramentas deles; ele precisa procurar as próprias chamadas. A linha ollama acima mostra isso: `stop`, e uma chamada.

## Por que o curso escreve a maioria dos laços para um protocolo

As aulas 5 a 7 usam o formato da Anthropic, porque os exemplos do curso precisam de um formato só e este mantém a chamada e o resultado em dois blocos com nomes claros. Nada do que elas ensinam depende disso: o portão de validação, os erros, os limites e o rastro funcionam igual nos três. O SDK da aula 8 usa a Responses API da OpenAI, o da aula 10 chega ao `/api/chat` do próprio Ollama pelo LiteLLM, e a aula 13 mostra o formato do próprio MCP para uma ferramenta, que é o mais próximo do da Anthropic: `name`, `description`, `inputSchema`.
