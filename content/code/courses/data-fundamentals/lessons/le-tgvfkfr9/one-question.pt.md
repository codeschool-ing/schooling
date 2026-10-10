---
title: Uma pergunta, seguida desde quem a fez
version: 1
---

**O jeito mais rápido de ver o que faz um engenheiro de dados é seguir uma pergunta até ela ser
respondida, e reparar em quem encosta nela.** Esta é a de Marta, numa segunda-feira de manhã:

> Quais estações ficaram sem bicicleta na semana passada, e por quanto tempo?

Parece uma consulta. Ainda não é, porque nada na Roda Livre guarda a resposta. A resposta está
espalhada por três sistemas feitos para outros fins, e nenhum deles foi desenhado para responder isso.

## Onde a resposta está escondida

- **O banco do aplicativo** conhece cada viagem: que bicicleta saiu de que estação, e quando foi
  devolvida. Ele foi feito para cobrar o cliente corretamente, e guarda o estado atual das coisas, não
  a história delas.
- **Os sensores das docas** informam, a cada minuto, se cada doca tem uma bicicleta. Foram feitos para o
  aplicativo mostrar um mapa, e mandam as leituras para um servidor que as guarda por dois dias.
- **A planilha de manutenção** diz quais docas quebraram, de quando a quando. Foi feita por um
  mecânico, para os mecânicos.

"Ficar sem bicicleta" quer dizer uma estação com zero bicicletas disponíveis. As três fontes discordam
sobre isso em pequenas coisas: uma bicicleta numa doca quebrada está na estação e não pode ser
retirada; um sensor pode parar de informar; o relógio do banco e o relógio dos sensores não são o
mesmo relógio.

## Quem faz o quê

**Davi, o engenheiro de dados, torna a pergunta respondível.** Ele copia as leituras dos sensores para
um lugar onde ficam guardadas por mais de dois dias, todo dia, sem perder nenhum. Copia as viagens para
fora do banco do aplicativo sem deixar o aplicativo lento. Carrega a planilha, cujas colunas os
mecânicos renomeiam quando bem entendem. Põe as três num só relógio, num só lugar, em tabelas com nomes
que querem dizer alguma coisa, e confere toda manhã que o dia anterior chegou.

**Um analista a responde.** Com essas tabelas, "ficar sem bicicleta" vira uma definição — zero
bicicletas disponíveis por pelo menos cinco minutos, digamos — e a resposta vira uma consulta e um
gráfico. Essa metade do trabalho é `analytics-bi`, e é outro ofício.

**Caio, o cientista de dados, faz a pergunta seguinte.** Com as mesmas tabelas, e dois anos delas, ele
consegue prever quais estações *vão* esvaziar na próxima sexta às seis. Essa pergunta é impossível até
a primeira se tornar respondível, e continuar respondível todo dia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O banco do aplicativo, os sensores das docas e a planilha de manutenção alimentam o engenheiro de dados, que copia, guarda, põe num só relógio e confere tudo todo dia, produzindo tabelas. Um analista lê as tabelas para responder quais estações esvaziaram; o cientista de dados as lê para prever quais vão esvaziar.\" data-fig=\"one-question\"><defs><marker id=\"one-question-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"178\" y=\"14\" width=\"362\" height=\"232\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"359\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">a metade do engenheiro de dados</text><rect x=\"14\" y=\"46\" width=\"146\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"87.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o banco do aplicativo</text><line x1=\"160\" y1=\"69\" x2=\"196\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"14\" y=\"112\" width=\"146\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"87.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os sensores das docas</text><line x1=\"160\" y1=\"135\" x2=\"196\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"14\" y=\"178\" width=\"146\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"87.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a planilha de manutenção</text><line x1=\"160\" y1=\"201\" x2=\"196\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"198\" y=\"56\" width=\"160\" height=\"148\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"278.0\" y=\"91.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">o pipeline</text><text x=\"278.0\" y=\"106.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copiar para fora</text><text x=\"278.0\" y=\"122.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">guardar por mais tempo</text><text x=\"278.0\" y=\"137.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um só relógio</text><text x=\"278.0\" y=\"153.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um só lugar</text><text x=\"278.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">conferir todo dia</text><line x1=\"358\" y1=\"130\" x2=\"386\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"388\" y=\"92\" width=\"136\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"456.0\" y=\"114.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">tabelas</text><text x=\"456.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">viagens, docas,</text><text x=\"456.0\" y=\"145.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consertos</text><line x1=\"524\" y1=\"116\" x2=\"562\" y2=\"82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><line x1=\"524\" y1=\"144\" x2=\"562\" y2=\"178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"564\" y=\"50\" width=\"144\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">um analista</text><text x=\"636.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quais estações</text><text x=\"636.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esvaziaram?</text><rect x=\"564\" y=\"148\" width=\"144\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">o cientista de dados</text><text x=\"636.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quais vão</text><text x=\"636.0\" y=\"194.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esvaziar na sexta?</text></svg>", "caption": "Três sistemas feitos para outros fins, um engenheiro que os torna consultáveis, e duas pessoas que fazem as perguntas."}
```

## A parte que ninguém vê

**Quase todo o trabalho do engenheiro de dados é invisível quando funciona.** Marta vê um gráfico. Ela
não vê que o servidor dos sensores foi trocado em agosto e passou a mandar horários em UTC, e que
alguém percebeu porque uma quarta-feira teve 27 horas de leituras. Não vê a manhã em que a planilha
chegou com uma coluna chamada `doca` em vez de `dock`, e a carga parou em vez de dar todas as docas
como inteiras.

Esse é o formato do trabalho, e o resto desta aula dá nome a ele. **Um engenheiro de dados constrói e
opera os sistemas que transformam dado feito para um fim em dado capaz de responder perguntas que
ninguém fez ainda.** O cientista de dados e o analista as fazem.
