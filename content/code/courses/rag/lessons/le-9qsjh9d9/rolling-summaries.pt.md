---
title: Resumos em sequência
version: 2
---

Uma conversa longa é compactada mais de uma vez. O jeito simples é resumir o resumo antigo junto com os
turnos novos, a cada poucos turnos, para que o resumo avance com a conversa. O `rolling.py` faz isso a
cada quatro turnos, com limite de 40 palavras:

```schooling-example
{
  "language": "python",
  "file": "rolling.py",
  "parts": [
    {
      "code": "from compact import summarise, tokens\nfrom essentials import ESSENTIALS, TURNS, kept\n\nsummary = \"\"\nfor start in range(0, 12, 4):\n    block = ([summary] if summary else []) + TURNS[start:start + 4]\n    summary = summarise(block, 40)\n    print(f\"after turns {start + 1:2}-{start + 4:2}: {tokens(summary):3} tokens, essentials {len(kept(summary))}/{len(ESSENTIALS)}\")\n    print(\"  \", summary)",
      "note": "A conversa resumida de quatro em quatro turnos, cada resumo dobrado no seguinte, como faria um chat que compacta à medida que avança."
    }
  ]
}
```
```
ana@vm:~/rag$ python rolling.py
after turns  1- 4:  37 tokens, essentials 2/6
   Beatriz Costa, your order MG-20481937 had two issues: one book had water damage and the other was the wrong title, Mansfield Park instead of Middlemarch.
after turns  5- 8:  53 tokens, essentials 1/6
   Beatriz Costa's order had two issues: a water-damaged book and incorrect title. She wants a replacement for Persuasion, but a refund for Middlemarch, which she bought elsewhere. She has photos of the damaged book and wants to send them.
after turns  9-12:  47 tokens, essentials 1/6
   Beatriz Costa's order had two issues: a water-damaged book and incorrect title. She wants a replacement for Persuasion and a refund for Middlemarch, which she bought elsewhere, and has photos of the damaged book.
```

Depois dos quatro primeiros turnos o resumo tinha **dois essenciais**, o número do pedido e o livro
errado. Depois dos quatro seguintes, um, e o número do pedido tinha sumido: o segundo resumo foi feito
do primeiro resumo e de quatro turnos novos, e as frases do primeiro resumo disputaram as 40 palavras
com as novas e perderam. Depois dos quatro últimos, ainda um. O pedido de só e-mail, dito no quarto
turno, não entrou em nenhum deles.

**Um resumo em sequência perde fatos que já teve.** Cada rodada é uma escolha nova feita sem saber para
que serviam as escolhas anteriores, então um fato que sobreviveu a uma rodada pode ser largado na
seguinte, e daí some para todas as rodadas depois. É a cópia da cópia da cópia, e nada no resumo mais
recente mostra o que havia no primeiro.

Fixar resolve isso do mesmo jeito que resolveu o resumo único: frases fixadas seguem adiante como estão,
e só a parte não fixada é resumida a cada rodada. O teste dos essenciais resolve o resto: rode-o no
resumo depois de cada rodada, e não só da primeira, e um fato perdido na rodada três é achado na rodada
três.
