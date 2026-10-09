---
title: Comprimindo as fontes
version: 2
---

Um pedaço de 60 palavras foi escolhido na aula 4 porque costuma guardar uma resposta inteira. Ele
também costuma guardar outra coisa: a frase antes da resposta, a exceção depois dela, uma frase sobre
outro caso. **A compressão mantém as frases de cada fonte que tratam da pergunta** e descarta o resto,
de modo que a fonte que o modelo lê é mais curta e continua sendo as palavras do próprio documento.

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def sentences(text):\n    return [s for s in re.split(r\"(?<=[.!?])\\s+(?=[A-Z0-9])|\\n(?=- )|\\n\\n\", text) if s.strip()]",
      "note": "Frases, cortadas num ponto final antes de maiúscula ou dígito, num item de lista e numa linha em branco."
    },
    {
      "code": "def compress(question, source, keep=KEEP):\n    \"\"\"Keep the sentences of a source that are about the question, in their order, and always its best.\"\"\"\n    parts = sentences(source[\"text\"])\n    scores = embed(parts) @ embed(question)[0]\n    chosen = [p for p, s in zip(parts, scores) if s >= keep or s == scores.max()]\n    return {**source, \"text\": \" \".join(\" \".join(p.split()) for p in chosen)}",
      "note": "Cada frase é comparada com a pergunta, e as que chegam a `KEEP` ou mais ficam, na ordem original, com a melhor sempre mantida para que nenhuma fonte fique vazia. O corte é por frase, então o que fica ainda é texto que o documento diz."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "squeezed.py",
  "parts": [
    {
      "code": "import sys\n\nfrom context import candidates, compress\n\nquestion = sys.argv[1]\nsource = candidates(question, 1)[0]\nprint(source[\"path\"])\nprint(\" \".join(source[\"text\"].split()))\nprint(\"kept:\")\nprint(compress(question, source)[\"text\"])",
      "note": "Uma fonte antes e depois do `compress`, para ler o que ele manteve."
    }
  ]
}
```
```
ana@vm:~/rag$ python squeezed.py "How long after my return arrives will I get the refund?"
Returns and refunds policy > Refunds
We refund within three working days of the return reaching our warehouse. The money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. Delivery costs are refunded when you return the whole order; when you return part of it, they are not.
kept:
We refund within three working days of the return reaching our warehouse. The money goes back to the card or account you paid with, and your bank may take another five to ten days to show it.
```

A seção de reembolsos tem três frases; ficaram as duas sobre quando o dinheiro chega, e saiu a dos
custos de entrega. A fonte ficou um terço mais curta e guarda a mesma resposta.

## Escolhendo onde cortar

O `KEEP` é um limite, então é escolhido do jeito que a aula 8 escolheu o piso: medido nas perguntas de
desenvolvimento, depois conferido uma vez nas separadas. Para cada valor, as três fontes que a aula 7
mandaria são comprimidas, e a tabela conta as respostas que continuam dentro delas e os tokens que
sobram:

```schooling-example
{
  "language": "python",
  "file": "squeeze.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nfrom context import candidates, compress, tokens\n\nsplit = sys.argv[1]\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\"))\n             if q[\"facts\"] and (int(q[\"id\"][1:]) % 3 == 0) == (split == \"held-out\")]\nnorm = lambda t: \" \".join(t.replace(\"|\", \" \").split())\nfound = {q[\"id\"]: candidates(q[\"question\"], 3, \"status = %s\", (\"current\",)) for q in questions}\nprint(f\"{split}: {len(questions)} answerable questions\")\nprint(f\"{'keep':>5} {'found':>6} {'tokens':>7}\")\nfor keep in (0.0, 0.35, 0.45, 0.5, 0.6, 1.0):\n    hits, used = 0, 0\n    for q in questions:\n        cut = [compress(q[\"question\"], s, keep) for s in found[q[\"id\"]]]\n        hits += any(f in norm(s[\"text\"]) for s in cut for f in q[\"facts\"])\n        used += sum(tokens(s[\"text\"]) for s in cut)\n    print(f\"{keep:5.2f} {hits:3}/{len(questions)} {used / len(questions):7.0f}\")",
      "note": "O `compress` em seis níveis de quanto manter de cada fonte, numa parte do conjunto de teste de cada vez, com quantas respostas sobreviveram e quantos tokens sobraram."
    }
  ]
}
```
```
ana@vm:~/rag$ python squeeze.py dev
dev: 18 answerable questions
 keep  found  tokens
 0.00  17/18     134
 0.35  17/18     103
 0.45  17/18      84
 0.50  15/18      73
 0.60  15/18      71
 1.00  15/18      69
ana@vm:~/rag$ python squeeze.py held-out
held-out: 8 answerable questions
 keep  found  tokens
 0.00   8/8     167
 0.35   8/8     129
 0.45   8/8     116
 0.50   8/8      97
 0.60   8/8      87
 1.00   7/8      78
```

Nas perguntas de desenvolvimento, **0,45 é o último valor que não perde nada**: 17 de 18 achadas, como
sem compressão nenhuma, com 84 tokens em vez de 134, 37% menos. Com 0,5 saem duas respostas. As
perguntas separadas, que ninguém olhou durante a escolha, concordam: 8 de 8 com 0,45, com 116 tokens
em vez de 167. Um limite ajustado só nas perguntas de desenvolvimento que perdesse respostas nas
separadas seria um limite encaixado em dezoito perguntas.

## O que a compressão não conserta

```
ana@vm:~/rag$ python squeezed.py "Can I return a signed copy?"
Returns and refunds policy > Damaged, faulty and wrong items
If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days of delivery. We replace damaged books at no cost and you do not need to send the damaged copy back.
kept:
We replace damaged books at no cost and you do not need to send the damaged copy back.
```

A melhor fonte para esta pergunta é sobre livros danificados, e não sobre exemplares autografados; a
lista de itens que não podem ser devolvidos está em outro pedaço. A compressão manteve a melhor frase
dessa fonte, porque sempre mantém uma, e a frase não é a resposta. **A compressão trabalha dentro das
fontes que a busca achou; ela não transforma uma fonte errada em certa.** A pergunta acima passa do
piso com um pedaço que não a responde, que é o problema da aula 6, e o lugar de consertar isso é a
busca.

A compressão também tem um custo que importa para a aula 7. Uma frase tirada do parágrafo pode perder a
condição que a limitava, um "a menos que" na frase anterior. O limite acima torna isso raro ao manter
toda frase razoavelmente próxima da pergunta, e a aula 15, em que conversas inteiras são encurtadas,
volta ao que nunca pode ser cortado.
