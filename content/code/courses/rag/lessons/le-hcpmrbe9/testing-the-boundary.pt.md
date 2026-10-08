---
title: Testando a fronteira
version: 2
---

Uma permissão que não é testada é uma permissão que funcionou no dia em que foi escrita. O teste desta
é simples de enunciar: **para todo papel, para toda pergunta que temos, nenhuma linha devolvida pode vir
de um público que o papel não pode ler**. O `audit.py` o roda sobre as 36 perguntas do `eval.jsonl` e do
`identifiers.jsonl`, cinco linhas por pergunta, para cada um dos cinco papéis:

```schooling-example
{
  "language": "python",
  "file": "audit.py",
  "parts": [
    {
      "code": "import json\nimport sys\n\nimport access\nfrom vectors import embed\nfrom search import conn as loader\n\n\ndef careless(conn, role, question, k):\n    \"\"\"A search written without the role, through a connection the policy does not limit.\"\"\"\n    q = embed(question)[0]\n    return loader.execute(\"SELECT id, path, text, audience, 1 - (embedding <=> %s) FROM chunks\"\n                          \" ORDER BY embedding <=> %s LIMIT %s\", (q, q, k)).fetchall()\n\n\nsearch = careless if \"--careless\" in sys.argv else access.search\nassistant = access.connect()\nquestions = [q[\"question\"] for q in map(json.loads, open(\"data/eval.jsonl\"))]\nquestions += [q[\"question\"] for q in map(json.loads, open(\"data/identifiers.jsonl\"))]\nleaks, seen = 0, 0\nfor role in access.ROLES:\n    for question in questions:\n        for row in search(assistant, role, question, 5):\n            seen += 1\n            leaks += row[3] not in access.audiences(role)\nprint(f\"{len(access.ROLES)} roles x {len(questions)} questions, {seen} rows returned, {leaks} outside the role\")",
      "note": "Todo papel faz toda pergunta dos dois conjuntos de teste, e cada linha devolvida é conferida contra o que o papel pode ler; o `--careless` roda a mesma auditoria contra uma busca escrita sem o papel, pela conexão do carregador."
    }
  ]
}
```
```
ana@vm:~/rag$ python audit.py
5 roles x 36 questions, 900 rows returned, 0 outside the role
ana@vm:~/rag$ python audit.py --careless
5 roles x 36 questions, 900 rows returned, 210 outside the role
```

**900 linhas, nenhuma fora do seu papel.** A segunda linha é o mesmo teste rodado contra uma busca
escrita sem o papel, por uma conexão que a política não limita, e ele acha **210** linhas que um leitor
não deveria ter visto. Essa execução não é enfeite: um teste que nunca foi visto falhar pode estar
passando porque não confere nada. Rodá-lo uma vez contra uma busca quebrada prova que ele sabe
distinguir.

O que este teste cobre e o que não cobre:

- **Cobre o caminho do código.** Um papel acrescentado ao `ROLES` com os públicos errados, uma função
  nova que chama outra busca que não o `access.search`, uma mudança no `WHERE`: cada um o faz falhar.
- **Cobre as perguntas que tem.** Trinta e seis perguntas alcançam os documentos que alcançam. Um
  conjunto de sondas escrito para permissões acrescenta perguntas dirigidas a cada documento restrito,
  como a marcação por reembolsos e o limite de fraude, para que todo pedaço restrito seja o melhor
  casamento de pelo menos uma sonda.
- **Não testa a política**, porque o `access.search` filtra no `WHERE` antes de a política ser
  necessária. A política tem o seu próprio teste, o assistente contando linhas sem nada definido e com
  cada público definido, como na seção sobre o banco. Cada camada é testada sozinha, ou uma quebra numa
  fica escondida pela outra.

Rode-o na CI a cada mudança no código, nos papéis ou no acervo. Um documento novo com a linha
`audience:` errada é um vazamento que sai com a próxima reconstrução do índice, e só um teste sobre os
dados indexados o enxerga.
