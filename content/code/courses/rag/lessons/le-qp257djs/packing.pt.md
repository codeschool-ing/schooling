---
title: Empacotando a janela
version: 2
---

As decisões desta aula, na ordem em que precisam acontecer, são uma função do `context.py`:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"What goes into the window, and in what order: lesson 12's decisions in one place.\"\"\"\nimport re\n\nimport tiktoken\nfrom answer import FLOOR, REFUSAL, ask\nfrom vectors import embed\nfrom search import conn, vector\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nSAME = 0.9      # two sources this similar say the same thing\nKEEP = 0.45     # a sentence this similar to the question stays in its source\nBUDGET = 200    # tokens of sources, headers included",
      "note": "As três configurações que esta aula mede, escritas onde podem ser achadas. O `BUDGET` conta as fontes com os cabeçalhos; as instruções e a pergunta são pagas de qualquer jeito."
    },
    {
      "code": "def candidates(question, k=10, where=\"status = %s AND audience = %s\", params=(\"current\", \"public\")):\n    \"\"\"Up to K chunks above the floor, best first, with what a source header needs.\"\"\"\n    found = [r for r in vector(question, k, where, params) if r[3] >= FLOOR]\n    meta = {i: (u, v) for i, u, v in conn.execute(\n        \"SELECT id, updated, doc_version FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in found],))}\n    return [{\"id\": i, \"path\": p, \"text\": t, \"score\": s, \"updated\": meta[i][0], \"version\": meta[i][1]}\n            for i, p, t, s in found]",
      "note": "O `sources_for` da aula 7, pedindo dez em vez de três: agora é o piso, e não o `k`, que decide quantas voltam."
    },
    {
      "code": "def ends(sources):\n    \"\"\"Best first, second best last, the weakest in the middle.\"\"\"\n    return sources[0::2] + sources[1::2][::-1]\n\ndef header(n, source):\n    return f\"[{n}] {source['path']} (updated {source['updated']})\\n\"",
      "note": "O `ends` põe a melhor fonte primeiro e a segunda melhor por último; o `header` é a linha que o prompt da aula 7 escreve acima de cada fonte."
    },
    {
      "code": "def pack(question, budget=BUDGET, k=10, **filters):\n    \"\"\"Floor, then duplicates out, then each source cut to what is about the question, then as many\n    as fit the budget, best first, and finally the strongest two at the two ends.\"\"\"\n    kept, used = [], 0\n    for s in dedupe(candidates(question, k, **filters)):\n        s = compress(question, s)\n        cost = tokens(header(0, s) + s[\"text\"])\n        if used + cost <= budget:\n            kept.append(s)\n            used += cost\n    return ends(kept)",
      "note": "A ordem dos passos é o que importa: as duplicatas saem antes de qualquer contagem, cada fonte é cortada antes de ter o preço calculado, e o orçamento é gasto da melhor para a pior, de modo que uma fonte que não cabe é sempre mais fraca que todas as que couberam."
    },
    {
      "code": "def answer(question, **filters):\n    sources = pack(question, **filters)\n    if not sources:\n        return REFUSAL, []\n    return ask(question, sources), sources",
      "note": "O mesmo contrato do `answer` da aula 7: nada acima do piso quer dizer a recusa, e nenhuma chamada ao modelo."
    }
  ]
}
```

A ordem é o desenho. As duplicatas saem primeiro, para que uma fonte repetida nunca ocupe um lugar que
outra poderia ter. A compressão vem antes do preço, para que uma fonte seja cobrada pelas frases que de
fato vai mandar. O orçamento é gasto da melhor para a pior, de modo que o que não cabe é mais fraco do
que tudo o que coube. E a ordem de escrita vem por último, porque não muda nada além da sequência.

## Uma pergunta, três janelas

O `three.py` monta o prompt da pergunta sobre cartão-presente de três jeitos: os doze pedaços mais
próximos sem filtro nenhum, as três fontes da aula 7 acima do piso, e o `pack`.

```schooling-example
{
  "language": "python",
  "file": "three.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import SYSTEM, sources_for\nfrom context import header, pack, tokens\nfrom search import conn, vector\n\nquestion = sys.argv[1]\nrows = vector(question, 12)\nupdated = dict(conn.execute(\"SELECT id, updated FROM chunks WHERE id = ANY(%s)\", ([r[0] for r in rows],)).fetchall())\nnear = [{\"path\": p, \"text\": t, \"updated\": updated[i]} for i, p, t, _ in rows]\nfor name, sources in ((\"twelve nearest\", near), (\"lesson 7\", sources_for(question)), (\"packed\", pack(question))):\n    heads = sum(tokens(header(n, s)) for n, s in enumerate(sources, 1))\n    texts = sum(tokens(s[\"text\"]) for s in sources)\n    asked = tokens(\"Question: \" + question)\n    print(f\"{name:15} instructions {tokens(SYSTEM):3}  headers {heads:3}  sources {texts:3}  question {asked:2}\"\n          f\"  total {tokens(SYSTEM) + heads + texts + asked:4}  ({len(sources)} sources)\")",
      "note": "A mesma pergunta empacotada de três jeitos, os doze pedaços mais próximos, as fontes da aula 7 e o `pack` desta aula, e para onde vão os tokens em cada um."
    }
  ]
}
```
```
ana@vm:~/rag$ python three.py "How long is a gift card valid?"
twelve nearest  instructions  71  headers 248  sources 671  question 10  total 1000  (12 sources)
lesson 7        instructions  71  headers  63  sources 167  question 10  total  311  (3 sources)
packed          instructions  71  headers  62  sources 116  question 10  total  259  (3 sources)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três barras, um prompt cada para a pergunta sobre a validade de um cartão-presente, divididas em instruções, cabeçalhos das fontes, texto das fontes e a pergunta. Os doze pedaços mais próximos sem filtro: 1.000 tokens, dos quais 671 são texto das fontes e 248 cabeçalhos. As três acima do piso da aula 7: 311. Empacotado: 259, com 116 tokens de texto das fontes.\"><text x=\"140\" y=\"45\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">doze mais próximos</text><rect x=\"150.0\" y=\"30\" width=\"27.0\" height=\"30\" fill=\"var(--wire)\"></rect><rect x=\"177.0\" y=\"30\" width=\"94.2\" height=\"30\" fill=\"var(--amber)\"></rect><rect x=\"271.2\" y=\"30\" width=\"255.0\" height=\"30\" fill=\"var(--phosphor)\"></rect><rect x=\"526.2\" y=\"30\" width=\"3.8\" height=\"30\" fill=\"var(--paper-dim)\"></rect><text x=\"537.9999999999999\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1.000 tokens, 12 fontes</text><text x=\"140\" y=\"103\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">aula 7</text><rect x=\"150.0\" y=\"88\" width=\"27.0\" height=\"30\" fill=\"var(--wire)\"></rect><rect x=\"177.0\" y=\"88\" width=\"23.9\" height=\"30\" fill=\"var(--amber)\"></rect><rect x=\"200.9\" y=\"88\" width=\"63.5\" height=\"30\" fill=\"var(--phosphor)\"></rect><rect x=\"264.4\" y=\"88\" width=\"3.8\" height=\"30\" fill=\"var(--paper-dim)\"></rect><text x=\"276.18\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">311 tokens, 3 fontes</text><text x=\"140\" y=\"161\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">empacotado</text><rect x=\"150.0\" y=\"146\" width=\"27.0\" height=\"30\" fill=\"var(--wire)\"></rect><rect x=\"177.0\" y=\"146\" width=\"23.6\" height=\"30\" fill=\"var(--amber)\"></rect><rect x=\"200.5\" y=\"146\" width=\"44.1\" height=\"30\" fill=\"var(--phosphor)\"></rect><rect x=\"244.6\" y=\"146\" width=\"3.8\" height=\"30\" fill=\"var(--paper-dim)\"></rect><text x=\"256.42\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">259 tokens, 3 fontes</text><rect x=\"150\" y=\"210\" width=\"12\" height=\"12\" fill=\"var(--wire)\"></rect><text x=\"168\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instruções</text><rect x=\"272\" y=\"210\" width=\"12\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"290\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cabeçalhos</text><rect x=\"394\" y=\"210\" width=\"12\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"412\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fontes</text><rect x=\"484\" y=\"210\" width=\"12\" height=\"12\" fill=\"var(--paper-dim)\"></rect><text x=\"502\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pergunta</text></svg>", "caption": "Uma pergunta, três janelas. As instruções e a pergunta custam o mesmo nas três; o que muda é quantas fontes entram e quanto de cada uma. O empacotamento manteve três fontes e cortou o texto delas de 167 tokens para 116."}
```

**De 1.000 tokens para 311 e para 259.** Doze fontes sem filtro custam o triplo do prompt da aula 7, e
quase toda a diferença é texto de fonte de que a pergunta não precisava. O `pack` manteve as mesmas três
fontes que a aula 7 mandou e cortou o texto delas de 167 tokens para 116.

## Medido, em todas as perguntas

O `compare.py` roda os dois pipelines nas 30 perguntas do `eval.jsonl`, pelo llama3.2:3b, e pontua as
respostas com as regras da aula 8. Uma resposta está correta quando contém um fato da resposta, ou
recusa uma pergunta que os documentos não respondem, e é fiel quando toda frase está citada literalmente
ou perto da fonte citada.

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "import json\n\nimport answer as plain\nimport context as packed\nfrom context import tokens\nfrom verify import check\n\nnorm = lambda t: \" \".join(t.replace(\"|\", \" \").split())\nquestions = list(map(json.loads, open(\"data/eval.jsonl\")))\nwhere = dict(where=\"status = %s\", params=(\"current\",))\nprint(f\"{'pipeline':8} {'correct':>8} {'refused':>8} {'faithful':>9} {'sources':>8} {'prompt':>7}\")\nfor name, run in ((\"plain\", plain.answer), (\"packed\", packed.answer)):\n    correct, refused, faithful, sources, sent = 0, 0, 0, 0, 0\n    for q in questions:\n        reply, found = run(q[\"question\"], **where)\n        refusal = reply == plain.REFUSAL\n        correct += refusal if not q[\"facts\"] else not refusal and any(f in norm(reply) for f in q[\"facts\"])\n        refused += refusal and not q[\"facts\"]\n        faithful += refusal or all(v.startswith((\"quoted\", \"close\")) for _, _, v in check(reply, found))\n        sources += len(found)\n        sent += tokens(plain.SYSTEM) + tokens(plain.prompt(q[\"question\"], found)) if found else 0\n    n = len(questions)\n    print(f\"{name:8} {correct:5}/{n} {refused:6}/4 {faithful:6}/{n} {sources / n:8.1f} {sent / n:7.0f}\")",
      "note": "O pipeline da aula 7 e o empacotado desta aula, nas trinta perguntas, pelo mesmo modelo: quantas respostas estavam certas, quantas recusas estavam certas, quantas eram fiéis às fontes, e quantas fontes e tokens cada um mandou."
    }
  ]
}
```
```
ana@vm:~/rag$ python compare.py
pipeline  correct  refused  faithful  sources  prompt
plain       23/30      4/4     14/30      2.2     247
packed      23/30      4/4     20/30      2.3     198
```

**As mesmas 23 corretas, 20 fiéis em vez de 14, e 198 tokens por prompt em vez de 247**, um quinto a
menos, com um orçamento de 200 tokens de fontes. Os tokens são a metade mensurável: mesmas respostas,
conta menor, leitura mais curta. A fidelidade é a surpresa. Mais seis respostas tiveram toda frase
citada literalmente ou perto da fonte, e uma execução em trinta perguntas não sabe dizer por quê. Um
palpite que vale testar é que uma fonte mais curta deixa ao modelo menos em volta do que parafrasear,
e então mais do que ele escreve são as palavras da própria fonte. A metade que a pesquisa estuda, a
atenção espalhada por texto irrelevante, aponta para o mesmo lado, e uma equipe com um modelo maior
roda a mesma comparação contra ele para saber se isso também vale.

Toda configuração da função, `SAME`, `KEEP`, `BUDGET` e o piso, é um número que esta aula escolheu
medindo este acervo. Em outro acervo, eles são por onde começar, nunca o que manter.
