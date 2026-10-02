---
title: O laço em código
version: 1
---

O host é curto. Ele se conecta ao servidor MCP da loja (aula 7 seção 06), transforma as ferramentas
que o servidor lista nas definições de ferramenta que a API do modelo espera, e roda o laço com um
limite de passos. Toda decisão do modelo nesta aula foi escrita pelo curso, como regras no
`scripted-1`; o host, o servidor e todo resultado de ferramenta são reais.

```schooling-example
{
  "language": "python",
  "file": "agent.py",
  "parts": [
    {
      "code": "\"\"\"A host: it starts the shop's MCP server, offers its tools to the model, and runs the loop.\"\"\"\nimport asyncio\nimport json\nimport sys\n\nimport anthropic\nfrom mcp import Client, StdioServerParameters\n\n"
    },
    {
      "code": "MAX_STEPS = 5\nmodel = anthropic.Anthropic()\n\n\n",
      "note": "**As guardas são constantes no host**, onde o modelo não consegue mudá-las."
    },
    {
      "code": "def approve(name, args):\n    answer = input(f\"allow {name}({json.dumps(args)})? [y/N] \")\n    print(answer)\n    return answer.strip().lower() == \"y\"\n\n\n",
      "note": "**Uma pessoa aprova uma chamada que muda algo**, vendo os argumentos exatos."
    },
    {
      "code": "async def run(question):\n    async with Client(StdioServerParameters(command=\"python\", args=[\"mcp_shop.py\"])) as shop:\n        listed = (await shop.list_tools()).tools\n        tools = [{\"name\": t.name, \"description\": t.description, \"input_schema\": t.input_schema} for t in listed]\n        read_only = {t.name for t in listed if t.annotations and t.annotations.read_only_hint}\n        messages = [{\"role\": \"user\", \"content\": question}]\n        seen = set()\n",
      "note": "**As ferramentas do servidor viram as ferramentas do modelo.** Nomes, descrições e esquemas vêm do `tools/list`, e o host guarda quais dizem que só leem."
    },
    {
      "code": "        for step in range(1, MAX_STEPS + 1):\n            r = model.messages.create(model=\"scripted-1\", max_tokens=500, tools=tools, messages=messages)\n            messages.append({\"role\": \"assistant\", \"content\": [b.model_dump(exclude_none=True) for b in r.content]})\n            for b in r.content:\n                if b.type == \"text\":\n                    print(f\"[{step}] model:  {b.text}\")\n            if r.stop_reason != \"tool_use\":\n                return\n",
      "note": "**Um passo é uma requisição**: o modelo vê tudo até ali e responde ou pede ferramentas. Sem `tool_use` quer dizer que respondeu, e o laço termina."
    },
    {
      "code": "            results = []\n            for b in r.content:\n                if b.type != \"tool_use\":\n                    continue\n                print(f\"[{step}] call:   {b.name}({json.dumps(b.input)})\")\n                call = (b.name, json.dumps(b.input, sort_keys=True))\n                if call in seen:\n                    print(f\"[{step}] host:   the same call twice in one task; stopping\")\n                    return\n                seen.add(call)\n                if b.name not in read_only and not approve(b.name, b.input):\n                    text, error = \"refused by the operator\", True\n                else:\n                    result = await shop.call_tool(b.name, b.input)\n                    text, error = result.content[0].text, result.is_error\n                print(f\"[{step}] result: {' '.join(text.split())[:72]}\")\n                results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": text, \"is_error\": error})\n            messages.append({\"role\": \"user\", \"content\": results})\n",
      "note": "**Cada chamada passa pelas guardas**: recusada se repetida, segurada para aprovação se muda algo, senão feita pelo MCP. O resultado, erro ou não, volta ao modelo."
    },
    {
      "code": "        print(f\"host: stopped after {MAX_STEPS} steps without an answer\")\n\n\n",
      "note": "**Esgotar os passos é informado**, não escondido atrás de uma resposta inventada."
    },
    {
      "code": "asyncio.run(run(sys.argv[1]))"
    }
  ]
}
```

## Uma pergunta que precisa de duas ferramentas

```
ana@dev:~/shop$ python agent.py "Can the customer of order 1042 still return it?"
[1] model:  I will look up the order first.
[1] call:   get_order({"order_id": "1042"})
[1] result: { "status": "delivered", "delivered_on": "2026-09-28", "lines": [ { "sku
[2] call:   read_handbook({"name": "returns"})
[2] result: # Returns and refunds A customer may return any item within 30 days of d
[3] model:  Yes. Order 1042 was delivered on 28 September 2026, and the handbook allows a return within 30 days of delivery, so the customer has until 28 October 2026. The two mugs must be unused and in their original packaging.
```

Três passos. **Passo 1**: o modelo anuncia um plano e pede o pedido. **Passo 2**: com a data de
entrega na conversa, pede a página de devoluções. **Passo 3**: com as duas, responde, e o
`stop_reason` deixa de ser `tool_use`, então o laço termina.

Leia a resposta contra os resultados das ferramentas. A data de entrega, 28 de setembro, veio do
`get_order`; os 30 dias vieram do `read_handbook`; a conclusão, 28 de outubro, é conta feita com os
dois. **Todo fato da resposta tem um resultado de ferramenta por trás**, e é isso que torna a resposta
de um agente conferível do mesmo jeito que a aula 6 seção 08 conferiu citações.

## O que o código faz e o modelo não consegue

- **Ele para.** O `MAX_STEPS` é um limite rígido, imposto por um laço `for` e não pedido num prompt.
- **Ele recusa repetições.** A mesma chamada duas vezes na mesma tarefa quase sempre é um laço de que
  o modelo não sai sozinho; a aula 7 seção 09 mostra um.
- **Ele pergunta antes de agir.** Uma ferramenta não marcada como só leitura não é chamada até uma
  pessoa dizer sim; a aula 7 seção 08 mostra as duas respostas.
- **Ele informa erros como resultados.** Uma ferramenta que falha devolve `is_error` ao modelo, que
  pode tentar outra coisa, em vez de derrubar o host.
