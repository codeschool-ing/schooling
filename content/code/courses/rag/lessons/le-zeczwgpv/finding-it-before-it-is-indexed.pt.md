---
title: Achando antes de indexar
version: 1
---

Um anúncio é escrito uma vez e lido por toda pergunta que o recupera. Isso faz da ingestão o lugar mais
barato para olhar para ele, uma vez, antes de chegar a qualquer prompt:

```schooling-example
{
  "language": "python",
  "file": "scan.py",
  "parts": [
    {
      "code": "import json\nimport re",
      "note": "Os anúncios como os vendedores os enviaram."
    },
    {
      "code": "# Words that address a reader of the text rather than describe a book. A seller has no reason to\n# write them; finding them is a reason for a person to look, not proof of anything.\nSUSPECT = re.compile(r\"\\b(ignore|disregard)\\b.{0,40}\\b(question|instructions?|above|previous)\\b\"\n                     r\"|\\breply with\\b|\\b(assistant|AI|model) reading this\\b\", re.I)\nfor line in open(\"data/listings.jsonl\"):\n    listing = json.loads(line)\n    found = SUSPECT.search(listing[\"description\"])\n    print(f\"{listing['id']}  {'HOLD  ' + repr(found.group(0)) if found else 'ok'}\")",
      "note": "Um padrão para texto que fala com um leitor em vez de descrever um livro. Um casamento põe o anúncio em espera para uma pessoa olhar; sozinho, não decide nada."
    }
  ]
}
```

```
ana@lab:~/rag$ python scan.py
L01  ok
L02  ok
L03  ok
L04  HOLD  'assistant reading this'
L05  ok
L06  ok
```

**O L04 fica em espera**, pelas palavras "assistant reading this", e os outros cinco passam. Um anúncio
em espera não é apagado nem publicado; espera por uma pessoa, que vê o casamento e decide. A maioria dos
casamentos vai ser inofensiva, um vendedor escrevendo "ignore the creases on the cover", e a regra custa
alguns segundos de uma pessoa a cada vez.

Esta camada é a mais fraca das quatro, e é dito com todas as letras para que ninguém se apoie nela. Um
padrão pega as redações em que alguém pensou. Uma injeção pode ser escrita em outra língua, dividida
entre campos, escondida em palavras que só significam algo para um modelo, e um filtro de frases
conhecidas vai perdê-la. A varredura merece o lugar por pegar o descuidado e o copiado, e por produzir um
registro: um anúncio em espera com o seu casamento é prova de que alguém tentou, o que vale saber sobre
um vendedor.

O que ela nunca pode virar é uma porta que decide sozinha o que é seguro. Um anúncio que passa na
varredura é um anúncio que a varredura não reconheceu, e nada mais.
