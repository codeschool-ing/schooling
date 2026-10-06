---
title: Conferindo o que foi carregado
version: 1
---

Uma indexação que termina sem erro provou que terminou. Não provou que o índice está certo: um documento
pode estar faltando, um vetor pode ter vindo do modelo errado, um pedaço pode ter o triplo do tamanho que
o orçamento do prompt supôs. Essas falhas são silenciosas na hora da indexação e só aparecem depois, como
respostas um pouco piores, que é o tipo de falha mais difícil de rastrear até a origem.

Então a execução termina com uma verificação que **falha alto**:

```schooling-example
{
  "language": "python",
  "file": "check_index.py",
  "parts": [
    {
      "code": "import sys\n\nimport psycopg\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector",
      "note": "A verificação precisa do banco, do tipo vetor e do cliente de embeddings."
    },
    {
      "code": "failures = []\nwith psycopg.connect() as conn:\n    register_vector(conn)\n    one = lambda sql: conn.execute(sql).fetchone()[0]\n    docs = one(\"SELECT count(DISTINCT doc_id) FROM chunks\")\n    if docs != 13:\n        failures.append(f\"{docs} documents in the index, expected 13\")\n    if one(\"SELECT count(*) FROM chunks WHERE vector_dims(embedding) <> 384\"):\n        failures.append(\"a vector with the wrong number of dimensions\")\n    if one(\"SELECT count(DISTINCT model) FROM chunks\") != 1:\n        failures.append(\"vectors from more than one model\")\n    if one(\"SELECT max(tokens) FROM chunks\") > 400:\n        failures.append(\"a chunk over 400 tokens\")",
      "note": "Quatro verificações de estrutura: todos os documentos presentes, todo vetor do tamanho certo, um único modelo para todos, e nenhum pedaço maior do que o orçamento do prompt supõe. Cada falha é juntada em vez de levantada, para uma execução relatar todas."
    },
    {
      "code": "    # A question whose answer is known: the chunk holding it must come first.\n    q = OpenAI().embeddings.create(model=\"lab-minilm\", input=[\"How long is a gift card valid?\"]).data[0].embedding\n    top = conn.execute(\"SELECT path FROM chunks ORDER BY embedding <=> %s::vector LIMIT 1\", (q,)).fetchone()[0]\n    if \"Validity\" not in top:\n        failures.append(f\"the gift card question found {top!r}\")",
      "note": "Uma resposta conhecida: a pergunta do vale-presente tem de achar a seção *Validity* primeiro. Ela passa pelo provedor, pelo operador e pelo índice, o mesmo caminho de uma pergunta real."
    },
    {
      "code": "print(\"\\n\".join(failures) or f\"ok: {docs} documents, every check passed\")\nsys.exit(1 if failures else 0)",
      "note": "Cada falha impressa, e uma saída diferente de zero se houver alguma, para o que vier depois poder parar."
    }
  ]
}
```

Cada teste é algo que já deu errado em pipelines reais. Um documento que não foi lido e ficou de fora.
Uma configuração que apontou metade da execução para outro modelo. Uma mudança no corte que deixou um
pedaço engolir uma seção inteira. E o último teste é o que vale copiar para todo lugar: **uma pergunta
cuja resposta é conhecida, rodada contra o índice, com o pedaço que tem de vir primeiro nomeado de
antemão.** Ela exercita o caminho inteiro, o modelo, os vetores, o operador e o índice, numa única
afirmação.

## Quando passa e quando falha

Rodada depois da primeira carga, ela passa:

```
ana@lab:~/rag$ python check_index.py; echo "exit $?"
ok: 13 documents, every check passed
exit 0
```

Rodada no fim desta aula, depois que o regulamento de 2025 foi apagado, ela falha:

```
ana@lab:~/rag$ python check_index.py; echo "exit $?"
12 documents in the index, expected 13
exit 1
```

**Essa falha está certa.** O corpus agora tem doze documentos, e uma verificação que espera treze deve
dizer isso; se a exclusão foi intencional é decisão de uma pessoa, e o código de saída é o que impede uma
implantação automática de tomá-la em silêncio. Num pipeline real a contagem esperada vem da fonte dos
documentos, não de uma constante, e a verificação compara as duas.

## Onde ela roda

A verificação pertence ao fim de toda indexação, e uma saída diferente de zero deveria parar o que vem a
seguir: a troca para um índice novo, a implantação, o anúncio de que a mudança de política está no ar.
Uma verificação que só imprime é uma verificação que alguém lê no dia seguinte ao incidente. A aula 8
acrescenta a outra metade, um teste de respostas em vez de índice, e as duas juntas são o que deixa uma
equipe trocar o corte ou o modelo numa terça à tarde sem medo.
