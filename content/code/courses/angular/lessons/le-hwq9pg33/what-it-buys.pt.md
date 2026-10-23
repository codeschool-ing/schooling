---
title: O que a caixa compra, e quem a compra
version: 1
---

O resumo do curso chama o Angular de framework do banco, da seguradora e do governo. Isso descreve
quem o escolhe, não é um ranking, e vale conhecer os motivos antes de investir noventa horas nele.
São os mesmos motivos pelos quais ele vai parecer pesado nas primeiras aulas.

## Três coisas que uma organização grande paga para ter

**Um jeito só para cada assunto.** Uma organização com quarenta pessoas de front-end em oito times
move gente entre os times. Quando as rotas, os formulários e o acesso a dados de todo time são as
mesmas bibliotecas usadas do mesmo jeito, quem muda de time lê o código novo no primeiro dia. A
tabela da seção anterior é o que torna isso verdade: não há nada por time para escolher.

**Um calendário.** O Angular publica uma versão major duas vezes por ano, e as datas são regulares
o bastante para planejar um orçamento em volta delas. O registro do npm guarda quando cada `.0.0` do
`@angular/core` foi publicado; a aula 2 pergunta, e recebe a 20.0.0 em 28 de maio de 2025, a 21.0.0
em 19 de novembro de 2025 e a 22.0.0 em 3 de junho de 2026. Cada major tem dezoito meses de suporte:
seis de desenvolvimento ativo, depois doze de suporte de longo prazo, o que quer dizer só correções
de segurança e críticas.

**Atualizações que editam o seu código por você.** O `ng update`, que a aula 2 roda, não só sobe
números de versão. Uma versão traz **migrações**, pequenos programas que reescrevem o código do seu
projeto onde uma API mudou. O Angular trocou nos templates o `*ngIf` pelo `@if` (aula 5) e nos
componentes os NgModules pelos standalone (aula 3) desse jeito, em bases com milhares de arquivos, e
as formas antigas continuaram funcionando por várias versões enquanto os times migravam.

## TypeScript desde a primeira linha

Todo projeto Angular é TypeScript, e não existe opção em JavaScript. Isso importa mais para quem
escolhe do que para quem aprende: um erro de tipo achado pelo compilador num template é um bug que
nunca chegou a quem testa, e numa base que dez pessoas mudam todo dia o compilador é o único revisor
que lê todas as linhas. Duas seções desta aula ensinam TypeScript suficiente para começar; cada aula
depois acrescenta a parte de que precisa.

## O que custa

- **Mais para aprender antes da primeira tela.** Decorators, a lista `imports`, templates, e
  injeção de dependência na aula 10. O React pede menos no primeiro dia.
- **Mais palavras por funcionalidade.** Um componente é uma classe, um decorator, um template e
  muitas vezes uma folha de estilo, às vezes em quatro arquivos. O gerador da aula 2 escreve o
  esqueleto, o que ajuda e não deixa a leitura mais curta.
- **Peso antes de você escrever qualquer coisa.** O framework traz a maquinaria que chama o seu
  código, então até uma aplicação que só diz olá tem um tamanho. A aula 2 mede uma, e
  `front-performance` é o curso sobre o que fazer com números assim.
- **Duas gerações de código por aí.** O Angular está no meio de uma longa mudança de modelo: signals
  no lugar do zone.js para saber quando algo mudou (aulas 6 e 7), e componentes standalone no lugar
  de módulos (aula 3). Código novo se escreve do jeito novo; o código que você vai abrir no trabalho
  muitas vezes é o antigo. Este curso ensina os dois, e diz qual é qual.

## A quem serve

Serve a um projeto que vai viver por anos, mantido por pessoas que não vão estar todas lá no fim.
Serve menos a um protótipo de fim de semana, ou a um time de duas pessoas que já sabe React. Nada
disso decide a sua carreira: as ideias se transferem, que é o ponto da aula 25, e a bifurcação da
trilha `frontend` existe para você aprender um framework direito antes de olhar os outros.
