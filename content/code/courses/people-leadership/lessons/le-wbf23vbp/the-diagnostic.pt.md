---
title: Uma sequência de perguntas, antes de qualquer conclusão
version: 1
---

Robert Mager e Peter Pipe escreveram em 1970 um livro curto, *Analyzing Performance Problems*,
construído em torno de um fluxograma de perguntas que uma gestora deveria fazer antes de decidir o que
fazer com alguém que não está rendendo. **A pergunta mais famosa dele é direta: a pessoa conseguiria
fazer se a vida dela dependesse disso?** Se sim, o problema não é habilidade, e treinamento não vai
resolver. Se não, nenhuma quantidade de incentivo vai.

A sequência abaixo adapta a ideia deles para um time de engenharia. Ela está ordenada para que as causas
que são responsabilidade da gestora venham primeiro, porque são as que gestoras têm menos vontade de
procurar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l19-diagnostic\" aria-label=\"Seis perguntas em sequência, de cima para baixo. Um: as expectativas estão claras? Dois: a pessoa tem o que precisa? Três: conseguiria fazer se a vida dependesse disso? Quatro: algo recompensa fazer mal, ou pune fazer bem? Cinco: algo fora do trabalho está atrapalhando? Seis, por último: é motivação? Uma chave marca as duas primeiras como a parte da própria gestora.\"><defs><marker id=\"l19-diagnostic-pl-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150.0\" y=\"20.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"198.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">as expectativas estão claras?</text><path d=\"M360.0 59.0 L360.0 69.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"70.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"89.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"198.0\" y=\"89.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a pessoa tem o que precisa?</text><path d=\"M360.0 109.0 L360.0 119.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"120.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"198.0\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">conseguiria se a vida dependesse disso?</text><path d=\"M360.0 159.0 L360.0 169.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"170.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"198.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">algo recompensa fazer mal?</text><path d=\"M360.0 209.0 L360.0 219.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"220.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"239.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"198.0\" y=\"239.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">algo fora do trabalho atrapalha?</text><path d=\"M360.0 259.0 L360.0 269.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-diagnostic-pl-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"270.0\" width=\"420.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"289.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"198.0\" y=\"289.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">só então: é motivação?</text><path d=\"M138 22 L128 22 L128 106 L138 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"120.0\" y=\"57.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a parte da</text><text x=\"120.0\" y=\"70.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">gestora</text><text x=\"584.0\" y=\"282.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a conclusão a que</text><text x=\"584.0\" y=\"295.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">se chega primeiro</text></svg>", "caption": "A partir de Mager e Pipe. A ordem põe primeiro as causas que a gestora tem menos vontade de procurar."}
```

## 1. As expectativas estão claras?

A pessoa sabe como é o bom, neste cargo, para este trabalho? Alguém disse a ela, em termos que ela
conseguiria repetir? Uma parte surpreendente dos problemas de desempenho são expectativas que nunca
foram ditas, ou foram ditas uma vez e contrariadas depois. **O teste é pedir à pessoa que descreva o que
acha que se espera dela**, e comparar com o que a gestora acha.

## 2. A pessoa tem o que precisa?

Acessos, ferramentas, informação, tempo. Uma pessoa esperando duas semanas por acesso a um sistema, ou
trabalhando com uma suíte de testes que falha ao acaso, ou carregando três projetos quando a gestora acha
que ela tem um, não está rendendo pouco; está bloqueada. Essa é a pergunta do ambiente, e a gestora
costuma ser a única pessoa que pode resolvê-lo.

## 3. Conseguiria fazer se a vida dependesse disso?

A pergunta de Mager e Pipe. Se a pessoa já fez esse tipo de trabalho bem antes, a habilidade está lá e
outra coisa está no caminho. Se nunca fez, e o trabalho precisa disso, o problema é habilidade, e a
resposta é treinamento, pareamento ou outra tarefa.

## 4. Algo torna desagradável fazer bem, ou recompensa fazer mal?

Mager e Pipe deram atenção especial a isso. Alguém que recebe mais trabalho toda vez que termina rápido
aprendeu a terminar devagar. Alguém cujos testes cuidadosos nunca são notados, enquanto as entregas
rápidas e cheias de bugs de um colega são elogiadas nas demonstrações, aprendeu o que o time valoriza.
**Consequências ensinam**, e às vezes ensinam o contrário do que a gestora quer.

## 5. Algo fora do trabalho está atrapalhando?

Doença, uma crise familiar, cuidar de alguém, preocupações com dinheiro, luto. A gestora não precisa, e
muitas vezes não deveria ter, os detalhes. O que ela precisa saber é se algo está afetando a capacidade
da pessoa, para que a resposta seja apoio e não pressão. As regras da aula 5 sobre o que fica escrito
valem aqui com toda a força.

## 6. Só então: é motivação?

Motivação vem por último, não porque nunca importe, mas porque é a conclusão a que gestoras chegam
primeiro e, muitas vezes, errado. Se as expectativas estavam claras, as ferramentas estavam lá, a
habilidade existe, nada recompensa fazer mal e nada fora do trabalho está no caminho, e o trabalho
continua não sendo feito, então talvez seja questão de vontade. Mesmo aí, "por quê?" é a próxima
pergunta, e a resposta muitas vezes é uma das cinco anteriores disfarçada.

## O que a Renata encontrou

Percorrendo a sequência antes da conversa seguinte com o Marcos, a Renata encontrou duas coisas que ela
mesma podia conferir. Sobre expectativas: ninguém tinha dito ao Marcos que o time esperava saber de um
travamento em um ou dois dias; o gestor anterior dele tratava pedir ajuda como fraqueza, o que a aula 5
já tinha insinuado. Sobre o ambiente: a biblioteca de notificações em que ele tinha travado não tinha
documentação, e a única pessoa que a conhecia tinha saído da Caju no ano anterior. As outras perguntas
precisavam dele.
