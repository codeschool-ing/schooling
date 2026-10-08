---
title: A primeira busca
version: 2
---

A aula 5 deixou uma tabela de 137 pedaços, cada um com um vetor e os metadados do seu documento, e
depois mudou três documentos de propósito para mostrar o que uma atualização faz. Ponha-os de volta
antes de buscar: o script da aula 1 escreve os documentos de novo, e um índice refeito do zero bate
com eles.

```
ana@vm:~/rag$ sh docs.sh
ana@vm:~/rag$ psql -qc "DROP TABLE chunks"
ana@vm:~/rag$ python ingest.py
chunks: 137  embedded: 137  removed: 0  kept: 0
```

Essa é a tabela que toda busca desta aula lê. Buscar nela por significado é um comando SQL, e o
`search.py` é o módulo que guarda esse comando e os outros três jeitos de buscar que esta aula
acrescenta. Salve o módulo inteiro agora; as seções seguintes desmontam as funções dele uma de cada
vez:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import re\n\nimport numpy as np\nimport psycopg\nfrom openai import OpenAI\nfrom pgvector.psycopg import register_vector\nfrom rank_bm25 import BM25Okapi\nfrom vectors import embed\n\nclient = OpenAI()\n\nconn = psycopg.connect(autocommit=True)\nregister_vector(conn)",
      "note": "Uma conexão para o módulo inteiro, com os tipos do pgvector registrados nela, o rank_bm25 para a busca lexical, e um cliente para o modelo, que o reordenador usa."
    },
    {
      "code": "def rows(where=\"TRUE\", params=()):\n    return conn.execute(f\"SELECT id, path, text FROM chunks WHERE {where} ORDER BY id\", params).fetchall()",
      "note": "Todo pedaço que a condição permite, para os métodos que pontuam em Python e não no banco."
    },
    {
      "code": "def vector(question, k=3, where=\"TRUE\", params=()):\n    \"\"\"The K chunks nearest the question, by cosine similarity, among those WHERE allows.\"\"\"\n    q = embed(question)[0]\n    return conn.execute(\n        f\"SELECT id, path, text, 1 - (embedding <=> %s) FROM chunks WHERE {where}\"\n        \" ORDER BY embedding <=> %s LIMIT %s\", (q, *params, q, k)).fetchall()",
      "note": "A pergunta vira embedding com o mesmo all-minilm com que os pedaços viraram, e o PostgreSQL ordena os pedaços pela distância de cosseno, `<=>`. O `1 -` transforma a distância de volta em similaridade. O `WHERE` é o gancho para os filtros desta aula."
    },
    {
      "code": "TOKEN = re.compile(r\"[a-z0-9]+(?:[-.%][a-z0-9]+)*%?\")\n\n\ndef words(text):\n    return TOKEN.findall(text.lower())",
      "note": "Palavras são sequências de letras e dígitos, mantidas inteiras através de um hífen, um ponto ou um sinal de porcentagem, para que `E-4104`, `9.90` e `12%` sejam uma palavra cada. Em minúsculas, porque `Express` e `express` são a mesma palavra para quem lê."
    },
    {
      "code": "def lexical(question, k=3, where=\"TRUE\", params=()):\n    \"\"\"The K chunks BM25 scores highest for the question's words.\"\"\"\n    found = rows(where, params)\n    bm25 = BM25Okapi([words(path + \" \" + text) for _, path, text in found])\n    scores = bm25.get_scores(words(question))\n    return [(*found[i], float(scores[i])) for i in np.argsort(-scores, kind=\"stable\")[:k]]",
      "note": "BM25 sobre o caminho e o texto de cada pedaço. Ele é refeito a cada chamada, o que serve para 137 pedaços e é o que o índice invertido de um buscador faz uma vez e guarda."
    },
    {
      "code": "def hybrid(question, k=3, depth=20, where=\"TRUE\", params=()):\n    \"\"\"Reciprocal rank fusion of the two lists, each DEPTH long.\"\"\"\n    fused = {}\n    for ranking in (vector(question, depth, where, params), lexical(question, depth, where, params)):\n        for rank, row in enumerate(ranking, 1):\n            fused.setdefault(row[0], [row[:3], 0.0])[1] += 1 / (60 + rank)\n    best = sorted(fused.values(), key=lambda item: -item[1])[:k]\n    return [(*row, score) for row, score in best]",
      "note": "Cada lista contribui com 1/(60 + posição) para cada pedaço que tem, e um pedaço nas duas listas ganha as duas parcelas. As notas dos dois métodos nunca são comparadas, só as posições, e é isso que permite combinar um cosseno com uma nota BM25."
    },
    {
      "code": "JUDGE = \"\"\"Question: {question}\n\nPassage:\n{passage}\n\nHow well does the passage answer the question? Reply with one whole number from 0 (not at all) to 10 (completely), and nothing else.\"\"\"",
      "note": "A instrução, a mesma para todo candidato. A pergunta vem primeiro, para que as vinte requisições de uma pergunta compartilhem o começo do prompt."
    },
    {
      "code": "def rerank(question, candidates, k=3):\n    \"\"\"The generator reads the question with each candidate and gives it a mark; the marks decide the order.\"\"\"\n    scores = []\n    for _, path, text, _ in candidates:\n        reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, max_tokens=4, messages=[\n            {\"role\": \"user\", \"content\": JUDGE.format(question=question, passage=path + \"\\n\" + text)}])\n        found = re.search(r\"\\d+\", reply.choices[0].message.content)\n        scores.append(int(found.group()) if found else 0)\n    order = np.argsort(-np.array(scores), kind=\"stable\")[:k]\n    return [(*candidates[i][:3], scores[i]) for i in order]",
      "note": "Uma chamada por candidato, no máximo quatro tokens de resposta, e uma resposta sem número conta como 0. A ordenação é estável, então candidatos com a mesma nota mantêm a ordem que a primeira busca lhes deu, o que com notas de 0 a 10 acontece com frequência."
    }
  ]
}
```

O `show.py` roda um dos métodos do módulo e imprime os cinco melhores pedaços, as notas, os caminhos
e as primeiras palavras do texto:

```schooling-example
{
  "language": "python",
  "file": "show.py",
  "parts": [
    {
      "code": "import sys\n\nimport search\n\nmethod, question = sys.argv[1], sys.argv[2]\nfor rank, (id, path, text, score) in enumerate(getattr(search, method)(question, 5), 1):\n    print(f\"{rank}  {score:7.3f}  {path}  | {' '.join(text.split())[:48]}\")",
      "note": "O método vem da linha de comando, então o mesmo programa mostra toda busca desta aula."
    }
  ]
}
```

```
ana@vm:~/rag$ python show.py vector "How much is express delivery?"
1    0.658  Shipping and delivery > Delivery options and costs  | The threshold of 40 is the value of the books in
2    0.612  Shipping and delivery > Delivery options and costs  | | option | time | cost | | --- | --- | --- | | s
3    0.504  Shipping and delivery > Delivery options and costs  | Express orders placed after 2 pm, or on a Saturd
4    0.499  Shipping and delivery > Addresses  | Express delivery is not available to post office
5    0.492  Shipping and delivery > Parcels that are late or lost  | A standard parcel whose tracking has not changed
```

**Os três primeiros resultados são todos de *Delivery options and costs*,** e o segundo é a tabela com
o preço. Na aula 1 o preço estava em algum lugar dentro de uma seção inteira cortada no título; aqui a tabela é
um pedaço próprio, e o caminho diz ao embedding do que ela trata.

## O que os números significam

A nota é a similaridade de cosseno entre o vetor da pergunta e o do pedaço, de 1 para direção idêntica
para baixo. É um sinal de ordenação e nada mais. 0,658 não é "66% relevante"; é maior que 0,612, e é
só isso que uma busca pode concluir. Notas de perguntas diferentes também não se comparam, porque uma
pergunta com palavras comuns cai perto de tudo, e uma com palavras raras não. A última seção desta aula
tenta mesmo assim transformar a nota numa decisão, e mostra até onde isso vai.

## No que esta busca é boa e no que é ruim

O `measure.py`, rodado na seção sobre busca híbrida, avalia esta busca nas 26 perguntas com resposta do
conjunto de teste da aula 4: o pedaço com a resposta vem em primeiro em 19 delas e entre os três
primeiros em todas as 26. É o caminho da aula 5 dando resultado. Em perguntas parafraseadas, as palavras
do cliente contra as da política, uma busca vetorial densa é muito difícil de vencer.

Ela tem um ponto cego conhecido, que a aula 2 achou: **uma palavra que é um identificador e não um
significado.** Códigos de erro, números de cláusula, códigos de produto e strings de versão carregam
quase nenhum significado que um modelo de embeddings tenha aprendido, então dois deles que diferem num
caractere parecem iguais. A próxima seção mede isso e acrescenta a busca que não tem esse ponto cego.
