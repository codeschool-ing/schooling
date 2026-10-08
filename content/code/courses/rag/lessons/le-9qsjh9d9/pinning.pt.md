---
title: Fixando o que precisa sobreviver
version: 2
---

Se os detalhes que importam são os que um resumo larga, eles não deveriam passar pelo resumo. **Fixar**
mantém certas frases palavra por palavra, e resume só o que sobra:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"Making a long conversation short: pin what must survive word for word, summarise the rest, keep the\nlatest turns as they were.\"\"\"\nimport re\n\nimport tiktoken\nfrom memory import ORDER\nfrom openai import OpenAI",
      "note": "Uma frase é fixada quando leva um número de pedido ou uma das poucas palavras que marcam uma escolha. A regra fica escrita junto do código, para poder ser lida, discutida e testada."
    },
    {
      "code": "def pinned(turns):\n    return [s for t in turns for s in sentences(t) if PIN.search(s)]",
      "note": "Frases fixadas são mantidas palavra por palavra, nunca resumidas."
    },
    {
      "code": "def compact(turns, words=30, keep=KEEP):\n    \"\"\"The pinned sentences of the older turns, a summary of what is left of them, and the last KEEP\n    turns as they were.\"\"\"\n    older, recent = turns[:-keep], turns[-keep:]\n    pins = pinned(older)\n    rest = [s for t in older for s in sentences(t) if s not in pins]\n    return {\"pinned\": pins, \"summary\": summarise(rest, words) if rest else \"\", \"recent\": recent}",
      "note": "Os turnos mais antigos são divididos: o que está fixado fica, o resto vai para o resumidor. Os três últimos turnos ficam como estavam, porque a próxima resposta provavelmente é sobre eles."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "compacted.py",
  "parts": [
    {
      "code": "from compact import compact, text_of, tokens\nfrom essentials import ESSENTIALS, TURNS, kept\n\nc = compact(TURNS[:11])\nprint(\"pinned:\")\nfor s in c[\"pinned\"]:\n    print(\"  \", s)\nprint(\"summary:\")\nprint(\"  \", c[\"summary\"])\nprint(\"recent:\")\nfor t in c[\"recent\"]:\n    print(\"  \", t)\ntext = text_of(c)\nprint(f\"{tokens(text)} tokens, essentials {len(kept(text))}/{len(ESSENTIALS)}\")",
      "note": "Os mesmos onze turnos compactados: o que foi fixado, o resumo do resto, os turnos mantidos como estavam, e o quanto tudo isso custa e mantém."
    }
  ]
}
```
```
ana@vm:~/rag$ python compacted.py
pinned:
   Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.
   Please write to me by email only.
   For Persuasion I would like a replacement, not a refund.
   For Middlemarch I want my money back.
   Also, I am moving house next week, so the replacement should go to Rua das Flores 120, Curitiba.
summary:
   You ordered Persuasion and Mansfield Park, received damaged Persuasion and Mansfield Park, and need to send photos of damaged book cover.
recent:
   Do I need to send the damaged copy back to you?
   How do I send back Mansfield Park?
   How long will the refund for Middlemarch take?
141 tokens, essentials 6/6
```

**Seis de seis, em 141 tokens**, contra 182 dos próprios turnos e quatro de seis do melhor resumo.
Cinco frases foram fixadas: a do número do pedido, o pedido de só e-mail, as duas escolhas sobre os
livros e o endereço novo. O resumo cobriu o que sobrou, e os três últimos turnos ficaram como estavam.
O resumo também está errado: a Beatriz não recebeu um *Mansfield Park* danificado. Nada nos essenciais
pega isso, porque os essenciais listam o que precisa estar lá e não o que não pode estar, e aqui as
frases fixadas e os turnos recentes levam a verdade ao lado dele.

A economia aqui é modesta, 41 tokens, porque a Beatriz escreve mensagens curtas e as frases fixadas são
a maior parte do que ela disse. Numa conversa com mensagens longas, texto colado ou as respostas do
próprio assistente, a parte resumida é a maior parte do histórico e a parte fixada fica pequena. O que
não muda é o resultado: **os fatos que uma regra reconhece sobrevivem porque nunca dependeram do
resumidor.**

A regra é o ponto fraco e deve ser tratada como código. Ela reconhece um número de pedido pelo formato
exato, o que é confiável, e uma escolha por um punhado de palavras, `only`, `please`, `would like`,
`want`, `instead`, `should go to`, o que é um palpite sobre como clientes escrevem. Ela pegou as cinco
aqui; vai perder uma escolha escrita de outro jeito, e fixar frases que só parecem escolhas. Uma equipe
que a usa escreve conversas que a testam, exatamente como os essenciais testam o resumo. Um modelo
também pode fixar, se lhe pedirem campos com nome em vez de um parágrafo, o que vira uma extração
estruturada com uma lista contra a qual conferir, em vez de um resumo em que se confia.
