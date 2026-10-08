---
title: Cortando onde o significado muda
version: 2
---

Títulos são onde um autor disse que o assunto muda. O **corte semântico** tenta achar onde o assunto
muda de fato, medindo: gerar o embedding de cada frase, comparar cada uma com a seguinte, e cortar onde
duas vizinhas se parecem menos. Não precisa de estrutura nenhuma, o que o torna atraente para
transcrições e outros textos sem títulos.

```schooling-example
{
  "language": "python",
  "file": "chunking.py",
  "parts": [
    {
      "code": "def sentences(text):\n    flat = \" \".join(line for line in text.splitlines() if not line.startswith(\"#\"))\n    return [s for s in re.split(r\"(?<=[.!?])(?<!\\b\\d\\.)\\s+(?=[A-Z0-9])\", \" \".join(flat.split())) if s]",
      "note": "Frases, separadas depois de um ponto seguido de maiúscula ou dígito. O `(?<!\\b\\d\\.)` mantém um marcador de lista como `1.` preso ao seu item."
    },
    {
      "code": "def semantic(text, quantile=0.25):\n    \"\"\"Cut between two sentences wherever their similarity is in the lowest QUANTILE.\"\"\"\n    sents = sentences(text)\n    v = embed(sents)\n    sim = (v[:-1] * v[1:]).sum(axis=1)\n    cut = np.quantile(sim, quantile)\n    chunks, start = [], 0\n    for i, s in enumerate(sim):\n        if s <= cut:\n            chunks.append(\" \".join(sents[start:i + 1]))\n            start = i + 1\n    chunks.append(\" \".join(sents[start:]))\n    return chunks",
      "note": "Cada frase vira embedding, e cada uma é comparada com a seguinte. Onde essa similaridade está entre o quarto mais baixo do documento, o assunto provavelmente mudou, e um pedaço termina ali."
    }
  ]
}
```

## O que ele achou no regulamento de devoluções

```schooling-example
{
  "language": "python",
  "file": "boundaries_semantic.py",
  "parts": [
    {
      "code": "from chunking import load, semantic\n\nmeta, body = load()[\"returns-policy\"]\nfor i, chunk in enumerate(semantic(body), 1):\n    print(f\"{i:2} {len(chunk.split()):4} words  {' '.join(chunk.split()[:9])} ...\")",
      "note": "Todo pedaço que o `semantic` faz da política de devolução, com o tamanho e as primeiras nove palavras."
    }
  ]
}
```

```
ana@vm:~/rag$ python boundaries_semantic.py
 1   31 words  This policy applies to every order placed on marginalia.example ...
 2   84 words  It covers printed books, gifts and items sold by ...
 3   66 words  A book is in the condition you received it ...
 4   10 words  The statutory right of withdrawal is seven days from ...
 5   17 words  This policy gives you more than the law requires, ...
 6   35 words  1. Open the order in your account and choose ...
 7   24 words  3. Print the prepaid label we email you. If ...
 8   20 words  4. Pack the books so that they cannot move ...
 9   75 words  Returns are free. You do not pay for the ...
10  132 words  Delivery costs are refunded when you return the whole ...
11   23 words  If we sent a different title from the one ...
12  223 words  We send the right book at once with a ...
13   99 words  Items marked Sold by, followed by a seller's name, ...
```

Alguns cortes são bons. O pedaço 9 começa exatamente em *Returns are free*, que nenhuma outra estratégia
desta aula isolou tão bem, e o pedaço 13 começa na seção do marketplace.

Outros não. **O pedaço 2 junta o fim da introdução com o começo do prazo de devolução**, um corte que o
título pôs no lugar certo e as similaridades não. Os quatro passos numerados para começar uma devolução
foram divididos em três, os pedaços 6, 7 e 8, porque instruções seguidas sobre ações diferentes não se
parecem muito entre si, mesmo pertencendo juntas. O pedaço 4 é uma única frase de dez palavras. E **o
pedaço 12 tem 223 palavras**, porque os parágrafos sobre títulos trocados, livros com defeito, itens
que não podem ser devolvidos, presentes e e-books parecem todos iguais para o modelo, então nada entre
eles caiu no quarto mais baixo.

## Duas fraquezas, as duas consertáveis, nenhuma de graça

**Não há limite de tamanho.** Um corte semântico só acontece onde a similaridade cai, então uma passagem
longa sobre um assunto vira um pedaço longo, e um pedaço de 223 palavras fica perto do limite que a
primeira seção desta aula mediu. As versões práticas combinam o corte com um tamanho máximo, o que traz
de volta um corte de tamanho fixo dentro das passagens longas.

**Custa um embedding por frase**, antes de qualquer pedaço virar embedding. A última seção desta aula
indexou o corpus frase por frase e contou 319 delas; para um corpus grande, gerar o embedding de cada
frase primeiro mais ou menos dobra a conta de indexação.

A medição no fim da aula é o veredito neste corpus: o corte semântico achou a resposta de 20 das 26
perguntas, uma a mais que pedaços fixos de 60 palavras e cinco a menos que cortar nos títulos. **Em
documentos com bons títulos, as marcas do próprio autor vencem uma estimativa delas.** Em texto sem
marcas é uma escolha razoável, e ali a escolha é entre ele e cortes de tamanho fixo com sobreposição.
