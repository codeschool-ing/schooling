---
title: Do que uma ferramenta é feita
version: 1
---

Uma ferramenta, do jeito que uma API de modelo a entende, são três coisas: um **nome**, uma **descrição** em linguagem comum e um **esquema de entrada**, um JSON Schema que descreve os argumentos. A função que faz o trabalho não faz parte disso. O modelo nunca vê o `shop.py`; ele vê as três coisas e decide, só a partir delas, quando chamar a ferramenta e o que pôr nos argumentos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma definição de ferramenta e seus dois leitores. O nome e a descrição são lidos pelo modelo, que os usa para decidir quando chamar a ferramenta. O esquema de entrada é lido pelos dois: o modelo o usa para montar os argumentos, e o hospedeiro valida cada chamada contra ele. A função em si não é lida por nenhum dos dois; só o hospedeiro a executa.\"><defs><marker id=\"l4contract-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l4contract-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">name</text><text x=\"30\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order</text><rect x=\"20\" y=\"90\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">description</text><text x=\"30\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma frase para o modelo</text><rect x=\"20\" y=\"150\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">input_schema</text><text x=\"30\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON Schema 2020-12</text><rect x=\"500\" y=\"50\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o modelo</text><text x=\"510\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decide quando, e com o quê</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o hospedeiro</text><text x=\"510\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">valida, depois roda o shop.py</text><path d=\"M220 52 L500 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4contract-ah-amber)\"></path><path d=\"M220 112 L500 80\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4contract-ah-amber)\"></path><path d=\"M220 166 L500 90\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4contract-ah-amber)\"></path><path d=\"M220 178 L500 175\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l4contract-ah-phosphor)\"></path><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a função: executada pelo hospedeiro, vista por mais ninguém</text></svg>", "caption": "O esquema é a única parte que os dois lados leem, e é isso que faz dele o lugar de impor o contrato.", "same": ["get_order", "JSON Schema 2020-12"]}
```

Isso faz de uma definição de ferramenta um contrato com dois leitores, e cada um a lê com um propósito:

- **O modelo** lê o nome e a descrição para decidir se esta ferramenta serve para o passo em que está, e o esquema para montar os argumentos. Ele os lê a cada pedido, porque as definições viajam com a conversa.
- **O hospedeiro** lê o esquema para decidir se uma chamada pode passar. Uma chamada que não bate é recusada antes de qualquer coisa rodar.

As ferramentas desta aula estão no `tools.py`: o mesmo `get_order` de antes com um esquema mais rígido, o `find_books` sobre o catálogo, e o `issue_refund`, a primeira ferramenta deste curso que muda alguma coisa.

```schooling-example
{
  "language": "python",
  "file": "tools.py",
  "parts": [
    {
      "code": "\"\"\"Marginalia's tools for the model: each a schema the model reads and a function the host runs.\"\"\"\nimport json\nfrom pathlib import Path\n\nfrom jsonschema import Draft202012Validator\n\nimport shop\n\n"
    },
    {
      "code": "GENRES = sorted({json.loads(line)[\"genre\"] for line in open(\"data/books.jsonl\")})\n\n",
      "note": "**Os gêneros permitidos são lidos dos dados**, então a lista do esquema não tem como se desencontrar do catálogo."
    },
    {
      "code": "TOOLS = [\n    {\"name\": \"get_order\",\n     \"description\": (\"Look up one Marginalia order by its id, which is M- followed by four digits, such as M-1042. \"\n                     \"Returns status, dates, lines and amounts in cents.\"),\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"order_id\"],\n                      \"properties\": {\"order_id\": {\"type\": \"string\", \"pattern\": \"^M-[0-9]{4}$\"}}}},\n",
      "note": "**Três definições no formato da Anthropic**: `name`, `description`, `input_schema`. A seção 07 mostra a mesma ferramenta nos formatos da OpenAI e do Google."
    },
    {
      "code": "    {\"name\": \"find_books\",\n     \"description\": \"List books Marginalia has in stock in one genre, cheapest first, with prices in cents.\",\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"genre\"],\n                      \"properties\": {\"genre\": {\"type\": \"string\", \"enum\": GENRES},\n                                     \"max_results\": {\"type\": \"integer\", \"minimum\": 1, \"maximum\": 10}}}},\n",
      "note": "**Um enum e uma faixa.** O modelo só pode escolher um gênero da lista, e no máximo dez resultados."
    },
    {
      "code": "    {\"name\": \"issue_refund\",\n     \"description\": (\"Refund part or all of an order, in cents. Send the same idempotency_key again to retry \"\n                     \"safely: a key already used returns the first result and refunds nothing more.\"),\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False,\n                      \"required\": [\"order_id\", \"cents\", \"reason\", \"idempotency_key\"],\n                      \"properties\": {\"order_id\": {\"type\": \"string\", \"pattern\": \"^M-[0-9]{4}$\"},\n                                     \"cents\": {\"type\": \"integer\", \"minimum\": 1},\n                                     \"reason\": {\"type\": \"string\", \"minLength\": 3},\n                                     \"idempotency_key\": {\"type\": \"string\", \"minLength\": 8}}}},\n]\n",
      "note": "**Uma escrita, então o esquema pede mais**: um valor em centavos inteiros, um motivo, e uma chave que torna segura uma nova tentativa (seção 09)."
    },
    {
      "code": "VALIDATORS = {t[\"name\"]: Draft202012Validator(t[\"input_schema\"]) for t in TOOLS}\nKEYS = Path(\"data/refund_keys.json\")\n\n\n",
      "note": "**Um validador por ferramenta, montado uma vez**, no dialeto 2020-12 do JSON Schema, que é o que o MCP também supõe (aula 13)."
    },
    {
      "code": "def find_books(genre, max_results=3):\n    books = [shop.get_book(json.loads(line)[\"id\"]) for line in open(\"data/books.jsonl\")]\n    stocked = [b for b in books if b[\"genre\"] == genre and b[\"stock\"] > 0]\n    stocked.sort(key=lambda b: b[\"cents\"])\n    return [{\"id\": b[\"id\"], \"title\": b[\"title\"], \"author\": b[\"author\"], \"cents\": b[\"cents\"]}\n            for b in stocked[:max_results]]\n\n\ndef issue_refund(order_id, cents, reason, idempotency_key):\n    done = json.loads(KEYS.read_text()) if KEYS.exists() else {}\n    if idempotency_key in done:\n        return dict(done[idempotency_key], note=\"already processed with this key; nothing refunded now\")\n    result = shop.refund(order_id, cents, reason, approved_by=\"agent\")\n    done[idempotency_key] = result\n    KEYS.write_text(json.dumps(done))\n    return result\n\n\n",
      "note": "**As funções são Python comum.** Nada nelas sabe que um modelo vai pedi-las."
    },
    {
      "code": "RUN = {\"get_order\": shop.get_order, \"find_books\": find_books, \"issue_refund\": issue_refund}\n\n\n",
      "note": "**A tabela pela qual o hospedeiro despacha.** Um nome que não está nela não é ferramenta."
    },
    {
      "code": "def run_tool(name, args):\n    \"\"\"(text for the model, is_error). Nothing reaches a function before its arguments pass the schema.\"\"\"\n    if name not in RUN:\n        return f\"unknown tool {name!r}; the tools are {', '.join(RUN)}\", True\n    problems = sorted(VALIDATORS[name].iter_errors(args), key=lambda e: list(e.path))\n    if problems:\n        return \"invalid arguments: \" + \"; \".join(\n            f\"{'/'.join(map(str, p.path)) or 'arguments'}: {p.message}\" for p in problems), True\n    try:\n        return json.dumps(RUN[name](**args)), False\n    except (LookupError, ValueError) as e:\n        return f\"{type(e).__name__}: {e}\", True",
      "note": "**O portão**: ferramenta desconhecida, argumentos inválidos, um erro conhecido da função, ou o resultado. A seção 05 o executa."
    }
  ]
}
```

## Nomes

Um nome é um identificador que o modelo escreve de volta, então mantenha-o curto, em `snake_case` e específico: `get_order` e `find_books`, não `orders` e `search`. Duas ferramentas cujos nomes poderiam descrever a mesma ação vão ser confundidas, pelos modelos e pelas pessoas que leem os rastros. Os fornecedores limitam nomes a letras, dígitos, sublinhados e hifens, e a algumas dezenas de caracteres; o hábito seguro é ficar bem dentro dos dois limites.
