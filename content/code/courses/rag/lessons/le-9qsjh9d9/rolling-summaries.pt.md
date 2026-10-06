---
title: Resumos em sequência
version: 1
---

Uma conversa longa é compactada mais de uma vez. O jeito simples é resumir o resumo antigo junto com os
turnos novos, a cada poucos turnos, para que o resumo avance com a conversa. O `rolling.py` faz isso a
cada quatro turnos, com limite de 40 palavras:

```
ana@lab:~/rag$ python rolling.py
after turns  1- 4:  54 tokens, essentials 3/6
   Hi, my name is Beatriz Costa and I have a problem with order MG-20481937. The order had two books. The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. Please write to me by email only.
after turns  5- 8:  48 tokens, essentials 2/6
   The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. For Persuasion I would like a replacement, not a refund. I bought it somewhere else in the meantime. Where do I send them?
after turns  9-12:  51 tokens, essentials 2/6
   The other parcel had the wrong book: I ordered Middlemarch and got Mansfield Park. For Persuasion I would like a replacement, not a refund. I bought it somewhere else in the meantime. How do I send back Mansfield Park?
```

Depois dos quatro primeiros turnos o resumo tinha **três essenciais**, o número do pedido e o pedido de
só e-mail entre eles. Depois dos quatro seguintes, dois, e aqueles dois tinham sumido: o segundo resumo
foi feito do primeiro resumo e de quatro turnos novos, e as frases do primeiro resumo disputaram as 40
palavras com as novas e perderam. Depois dos quatro últimos, ainda dois, e os mesmos dois.

**Um resumo em sequência perde fatos que já teve.** Cada rodada é uma escolha nova feita sem saber para
que serviam as escolhas anteriores, então um fato que sobreviveu a uma rodada pode ser largado na
seguinte, e daí some para todas as rodadas depois. É a cópia da cópia da cópia, e nada no resumo mais
recente mostra o que havia no primeiro.

Fixar resolve isso do mesmo jeito que resolveu o resumo único: frases fixadas seguem adiante como estão,
e só a parte não fixada é resumida a cada rodada. O teste dos essenciais resolve o resto: rode-o no
resumo depois de cada rodada, e não só da primeira, e um fato perdido na rodada três é achado na rodada
três.
