---
title: O que um teste de regressão confere
version: 1
---

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro relatórios de regressão como barras. De 2026.09.4 para 2026.10.1: 0 consertados, 5 quebrados, custo 48% menor. Para 2026.10.2, o modelo novo: nada consertado nem quebrado, custo 118% maior. Para 2026.10.3, o piso de volta: 5 consertados, nenhum quebrado, custo 93% maior. Para 2026.10.4, as duas mudanças: 6 consertados, nenhum quebrado, uma verificação passando a falhar, custo 341% maior.\"><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.09.4 → 2026.10.1</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a versão que foi ao ar</text><rect x=\"330\" y=\"43\" width=\"180\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"518\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">5</text><text x=\"700\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−48%</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.2</text><text x=\"20\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">modelo novo</text><text x=\"330\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"700\" y=\"98\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+118%</text><text x=\"20\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.3</text><text x=\"20\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">piso de volta</text><rect x=\"330\" y=\"135\" width=\"180\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"518\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">5</text><text x=\"700\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+93%</text><text x=\"20\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.4</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as duas, uma verificação quebrada</text><rect x=\"330\" y=\"181\" width=\"216\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">6</text><text x=\"700\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+341%</text><rect x=\"330\" y=\"13\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"348\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">consertados</text><rect x=\"450\" y=\"13\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"468\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">quebrados</text><text x=\"700\" y=\"19\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">custo</text></svg>", "caption": "Casos consertados e quebrados contra a versão anterior, e a mudança no custo de responder ao conjunto. A mudança mais barata é a que quebrou cinco casos."}
```

Os quatro relatórios dão as regras que um teste de regressão aplica, e cada uma foi necessária para um
deles:

1. **As duas execuções fizeram as mesmas perguntas.** O `regress.py` recusa o contrário, e a versão do
   conjunto da aula 13 é contra o que ele compara. Uma execução da versão 1 do conjunto não é comparável
   com uma da versão 2:

```
ana@lab:~/obs$ python evalrun.py v1 --release 2026.10.1 && python regress.py 2026.10.1 v1
runs/v1.jsonl: 30 questions, release 2026.10.1
runs/v1.jsonl did not ask the questions of data/eval-v2.jsonl: refusing to compare
```

2. **Nenhum caso vai de certo para errado sem alguém lê-lo.** A versão que foi ao ar quebrou cinco, com
   p = 0,0625. A regra é sobre os casos, não sobre o valor-p.
3. **Nenhuma verificação passa a falhar.** A candidata combinada passou em todos os fatos em que passava
   e quebrou uma regra de forma; só as verificações viram.
4. **Custo e latência são relatados ao lado dos casos, com a sua direção.** A versão que foi ao ar era
   mais barata e mais rápida por um motivo ruim; o modelo novo era mais caro por nenhum motivo que o
   conjunto consiga ver. Cada um precisa de um orçamento que alguém combinou: quanto mais uma versão pode
   custar, quanto mais lenta pode ser.
5. **O número de respostas que mudaram é relatado**, para que alguém as leia. Uma resposta pode mudar de
   jeitos que nenhum avaliador do conjunto mede.

O que ele não confere é igualmente importante. **Ele não diz que a candidata é boa.** Diz que a candidata
não é pior que a produção em 42 perguntas. A divisão reservada, da aula 13, roda uma vez quando a
candidata está pronta; os sinais de produção da aula 5 assumem depois do lançamento, nas perguntas que
ninguém pensou em pôr num conjunto.

A aula 15 transforma essas regras num teste que roda em toda mudança, e reprova o build quando uma é
quebrada.
