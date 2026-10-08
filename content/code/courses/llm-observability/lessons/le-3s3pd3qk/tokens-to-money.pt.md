---
title: De tokens a dinheiro
version: 2
---

Os spans registram tokens. O dinheiro é calculado a partir deles, e **onde** isso é feito é a primeira
decisão. O lugar óbvio é o próprio span: multiplicar na hora, registrar `app.cost = 0.0006`, somar
depois. É o lugar errado, porque preços mudam, e um span escrito com o preço do mês passado não pode
ser corrigido sem ser reescrito.

A tabela de preços é um arquivo. Salve-a como `prices.json` em `~/obs`:

```json
{
  "note": "Written by the course. Ollama charges nothing per token; these are what a hosted provider might charge for each model, chosen so that a week adds up to sums worth reading. Read your own provider's page.",
  "currency": "USD",
  "per": "1000000 tokens",
  "models": {
    "llama3.2:3b": [
      {"from": "2026-01-01", "input": "2.00", "output": "8.00"},
      {"from": "2026-09-30", "input": "1.50", "output": "6.00"}
    ],
    "llama3.2:1b": [{"from": "2026-01-01", "input": "0.50", "output": "2.00"}],
    "all-minilm": [{"from": "2026-01-01", "input": "0.02", "output": "0"}]
  }
}
```

**Esses preços foram escritos pelo curso e nenhum fornecedor os cobra.** O Ollama não cobra nada, e
o curso ainda precisa de uma conta para ler. Eles têm a forma que tabelas de preço reais têm: um
preço por milhão de tokens, diferente para entrada e saída, com a saída quatro vezes a entrada, e um
modelo menor que custa menos. E eles mudam: o `llama3.2:3b` ficou 25% mais barato em 30 de setembro,
a quarta-feira da semana reproduzida.

Então cada modelo tem uma lista de preços, cada um a partir de uma data, e um span é cobrado pelo que
estava em vigor no dia em que rodou. Isso é um **preço com vigência**: um preço novo é uma linha nova, e
o antigo fica para os dias em que valeu. A pergunta "quanto custou a terça" tem a mesma resposta antes
e depois da mudança de preço, o que não aconteceria se alguém sobrescrevesse o número antigo.

```
(Decimal('2.00'), Decimal('8.00')) (Decimal('1.50'), Decimal('6.00'))
```

O `costs.py` faz o resto:

```schooling-example
{
  "language": "python",
  "file": "costs.py",
  "parts": [
    {
      "code": "\"\"\"costs.py: what each request cost, from the tokens on its spans and the price in force when it ran.\n\n    import costs\n    for r in costs.requests():      # one record per trace in spans.jsonl\n        print(r[\"feature\"], r[\"cost\"])\n\nTokens are what the spans record; money is worked out here, at reading time,\nfrom prices.json. A price is effective-dated: each model has a list of prices,\neach from a date, and a span is charged the latest one whose date is not after\nthe moment it ran. Amounts are Decimal, never float.\n\"\"\"\nimport json\nfrom collections import defaultdict\nfrom datetime import datetime\nfrom decimal import Decimal\n\n",
      "note": "Para que serve o arquivo. Os tokens estão nos spans; o dinheiro é calculado aqui, toda vez que alguém o lê."
    },
    {
      "code": "PRICES = json.load(open(\"prices.json\"))\nMILLION = Decimal(1_000_000)\n\n\ndef price_at(model, day):\n    \"\"\"(input, output) in dollars per million tokens for MODEL on DAY, an ISO date.\"\"\"\n    rows = [p for p in PRICES[\"models\"].get(model, []) if p[\"from\"] <= day]\n    if not rows:\n        raise LookupError(f\"no price for {model} on {day}\")\n    p = max(rows, key=lambda p: p[\"from\"])\n    return Decimal(p[\"input\"]), Decimal(p[\"output\"])\n\n\n",
      "note": "A tabela de preços é lida uma vez. O `price_at` escolhe, para um modelo e um dia, o preço mais recente cuja data não é posterior a esse dia, que é o que quer dizer um preço com data de vigência: um preço novo é uma linha nova, e o antigo fica para os dias em que valeu."
    },
    {
      "code": "def span_cost(s):\n    \"\"\"The cost of one span: zero unless it records tokens.\"\"\"\n    a = s[\"attributes\"]\n    if \"gen_ai.usage.input_tokens\" not in a:\n        return Decimal(0)\n    model = a.get(\"gen_ai.response.model\") or a[\"gen_ai.request.model\"]\n    pin, pout = price_at(model, datetime.fromtimestamp(s[\"start\"] / 1e9).date().isoformat())\n    return (a[\"gen_ai.usage.input_tokens\"] * pin + a.get(\"gen_ai.usage.output_tokens\", 0) * pout) / MILLION\n\n\n",
      "note": "Um span com tokens é cobrado pela entrada e pela saída ao preço do dia em que rodou. O `Decimal` guarda todos os dígitos: `0.1 + 0.2` em ponto flutuante não é `0.3`, e uma soma de um milhão de floats pequenos deriva."
    },
    {
      "code": "ROOT = {\"app.feature\": \"feature\", \"app.release\": \"release\", \"app.outcome\": \"outcome\",\n        \"user.hash\": \"user\", \"session.id\": \"session\", \"gen_ai.request.model\": \"model\"}\n\n\ndef requests(path=\"spans.jsonl\"):\n    \"\"\"One record per trace: its root's attributes, when it started, how long it took, its tokens, its cost.\"\"\"\n    by = defaultdict(list)\n    for line in open(path):\n        s = json.loads(line)\n        by[s[\"trace\"]].append(s)\n    out = []\n    for trace, spans in by.items():\n        root = next(s for s in spans if s[\"parent\"] is None)\n        chats = [s for s in spans if s[\"attributes\"].get(\"gen_ai.operation.name\") == \"chat\"]\n        out.append({\"trace\": trace, \"at\": datetime.fromtimestamp(root[\"start\"] / 1e9),\n                    \"ms\": (root[\"end\"] - root[\"start\"]) / 1e6, \"status\": root[\"status\"],\n                    **{short: root[\"attributes\"].get(k) for k, short in ROOT.items()},\n                    \"input\": sum(s[\"attributes\"].get(\"gen_ai.usage.input_tokens\", 0) for s in chats),\n                    \"output\": sum(s[\"attributes\"].get(\"gen_ai.usage.output_tokens\", 0) for s in chats),\n                    \"cost\": sum((span_cost(s) for s in spans), Decimal(0))})\n    return sorted(out, key=lambda r: r[\"at\"])\n",
      "note": "Um registro por trace, com os atributos da raiz sob nomes curtos e os custos de todos os seus spans somados. Os tokens do embedding contam também, ao preço deles."
    }
  ]
}
```

## Um pedido, com preço

```
ana@dev:~/obs$ python -c "import costs; r = next(r for r in costs.requests() if r[\"output\"] and r[\"feature\"] == \"help\"); print(r[\"trace\"], r[\"feature\"], r[\"input\"], r[\"output\"], r[\"cost\"])"
3e9d6efdd66f2552ea1176f2a1bd9a4c help 279 32 0.00081418
ana@dev:~/obs$ python tree.py --attrs 3e9d6efd | grep -E " ms |usage|model"
      0   5,323 ms  ask
                     gen_ai.request.model = "llama3.2:3b"
      0     208 ms    embed
                       gen_ai.request.model = "all-minilm"
                       gen_ai.usage.input_tokens = 9
    208       0 ms    search
    208   5,114 ms    generate
    208   5,114 ms      chat llama3.2:3b
                         gen_ai.request.model = "llama3.2:3b"
                         gen_ai.usage.input_tokens = 279
                         gen_ai.usage.output_tokens = 32
                         gen_ai.response.model = "llama3.2:3b"
  5,323       0 ms    check_citations
```

A primeira pergunta de help da semana a chegar ao modelo, às 7h34 da segunda. 279 tokens de entrada
e 32 de saída ao preço de antes de quarta: 279 × 2,00 mais 32 × 8,00, dividido por um milhão, dá
0,000814 dólar, e os 9 tokens do embedding a 0,02 somam 0,00000018. O total é 0,00081418 dólar,
impresso até o último dígito porque um `Decimal` guarda todos.

Repare onde estavam os tokens. **A entrada é 90% dos tokens e 69% do custo**, embora cada token de
saída custe quatro vezes mais. Essa é a forma de um assistente com recuperação: um prompt longo de
instruções e fontes, uma resposta curta. Ela decide qual alavanca vale puxar: um prompt mais curto
economiza mais que uma resposta mais curta, o contrário do que a latência da aula 1 sugeria, onde a
resposta era a maior parte do tempo.