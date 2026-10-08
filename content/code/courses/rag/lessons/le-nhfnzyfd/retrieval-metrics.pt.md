---
title: Medindo a recuperação
version: 2
---

A aula 7 separou três propriedades: a busca achou o trecho, cada frase vem da sua fonte, e a resposta
responde à pergunta. O `evaluate.py` mede as três para cada pergunta de uma parte do conjunto:

```schooling-example
{
  "language": "python",
  "file": "evaluate.py",
  "parts": [
    {
      "code": "import argparse\nimport json\nimport sys\n\nimport answer as pipeline\nfrom search import vector\nfrom verify import check, norm\n\np = argparse.ArgumentParser(description=\"Measure retrieval and answers against data/eval.jsonl.\")\np.add_argument(\"--split\", choices=[\"dev\", \"held-out\", \"all\"], default=\"dev\")\np.add_argument(\"--floor\", type=float, default=pipeline.FLOOR)\np.add_argument(\"--k\", type=int, default=3)\np.add_argument(\"--list\", action=\"store_true\", help=\"one line per question\")\np.add_argument(\"--min-correct\", type=float, default=0.0, help=\"fail below this share of correct replies\")\na = p.parse_args()\npipeline.FLOOR = a.floor",
      "note": "Opções para as comparações mais adiante na aula: que parte do conjunto de teste, o piso, o k, uma listagem por pergunta, e a fração de respostas corretas abaixo da qual a execução falha. O `--floor` substitui o valor do próprio pipeline só nesta execução."
    },
    {
      "code": "def split_of(q):\n    \"\"\"Every third question is held out, decided by its id and nothing else.\"\"\"\n    return \"held-out\" if int(q[\"id\"][1:]) % 3 == 0 else \"dev\"",
      "note": "O terço separado é escolhido pelo id da pergunta, então é o mesmo terço em toda execução e em toda máquina, e ninguém escolhe quais perguntas são fáceis de separar."
    },
    {
      "code": "questions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if a.split in (\"all\", split_of(q))]\nwhere, params = \"status = %s\", (\"current\",)\nranks, correct, faithful, refused_right, rows = [], 0, 0, 0, []\nfor q in questions:\n    found = vector(q[\"question\"], 5, where, params)\n    rank = next((i for i, r in enumerate(found, 1) if any(f in norm(r[2]) for f in q[\"facts\"])), None)\n    reply, sources = pipeline.answer(q[\"question\"], k=a.k, where=where, params=params)\n    refused = reply == pipeline.REFUSAL\n    right = refused if not q[\"facts\"] else not refused and any(f in norm(reply) for f in q[\"facts\"])\n    true = refused or all(v.startswith((\"quoted\", \"close\")) for _, _, v in check(reply, sources))\n    correct += right\n    faithful += true\n    if q[\"facts\"]:\n        ranks.append(rank)\n    else:\n        refused_right += refused\n    rows.append(f\"{q['id']}  rank {rank or '-'}  {'refused ' if refused else 'answered'}  \"\n                f\"{'correct' if right else 'WRONG  '}  {'faithful' if true else 'UNFAITHFUL'}  {q['question']}\")",
      "note": "Para cada pergunta, três medições. Recuperação: a posição do primeiro pedaço com as palavras da resposta, entre os cinco mais próximos. Correção: uma pergunta com resposta tem de receber uma resposta com essas palavras, e uma sem resposta tem de ser recusada. Fidelidade: toda frase de uma resposta que não é recusa tem de passar na verificação da aula 7."
    },
    {
      "code": "n, answerable = len(questions), len(ranks)\nhits = lambda k: sum(1 for r in ranks if r and r <= k)\nprint(f\"{a.split}: {n} questions, {answerable} answerable, floor {a.floor}, k {a.k}\")\nprint(f\"retrieval  recall@1 {hits(1)}/{answerable}  recall@3 {hits(3)}/{answerable}  recall@5 {hits(5)}/{answerable}\"\n      f\"  MRR {sum(1 / r for r in ranks if r) / answerable:.2f}\")\nprint(f\"answers    correct {correct}/{n}  refused rightly {refused_right}/{n - answerable}  faithful {faithful}/{n}\")\nif a.list:\n    print(\"\\n\".join(rows))\nif correct / n < a.min_correct:\n    print(f\"FAIL: {correct}/{n} correct is below {a.min_correct:.0%}\")\n    sys.exit(1)",
      "note": "Revocação em 1, 3 e 5, posição recíproca média, e as três contagens das respostas; depois as linhas por pergunta se pedidas, e uma saída diferente de zero se a correção ficar abaixo da barra."
    }
  ]
}
```

Esta seção trata da primeira propriedade.

```
ana@vm:~/rag$ python evaluate.py --split dev
dev: 20 questions, 18 answerable, floor 0.5, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 15/20  refused rightly 2/2  faithful 9/20
```

## Revocação em k

A **revocação em k** (recall@k) é a fração das perguntas com resposta cuja resposta está nos k primeiros
pedaços que a busca devolve. No dev ela é 13 de 18 em um, e 18 de 18 em três e em cinco. O "achadas" da
aula 4 era a revocação em 3 com outro nome.

Dois valores importam mais que o resto. **A revocação no k que o pipeline de fato usa**, aqui três, diz
se o gerador chegou a receber a resposta: se não recebeu, nada adiante conserta. **A revocação em um**
diz com que frequência a resposta vem primeiro, o que importa porque um modelo tende a usar o
que lê primeiro, e porque a aula 12 vai querer menos fontes, não mais.

## Posição recíproca média

A revocação conta acertos e ignora onde eles caíram dentro dos k. A **posição recíproca média** (mean
reciprocal rank, MRR) dá a uma pergunta 1 quando a resposta vem primeiro, 1/2 quando em segundo, 1/3
quando em terceiro, e 0 quando não é achada, e depois tira a média. 0,86 aqui: 13 perguntas com 1 e 5
com 1/2, divididos por 18. A MRR é um número só que se mexe quando uma resposta sobe de terceiro para
primeiro, o que a revocação em 3 não vê, e isso a torna o número melhor para acompanhar ao ajustar um
reordenador ou uma reescrita.

## O que esses números não dizem

**Não dizem se o pedaço achado foi usado.** Cinco das 18 perguntas com a resposta entre as três
primeiras ainda receberam uma resposta errada, como a próxima seção mostra. Boa recuperação é necessária
e está longe de bastar.

**Dependem de os fatos serem encontráveis.** Um pedaço conta como portador da resposta quando contém as
palavras do fato. Uma pergunta cuja resposta está espalhada por dois pedaços, ou redigida no documento
de outro jeito que no fato, conta como erro quando a busca foi bem. Escrever os fatos com cuidado, com
as palavras exatas da fonte, é o que mantém isso honesto.

**São sobre o dev.** A execução do conjunto separado vem no fim da aula, depois das comparações.
