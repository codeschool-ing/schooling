---
title: Faixas, não pontos
version: 1
---

"Quantas vezes por ano uma conta da equipe vai ser roubada por phishing e usada para ler
prontuários?" Ninguém sabe, e um número único, 0,3, finge que alguém sabe. A resposta honesta é uma
**faixa**: *algo entre uma vez em vinte anos e uma vez por ano, mais provavelmente uma vez a cada três
ou quatro.* Essa resposta diz quanto a equipe não sabe, e isso é informação de que uma decisão
precisa.

### O intervalo de 90%

A convenção, do trabalho de Douglas Hubbard sobre medir coisas incertas, é um **intervalo de
confiança de 90%**: um valor baixo e um alto escolhidos de modo que quem estima tenha 90% de certeza
de que o valor verdadeiro está entre eles. Ele tem uma propriedade útil que uma estimativa pontual não
tem: **dá para conferi-lo contra você mesmo.** De dez intervalos que você der, uns nove deveriam
acabar contendo a verdade. Se os dez contiverem, as suas faixas estavam largas demais e disseram à
decisão menos do que poderiam; se cinco contiverem, você foi confiante demais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l09-ranges\" aria-label=\"Para cada risco, a faixa de 90% da equipe para eventos por ano como uma barra num eixo logarítmico, com o melhor palpite único como um ponto. As faixas são largas: T03 de 0,05 a 1 por ano, T13 de 0,01 a 0,25, T02 de 2 a 15. Todo ponto fica dentro da sua barra.\"><text x=\"78.0\" y=\"24.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T01</text><rect x=\"271.8\" y=\"18.0\" width=\"236.6\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"398.9\" cy=\"24.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"54.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T02</text><rect x=\"508.4\" y=\"48.0\" width=\"159.1\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"595.1\" cy=\"54.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"84.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T03</text><rect x=\"217.1\" y=\"78.0\" width=\"236.6\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"358.6\" cy=\"84.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T07</text><rect x=\"217.1\" y=\"108.0\" width=\"218.9\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"326.6\" cy=\"114.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T08</text><rect x=\"398.9\" y=\"138.0\" width=\"196.2\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"508.4\" cy=\"144.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"174.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T10</text><rect x=\"358.6\" y=\"168.0\" width=\"181.8\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"453.6\" cy=\"174.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T11</text><rect x=\"398.9\" y=\"198.0\" width=\"196.2\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"508.4\" cy=\"204.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"234.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T13</text><rect x=\"90.0\" y=\"228.0\" width=\"254.2\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"217.1\" cy=\"234.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"264.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">T14</text><rect x=\"144.7\" y=\"258.0\" width=\"213.8\" height=\"12.0\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><circle cx=\"249.1\" cy=\"264.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M90.0 286.0 L690.0 286.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 286.0 L90.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,01</text><path d=\"M271.8 286.0 L271.8 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"271.8\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,1</text><path d=\"M453.6 286.0 L453.6 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"453.6\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><path d=\"M635.5 286.0 L635.5 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"635.5\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"390.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">eventos por ano, faixa de 90% (escala log)</text></svg>", "caption": "Uma faixa diz quanto a equipe não sabe. Um número único esconde isso, e a aula 10 põe as faixas para trabalhar."}
```

As faixas da Vereda são largas, e devem ser: a T13, a falha no worker, vai de uma vez em cem anos a
uma vez em quatro. Ninguém na Vereda viu isso acontecer, a equipe não tem histórico em que se apoiar,
e uma faixa estreita seria uma pretensão de conhecimento que ninguém tem.

### Melhorando nisso

Estimar faixas é uma habilidade, e ela melhora com prática e retorno. Três hábitos do treino de
calibração de Hubbard ajudam mais:

1. **Comece pelos extremos, não pelo meio.** Pergunte "que número me surpreenderia de verdade pelo
   lado baixo?" e depois pelo lado alto, e só então o melhor palpite. Começar pelo meio ancora as
   duas pontas nele, e é assim que as faixas ficam estreitas demais.
2. **Aposte.** Você prefere ganhar R$ 1.000 se o valor verdadeiro estiver dentro da sua faixa, ou
   ganhar R$ 1.000 com 90% de chance girando uma roleta? Se prefere a roleta, a sua faixa está
   estreita demais; se prefere a faixa, talvez esteja larga demais. Quem está calibrado fica
   indiferente.
3. **Procure uma classe de referência.** "Com que frequência clínicas do nosso tamanho sofrem
   vazamento?" tem evidência melhor por trás que "com que frequência nós vamos sofrer?". Comece pela
   classe e ajuste pelo que é diferente em você.

### Guardadas ao lado dos pontos

O `risks.csv` guarda as duas coisas: o melhor palpite único para a aritmética desta aula, e a faixa
de 90% para a da aula 10, que usa as faixas no lugar dos pontos:

```
(.venv) ana@vm:~/tm/portal-model$ head -3 risks.csv
id,risk,per_year,loss,per_year_low,per_year_high,loss_low,loss_high
T01,forged payment webhook,0.5,12000,0.1,2,4000,40000
T02,patient account taken over,6,1500,2,15,500,4000
```

As colunas `per_year_low` e `per_year_high` são a faixa de frequência, e `loss_low` e `loss_high` a
faixa de custo. Os melhores palpites ficam dentro delas, e nada os obriga a ficar no meio.
