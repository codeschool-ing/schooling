---
title: Medindo uma busca
version: 1
---

Testar algumas perguntas e gostar das respostas é como a maioria das buscas vai para o ar, e é
também como vai para o ar uma busca que falha em um terço das perguntas reais. Para comparar duas
buscas, ou uma busca antes e depois de uma mudança, você precisa de **julgamentos de relevância**:
uma lista de perguntas, cada uma com os documentos que a respondem, decidida por uma pessoa antes de
a busca rodar.

`data/queries.jsonl` é essa lista para este curso: 24 perguntas que um cliente poderia digitar, cada
uma com o artigo ou os artigos que o curso decidiu que a respondem. A primeira é
`{"id": "q01", "text": "how do I get my money back", "relevant": ["h15", "h14"]}`.

## Recall em k

A medida é simples. Para cada pergunta, rode a busca e olhe os `k` primeiros resultados; conte a
pergunta como encontrada se um artigo relevante estiver entre eles. O **recall@1** pergunta se o
artigo certo veio primeiro, e o **recall@3** se ele ficou entre os três primeiros, que é mais ou
menos o que um cliente lê antes de desistir.

A rigor, o recall@k é a fração de *todos* os documentos relevantes que aparecem entre os `k`
primeiros, e a q01 tem dois. Com uma resposta por pergunta, como em 23 destas 24, as duas
definições coincidem, e este curso conta uma pergunta como encontrada quando qualquer das respostas
dela está ali.

```schooling-example
{
  "language": "python",
  "file": "evaluate.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom bm25 import keyword_search\nfrom search import D, ids, embed\n\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nexact = [(\"MG-20481937\", [\"h06\"]), (\"Pix\", [\"h20\"]), (\"EPUB\", [\"h32\"]), (\"4.90\", [\"h07\"]),\n         (\"Visa\", [\"h20\"]), (\"prepaid label\", [\"h14\"]), (\"photo ID\", [\"h11\"]),\n         (\"cash on delivery\", [\"h20\"])]\nnatural = [(q[\"text\"], q[\"relevant\"]) for q in queries]",
      "note": "Dois conjuntos de julgamentos: as 24 perguntas do curso e oito textos exatos escritos para esta seção, cada um com o artigo que o contém."
    },
    {
      "code": "def embedding_search(text):\n    return list(np.argsort(-(D @ embed(text)[0])))\n\ndef recall(rank, questions, k):\n    found = 0\n    for text, relevant in questions:\n        found += any(ids[i] in relevant for i in rank(text)[:k])\n    return found",
      "note": "Uma ordem dos 40 artigos por embedding, e o recall: para quantas perguntas um artigo relevante aparece entre os `k` primeiros de uma ordem. `rank` é qualquer função de uma pergunta para uma lista de linhas, então o mesmo código mede as duas buscas."
    },
    {
      "code": "if __name__ == \"__main__\":\n    for name, questions in ((\"24 questions\", natural), (\"8 exact strings\", exact)):\n        print(name)\n        for method, rank in ((\"keyword\", keyword_search), (\"embedding\", embedding_search)):\n            print(f\"  {method:10} recall@1 {recall(rank, questions, 1):2}  recall@3 {recall(rank, questions, 3):2}\")",
      "note": "Recall em 1 e em 3 das duas buscas, nos dois conjuntos."
    },
    {
      "code": "    for text, relevant in exact:\n        k, e = keyword_search(text), embedding_search(text)\n        where = lambda r: r.index(ids.index(relevant[0])) + 1 if ids.index(relevant[0]) in r else \"-\"\n        print(f\"  {text:18} keyword rank {where(k)}  embedding rank {where(e)}\")",
      "note": "Para cada texto exato, onde cada busca pôs o artigo que o contém."
    }
  ]
}
```

```
ana@lab:~/emb$ python evaluate.py
24 questions
  keyword    recall@1 10  recall@3 15
  embedding  recall@1 19  recall@3 22
8 exact strings
  keyword    recall@1  8  recall@3  8
  embedding  recall@1  3  recall@3  7
  MG-20481937        keyword rank 1  embedding rank 1
  Pix                keyword rank 1  embedding rank 1
  EPUB               keyword rank 1  embedding rank 1
  4.90               keyword rank 1  embedding rank 11
  Visa               keyword rank 1  embedding rank 2
  prepaid label      keyword rank 1  embedding rank 3
  photo ID           keyword rank 1  embedding rank 2
  cash on delivery   keyword rank 1  embedding rank 2
```

## Lendo os números

**Nas 24 perguntas, a busca por embedding achou o artigo certo em primeiro 19 vezes e entre os três
primeiros 22 vezes. O BM25 conseguiu 10 e 15.** Essa diferença é o argumento inteiro da aula 1,
medido: clientes e artigos usam palavras diferentes, e só uma das duas buscas foi feita para isso.

Os oito textos exatos contam a outra história. Eles foram escritos para esta aula: um número de
pedido, um preço, nomes de marcas e frases copiadas de um artigo, o tipo de coisa que um cliente
cola em vez de digitar. **O BM25 pôs o artigo certo em primeiro em todos os 8; a busca por embedding
em 3.** Ela achou o número do pedido, `Pix` e `EPUB`, mas `4.90`, um preço de entrega, deixou o
artigo na posição 11. Uma sequência de dígitos tem pouco significado para um modelo situar, e o
artigo que veio primeiro para ela, como as últimas linhas da seção *Busca híbrida* mostram, foi o
artigo de entrega em português, que escreve o mesmo preço como `4,90`.

## Até onde vão 24 perguntas

Cada pergunta é um vinte e quatro avos da nota, então uma pergunta move o recall em cerca de quatro
pontos. 19 contra 10 é uma diferença em que dá para confiar; 19 contra 18 não seria, nem uma mudança
de uma pergunta depois que você edita o código. Os oito textos exatos são ainda mais finos, e foram
escolhidos para sondar uma fraqueza, não para representar o que os clientes digitam.

Os julgamentos também são do curso, e a sua central de ajuda não é esta. **O conjunto que decide a
sua busca é um conjunto que você escreve**: perguntas reais dos registros de busca ou da caixa de
suporte, cada uma com a resposta conferida por alguém que conhece os documentos. É um trabalho lento
e nada o substitui. Um benchmark público diz como um modelo se sai nas perguntas de outra pessoa; a
aula 9 mostra até onde isso vai.
