---
title: Mais fontes não são mais respostas
version: 2
---

O jeito óbvio de garantir que a resposta está no prompt é mandar mais: aumentar o `k`, e o que a busca
pôs em quarto ou oitavo lugar vem junto. O `sweep.py` mede o que isso compra, para as 26 perguntas
com resposta do `eval.jsonl`, em seis valores de `k`:

```schooling-example
{
  "language": "python",
  "file": "sweep.py",
  "parts": [
    {
      "code": "import itertools\nimport json\n\nfrom context import FLOOR, tokens\nfrom vectors import embed\nfrom search import vector\n\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.replace(\"|\", \" \").split())\nprint(f\"{'k':>3} {'found':>6} {'tokens':>7} {'alike':>6} {'above floor':>12}\")\nfor k in (1, 2, 3, 5, 8, 12):\n    found, used, alike, kept = 0, 0, 0, 0\n    for q in questions:\n        top = vector(q[\"question\"], k, \"status = %s\", (\"current\",))\n        found += any(f in norm(r[2]) for r in top for f in q[\"facts\"])\n        used += tokens(\"\\n\".join(r[2] for r in top))\n        v = embed([r[2] for r in top])\n        alike += sum(1 for i, j in itertools.combinations(range(len(top)), 2) if v[i] @ v[j] >= 0.8)\n        kept += sum(1 for r in top if r[3] >= FLOOR)\n    n = len(questions)\n    print(f\"{k:3} {found:3}/{n} {used / n:7.0f} {alike:6} {kept / n:12.1f}\")",
      "note": "A mesma busca com k de 1 a 12, e para cada k quantas respostas ela achou, quantos tokens custou, quantos pares de fontes eram quase duplicatas um do outro, e quantas fontes em média passaram do piso."
    }
  ]
}
```
```
ana@vm:~/rag$ python sweep.py
  k  found  tokens  alike  above floor
  1  20/26      60      0          1.0
  2  26/26     116      3          1.8
  3  26/26     171      3          2.6
  5  26/26     279      7          3.4
  8  26/26     441     12          4.1
 12  26/26     660     16          4.7
```

As colunas são: em quantas perguntas um fato da resposta estava em algum lugar do que foi recuperado,
os tokens de texto das fontes por pergunta, quantos pares de pedaços recuperados tinham similaridade
0,8 ou mais, e quantos pedaços recuperados, em média, passariam do piso de 0,5 da aula 6.

**A recuperação para de melhorar em dois.** Com uma fonte, 20 de 26 respostas estavam no prompt; com
duas, as 26; depois disso, nada mais a achar. **Os tokens continuam crescendo em linha reta**, 116 com
duas e 660 com doze, e também os pares de pedaços que dizem quase a mesma coisa. Tudo depois da
segunda fonte é custo: as mesmas respostas, mais texto em volta.

## O que o texto a mais faz com um modelo

Trinta perguntas e um modelo pequeno são poucos para ver o que o texto a mais faz com as respostas de
um modelo de linguagem; a última seção desta aula compara dois prompts nas trinta, e é até aí que este
acervo vai. Duas medições publicadas vão além:

- **Texto irrelevante baixa a precisão.** Shi e outros, em *Large Language Models Can Be Easily
  Distracted by Irrelevant Context* (ICML 2023), acrescentaram uma frase que nada tinha a ver com a
  pergunta a problemas de aritmética em texto, e os modelos que testaram erraram visivelmente mais.
- **Onde a resposta fica importa.** Liu e outros, em *Lost in the Middle: How Language Models Use Long
  Contexts* (TACL 2024), puseram o trecho com a resposta em posições diferentes entre muitos outros e
  viram que os modelos o usavam melhor no começo ou no fim da entrada, e pior no meio, inclusive
  modelos feitos para entradas longas.

Nenhum dos dois artigos mediu o seu modelo nos seus documentos, e os modelos mudaram desde então. Eles
são o motivo para tratar cada fonte a mais como custo até uma medição dizer o contrário, e o motivo de
existir a seção de posicionamento. O teste que decide isso para uma implantação real é o da aula 8,
rodado contra o modelo real com dois valores de `k`.
