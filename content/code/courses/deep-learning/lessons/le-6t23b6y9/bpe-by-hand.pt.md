---
title: Byte-pair encoding, à mão
version: 1
---

**O byte-pair encoding começa com caracteres isolados e cola o par que aparece mais vezes, de novo e
de novo.** Cada par colado vira uma entrada nova no vocabulário, e a lista de fusões, na ordem em que
foram feitas, é o tokenizador inteiro. Era um truque de compressão de 1994 antes de virar tokenizador,
e quase todo modelo de linguagem de hoje usa ele ou um parente próximo.

Cinco palavras, cada uma com quantas vezes foi vista, bastam para vê-lo funcionar. Salve isto como
`~/dl/bpe.py`:

```schooling-example
{
  "language": "python",
  "file": "bpe.py",
  "parts": [
    {
      "code": "\"\"\"bpe: byte-pair encoding by hand, on five words and how often each was seen.\"\"\"\nfrom collections import Counter\n\ncounts = {\"bake\": 5, \"baker\": 6, \"bakers\": 2, \"make\": 4, \"maker\": 3}\nwords = {w: list(w) for w in counts}",
      "note": "Cinco palavras e quantas vezes cada uma apareceu. Cada palavra começa como a lista das suas letras, e essas letras são todo o vocabulário com que o BPE começa."
    },
    {
      "code": "def pairs():\n    seen = Counter()\n    for w, pieces in words.items():\n        for a, b in zip(pieces, pieces[1:]):\n            seen[a, b] += counts[w]\n    return seen",
      "note": "Todo par de pedaços vizinhos, contado. Um par dentro de uma palavra vista seis vezes conta seis."
    },
    {
      "code": "def merge(pieces, a, b):\n    out, i = [], 0\n    while i < len(pieces):\n        if i + 1 < len(pieces) and pieces[i] == a and pieces[i + 1] == b:\n            out.append(a + b)\n            i += 2\n        else:\n            out.append(pieces[i])\n            i += 1\n    return out",
      "note": "Troca cada ocorrência do par `a`, `b` pelo pedaço único `a + b`, lendo da esquerda para a direita."
    },
    {
      "code": "merges = []\nfor step in range(1, 7):\n    (a, b), n = pairs().most_common(1)[0]\n    merges.append((a, b))\n    for w in words:\n        words[w] = merge(words[w], a, b)\n    print(f\"merge {step}: {a!r} + {b!r} seen {n:2d} times ->\", \" \".join(\"|\".join(p) for p in words.values()))",
      "note": "Seis rodadas de uma regra só: pega o par mais comum, faz dele um pedaço, anota. A lista `merges`, na ordem dela, é o tokenizador. Um empate fica com o par contado primeiro."
    },
    {
      "code": "def encode(word):\n    pieces = list(word)\n    for a, b in merges:\n        pieces = merge(pieces, a, b)\n    return pieces",
      "note": "Uma palavra nova começa como letras e passa pelas fusões na ordem em que foram aprendidas."
    },
    {
      "code": "for new in [\"makers\", \"baked\", \"taker\"]:\n    print(f\"{new!r} was never seen ->\", encode(new))",
      "note": "Três palavras que as cinco não continham."
    }
  ]
}
```

```
PENDING bpe
```

## Lendo as fusões

**A primeira fusão é `a` + `k`, vista 20 vezes**: ela ocorre uma vez em cada uma das cinco palavras, e
as cinco foram vistas 5 + 6 + 2 + 4 + 3 = 20 vezes. `k` + `e` também foi visto 20 vezes, e o empate
ficou com o par contado primeiro. A segunda fusão cola `ak` em `e`, e daí em diante a regra continua
construindo sobre o próprio resultado: `bake` na fusão 3, `baker` na fusão 4, depois `make` e `maker`.

Repare nas contagens caindo: 20, 20, 13, 8, 7, 3. As primeiras fusões são pedaços que muitas palavras
dividem, e as últimas são palavras inteiras que só são frequentes. Um tokenizador de verdade roda o
mesmo laço dezenas de milhares de vezes sobre gigabytes de texto, e as fusões finais dele são palavras
raras, nomes e pedaços de código.

## Palavras que ele nunca viu

**Codificar uma palavra nova repete as fusões, na ordem em que foram aprendidas.** `makers` não estava
entre as cinco, e sai como `maker` e `s`, dois pedaços que o vocabulário tem, que é exatamente a
relação que um vocabulário de palavras não conseguia ver. `baked` vira `bake` e `d`.

`taker` mostra o outro lado. Nenhuma fusão produziu `ta`, então o `t` fica sozinho, e depois vêm `ake`
e `r`, das fusões 2 e 1. A palavra continua representada, sem `<unk>`, só que em mais pedaços. Esse é
o comportamento geral: **uma palavra parecida com o texto de treino custa poucos tokens, e uma palavra
diferente dele custa muitos**, até um por caractere. A conta disso chega na última seção desta aula.

Nada aqui sabe o que é um padeiro. As fusões são frequências, e `bake` virou um pedaço porque era
comum, não porque é um verbo. O sentido vem depois, do modelo que lê os ids.
