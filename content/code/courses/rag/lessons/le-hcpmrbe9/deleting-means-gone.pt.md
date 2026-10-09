---
title: Apagar quer dizer sumir
version: 2
---

A aula 2 pôs uma exclusão que funcione entre as coisas que conhecimento interno pede a um pipeline:
quando um documento é retirado, os pedaços dele precisam sair do índice no mesmo dia. Retirar também é
uma mudança de permissão, a mais completa, para ninguém, e merece o mesmo tipo de prova que os filtros.
O `deleted.py` faz duas perguntas ao sistema: quantos pedaços do manual do armazém estão na tabela, e
quantos dos cinco pedaços mais próximos do atendente, numa pergunta que só o manual responde, vêm dele.

```schooling-example
{
  "language": "python",
  "file": "deleted.py",
  "parts": [
    {
      "code": "import access\nfrom search import conn\n\nQUESTION = \"What is a SEV-2 incident?\"\nchunks = conn.execute(\"SELECT count(*) FROM chunks WHERE doc_id = 'warehouse-runbook'\").fetchone()[0]\nfound = [r[1] for r in access.search(access.connect(), \"agent\", QUESTION, 5)]\nfrom_it = [p for p in found if p.startswith(\"Warehouse on-call runbook\")]\nprint(f\"chunks of warehouse-runbook in the table: {chunks}\")\nprint(f\"of the agent's 5 nearest for {QUESTION!r}, from the runbook: {len(from_it)}\")",
      "note": "Quantos pedaços do manual do armazém a tabela guarda, e quantos dos cinco resultados mais próximos de um atendente para uma pergunta do manual vêm dele."
    }
  ]
}
```
```
ana@vm:~/rag$ python deleted.py
chunks of warehouse-runbook in the table: 7
of the agent's 5 nearest for 'What is a SEV-2 incident?', from the runbook: 4
ana@vm:~/rag$ rm data/docs/warehouse-runbook.md && python ingest.py
chunks: 130  embedded: 0  removed: 7  kept: 130
ana@vm:~/rag$ python deleted.py
chunks of warehouse-runbook in the table: 0
of the agent's 5 nearest for 'What is a SEV-2 incident?', from the runbook: 0
```

Antes: **7 pedaços, e 4 dos 5 resultados do atendente.** O arquivo é removido e o `ingest.py` da aula 5
roda, comparando os ids que quer com os ids que tem: **7 removidos**. Depois: **0 pedaços, e 0 dos
resultados do atendente.** Depois de uma exclusão os dois números têm um único valor aprovado, zero,
então uma verificação na CI os afirma em vez de imprimi-los, e uma exclusão que deixasse um pedaço para
trás falharia no primeiro e muito provavelmente no segundo.

Isso é o índice. O texto de um documento também viaja para lugares que o índice não cobre, e uma
exclusão que para na tabela parou cedo:

- **O registro de consultas.** O `queries.jsonl` da aula 9 guarda os ids dos pedaços que cada resposta
  usou, e as respostas citam as frases deles. Um documento retirado continua sendo lido de volta de um
  registro do que foi respondido.
- **Caches.** A aula 17 guarda respostas em cache pela pergunta. Uma resposta em cache feita de um
  pedaço apagado continua a servi-lo até expirar.
- **Memórias e resumos**, os das aulas 13 e 15, onde uma resposta que citou o documento foi guardada.
- **Backups**, que uma equipe não consegue editar, e que por isso precisam de um prazo de retenção curto
  o bastante para que uma exclusão um dia chegue até eles.

Para cada um, o teste tem o mesmo formato do `deleted.py`: depois da exclusão, pergunte ao lugar pelo
documento e conte o que volta. Zero é o único número aprovado.
