---
title: O harness
version: 1
---

O harness é o programa que manda cada caso para cada modelo, pontua cada resposta e guarda um
registro de tudo. O `evalkit.py` tem pouco mais de cem linhas, e cada parte dele é uma decisão que
vale a pena ver:

```schooling-example
{
  "language": "python",
  "file": "evalkit.py",
  "parts": [
    {
      "code": "\"\"\"evalkit: run a task's cases through several models, and score what came back.\"\"\"\nimport json\nimport math\nimport re\nimport sys\nimport time\n\nimport openai\n\nclient = openai.OpenAI()  # the address and the key come from desk.env\n\n\n",
      "note": "Um cliente para todos os candidatos. O `desk.env` o aponta para o Ollama; com uma chave, o mesmo cliente alcança qualquer provedor que responda nesse formato, e a aula 20 conta quantos."
    },
    {
      "code": "def score_triage(answer, case):\n    strict = answer == case[\"label\"]\n    loose = answer.strip().lower().rstrip(\".\") == case[\"label\"]\n    return strict, loose\n\n\n",
      "note": "**Estrito** é caractere por caractere. **Tolerante** perdoa a desarrumação que a seção 04 mostrou: espaços, maiúsculas, um ponto final."
    },
    {
      "code": "def score_extract(answer, case):\n    try:\n        strict = json.loads(answer).get(\"order\") == case[\"order\"]\n    except (json.JSONDecodeError, AttributeError):\n        strict = False\n    found = re.search(r\"\\{.*\\}\", answer, re.S)\n    try:\n        loose = bool(found) and json.loads(found.group(0)).get(\"order\") == case[\"order\"]\n    except json.JSONDecodeError:\n        loose = False\n    return strict, loose\n\n\n",
      "note": "**Estrito** é o que o `json.loads` aceita, inteiro. **Tolerante** pesca o primeiro `{...}` da resposta. Os dois depois comparam o número do pedido com o do caso."
    },
    {
      "code": "def run(task, models, out, temperature=0.0):\n    system = open(f\"prompts/{task}.txt\").read()\n    cases = [json.loads(line) for line in open(\"cases/triage.jsonl\")]\n    score = score_triage if task == \"triage\" else score_extract\n    with open(out, \"w\") as f:\n        for model in models:\n            for case in cases:\n                start = time.perf_counter()\n                r = client.chat.completions.create(\n                    model=model, max_tokens=50, temperature=temperature,\n                    messages=[{\"role\": \"system\", \"content\": system}, {\"role\": \"user\", \"content\": case[\"text\"]}])\n                answer = r.choices[0].message.content\n                strict, loose = score(answer, case)\n                f.write(json.dumps({\"task\": task, \"model\": r.model, \"case\": case[\"id\"], \"answer\": answer, \"strict\": strict,\n                                    \"loose\": loose, \"seconds\": round(time.perf_counter() - start, 3),\n                                    \"in\": r.usage.prompt_tokens, \"out\": r.usage.completion_tokens}) + \"\\n\")\n\n\n",
      "note": "Todo caso, todo modelo, as mesmas mensagens e configurações. A resposta crua é gravada com as duas notas, o tempo e os tokens, para a pontuação poder mudar depois sem pagar as requisições de novo."
    },
    {
      "code": "def wilson(k, n, z=1.96):\n    \"\"\"The 95% interval around k right out of n, by Wilson's formula.\"\"\"\n    p = k / n\n    centre = (p + z * z / (2 * n)) / (1 + z * z / n)\n    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)\n    return centre - half, centre + half\n\n\n",
      "note": "**O intervalo de Wilson** para k acertos em n. Com quarenta casos ele é largo, e é por isso que vale imprimi-lo."
    },
    {
      "code": "def report(path):\n    rows = [json.loads(line) for line in open(path)]\n    print(f\"{'model':12} {'strict':>7} {'loose':>7} {'loose, 95%':>14} {'p50 s':>6} {'out tok':>8}\")\n    for model in dict.fromkeys(r[\"model\"] for r in rows):\n        mine = [r for r in rows if r[\"model\"] == model]\n        n, strict, loose = len(mine), sum(r[\"strict\"] for r in mine), sum(r[\"loose\"] for r in mine)\n        lo, hi = wilson(loose, n)\n        p50 = sorted(r[\"seconds\"] for r in mine)[n // 2]\n        out = sum(r[\"out\"] for r in mine) / n\n        print(f\"{model:12} {strict:>4}/{n} {loose:>4}/{n} {lo:>7.0%} to {hi:>4.0%} {p50:>6.2f} {out:>8.1f}\")\n\n\n",
      "note": "Uma linha por modelo: as duas notas, o intervalo em volta da frouxa, o tempo mediano e quantos tokens ele escreveu, em média."
    },
    {
      "code": "def compare(path, a, b):\n    \"\"\"Cases where exactly one of the two models was right, and how likely that split is by chance.\"\"\"\n    rows = [json.loads(line) for line in open(path)]\n    right = {(r[\"model\"], r[\"case\"]): r[\"loose\"] for r in rows}\n    cases = [r[\"case\"] for r in rows if r[\"model\"] == a]\n    only_a = [c for c in cases if right[(a, c)] and not right[(b, c)]]\n    only_b = [c for c in cases if right[(b, c)] and not right[(a, c)]]\n    n, k = len(only_a) + len(only_b), min(len(only_a), len(only_b))\n    p = min(1.0, 2 * sum(math.comb(n, i) for i in range(k + 1)) / 2 ** n) if n else 1.0\n    print(f\"only {a} right: {len(only_a)} {only_a}\")\n    print(f\"only {b} right: {len(only_b)} {only_b}\")\n    print(f\"chance of a split at least this uneven if they were equally good: {p:.3f}\")\n\n\n",
      "note": "Só os casos em que exatamente um modelo acertou dizem algo sobre a diferença. Se os dois fossem igualmente bons, cada um seria cara ou coroa, e a última linha é a chance de uma divisão pelo menos tão desigual."
    },
    {
      "code": "def errors(path):\n    rows = [json.loads(line) for line in open(path)]\n    cases = {c[\"id\"]: c for c in map(json.loads, open(\"cases/triage.jsonl\"))}\n    for r in rows:\n        if not r[\"strict\"]:\n            want = cases[r[\"case\"]][\"label\" if r[\"task\"] == \"triage\" else \"order\"]\n            mark = \"loose ok\" if r[\"loose\"] else \"wrong\"\n            print(f\"{r['model']:12} {r['case']} {mark:8}  expected {want!s:15} got {r['answer']!r}\")\n\n\ndef gate(base, new, model, allowed=1):\n    \"\"\"Fail, with exit status 1, if model's new run is worse than its baseline by more than allowed cases.\"\"\"\n    def score(path):\n        return sum(json.loads(line)[\"loose\"] for line in open(path) if json.loads(line)[\"model\"] == model)\n    before, after = score(base), score(new)\n    verdict = \"pass\" if after >= before - int(allowed) else \"FAIL\"\n    print(f\"{model}: {before} before, {after} now, {int(allowed)} allowed: {verdict}\")\n    sys.exit(0 if verdict == \"pass\" else 1)\n\n\n",
      "note": "O `errors` lista toda resposta que não estava estritamente certa, com o que era esperado. O `gate` transforma a comparação com a linha de base num status de saída com que um script pode agir."
    },
    {
      "code": "if __name__ == \"__main__\":\n    cmd, *args = sys.argv[1:]\n    if cmd == \"run\":\n        task, out, temperature, models = args[0], args[1], float(args[2]), args[3:]\n        run(task, models, out, temperature)\n    else:\n        {\"report\": report, \"compare\": compare, \"errors\": errors, \"gate\": gate}[cmd](*args)\n",
      "note": "A linha de comando: `run`, `report`, `compare`, `errors` e `gate`."
    }
  ]
}
```

Duas escolhas nele merecem nome.

**Ele fala com todos os modelos por uma API só.** Os três candidatos são chamados pelo Chat
Completions do SDK da OpenAI, com as mesmas mensagens, o mesmo `max_tokens` e a mesma temperatura. A
documentação da própria OpenAI hoje prefere um nome mais novo para o limite,
`max_completion_tokens`, e o Ollama ignora esse sem dizer nada, como a aula 20 mostra; o
`max_tokens` é o que os dois leem. A aula 20 mostra até onde isso alcança: muitos provedores aceitam
esse formato. Quando um candidato precisa do próprio SDK, o harness ganha um segundo jeito de fazer
a requisição, e tudo depois dele continua igual.

**Ele registra antes de julgar.** Cada linha de `runs/*.jsonl` guarda a resposta crua, as duas
notas, o tempo e os tokens. A pontuação pode mudar depois e ser reaplicada às mesmas respostas sem
pagar as requisições de novo, e uma discussão sobre um caso pode ser resolvida lendo o que o modelo
de fato escreveu.

## Rodando

```
ana@desk:~/desk$ time python evalkit.py run triage runs/triage.jsonl 0 llama3.2:3b qwen2.5:3b llama3.2:1b

real	1m47.419s
user	0m0.914s
sys	0m0.054s
```

Cento e vinte requisições, quarenta por modelo, uma depois da outra, em menos de dois minutos: pouco
menos de um segundo cada, num processador sem placa de vídeo. O que ele gravou:

```
ana@desk:~/desk$ wc -l runs/triage.jsonl; head -2 runs/triage.jsonl
120 runs/triage.jsonl
{"task": "triage", "model": "llama3.2:3b", "case": "c01", "answer": "order-status", "strict": true, "loose": true, "seconds": 1.19, "in": 91, "out": 3}
{"task": "triage", "model": "llama3.2:3b", "case": "c02", "answer": "refund", "strict": true, "loose": true, "seconds": 0.889, "in": 93, "out": 2}
```

Uma linha por resposta, e tudo o que as seções 06 a 10 relatam vem de ler essas linhas de volta.
