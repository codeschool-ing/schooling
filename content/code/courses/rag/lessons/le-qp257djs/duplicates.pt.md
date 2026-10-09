---
title: Duplicatas
version: 2
---

Uma empresa escreve a mesma regra em mais de um lugar. A política de devoluções da Marginalia tem uma
seção sobre e-books e audiolivros, e o documento sobre e-books e audiolivros tem a sua; os dois dizem
quando um audiolivro pode ser reembolsado. Os dois são atuais, os dois são públicos, e uma busca por
essa pergunta acha os dois, perto do topo. Mandar os dois não compra nada: a segunda cópia diz o que a
primeira disse, no lugar de uma fonte que poderia dizer outra coisa.

O `dedupe` percorre as fontes da melhor para a pior e descarta uma que seja parecida demais com uma
fonte já mantida:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def dedupe(sources, same=SAME):\n    \"\"\"Drop a source that says what a better one already said.\"\"\"\n    if not sources:\n        return []\n    v = embed([s[\"text\"] for s in sources])\n    kept = []\n    for i in range(len(sources)):\n        if all(v[i] @ v[j] < same for j in kept):\n            kept.append(i)\n    return [sources[i] for i in kept]",
      "note": "Percorrer as fontes da melhor para a pior, e manter uma só se ela for menos de `SAME`, 0,9, parecida com toda fonte já mantida. Uma fonte que repete outra melhor sai; a melhor fica, porque veio antes."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "alike.py",
  "parts": [
    {
      "code": "import sys\n\nfrom context import candidates, dedupe\n\nfound = candidates(sys.argv[1], 10)\nfor s in found:\n    print(f\"{s['score']:.3f}  {s['path']}\")\nprint(\"after dedupe:\")\nfor s in dedupe(found):\n    print(f\"{s['score']:.3f}  {s['path']}\")",
      "note": "Os dez candidatos mais próximos de uma pergunta, e o que sobra deles depois do `dedupe`."
    }
  ]
}
```
```
ana@vm:~/rag$ python alike.py "When can an audiobook be refunded?"
0.902  Returns and refunds policy > E-books and audiobooks
0.894  E-books and audiobooks > Audiobooks
0.831  Returns and refunds policy > E-books and audiobooks
0.812  E-books and audiobooks > Refunds for e-books
0.778  E-books and audiobooks > Refunds for e-books
0.665  Returns and refunds policy > Damaged, faulty and wrong items
0.625  Terms of sale > 8. Digital content
0.622  Returns and refunds policy > Damaged, faulty and wrong items
0.610  Returns and refunds policy > The return window
0.585  Returns and refunds policy > Damaged, faulty and wrong items
after dedupe:
0.902  Returns and refunds policy > E-books and audiobooks
0.831  Returns and refunds policy > E-books and audiobooks
0.778  E-books and audiobooks > Refunds for e-books
0.665  Returns and refunds policy > Damaged, faulty and wrong items
0.625  Terms of sale > 8. Digital content
0.622  Returns and refunds policy > Damaged, faulty and wrong items
0.610  Returns and refunds policy > The return window
0.585  Returns and refunds policy > Damaged, faulty and wrong items
```

**Dez fontes passaram do piso, e duas foram descartadas**: a seção de audiolivros do documento de
e-books, 0,894 para a pergunta, e um dos dois pedaços da seção sobre reembolso de e-books, 0,812. Cada
uma tinha similaridade 0,9 ou mais com um pedaço da política de devoluções que teve nota maior e já
estava mantido. A política de devoluções disse primeiro, então a política de devoluções fica.

O limite é a decisão. Com 0,9 só quase-cópias saem, e nas 30 perguntas isso é raro:

```schooling-example
{
  "language": "python",
  "file": "removed.py",
  "parts": [
    {
      "code": "import json\n\nfrom context import candidates, dedupe\n\ntotal, removed = 0, 0\nfor q in map(json.loads, open(\"data/eval.jsonl\")):\n    found = candidates(q[\"question\"], 10, \"status = %s\", (\"current\",))\n    total += len(found)\n    removed += len(found) - len(dedupe(found))\nprint(f\"{removed} of {total} sources removed as duplicates, over 30 questions\")",
      "note": "Quantos dos candidatos o `dedupe` remove no conjunto de teste inteiro."
    }
  ]
}
```
```
ana@vm:~/rag$ python removed.py
5 of 115 sources removed as duplicates, over 30 questions
```

Baixe o limite e ele começa a tirar fontes que se sobrepõem sem se repetir, como uma política e uma
exceção a ela, que é o par de que a aula 7 precisava inteiro. **Uma duplicata são duas fontes que
quem lê poderia trocar sem perceber**, e o limite deve tirar só essas. A duplicata do Haystack na aula
11, o mesmo pedaço guardado duas vezes com metadados diferentes, é o caso que ele tira sem dúvida
nenhuma: a similaridade dele consigo mesmo é 1.

Dois tipos de repetição não são trabalho desta função. Uma versão substituída de um documento não é
uma duplicata, é uma contradição, e o filtro de status da aula 6 a tira antes que chegue até aqui. E
dois pedaços cortados da mesma seção, que o prompt do cartão-presente tinha como fontes 2 e 3, são
vizinhos, e não repetições; estão um ao lado do outro porque a resposta precisava dos dois.
