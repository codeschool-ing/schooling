---
title: Para onde vão os tokens
version: 2
---

A aula 12 dividiu um prompt nas suas partes. O `split.py` faz o mesmo para a semana inteira, a partir das
contagens que o `priced.py` salvou:

```schooling-example
{
  "language": "python",
  "file": "split.py",
  "parts": [
    {
      "code": "import json\n\ncosts = json.load(open(\"costs.json\"))\nLOG = [json.loads(line) for line in open(\"data/querylog.jsonl\")]\nanswered = [costs[q[\"text\"]] for q in LOG if costs[q[\"text\"]][\"input\"]]\ntotal = sum(c[\"input\"] + c[\"output\"] for c in answered)\nfor part in (\"instructions\", \"sources\", \"output\"):\n    n = sum(c[part] for c in answered)\n    print(f\"{part:13} {n:6} tokens  {n / total:4.0%}\")\nrest = sum(c[\"input\"] - c[\"instructions\"] - c[\"sources\"] for c in answered)\nprint(f\"{'question etc':13} {rest:6} tokens  {rest / total:4.0%}\")",
      "note": "Para onde foram os tokens das perguntas respondidas: as instruções, as fontes, a resposta, e o resto do prompt."
    }
  ]
}
```
```
ana@vm:~/rag$ python split.py
instructions   34506 tokens   19%
sources       104725 tokens   57%
output         26677 tokens   15%
question etc   16580 tokens    9%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Uma barra dividida por onde foram os tokens da semana: fontes 57%. instruções 19%. saída 15%. a pergunta e o resto 9%. de 182.488 tokens em 486 chamadas ao modelo.\"><rect x=\"20.0\" y=\"40\" width=\"128.6\" height=\"40\" fill=\"var(--wire)\"></rect><rect x=\"148.6\" y=\"40\" width=\"390.2\" height=\"40\" fill=\"var(--phosphor)\"></rect><rect x=\"538.8\" y=\"40\" width=\"99.4\" height=\"40\" fill=\"var(--amber)\"></rect><rect x=\"638.2\" y=\"40\" width=\"61.8\" height=\"40\" fill=\"var(--paper-dim)\"></rect><rect x=\"20\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--wire)\"></rect><text x=\"38\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instruções 19%</text><rect x=\"176\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--phosphor)\"></rect><text x=\"194\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fontes 57%</text><rect x=\"297\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--amber)\"></rect><text x=\"315\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">saída 15%</text><rect x=\"411\" y=\"112\" width=\"12\" height=\"12\" fill=\"var(--paper-dim)\"></rect><text x=\"429\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pergunta e o resto 9%</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">182.488 tokens nas 486 chamadas ao modelo da semana</text></svg>", "caption": "As fontes são a maior parte da conta, e é por isso que o empacotamento da aula 12 é uma decisão de custo além de qualidade. As instruções são os mesmos 71 tokens em toda chamada: quase um quinto de tudo, pago 486 vezes."}
```

**As fontes são 57% da semana**, 104.725 tokens de texto recuperado e cabeçalhos. Isso faz do
empacotamento da aula 12 uma decisão de custo além de qualidade: o orçamento dele tirou um quinto de cada
prompt, e quase tudo saiu desta linha.

**As instruções são 19%**, e são a linha mais estranha da conta: os mesmos 71 tokens, o prompt de sistema
da aula 7, mandados 486 vezes. Nada nelas muda entre uma chamada e outra. É para isso que serve a última
técnica desta aula, o cache de prompt, embora, como a seção sobre ele mostra, 71 tokens seja um prefixo
curto demais para o cache de qualquer provedor.

A saída é 15%. É curta porque as respostas são curtas, e também é a única parte que o pipeline controla
só indiretamente, pelas instruções e por um limite de `max_tokens`. O orçamento da aula 9 reservou espaço
para ela; esta semana mostra que ela nunca chegou perto.
