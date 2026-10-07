---
title: Uma chamada, ida e volta
version: 2
---

A aula 7 usou ferramentas dentro de um agente, com o MCP no meio. Esta aula tira o protocolo e olha
para a troca da qual todo o resto é feito: **o modelo pede uma função, o seu código a roda, e o
resultado volta como parte da conversa**. Toda resposta nesta aula é do `llama3.2:3b`, a
temperatura 0.

## A ferramenta, como o modelo a vê

A loja guarda o estoque em `data/stock.json`, ao lado dos pedidos da aula 7:

```json
{
  "MUG-01": {"in_stock": 37, "unit_price": 3990},
  "LAMP-02": {"in_stock": 4, "unit_price": 21000},
  "GLASS-03": {"in_stock": 0, "unit_price": 2490}
}
```

e as ferramentas num módulo, `shop_tools.py`. Uma ferramenta são três coisas na requisição: um
`name`, uma `description` e um `input_schema`, que é um JSON Schema dos argumentos. **O modelo nunca
vê a sua função.** Ele vê a definição em `TOOLS`, e decide só pela descrição se a ferramenta serve
para a pergunta:

```schooling-example
{
  "language": "python",
  "file": "shop_tools.py",
  "parts": [
    {
      "code": "\"\"\"The shop's tools: what the model may ask for, and the code that does it.\"\"\"\nimport json\nfrom datetime import date\nfrom pathlib import Path\n\n"
    },
    {
      "code": "TODAY = date(2026, 10, 2)  # fixed, so the lesson's output does not move\nREASONS = [\"changed_mind\", \"wrong_item\", \"damaged\", \"faulty\"]\n\n",
      "note": "**O \"hoje\" da loja é fixo**, 2 de outubro de 2026, para o prazo de 30 dias dar a mesma resposta em toda rodada desta aula. Uma loja de verdade lê o relógio."
    },
    {
      "code": "TOOLS = [\n    {\n        \"name\": \"get_stock\",\n        \"description\": \"Units in stock and unit price in cents for one product, by its SKU.\",\n        \"input_schema\": {\n            \"type\": \"object\",\n            \"properties\": {\"sku\": {\"type\": \"string\", \"description\": \"The product's SKU, such as MUG-01.\"}},\n            \"required\": [\"sku\"],\n        },\n    },\n    {\n        \"name\": \"create_return\",\n        \"description\": \"Open a return for units of one line of a delivered order. \"\n                       \"Use it only when the customer has asked to return something.\",\n        \"input_schema\": {\n            \"type\": \"object\",\n            \"properties\": {\n                \"order_id\": {\"type\": \"string\", \"pattern\": \"^[0-9]{4}$\", \"description\": \"Such as 1042.\"},\n                \"sku\": {\"type\": \"string\", \"description\": \"The SKU as it appears on the order line.\"},\n                \"quantity\": {\"type\": \"integer\", \"minimum\": 1},\n                \"reason\": {\"type\": \"string\", \"enum\": REASONS},\n            },\n            \"required\": [\"order_id\", \"sku\", \"quantity\", \"reason\"],\n            \"additionalProperties\": False,\n        },\n    },\n]\n\n\n",
      "note": "**O que viaja até o modelo**: para cada ferramenta um `name`, uma `description` e um `input_schema`, um JSON Schema dos argumentos. O do `create_return` é rígido de propósito, e a aula 8 seção 03 o lê palavra-chave por palavra-chave."
    },
    {
      "code": "class ShopError(Exception):\n    \"\"\"A request the shop refuses. The message is written for the model to read.\"\"\"\n\n\n",
      "note": "**As recusas da loja têm um tipo próprio**, com mensagens escritas para o modelo ler."
    },
    {
      "code": "def get_stock(sku):\n    stock = json.loads(Path(\"data/stock.json\").read_text())\n    if sku not in stock:\n        raise ShopError(f\"no product {sku}; SKUs look like MUG-01\")\n    return stock[sku]\n\n\n",
      "note": "**A função por trás do `get_stock`** é Python comum. O modelo nunca a vê."
    },
    {
      "code": "def create_return(order_id, sku, quantity, reason):\n    orders = json.loads(Path(\"data/orders.json\").read_text())\n    order = orders.get(order_id)\n    if order is None:\n        raise ShopError(f\"no order {order_id}\")\n    if order[\"status\"] != \"delivered\":\n        raise ShopError(f\"order {order_id} is {order['status']}, not delivered; it cannot be returned yet\")\n    days = (TODAY - date.fromisoformat(order[\"delivered_on\"])).days\n    if days > 30:\n        raise ShopError(f\"order {order_id} was delivered {days} days ago; returns close after 30\")\n    bought = sum(line[\"quantity\"] for line in order[\"lines\"] if line[\"sku\"] == sku)\n    path = Path(\"data/returns.json\")\n    returns = json.loads(path.read_text()) if path.exists() else []\n    taken = sum(r[\"quantity\"] for r in returns if r[\"order_id\"] == order_id and r[\"sku\"] == sku)\n    if quantity > bought - taken:\n        raise ShopError(f\"order {order_id} has {bought - taken} of {sku} left to return, not {quantity}\")\n    record = {\"id\": f\"R-{order_id}-{len(returns) + 1}\", \"order_id\": order_id, \"sku\": sku,\n              \"quantity\": quantity, \"reason\": reason}\n    path.write_text(json.dumps(returns + [record], indent=1) + \"\\n\")\n    return record\n\n\n",
      "note": "**A função por trás do `create_return`** confere o que um esquema não consegue: que o pedido existe, foi entregue, está dentro dos 30 dias e tem essas unidades ainda para devolver."
    },
    {
      "code": "FUNCTIONS = {\"get_stock\": get_stock, \"create_return\": create_return}\n",
      "note": "**O host procura os nomes aqui**, e um nome fora desta tabela não roda nada."
    }
  ]
}
```

## O laço que imprime tudo

```schooling-example
{
  "language": "python",
  "file": "stock.py",
  "parts": [
    {
      "code": "\"\"\"One question, with tools: every request and reply of the round trip, printed.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\n"
    },
    {
      "code": "from shop_tools import FUNCTIONS, TOOLS\n\nmodel = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**As ferramentas vêm de um módulo**, junto com as funções que fazem o trabalho."
    },
    {
      "code": "while True:\n    r = model.messages.create(model=\"llama3.2:3b\", max_tokens=300, tools=TOOLS, messages=messages, extra_body={\"temperature\": 0})\n    print(\"<- stop_reason:\", r.stop_reason)\n    for b in r.content:\n        print(\"  \", json.dumps(b.model_dump(exclude_none=True)))\n",
      "note": "**Uma requisição por vez**, levando as ferramentas e a conversa inteira até ali. Cada bloco da resposta é impresso como chegou."
    },
    {
      "code": "    messages.append({\"role\": \"assistant\", \"content\": r.content})\n    if r.stop_reason != \"tool_use\":\n        break\n",
      "note": "**A resposta entra na conversa como veio**, e uma resposta que não pede ferramenta é a resposta final."
    },
    {
      "code": "    results = []\n    for b in r.content:\n        if b.type == \"tool_use\":\n            out = FUNCTIONS[b.name](**b.input)\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": json.dumps(out)})\n",
      "note": "**Só aqui algo roda.** O modelo deu o nome de uma função e os argumentos; o host procura o nome na própria tabela e chama."
    },
    {
      "code": "    print(\"-> user:\")\n    for x in results:\n        print(\"  \", json.dumps(x))\n    messages.append({\"role\": \"user\", \"content\": results})\n",
      "note": "**Todos os resultados voltam numa só mensagem de usuário**, cada um ligado à sua chamada pelo `tool_use_id`."
    }
  ]
}
```

## O que passou pelo fio

```
ana@dev:~/shop$ python stock.py "Is LAMP-02 in stock?"
<- stop_reason: tool_use
   {"id": "call_lz7psgft", "input": {"sku": "LAMP-02"}, "name": "get_stock", "type": "tool_use"}
-> user:
   {"type": "tool_result", "tool_use_id": "call_lz7psgft", "content": "{\"in_stock\": 4, \"unit_price\": 21000}"}
<- stop_reason: end_turn
   {"text": "The LAMP-02 is currently in stock. It has 4 units available, and the unit price is $21,000.", "type": "text"}
```

Leia de cima para baixo. **A primeira resposta não é uma resposta.** O `stop_reason` dela é
`tool_use`, e o conteúdo é um bloco com o nome da ferramenta e os argumentos, com um `id` que a API
atribuiu: `call_lz7psgft`. Os ids do Ollama começam com `call_` e os da Anthropic com `toolu_`;
ninguém os lê além do host. O modelo parou e está esperando.

**A resposta do host é uma mensagem `user`**, porque uma conversa alterna entre dois papéis e a
saída da ferramenta fica do lado do usuário. Ela leva um `tool_result` cujo `tool_use_id` é aquele
mesmo id. O id é a ligação: com duas chamadas em andamento, ele diz qual resultado responde a qual.

A segunda resposta é texto, e o `stop_reason` é `end_turn`. Ela diz que a luminária custa
**$21,000**. A ferramenta devolveu `21000`, e a descrição dela diz *in cents*: a luminária custa
210,00. O modelo leu o número e não a descrição, pôs nele um cifrão de dólar que esta loja nunca usa,
e errou por um fator de cem. **Essa conversão é do modelo, não do seu código**, e por isso pode estar
errada enquanto todo o resto da troca está certo; a aula 8 seção 07 volta ao que isso quer dizer
quando o número importa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A ida e volta de uma chamada de ferramenta. O host manda a pergunta e as definições de ferramentas. O modelo responde com um bloco tool_use com um id e para. O host roda a função e manda um tool_result com o mesmo id. O modelo responde com a resposta e end_turn.\"><defs><marker id=\"rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><path d=\"M110 48 L110 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"275\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">seu código (o host)</text><path d=\"M370 48 L370 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"525\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a função</text><path d=\"M620 48 L620 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M366 74 L114 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pergunta + definições de ferramentas</text><path d=\"M114 114 L366 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tool_use  id=call_…  get_stock {&quot;sku&quot;: &quot;LAMP-02&quot;}</text><path d=\"M374 154 L616 154\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"495.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get_stock(sku=&quot;LAMP-02&quot;)</text><path d=\"M616 194 L374 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"495.0\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{&quot;in_stock&quot;: 4, &quot;unit_price&quot;: 21000}</text><path d=\"M366 234 L114 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tool_result  tool_use_id=call_…</text><path d=\"M114 274 L366 274\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a resposta, end_turn</text></svg>", "caption": "O modelo propõe uma chamada e espera. Só o host roda algo, e o id liga cada resultado à sua chamada."}
```

## Três coisas que isto mostra

- **O modelo só propõe.** Nada rodou até o host procurar o nome em `FUNCTIONS` e chamar a função. Um modelo que
  pede uma ferramenta que você nunca ligou não recebe nada, e esse é o modelo de segurança inteiro
  da chamada de funções numa linha.
- **A conversa é o estado.** A segunda requisição leva a pergunta, a chamada e o resultado. Tire
  qualquer um e o modelo está respondendo a outra conversa.
- **Cada passo é uma requisição completa.** Duas idas e voltas custam duas requisições, cada uma
  cobrada por tudo o que leva, que é a conta da aula 2 aplicada a ferramentas.
