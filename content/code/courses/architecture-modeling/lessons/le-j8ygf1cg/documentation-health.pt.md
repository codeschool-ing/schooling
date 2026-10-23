---
title: Quão saudável está a documentação?
version: 1
---

**Cada dono mantém viva a sua página; ninguém enxerga o conjunto inteiro a não ser que alguém o
meça.** Um punhado de números, coletados por um script a partir do repositório, mostra a um
arquiteto onde a documentação está morrendo antes que os leitores deixem de confiar nela.

## Cinco medidas

| medida | como é coletada | Carcará, antes | depois de um trimestre |
| --- | --- | --- | --- |
| **páginas com dono** | um campo no front matter de cada página | 38% | 100% |
| **páginas verificadas nos últimos 12 meses** | uma *data de verificação* no front matter | 22% (31 de 140) | 89% (57 de 64) |
| **links internos quebrados** | um verificador de links no CI | 47 | 0, e a verificação agora quebra o build |
| **requisitos significativos com uma verificação** | a matriz da aula 6, lida por um script | 2 de 5 | 5 de 5 |
| **diagramas que mostram um elemento aposentado** | uma lista de nomes aposentados, procurada nos fontes dos diagramas | 3 | 0 |

Duas coisas na tabela merecem atenção. Primeiro, **o número de páginas caiu de 140 para 64**: a maior
parte da melhora veio de apagar, que é o assunto da última seção desta aula. Segundo, a *data de
verificação* não é a data de edição. Uma página pode estar certa por anos sem uma edição; o que a
data registra é que o dono **a leu e confirmou que continua verdadeira**. É esse gesto barato que
mantém a confiança, e ele custa um minuto.

## A cadência de revisão segue a volatilidade

Nem toda página precisa do mesmo ritmo. A Carcará definiu três:

- **a cada trimestre**: as visões de implantação e de containers, o mapa de plantão, tudo o que for
  de infraestrutura, que é o que muda mais rápido;
- **a cada ano**: a introdução do arc42, os conceitos transversais, o glossário, os objetivos de
  qualidade;
- **nunca**: registros de decisão e postmortems, que são registros de um momento e não se atualizam,
  como a aula 5 e a aula 8 de `architecture-role` fazem questão de dizer.

Um script pequeno lista as páginas cuja *data de verificação* é mais antiga que a sua cadência e abre
um chamado para cada dono. O que importa não é o script; é que **o lembrete vem de um calendário, e
não de alguém se lembrar**.

## O que os números não dizem

Uma página pode ter dono, ter sido verificada há pouco e ainda assim ser inútil, porque ninguém
precisa dela ou porque responde a uma pergunta que ninguém faz. Os números acham o envelhecimento;
não acham a irrelevância. Para isso, o melhor sinal é aquele com que a aula 1 começou: **peça a um
leitor que use a página e observe onde ele trava**. A Carcará faz isso uma vez por ano, com quem
entrou mais recentemente.
