---
title: Medindo a escolha
version: 1
---

Cada estratégia desta aula tem um argumento a favor, e argumentos não decidem qual usar num corpus
específico. Uma medição decide. O `compare.py` corta os treze documentos de nove jeitos, gera o
embedding de cada pedaço, e roda as 26 perguntas com resposta do conjunto de teste contra cada conjunto
de pedaços. Uma pergunta conta como **achada** quando o trecho que a responde, as palavras registradas
no `eval.jsonl`, está dentro de um dos três pedaços recuperados. Ele também conta quantos tokens esses
três pedaços poriam no prompt.

```
ana@lab:~/rag$ python compare.py
strategy                 chunks  words  found  tokens
fixed, 30 words             227     29  17/26     108
fixed, 60 words             116     57  21/26     217
fixed, 60 + 15 overlap      150     58  24/26     219
fixed, 120 words             62    106  23/26     404
fixed, 240 words             34    194  26/26     768
sections                     92     64  25/26     260
structured, 60 words        137     43  24/26     170
structured, 120 words        99     59  25/26     237
semantic                     98     63  21/26     333
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Um gráfico de dispersão de nove estratégias de corte: tokens recuperados por pergunta contra perguntas cuja resposta foi recuperada, de 26. Fixo 30 palavras: 108 tokens, 17. Fixo 60: 217, 21. Fixo 60 com 15 sobrepostas: 219, 24. Fixo 120: 404, 23. Fixo 240: 768, 26. Seções: 260, 25. Estruturado 60: 170, 24. Estruturado 120: 237, 25. Semântico: 333, 21.\"><path d=\"M70 280 L690 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 280 L70.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M225.0 280 L225.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"225.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M380.0 280 L380.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><path d=\"M535.0 280 L535.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"535.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">600</text><path d=\"M690.0 280 L690.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">800</text><path d=\"M65 280.0 L70 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><path d=\"M65 232.0 L70 232.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M65 184.0 L70 184.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M65 136.0 L70 136.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"136.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><path d=\"M65 88.0 L70 88.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26</text><text x=\"380.0\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens recuperados por pergunta, três pedaços</text><text x=\"70\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">perguntas cuja resposta foi recuperada, de 26</text><circle cx=\"153.7\" cy=\"256.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"161.7\" y=\"268.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 30</text><circle cx=\"238.2\" cy=\"160.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"246.175\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 60</text><circle cx=\"239.7\" cy=\"88.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"247.725\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 60+15</text><circle cx=\"383.1\" cy=\"112.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"391.1\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 120</text><circle cx=\"665.2\" cy=\"40.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"657.2\" y=\"54.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixo 240</text><circle cx=\"271.5\" cy=\"64.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"279.5\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">seções</text><circle cx=\"201.8\" cy=\"88.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"191.75\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estruturado 60</text><circle cx=\"253.7\" cy=\"64.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"245.675\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estruturado 120</text><circle cx=\"328.1\" cy=\"160.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"336.075\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">semântico</text></svg>", "caption": "Para cima e para a esquerda é melhor: mais respostas achadas com menos tokens. As três que seguem a estrutura dos próprios documentos ficam no alto à esquerda; o fixo 240 acha tudo pelo triplo do preço."}
```

## Lendo a tabela

**Os pedaços menores acharam menos respostas.** Janelas de trinta palavras acharam 17 de 26: cada uma é
curta demais para levar seu contexto, e o trecho que responde a uma pergunta muitas vezes fica cortado
entre duas delas.

**Os pedaços maiores acharam tudo, pelo triplo do preço.** Pedaços fixos de 240 palavras acharam as 26,
porque um pedaço desse tamanho em geral contém a seção inteira onde está a resposta. Eles puseram 768
tokens no prompt por pergunta, contra 237 do estruturado 120, que achou 25. Uma resposta a mais por 531
tokens a mais em toda pergunta é uma troca ruim, e a aula 12 mostra quanto desse texto a mais é ruído.

**Seguir a estrutura domina.** Seções, estruturado 120 e estruturado 60 ficam no alto à esquerda da
figura: 24 ou 25 achadas, por 170 a 260 tokens. O estruturado 60 achou 24 com o contexto mais barato de
todas as estratégias que acharam mais de 21. Nada do que as estratégias por contagem fizeram, a
sobreposição incluída, chegou a essa combinação.

**A sobreposição valeu o custo; o corte semântico não, aqui.** A sobreposição levou o fixo 60 de 21 para
24 por dois tokens a mais por pergunta. O corte semântico achou 21, o mesmo que o fixo 60 sem
sobreposição, e pôs mais tokens no prompt que qualquer das variantes estruturadas.

## O que esta medição é e o que não é

É uma medição neste corpus e nestas 26 perguntas, e os números serão outros no seu. **É para isso que
se roda**: o tamanho certo de pedaço depende de quão longos são os parágrafos dos documentos, de quão
específicas são as perguntas e de quantos tokens um prompt pode pagar, e nada disso é uma constante que
alguém possa lhe citar.

Ela mede só a recuperação. Uma resposta achada ainda tem de ser usada pelo gerador, e a aula 8 mede as
respostas também. E 26 perguntas é um conjunto de teste pequeno: uma pergunta são quatro pontos
percentuais, então a diferença entre 24 e 25 é uma pergunta e não deveria decidir nada sozinha. As
diferenças grandes, 17 contra 25, ou 768 tokens contra 237, são as que merecem ação.

O hábito que vale guardar é a forma do `compare.py`: **um conjunto fixo de perguntas com respostas
conhecidas, rodado contra cada candidato, informando qualidade e custo lado a lado.** A aula 8 o
transforma no teste permanente do pipeline.
