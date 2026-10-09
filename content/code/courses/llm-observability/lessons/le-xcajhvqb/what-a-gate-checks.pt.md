---
title: O que um teste de regressão verifica
version: 2
---

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro relatórios de regressão como pares de barras, casos consertados e casos quebrados. De 2026.09.4 para 2026.10.1, a versão que foi ao ar: 2 consertados, 7 quebrados, custo 34% menor. Para 2026.10.2, o modelo menor: 0 consertados, 7 quebrados, custo 62% menor. Para 2026.10.3, o piso de volta: 7 consertados, 2 quebrados, custo 50% maior. Para 2026.10.4, as duas mudanças: 4 consertados, 7 quebrados, custo 37% menor.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.09.4 → 2026.10.1</text><text x=\"20\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a versão que foi ao ar</text><rect x=\"300\" y=\"42\" width=\"40\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"346\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"300\" y=\"56\" width=\"140\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">7</text><text x=\"700\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−34%</text><text x=\"20\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.2</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">modelo menor</text><text x=\"306\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">0</text><rect x=\"300\" y=\"106\" width=\"140\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">7</text><text x=\"700\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−62%</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.3</text><text x=\"20\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">piso de volta</text><rect x=\"300\" y=\"142\" width=\"140\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">7</text><rect x=\"300\" y=\"156\" width=\"40\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"346\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2</text><text x=\"700\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">+50%</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026.10.1 → 2026.10.4</text><text x=\"20\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as duas mudanças</text><rect x=\"300\" y=\"192\" width=\"80\" height=\"10\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><rect x=\"300\" y=\"206\" width=\"140\" height=\"10\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"446\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">7</text><text x=\"700\" y=\"204\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">−37%</text><rect x=\"300\" y=\"13\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">consertados</text><rect x=\"420\" y=\"13\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"438\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">quebrados</text><text x=\"700\" y=\"19\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">custo</text></svg>", "caption": "Casos consertados e quebrados em relação à versão anterior, e a mudança no que custa responder ao conjunto. Três das quatro mudanças são mais baratas, e as três quebram sete casos."}
```

Os quatro relatórios dão as regras que um teste de regressão impõe, e cada uma foi necessária para um
deles:

1. **As duas execuções fizeram as mesmas perguntas.** O `regress.py` recusa o contrário, e a versão do
   conjunto da aula 13 é contra o que ele compara. Uma execução da versão 1 do conjunto não é comparável
   com uma da versão 2:

```
ana@dev:~/obs$ python evalrun.py v1 --release 2026.10.1 && python regress.py 2026.10.1 v1
runs/v1.jsonl: 24 questions, release 2026.10.1
runs/v1.jsonl did not ask the questions of data/eval-v2.jsonl: refusing to compare
EXIT 0
```

2. **Nenhum caso vai de certo para errado sem alguém o ler.** A versão que foi ao ar quebrou sete, com
   p = 0.18. A regra é sobre os casos, não sobre o p-valor.
3. **Nenhuma verificação passa a falhar sem alguém a ler.** O modelo menor manteve os fatos certos na
   maioria das respostas que mudou, e quebrou a forma do assistente em onze delas; só as verificações
   viram.
4. **Custo e latência são relatados ao lado dos casos, com a sua direção.** A versão que foi ao ar e o
   modelo menor eram os dois mais baratos, por maus motivos. Cada um precisa de um orçamento que alguém
   aprovou: quanto mais uma versão pode custar, quanto mais lenta pode ser, e quanto mais barata pode
   ficar antes de alguém perguntar por quê.
5. **O número de respostas que mudaram é relatado**, para que alguém as leia. A e31 mudou entre duas
   execuções da mesma configuração, para uma resposta que contradiz a sua fonte e ainda passa nos fatos.

O que ele não verifica importa tanto quanto. **Ele não diz que a candidata é boa.** Diz que a candidata
não é pior que a produção em 32 perguntas. A divisão reservada, a da aula 13, roda uma vez que a
candidata está final; os sinais de produção da aula 5 assumem depois da versão ir ao ar, nas perguntas
que ninguém pensou em pôr num conjunto.

A aula 15 transforma essas regras num teste que roda em toda mudança, e reprova o build quando uma é
quebrada.
