---
title: De tokens a dinheiro
version: 1
---

Os spans registram tokens. O dinheiro é calculado a partir deles, e **onde** isso é feito é a primeira
decisão. O lugar óbvio é o próprio span: multiplicar na hora, registrar `app.cost = 0.0006`, somar
depois. É o lugar errado, porque preços mudam, e um span escrito com o preço do mês passado não pode
ser corrigido sem ser reescrito.

A tabela de preços do laboratório é um arquivo:

```
ana@lab:~/obs$ cat prices.json
{
  "note": "Written by the course for the lab. No provider charges these prices; read your own provider's page.",
  "currency": "USD",
  "per": "1000000 tokens",
  "models": {
    "extract-1": [
      {"from": "2026-01-01", "input": "2.00", "output": "8.00"},
      {"from": "2026-10-01", "input": "1.50", "output": "6.00"}
    ],
    "extract-2": [{"from": "2026-09-15", "input": "3.00", "output": "12.00"}],
    "judge-1": [{"from": "2026-01-01", "input": "0.40", "output": "1.60"}],
    "lab-minilm": [{"from": "2026-01-01", "input": "0.02", "output": "0"}]
  }
}
```

**Esses preços foram escritos pelo curso e nenhum fornecedor os cobra.** Eles têm a forma que tabelas
de preço reais têm: um preço por milhão de tokens, diferente para entrada e saída, com a saída quatro
vezes a entrada, e um modelo mais barato para julgar. E eles mudam: o extract-1 ficou 25% mais barato
em 1º de outubro, a quinta-feira da semana reproduzida.

Então cada modelo tem uma lista de preços, cada um a partir de uma data, e um span é cobrado pelo que
estava em vigor no dia em que rodou. Isso é um **preço com vigência**: um preço novo é uma linha nova, e
o antigo fica para os dias em que valeu. A pergunta "quanto custou a terça" tem a mesma resposta antes
e depois da mudança de preço, o que não aconteceria se alguém sobrescrevesse o número antigo.

```
ana@lab:~/obs$ python -c "import costs; print(costs.price_at(\"extract-1\", \"2026-09-30\"), costs.price_at(\"extract-1\", \"2026-10-01\"))"
(Decimal('2.00'), Decimal('8.00')) (Decimal('1.50'), Decimal('6.00'))
```

O `costs.py` faz o resto:

```schooling-example
{
  "language": "python",
  "file": "costs.py",
  "parts": [
    {
      "code": "PRICES = json.load(open(\"prices.json\"))\nMILLION = Decimal(1_000_000)\n\n\ndef price_at(model, day):\n    \"\"\"(input, output) in dollars per million tokens for MODEL on DAY, an ISO date.\"\"\"\n    rows = [p for p in PRICES[\"models\"].get(model, []) if p[\"from\"] <= day]\n    if not rows:\n        raise LookupError(f\"no price for {model} on {day}\")\n    p = max(rows, key=lambda p: p[\"from\"])\n    return Decimal(p[\"input\"]), Decimal(p[\"output\"])",
      "note": "A lista de preços é lida uma vez. `price_at` escolhe, para um modelo e um dia, o preço mais recente cuja data não é posterior a esse dia, que é o que significa um preço com vigência: um preço novo é uma linha nova, e o antigo fica para os dias em que valeu."
    },
    {
      "code": "def span_cost(s):\n    \"\"\"The cost of one span: zero unless it records tokens.\"\"\"\n    a = s[\"attributes\"]\n    if \"gen_ai.usage.input_tokens\" not in a:\n        return Decimal(0)\n    model = a.get(\"gen_ai.response.model\") or a[\"gen_ai.request.model\"]\n    pin, pout = price_at(model, datetime.fromtimestamp(s[\"start\"] / 1e9).date().isoformat())\n    return (a[\"gen_ai.usage.input_tokens\"] * pin + a.get(\"gen_ai.usage.output_tokens\", 0) * pout) / MILLION",
      "note": "Um span com tokens é cobrado pela entrada e pela saída ao preço do dia em que rodou. `Decimal` guarda todos os dígitos: `0.1 + 0.2` em ponto flutuante não é `0.3`, e uma soma de um milhão de floats pequenos se desvia."
    },
    {
      "code": "ROOT = {\"app.feature\": \"feature\", \"app.release\": \"release\", \"app.outcome\": \"outcome\",\n        \"user.hash\": \"user\", \"session.id\": \"session\", \"gen_ai.request.model\": \"model\"}\n\n\ndef requests(path=\"spans.jsonl\"):\n    \"\"\"One record per trace: its root's attributes, when it started, how long it took, its tokens, its cost.\"\"\"\n    by = defaultdict(list)\n    for line in open(path):\n        s = json.loads(line)\n        by[s[\"trace\"]].append(s)\n    out = []\n    for trace, spans in by.items():\n        root = next(s for s in spans if s[\"parent\"] is None)\n        chats = [s for s in spans if s[\"attributes\"].get(\"gen_ai.operation.name\") == \"chat\"]\n        out.append({\"trace\": trace, \"at\": datetime.fromtimestamp(root[\"start\"] / 1e9),\n                    \"ms\": (root[\"end\"] - root[\"start\"]) / 1e6, \"status\": root[\"status\"],\n                    **{short: root[\"attributes\"].get(k) for k, short in ROOT.items()},\n                    \"input\": sum(s[\"attributes\"].get(\"gen_ai.usage.input_tokens\", 0) for s in chats),\n                    \"output\": sum(s[\"attributes\"].get(\"gen_ai.usage.output_tokens\", 0) for s in chats),\n                    \"cost\": sum((span_cost(s) for s in spans), Decimal(0))})\n    return sorted(out, key=lambda r: r[\"at\"])",
      "note": "Um registro por trace, com os atributos da raiz em nomes curtos e os custos de todos os seus spans somados. Os tokens do embedding contam também, ao preço deles."
    }
  ]
}
```

## Um pedido, com preço

```
ana@lab:~/obs$ python -c "import costs; r = next(r for r in costs.requests() if r[\"output\"]); print(r[\"trace\"], r[\"feature\"], r[\"input\"], r[\"output\"], r[\"cost\"])"
4be957f9979d11e46acb125624458d2d help 252 13 0.00060806
ana@lab:~/obs$ python tree.py --attrs 4be957f9 | grep -E " ms |usage|model"
      0   1,101 ms  ask
                     gen_ai.request.model = "extract-1"
      0     276 ms    embed
                       gen_ai.request.model = "lab-minilm"
                       gen_ai.usage.input_tokens = 3
    277      15 ms    search
    294     806 ms    generate
    294     806 ms      chat extract-1
                         gen_ai.request.model = "extract-1"
                         gen_ai.usage.input_tokens = 252
                         gen_ai.usage.output_tokens = 13
                         gen_ai.response.model = "extract-1"
  1,100       1 ms    check_citations
```

252 tokens de entrada e 13 de saída ao preço de setembro do extract-1: 252 × 2,00 mais 13 × 8,00,
dividido por um milhão, dá 0,000608 dólar, e os 3 tokens do embedding a 0,02 somam 0,00000006. O total
é 0,00060806 dólar, impresso até o último dígito porque um `Decimal` guarda todos.

Repare onde estavam os tokens. **A entrada é 95% dos tokens e 83% do custo**, embora cada token de
saída custe quatro vezes mais. Essa é a forma de um assistente com recuperação: um prompt longo de
instruções e fontes, uma resposta curta. Ela decide qual alavanca vale puxar: um prompt mais curto
economiza mais que uma resposta mais curta, o contrário do que a latência da aula 1 sugeria, onde a
resposta era a maior parte do tempo.
