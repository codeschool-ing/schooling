---
title: Busca por palavras, bem feita
version: 1
---

A aula 1 buscou na central de ajuda com `grep`, e perdeu. Não foi uma luta justa: o `grep` só diz
se uma linha contém um texto. Uma busca por palavras de verdade *ordena* os documentos pelo
quanto as palavras deles combinam com as da pergunta, e a função de ordenação que a maioria dos
buscadores usa há décadas é o **BM25**. Ele é o padrão do Lucene, e portanto do Elasticsearch e do
OpenSearch. Antes de construir uma busca por significado, vale construir a que ela precisa vencer.

```schooling-example
{
  "language": "python",
  "file": "bm25.py",
  "parts": [
    {
      "code": "import collections\nimport json\nimport math\nimport re\nimport sys\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]",
      "note": "Leia os 40 artigos."
    },
    {
      "code": "def words(text):\n    return re.findall(r\"[a-z0-9]+(?:[-.@][a-z0-9]+)*\", text.lower())\n\ndocs = [words(h[\"title\"] + \". \" + h[\"body\"]) for h in help]\naverage = sum(map(len, docs)) / len(docs)\ndf = collections.Counter(w for d in docs for w in set(d))",
      "note": "Separe o texto em palavras minúsculas. Um hífen, um ponto ou um `@` entre letras ou dígitos fica dentro da palavra, então `MG-20481937`, `4.90` e um endereço de e-mail ficam inteiros. Depois conte, para cada palavra, quantos artigos a contêm."
    },
    {
      "code": "def bm25(query, k1=1.5, b=0.75):\n    scores = [0.0] * len(docs)\n    for w in words(query):\n        if w not in df:\n            continue\n        idf = math.log(1 + (len(docs) - df[w] + 0.5) / (df[w] + 0.5))\n        for i, d in enumerate(docs):\n            tf = d.count(w)\n            scores[i] += idf * tf * (k1 + 1) / (tf + k1 * (1 - b + b * len(d) / average))\n    return scores",
      "note": "O BM25 propriamente dito. Para cada palavra da consulta que existe na central de ajuda, `idf` é alto para uma palavra rara e baixo para uma comum. `tf` é quantas vezes a palavra aparece neste artigo, amortecido por `k1` e ajustado pelo tamanho do artigo em relação à média por meio de `b`. Os dois valores padrão são escolhas comuns."
    },
    {
      "code": "def keyword_search(query):\n    scores = bm25(query)\n    found = [i for i in range(len(docs)) if scores[i] > 0]\n    return sorted(found, key=lambda i: -scores[i])",
      "note": "A busca: todo artigo com nota acima de zero, o melhor primeiro. Um artigo que não divide nenhuma palavra com a consulta nem entra na lista."
    },
    {
      "code": "if __name__ == \"__main__\":\n    query = sys.argv[1]\n    scores = bm25(query)\n    for i in keyword_search(query)[:3]:\n        print(f\"{scores[i]:6.2f}  {help[i]['id']}  {help[i]['title']}\")",
      "note": "Pela linha de comando, imprima os três primeiros com as notas."
    }
  ]
}
```

O BM25 soma, para cada palavra da pergunta encontrada num documento, uma nota feita de três ideias:

- **Uma palavra rara vale mais.** O `idf` é alto para uma palavra que poucos artigos contêm, como um
  número de pedido, e quase zero para uma que quase todos contêm, como *the*.
- **Repetir ajuda, cada vez menos.** Uma palavra que aparece duas vezes vale mais que uma vez, mas o
  `k1` limita quanto a mais, então uma página não ganha por dizer *refund* dez vezes.
- **Documentos longos levam desconto.** O `b` reduz a nota de um documento mais longo que a média,
  que de outro jeito combinaria com mais palavras só pelo tamanho.

## Onde ela ganha, e onde perde

```
ana@lab:~/emb$ python bm25.py "MG-20481937"
  3.22  h06  Where to find your order number
ana@lab:~/emb$ python bm25.py "get rid of my profile for good"
  4.11  h18  Returning a gift
  2.58  h05  Orders for schools and libraries
  2.57  h24  Using a gift card
```

**Um número de pedido é o caso para o qual a busca por palavras foi feita.** `MG-20481937` aparece
em um artigo de 40, então o `idf` dele é alto e esse artigo vem primeiro, sem mais nada combinando.
O texto não significa nada que um modelo pudesse ter aprendido; ele só precisa ser encontrado.

A segunda pergunta é o problema da aula 1 de novo. *get rid of my profile for good* ("quero apagar
meu perfil de vez") é respondida por **Closing your account** ("encerrar sua conta"), que divide uma
palavra com ela: *for*, tão comum na central de ajuda que o `idf` dela é baixo. O BM25 ordena o que
divide mais: o artigo do presente combinou em *get* e *for*, e os outros dois em *for* e *of*. Cada
nota acima é uma combinação real numa palavra, e nenhuma delas fala de encerrar uma conta.

Então a busca por palavras é forte quando o cliente digita o mesmo texto que o artigo: códigos,
nomes, preços, frases exatas. Ela é fraca sempre que os dois descrevem a mesma coisa com palavras
diferentes, o que numa central de ajuda é a maioria das perguntas. A seção *Medindo uma busca* põe
números nas duas metades.
