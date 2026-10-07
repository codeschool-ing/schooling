---
title: Um cabeçalho é dado disfarçado
version: 1
---

Depois do melt, os cabeçalhos antigos são valores numa coluna, `jan/25`, `fev/25` e assim por
diante, e continuam sendo texto. Um mês em texto se ordena alfabeticamente, `abr` antes de `fev`, e
não casa com um mês calculado a partir de uma data. Ele precisa virar um mês de verdade.

O atalho tentador é deixar um leitor de datas ler a abreviação:

```
ana@lab:~/clean$ python -c "import pandas as pd; print(pd.to_datetime('fev/25', format='%b/%y'))" 2>&1 | grep ^ValueError
ValueError: time data "fev/25" doesn't match format "%b/%y". You might want to try:
```

`%b` quer dizer "nome abreviado do mês", e **de que idioma é a abreviação depende do locale da
máquina**. O Python lê nomes de mês num locale neutro, a menos que um programa peça outro, então
conhece `Feb` e não `fev`. Uma máquina configurada em português talvez leia, e aí o mesmo script
funcionaria num notebook e falharia no servidor que o roda toda noite.

Por isso o `targets.py`, na seção anterior, escreve os doze meses num dicionário. São doze linhas
sem nada de esperto, e têm duas virtudes que um leitor de datas não tem: leem igual em toda
máquina, e **um cabeçalho desconhecido para o script** em vez de virar um mês vazio. Se um dia a
equipe escrever `Fev/25` ou `fevereiro/25`, o erro diz qual.

O resultado tem o tipo `period[M]`, um mês como valor: ordena no tempo, sabe que 2025-12 vem antes
de 2026-01, e é exatamente o que `.dt.to_period("M")` produz a partir de uma data. Essa última
propriedade é aquela de que a junção de duas seções adiante depende. **Uma chave de junção precisa
ter o mesmo tipo dos dois lados**, e um mês escrito de dois jeitos são duas chaves que nunca se
encontram.
