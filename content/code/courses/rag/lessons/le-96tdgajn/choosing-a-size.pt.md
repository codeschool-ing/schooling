---
title: Medindo a escolha
version: 2
---

Cada estratégia desta aula tem um argumento a favor, e argumentos não decidem qual usar num corpus
específico. Uma medição decide. O `compare.py` corta os treze documentos de nove jeitos, gera o
embedding de cada pedaço, e roda as 26 perguntas com resposta do conjunto de teste contra cada conjunto
de pedaços. Uma pergunta conta como **achada** quando o trecho que a responde, as palavras registradas
no `eval.jsonl`, está dentro de um dos três pedaços recuperados. Ele também conta quantos tokens esses
três pedaços poriam no prompt.

```schooling-example
{
  "language": "python",
  "file": "compare.py",
  "parts": [
    {
      "code": "import json\n\nimport tiktoken\nfrom chunking import fixed, load, sections, semantic, structured\nfrom vectors import embed\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\ndocs = load()\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.split())\nqv = embed([q[\"question\"] for q in questions])",
      "note": "As 26 perguntas que têm resposta, cada uma com as palavras que uma resposta certa contém, viram embedding uma vez."
    },
    {
      "code": "strategies = {\n    \"fixed, 30 words\": lambda b: fixed(b, 30),\n    \"fixed, 60 words\": lambda b: fixed(b, 60),\n    \"fixed, 60 + 15 overlap\": lambda b: fixed(b, 60, 15),\n    \"fixed, 120 words\": lambda b: fixed(b, 120),\n    \"fixed, 240 words\": lambda b: fixed(b, 240),\n    \"sections\": lambda b: [t for _, t in sections(b)],\n    \"structured, 60 words\": lambda b: [t for _, t in structured(b, 60)],\n    \"structured, 120 words\": lambda b: [t for _, t in structured(b, 120)],\n    \"semantic\": semantic,\n}",
      "note": "Nove jeitos de cortar o corpus, todas as funções do `chunking.py` com alguns tamanhos."
    },
    {
      "code": "print(f\"{'strategy':24} {'chunks':>6} {'words':>6} {'found':>6} {'tokens':>7}\")\nfor name, cut in strategies.items():\n    chunks = [c for _, body in docs.values() for c in cut(body)]\n    v = embed(chunks)\n    found, tokens = 0, 0\n    for q, scores in zip(questions, qv @ v.T):\n        top = [chunks[i] for i in scores.argsort()[::-1][:3]]\n        found += any(f in norm(t) for t in top for f in q[\"facts\"])\n        tokens += len(enc.encode(\"\\n\".join(top)))\n    mean = sum(len(c.split()) for c in chunks) / len(chunks)\n    print(f\"{name:24} {len(chunks):6} {mean:6.0f} {found:3}/{len(questions)} {tokens / len(questions):7.0f}\")",
      "note": "Para cada um, o número de pedaços e o tamanho médio, quantas perguntas tiveram um fato certo entre os três primeiros, e quantos tokens esses três acrescentariam a um prompt."
    }
  ]
}
```

```
ana@vm:~/rag$ python compare.py
strategy                 chunks  words  found  tokens
fixed, 30 words             227     29  15/26     108
fixed, 60 words             116     57  19/26     217
fixed, 60 + 15 overlap      150     58  22/26     220
fixed, 120 words             62    106  19/26     404
fixed, 240 words             34    194  24/26     768
sections                     92     64  25/26     260
structured, 60 words        137     43  24/26     170
structured, 120 words        99     59  25/26     237
semantic                     98     63  20/26     333
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Um gráfico de dispersão de nove estratégias de corte: tokens recuperados por pergunta contra perguntas cuja resposta foi recuperada, de 26. Fixo 30 palavras: 108 tokens, 15. Fixo 60: 217, 19. Fixo 60 com 15 sobrepostas: 220, 22. Fixo 120: 404, 19. Fixo 240: 768, 24. Seções: 260, 25. Estruturado 60: 170, 24. Estruturado 120: 237, 25. Semântico: 333, 20.\"><path d=\"M70 280 L690 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 280 L70.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M225.0 280 L225.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"225.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M380.0 280 L380.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><path d=\"M535.0 280 L535.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"535.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">600</text><path d=\"M690.0 280 L690.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">800</text><path d=\"M65 280.0 L70 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><path d=\"M65 240.0 L70 240.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><path d=\"M65 200.0 L70 200.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M65 160.0 L70 160.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M65 120.0 L70 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><path d=\"M65 80.0 L70 80.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26</text><text x=\"380.0\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens recuperados por pergunta, três pedaços</text><text x=\"70\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">perguntas cuja resposta foi recuperada, de 26</text><circle cx=\"153.7\" cy=\"260.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"161.7\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 30</text><circle cx=\"238.2\" cy=\"180.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"246.175\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 60</text><circle cx=\"240.5\" cy=\"120.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"248.5\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 60+15</text><circle cx=\"383.1\" cy=\"180.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"391.1\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 120</text><circle cx=\"665.2\" cy=\"80.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"657.2\" y=\"94.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 240</text><circle cx=\"271.5\" cy=\"60.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"279.5\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seções</text><circle cx=\"201.8\" cy=\"80.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"191.75\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estruturado 60</text><circle cx=\"253.7\" cy=\"60.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"245.675\" y=\"46.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estruturado 120</text><circle cx=\"328.1\" cy=\"160.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"336.075\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">semântico</text></svg>", "caption": "Para cima e para a esquerda é melhor: mais respostas achadas com menos tokens. As três que seguem a estrutura dos próprios documentos ficam no alto à esquerda; o fixo 240 custa o triplo e acha menos."}
```

## Lendo a tabela

**Os pedaços menores acharam menos respostas.** Janelas de trinta palavras acharam 15 de 26: cada uma é
curta demais para levar seu contexto, e o trecho que responde a uma pergunta muitas vezes fica cortado
entre duas delas.

**Os pedaços maiores custaram o triplo e acharam menos.** Pedaços fixos de 240 palavras acharam 24 de
26, uma a menos que as seções e o estruturado 120. Eles puseram 768 tokens no prompt por pergunta,
contra 237 do estruturado 120, que achou 25. Pagar 531 tokens a mais em toda pergunta por uma resposta
a menos é a pior troca da tabela, e a aula 12 mostra quanto desse texto a mais é ruído.

**Seguir a estrutura domina.** Seções, estruturado 120 e estruturado 60 ficam no alto à esquerda da
figura: 24 ou 25 achadas, por 170 a 260 tokens. O estruturado 60 achou 24 com o contexto mais barato de
todas as estratégias que acharam mais de 15. Nada do que as estratégias por contagem fizeram, a
sobreposição incluída, chegou a essa combinação.

**A sobreposição valeu o custo; o corte semântico não, aqui.** A sobreposição levou o fixo 60 de 19 para
22 por três tokens a mais por pergunta. O corte semântico achou 20, uma a mais que o fixo 60 sem
sobreposição e duas a menos que com ela, e pôs mais tokens no prompt que qualquer das variantes
estruturadas.

## O que esta medição é e o que não é

É uma medição neste corpus e nestas 26 perguntas, e os números serão outros no seu. **É para isso que
se roda**: o tamanho certo de pedaço depende de quão longos são os parágrafos dos documentos, de quão
específicas são as perguntas e de quantos tokens um prompt pode pagar, e nada disso é uma constante que
alguém possa lhe citar.

Ela mede só a recuperação. Uma resposta achada ainda tem de ser usada pelo gerador, e a aula 8 mede as
respostas também. E 26 perguntas é um conjunto de teste pequeno: uma pergunta são quatro pontos
percentuais, então a diferença entre 24 e 25 é uma pergunta e não deveria decidir nada sozinha. As
diferenças grandes, 15 contra 25, ou 768 tokens contra 237, são as que merecem ação.

O hábito que vale guardar é a forma do `compare.py`: **um conjunto fixo de perguntas com respostas
conhecidas, rodado contra cada candidato, informando qualidade e custo lado a lado.** A aula 8 o
transforma no teste permanente do pipeline.
