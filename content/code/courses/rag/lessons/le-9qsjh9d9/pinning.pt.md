---
title: Fixando o que precisa sobreviver
version: 1
---

Se os detalhes que importam são os que um resumo larga, eles não deveriam passar pelo resumo. **Fixar**
mantém certas frases palavra por palavra, e resume só o que sobra:

```schooling-example
{
  "language": "python",
  "file": "compact.py",
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

```
ana@lab:~/rag$ python compacted.py
pinned:
   Hi, my name is Beatriz Costa and I have a problem with order MG-20481937.
   Please write to me by email only.
   For Persuasion I would like a replacement, not a refund.
   For Middlemarch I want my money back.
   Also, I am moving house next week, so the replacement should go to Rua das Flores 120, Curitiba.
summary:
   The order had two books. The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. I have photographs of the damaged cover next to the box.
recent:
   Do I need to send the damaged copy back to you?
   How do I send back Mansfield Park?
   How long will the refund for Middlemarch take?
148 tokens, essentials 6/6
```

**Seis de seis, em 148 tokens**, contra 182 dos próprios turnos e quatro de seis do melhor resumo.
Cinco frases foram fixadas: a do número do pedido, o pedido de só e-mail, as duas escolhas sobre os
livros e o endereço novo. O resumo cobriu o que sobrou, e os três últimos turnos ficaram como estavam.

A economia aqui é modesta, 34 tokens, porque a Beatriz escreve mensagens curtas e as frases fixadas são
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
