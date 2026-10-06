---
title: Ids que barateiam a reindexação
version: 1
---

Documentos mudam um parágrafo de cada vez. Um pipeline que refaz o embedding do corpus inteiro sempre
que algo muda é correto e desperdiça; um que refaz só o que mudou precisa saber o que mudou, e o jeito
mais barato de saber é fazer o id do pedaço depender do conteúdo.

## Um hash do conteúdo como id

O `chunks_of` monta cada id com o id do documento e os doze primeiros caracteres hexadecimais de um hash
SHA-256 do caminho e do texto do pedaço. Mesmo texto, mesmo id; uma palavra diferente, outro id. O
`main` então compara dois conjuntos de ids, o que os documentos produzem agora e o que a tabela já tem:

```schooling-example
{
  "language": "python",
  "file": "ingest.py",
  "parts": [
    {
      "code": "def main():\n    want = [c for doc_id, (meta, body) in load().items() for c in chunks_of(doc_id, meta, body)]\n    with psycopg.connect() as conn:\n        conn.execute(SCHEMA)\n        register_vector(conn)\n        have = {row[0] for row in conn.execute(\"SELECT id FROM chunks\")}\n        new = [c for c in want if c[\"id\"] not in have]\n        gone = have - {c[\"id\"] for c in want}\n        for c, v in zip(new, embed([c[\"path\"] + \"\\n\" + c[\"text\"] for c in new])):\n            c[\"embedding\"] = v\n        with conn.cursor() as cur:\n            cur.executemany(\n                \"INSERT INTO chunks VALUES (%(id)s, %(doc_id)s, %(doc_version)s, %(status)s, %(audience)s,\"\n                \" %(owner)s, %(updated)s, %(path)s, %(position)s, %(text)s, %(tokens)s, %(model)s,\"\n                \" %(embedding)s::vector)\", new)\n            cur.executemany(\n                \"UPDATE chunks SET doc_version = %(doc_version)s, status = %(status)s,\"\n                \" audience = %(audience)s, owner = %(owner)s, updated = %(updated)s,\"\n                \" position = %(position)s WHERE id = %(id)s\", [c for c in want if c[\"id\"] in have])\n            cur.execute(\"DELETE FROM chunks WHERE id = ANY(%s)\", (list(gone),))\n    print(f\"chunks: {len(want)}  embedded: {len(new)}  removed: {len(gone)}  kept: {len(want) - len(new)}\")",
      "note": "O que os documentos dizem agora (`want`) é comparado com o que a tabela tem (`have`). Só os ids novos viram embedding e são inseridos; os ids que não são mais desejados são apagados; todo pedaço que sobrevive tem os metadados reescritos, porque um status pode mudar sem o texto mudar."
    },
    {
      "code": "if __name__ == \"__main__\":\n    main()"
    }
  ]
}
```

## Rodando duas vezes

```
ana@lab:~/rag$ python ingest.py
chunks: 137  embedded: 0  removed: 0  kept: 137
```

**Nenhum embedding, 137 mantidos.** Todo id que os documentos produziram já estava na tabela, então
nenhuma requisição foi ao provedor. É isso que torna a execução segura para repetir: uma execução que
morreu no meio, depois de gerar alguns lotes, é terminada rodando de novo, e só o que falta é mandado.

## Mudando uma frase

Suponha que o financeiro encurte o prazo de reembolso. A frase do regulamento sobre isso é editada, na
cópia de trabalho do corpus da ana:

```
ana@lab:~/rag$ sed -i "s/We refund within three working days/We refund within two working days/" data/docs/returns-policy.md
ana@lab:~/rag$ python ingest.py
chunks: 137  embedded: 1  removed: 1  kept: 136
```

**Um pedaço com embedding novo, um removido, 136 mantidos.** A frase editada mora num pedaço; o texto
desse pedaço mudou, então o hash mudou, então o id antigo deixou de ser desejado e o novo estava
faltando. Um embedding, uma inserção, uma exclusão, e o índice está atual. Para um corpus de milhões de
pedaços em que algumas centenas mudam por dia, essa é a diferença entre um processo noturno de minutos e
um de dias.

## O que um hash do conteúdo não pega

**Uma fronteira de pedaço que se mexe.** Se uma edição acrescenta um parágrafo, o `structured` pode
juntar os parágrafos seguintes de outro jeito, e vários pedaços mudam de texto sem ninguém editá-los.
Eles ganham ids novos e têm o embedding refeito, corretamente; o custo de uma edição nem sempre é um
pedaço.

**Uma troca de modelo.** O id não diz nada sobre qual modelo fez o vetor. Trocar de modelo de embeddings
quer dizer que todo vetor está errado, e nenhum id muda. A coluna `model` existe para a troca ser feita
de propósito: gerar tudo com o modelo novo em linhas novas ou numa tabela nova, conferir, e então trocar.
A aula 18 do `embeddings-vectors` mediu quanto custa refazer o embedding de um corpus inteiro.

**Uma mudança de metadados.** Um documento marcado como substituído, ou movido para outro público, tem o
mesmo texto e portanto os mesmos ids. Por isso o `main` reescreve os metadados de todo pedaço que
sobrevive em toda execução, o que é barato porque é uma atualização no banco sem embedding. A próxima
seção é esse caso.
