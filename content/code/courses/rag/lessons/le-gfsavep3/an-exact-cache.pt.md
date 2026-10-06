---
title: Um cache exato
version: 1
---

Um cache exato guarda cada resposta sob uma chave e a serve de novo quando a mesma chave volta. Todo o
desenho é a chave, e a chave fácil, o texto da pergunta, está errada de dois jeitos:

```schooling-example
{
  "language": "python",
  "file": "exact.py",
  "parts": [
    {
      "code": "import hashlib\nimport json\nimport re\n\nfrom search import conn\n\ncosts = json.load(open(\"costs.json\"))\nLOG = [json.loads(line) for line in open(\"data/querylog.jsonl\")]",
      "note": "Os custos calculados acima e o registro."
    },
    {
      "code": "def version():\n    \"\"\"The index the answers came from: a hash of every chunk id, which changes when any chunk does.\"\"\"\n    ids = [i for (i,) in conn.execute(\"SELECT id FROM chunks ORDER BY id\")]\n    return hashlib.sha256(\"\\n\".join(ids).encode()).hexdigest()[:12]",
      "note": "A versão do índice: um hash de todos os ids de pedaço. Os ids da aula 5 mudam quando o texto de um pedaço muda, então qualquer edição, acréscimo ou exclusão dá uma versão nova."
    },
    {
      "code": "def key(question, audiences, index):\n    \"\"\"Same words, same reader's permissions, same index: only then is an answer the same answer.\"\"\"\n    words = re.sub(r\"[^a-z0-9 ]\", \"\", question.lower()).split()\n    return (\" \".join(words), \",\".join(sorted(audiences)), index)",
      "note": "A chave: a pergunta sem maiúsculas e pontuação, os públicos que o leitor pode ver, e a versão do índice. Dois leitores com permissões diferentes nunca compartilham uma resposta, e uma resposta nunca sobrevive aos documentos de onde veio."
    },
    {
      "code": "if __name__ == \"__main__\":\n    index = version()\n    cache, calls, saved = set(), 0, 0\n    for q in LOG:\n        k = key(q[\"text\"], [\"public\"], index)\n        c = costs[q[\"text\"]]\n        if k in cache:\n            saved += c[\"input\"] + c[\"output\"]\n        else:\n            cache.add(k)\n            calls += bool(c[\"input\"])\n    print(f\"index version {index}\")\n    print(f\"{len(cache)} keys, {len(LOG) - len(cache)} hits of {len(LOG)} ({(len(LOG) - len(cache)) / len(LOG):.0%}), \"\n          f\"{calls} model calls, {saved} tokens not spent\")",
      "note": "A semana reproduzida pelo cache: uma chave já vista é um acerto, e os tokens que ela teria custado contam como não gastos."
    }
  ]
}
```

A chave tem três partes, e cada uma fecha um buraco que uma aula anterior achou.

- **A pergunta, normalizada.** Minúsculas, sem pontuação, para que "How many days...?" e "how many
  days..." sejam uma entrada só. Nada mais agressivo: radicalização ou sinônimos transformam um cache
  exato num aproximado sem medi-lo.
- **Os públicos do leitor.** A aula 14 deu ao atendente documentos que um cliente não pode ver. Um cache
  com a pergunta como única chave entregaria a resposta do atendente, feita do manual, ao próximo cliente
  que digitasse as mesmas palavras. A aula 16 achou o mesmo buraco pelo outro lado, com uma resposta
  contaminada.
- **A versão do índice.** Uma resposta é verdadeira sobre os documentos de onde veio. Quando eles mudam,
  como a seção depois da próxima mostra, toda resposta feita sobre eles tem de deixar de ser servida.

```
ana@lab:~/rag$ python exact.py
index version 0acfdfa0d064
38 keys, 462 hits of 500 (92%), 35 model calls, 156581 tokens not spent
```

**462 de 500 perguntas foram acertos, e a semana precisou de 35 chamadas ao modelo em vez de 486**, com
156.581 tokens não gastos. Neste registro o cache exato faz quase todo o trabalho, pelo motivo que a
seção anterior deu: o registro se repete muito mais que um real. Num registro real a taxa de acerto é
menor e o desenho é o mesmo.

Mais uma propriedade torna este cache seguro de acrescentar: **ele só pode devolver uma resposta que o
pipeline já deu à mesma pergunta, para um leitor com as mesmas permissões, a partir dos mesmos
documentos.** O que o teste da aula 8 disse sobre essa resposta continua valendo. O mesmo não vale para o
próximo cache.
