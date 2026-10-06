---
title: A primeira busca
version: 1
---

A aula 5 deixou uma tabela de 137 pedaços, cada um com um vetor e os metadados do seu documento.
Buscar nela por significado é um comando SQL, e o `search.py` é o módulo que guarda esse comando e os
outros três jeitos de buscar que esta aula acrescenta:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import re\n\nimport minilm\nimport numpy as np\nimport psycopg\nfrom minilm import embed\nfrom pgvector.psycopg import register_vector\nfrom rank_bm25 import BM25Okapi\n\nconn = psycopg.connect(autocommit=True)\nregister_vector(conn)",
      "note": "Uma conexão para o módulo inteiro, com os tipos do pgvector registrados nela, e o rank_bm25 para a busca lexical."
    },
    {
      "code": "def rows(where=\"TRUE\", params=()):\n    return conn.execute(f\"SELECT id, path, text FROM chunks WHERE {where} ORDER BY id\", params).fetchall()",
      "note": "Todo pedaço que a condição permite, para os métodos que pontuam em Python e não no banco."
    },
    {
      "code": "def vector(question, k=3, where=\"TRUE\", params=()):\n    \"\"\"The K chunks nearest the question, by cosine similarity, among those WHERE allows.\"\"\"\n    q = embed(question)[0]\n    return conn.execute(\n        f\"SELECT id, path, text, 1 - (embedding <=> %s) FROM chunks WHERE {where}\"\n        \" ORDER BY embedding <=> %s LIMIT %s\", (q, *params, q, k)).fetchall()",
      "note": "A pergunta vira embedding com o mesmo MiniLM que o `lab-minilm` serve, e o PostgreSQL ordena os pedaços pela distância de cosseno, `<=>`. O `1 -` transforma a distância de volta em similaridade. O `WHERE` é o gancho para os filtros desta aula."
    }
  ]
}
```

O `show.py` roda um dos métodos do módulo e imprime os cinco melhores pedaços, as notas, os caminhos e
as primeiras palavras do texto:

```
ana@lab:~/rag$ python show.py vector "How much is express delivery?"
1    0.658  Shipping and delivery > Delivery options and costs  | The threshold of 40 is the value of the books in
2    0.612  Shipping and delivery > Delivery options and costs  | | option | time | cost | | --- | --- | --- | | s
3    0.504  Shipping and delivery > Delivery options and costs  | Express orders placed after 2 pm, or on a Saturd
4    0.499  Shipping and delivery > Addresses  | Express delivery is not available to post office
5    0.492  Shipping and delivery > Parcels that are late or lost  | A standard parcel whose tracking has not changed
```

**Os três primeiros resultados são todos de *Delivery options and costs*,** e o segundo é a tabela com
o preço. Compare com a aula 1, em que seções cortadas nos títulos e sem caminho no embedding puseram a
seção certa em primeiro e a resposta ainda assim não trouxe o número: aqui a tabela é um pedaço próprio,
e o caminho diz ao embedding do que ela trata.

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
