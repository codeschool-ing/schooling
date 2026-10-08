---
title: O mesmo laço com chamadas nativas
version: 2
---

O `react_native.py` responde à mesma pergunta com a chamada de ferramentas do próprio fornecedor. O prompt de sistema pede uma frase de raciocínio antes de cada chamada, então todo passo traz um pensamento e uma ação, como no ReAct; o que muda é a forma em que eles chegam. Ele também registra cada passo no `trace.jsonl`, que a seção 06 lê, e recusa uma chamada que já fez, coisa de que a seção 08 precisa.

```schooling-example
{
  "language": "python",
  "file": "react_native.py",
  "parts": [
    {
      "code": "\"\"\"ReAct with native tool calls: the thought is a text block, the action a tool_use block.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "TOOLS = [\n    {\"name\": \"get_order\",\n     \"description\": \"Look up one Marginalia order by its id, such as M-1042: status, dates, lines and amounts in cents.\",\n     \"input_schema\": {\"type\": \"object\", \"properties\": {\"order_id\": {\"type\": \"string\"}}, \"required\": [\"order_id\"]}},\n    {\"name\": \"search_help\",\n     \"description\": \"Search Marginalia's help centre by meaning and return the three closest articles.\",\n     \"input_schema\": {\"type\": \"object\", \"properties\": {\"query\": {\"type\": \"string\"}}, \"required\": [\"query\"]}},\n]\nRUN = {\n    \"get_order\": lambda args: shop.get_order(args[\"order_id\"]),\n    \"search_help\": lambda args: [{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(args[\"query\"])],\n}\n",
      "note": "**As ferramentas em JSON Schema**, as mesmas duas da aula 1. O modelo recebe essas definições a cada pedido."
    },
    {
      "code": "SYSTEM = (\"You answer Marginalia's customers. Before each tool call, say in one sentence what you know \"\n          \"and what you need next. Never guess an order's details.\")\n\nclient = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**A metade ReAct do prompt**: uma frase de raciocínio antes de cada chamada. Nenhum formato a seguir, nenhuma linha a imitar."
    },
    {
      "code": "seen = set()\n",
      "note": "**Chamadas já feitas**, como nome e argumentos canônicos. A seção 08 usa isto."
    },
    {
      "code": "with open(\"trace.jsonl\", \"w\") as trace:\n    for step in range(1, 7):\n        reply = client.messages.create(model=\"llama3.2:3b\", max_tokens=1024, system=SYSTEM,\n                                       tools=TOOLS, messages=messages)\n        messages.append({\"role\": \"assistant\", \"content\": reply.content})\n",
      "note": "**Um arquivo de rastro, uma linha JSON por passo**, escrito durante a execução. A seção 06 o lê."
    },
    {
      "code": "        record = {\"step\": step, \"stop_reason\": reply.stop_reason, \"input_tokens\": reply.usage.input_tokens + (reply.usage.cache_read_input_tokens or 0),\n                  \"text\": \" \".join(b.text for b in reply.content if b.type == \"text\"), \"calls\": []}\n        results = []\n        for block in reply.content:\n            if block.type != \"tool_use\":\n                continue\n",
      "note": "**O que vale registrar de um passo**: por que parou, o tamanho do pedido, o que o modelo disse e o que chamou."
    },
    {
      "code": "            call = (block.name, json.dumps(block.input, sort_keys=True))\n            if call in seen:\n                record[\"calls\"].append({\"tool\": block.name, \"input\": block.input, \"refused\": \"repeat\"})\n                trace.write(json.dumps(record) + \"\\n\")\n                print(f\"host: step {step} repeats {block.name}({json.dumps(block.input)}); stopping\")\n                sys.exit(1)\n            seen.add(call)\n",
      "note": "**A guarda contra repetição.** A mesma chamada com os mesmos argumentos duas vezes numa execução encerra a execução."
    },
    {
      "code": "            output = json.dumps(RUN[block.name](block.input))\n            record[\"calls\"].append({\"tool\": block.name, \"input\": block.input, \"output\": output[:80]})\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": block.id, \"content\": output})\n        trace.write(json.dumps(record) + \"\\n\")\n        if reply.stop_reason != \"tool_use\":\n            print(record[\"text\"])\n            break\n        messages.append({\"role\": \"user\", \"content\": results})",
      "note": "**Rodar a ferramenta e devolver o resultado**, ligado à chamada pelo `tool_use_id`."
    }
  ]
}
```

```
ana@lab:~/agents$ python react_native.py "Can I still return the books in order M-1047, and how would the refund work?"
To return the books in order M-1047, you have 30 days from delivery to return the printed books in the condition they were received. To initiate the return, start by going to the order in your account, print the prepaid label, and then drop the parcel at any post office. Refunds for returned printed books will be issued in the original payment method. If you have any issues or concerns about the return process, please contact our customer service team for assistance.
```

Nenhuma expressão regular, nenhuma observação inventada, nenhum argumento na forma errada: a chamada chegou como um bloco `tool_use` com os argumentos em campos, e o programa a rodou. A resposta fala de devoluções em geral e está certa até onde vai. Ela não diz se o próprio M-1047 ainda pode voltar, porque o modelo buscou na central de ajuda e nunca consultou o pedido. É de novo o limite da aula 1, uma ferramenta e depois uma resposta, e a seção 06 o lê no rastro. Compare um passo de cada estilo:

| | ReAct em texto | chamadas nativas |
|---|---|---|
| o pensamento | uma linha `Thought:` | um bloco de texto |
| a ação | `Action: get_order[M-1047]`, interpretada pelo programa | um bloco `tool_use`: `{"order_id": "M-1047"}` |
| onde os argumentos são conferidos | em lugar nenhum, a não ser que o parser confira | contra o esquema que o pedido declarou |
| quem escreve a observação | o programa, se a sequência de parada segurar | o programa, sempre: a resposta acaba na chamada |
| como um resultado acha a sua chamada | pela posição na transcrição | pelo `tool_use_id`, igual ao `id` da chamada |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma chamada nativa de ferramenta e o resultado dela. A resposta do modelo tem um bloco de texto, o pensamento, e um bloco tool_use com um id, o nome da ferramenta e a entrada estruturada. A mensagem seguinte do programa tem um bloco tool_result que cita o mesmo id e traz a saída. É o id, não a posição, que liga o resultado à chamada.\"><defs><marker id=\"l3ids-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"320\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a resposta do modelo (role: assistant)</text><rect x=\"36\" y=\"52\" width=\"288\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"69.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">text</text><text x=\"46\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o pensamento, em palavras</text><rect x=\"36\" y=\"116\" width=\"288\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tool_use</text><text x=\"46\" y=\"151.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id: toolu_…</text><text x=\"46\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order, order_id = M-1047</text><rect x=\"380\" y=\"70\" width=\"320\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"392\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a próxima mensagem do programa (role: user)</text><rect x=\"396\" y=\"104\" width=\"288\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"406\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tool_result</text><text x=\"406\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tool_use_id: toolu_…</text><text x=\"406\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">content: o pedido, em JSON</text><path d=\"M324 150 L396 144\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l3ids-ah-phosphor)\"></path></svg>", "caption": "Dois blocos na ida, um bloco na volta, ligados por um id.", "same": ["id: toolu_…", "tool_use_id: toolu_…", "get_order, order_id = M-1047"]}
```

A última linha importa mais do que parece. Uma resposta pode trazer vários blocos `tool_use` de uma vez, e os resultados voltam como vários blocos `tool_result` numa mensagem. **É o id que os emparelha, não a posição**; a API recusa uma conversa em que uma chamada não tem resultado com o seu id, o que a aula 4 mostra acontecendo.

Chamadas nativas não dispensam o pensamento. Um modelo a quem se pede para dizer o que sabe antes de agir tende a escolher passos melhores, que é o resultado do artigo; a diferença é que o pensamento agora é um enfeite opcional numa chamada estruturada, e não o texto de que um parser depende. Opcional é a palavra: pediram ao `llama3.2:3b` uma frase antes de cada chamada, ele não escreveu nenhuma, e a chamada veio mesmo assim.
