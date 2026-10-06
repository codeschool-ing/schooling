---
title: Para onde vão os tokens
version: 1
---

A aula 12 dividiu um prompt nas suas partes. O `split.py` faz o mesmo para a semana inteira, a partir das
contagens que o `priced.py` salvou:

```
ana@lab:~/rag$ python split.py
instructions   34506 tokens   21%
sources       104725 tokens   62%
output         22563 tokens   13%
question etc    5888 tokens    4%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Uma barra dividida por onde foram os tokens da semana: fontes 62%, instruções 21%, saída 13%, a pergunta e o resto 4%, de 167.682 tokens em 486 chamadas ao modelo.\"><rect x=\"20.0\" y=\"40\" width=\"139.9\" height=\"40\" fill=\"var(--wire)\"></rect><rect x=\"159.9\" y=\"40\" width=\"424.7\" height=\"40\" fill=\"var(--phosphor)\"></rect><rect x=\"584.6\" y=\"40\" width=\"91.5\" height=\"40\" fill=\"var(--amber)\"></rect><rect x=\"676.1\" y=\"40\" width=\"23.9\" height=\"40\" fill=\"var(--paper-dim)\"></rect><rect x=\"20\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--wire)\"></rect><text x=\"38\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instruções 21%</text><rect x=\"162\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"180\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fontes 62%</text><rect x=\"276\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"294\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">saída 13%</text><rect x=\"383\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--paper-dim)\"></rect><text x=\"401\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pergunta e o resto 4%</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">167.682 tokens nas 486 chamadas ao modelo da semana</text></svg>", "caption": "As fontes são a maior parte da conta, e é por isso que o empacotamento da aula 12 é uma decisão de custo além de qualidade. As instruções são os mesmos 71 tokens em toda chamada: um quinto de tudo, pago 486 vezes."}
```

**As fontes são 62% da semana**, 104.725 tokens de texto recuperado e cabeçalhos. Isso faz do
empacotamento da aula 12 uma decisão de custo além de qualidade: o orçamento dele tirou um quinto de cada
prompt, e quase tudo saiu desta linha.

**As instruções são 21%**, e são a linha mais estranha da conta: os mesmos 71 tokens, o prompt de sistema
da aula 7, mandados 486 vezes. Nada nelas muda entre uma chamada e outra. É para isso que serve a última
técnica desta aula, o cache de prompt, embora, como a seção sobre ele mostra, 71 tokens seja um prefixo
curto demais para o cache de qualquer provedor.

A saída é 13%. É curta porque as respostas são curtas, e também é a única parte que o pipeline controla
só indiretamente, pelas instruções e por um limite de `max_tokens`. O orçamento da aula 9 reservou espaço
para ela; esta semana mostra que ela nunca chegou perto.
