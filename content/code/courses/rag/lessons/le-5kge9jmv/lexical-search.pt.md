---
title: Busca lexical
version: 1
---

Antes dos embeddings, os buscadores comparavam palavras. Uma busca **lexical** dá nota a um documento
pelas palavras que ele tem em comum com a consulta, com pesos para que palavras raras contem mais que as
comuns e uma palavra repetida muitas vezes conte menos a cada repetição. A fórmula padrão é a **BM25**,
usada pelo Elasticsearch, pelo OpenSearch, pelas extensões de busca para PostgreSQL e pela maioria das
bibliotecas de busca, e ainda é a referência contra a qual qualquer método de recuperação é medido.

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "TOKEN = re.compile(r\"[a-z0-9]+(?:[-.%][a-z0-9]+)*%?\")\n\n\ndef words(text):\n    return TOKEN.findall(text.lower())",
      "note": "Palavras são sequências de letras e dígitos, mantidas inteiras através de um hífen, um ponto ou um sinal de porcentagem, para que `E-4104`, `9.90` e `12%` sejam uma palavra cada. Em minúsculas, porque `Express` e `express` são a mesma palavra para quem lê."
    },
    {
      "code": "def lexical(question, k=3, where=\"TRUE\", params=()):\n    \"\"\"The K chunks BM25 scores highest for the question's words.\"\"\"\n    found = rows(where, params)\n    bm25 = BM25Okapi([words(path + \" \" + text) for _, path, text in found])\n    scores = bm25.get_scores(words(question))\n    return [(*found[i], float(scores[i])) for i in np.argsort(-scores, kind=\"stable\")[:k]]",
      "note": "BM25 sobre o caminho e o texto de cada pedaço. Ele é refeito a cada chamada, o que serve para 137 pedaços e é o que o índice invertido de um buscador faz uma vez e guarda."
    }
  ]
}
```

## Onde ela vence

O conjunto de teste da aula 4 foi escrito como um cliente perguntaria. Uma equipe cujos usuários são
desenvolvedores faz perguntas diferentes, então esta aula acrescenta um segundo conjunto, pequeno:
`data/identifiers.jsonl`, seis perguntas construídas em torno de um identificador exato, um código de
erro, um nível de severidade, um endpoint, um número de cláusula.

```
ana@lab:~/rag$ python show.py vector "What does error E-4104 mean?"
1    0.367  Affiliate API reference > Errors  | | code | HTTP | meaning | | --- | --- | --- | | 
2    0.355  Affiliate API reference > Errors  | Errors are returned as JSON with a code and a me
3    0.352  Affiliate API reference > Changes in 2.3  | Version 2.3, released on 10 February 2026, added
4    0.310  Affiliate API reference > Rate limits  | A key may make 120 requests per minute. A reques
5    0.264  E-books and audiobooks > Downloading  | An e-book appears in your library as soon as the
ana@lab:~/rag$ python show.py lexical "What does error E-4104 mean?"
1    5.787  Affiliate API reference > Errors  | | code | HTTP | meaning | | --- | --- | --- | | 
2    5.148  Customer support handbook > What you can decide on your own  | A replacement for a book that arrived damaged ne
3    4.268  Warehouse on-call runbook > After an incident  | Every SEV-1 and SEV-2 gets a short review within
4    4.267  Affiliate API reference > Errors  | Errors are returned as JSON with a code and a me
5    3.824  Customer support handbook > Handing over at the end of a shift  | Before you sign off, every open chat is either c
```

As duas puseram a tabela de erros em primeiro desta vez. A busca vetorial fez isso graças ao caminho,
*Affiliate API reference > Errors*, e com similaridade de 0,367, por pouco acima do registro de mudanças
com 0,352. A busca lexical fez isso porque `e-4104` é uma palavra da pergunta e da tabela e de mais
nada, e a nota dela, 5,787, fica bem acima do resto. Nas seis perguntas de identificador a diferença não
é pequena:

| | primeiro | três primeiros |
| --- | --- | --- |
| vetorial | 3 de 6 | 4 de 6 |
| lexical | 4 de 6 | 6 de 6 |

**A busca lexical achou todas as perguntas de identificador entre os três primeiros; a vetorial achou
quatro.**

## Onde ela perde

```
ana@lab:~/rag$ python show.py lexical "how do I send a book back"
1   10.636  Customer support handbook > What you can decide on your own  | A replacement for a book that arrived damaged ne
2    9.414  Returns and refunds policy > Damaged, faulty and wrong items  | If a book arrives with a torn cover, bent corner
3    8.771  Returns policy > Damaged books  | If a book arrives damaged, send it back within 1
4    7.663  Customer support handbook > How we write  | Quote the policy in your own words and link the 
5    7.612  Returns and refunds policy > The return window  | A book is in the condition you received it when 
```

A pergunta é o jeito do cliente de dizer *como devolvo um livro*, e o artigo da central de ajuda sobre
devoluções veio em primeiro na busca vetorial na aula 2. A BM25 não faz ideia de que *send back* quer
dizer *return*. Ela achou os pedaços que têm mais palavras em comum, *book* e *back*, e o melhor deles é a
regra do manual de atendimento sobre livros danificados. Nas 26 perguntas de cliente ela acha a resposta
entre os três primeiros em 20, contra 26 da busca vetorial.

As duas falhas são imagens no espelho. **A busca vetorial entende paráfrase e borra identificadores; a
lexical respeita identificadores e perde a paráfrase.** Um sistema cujos usuários fazem os dois tipos de
pergunta precisa das duas, que é a próxima seção.
