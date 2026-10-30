---
title: Quem testa, e o que você pede
version: 1
---

**Um beta sem ninguém olhando é um release com atraso.** As faixas e o TestFlight movem builds; o
que transforma um build em informação é quem está do outro lado e o que lhe pediram para fazer.

## As pessoas certas para cada degrau

- **Interno: a equipe, todo build.** Inclusive quem não escreve código. Uma designer percebe a tela
  que nunca deveria ter ficado daquele jeito; alguém do suporte percebe o fluxo sobre o qual os
  clientes perguntam.
- **Fechado: pessoas que usam o app de verdade.** Para o planner, alunos que aceitaram experimentar
  versões novas durante o semestre, com os cursos reais deles dentro. Uma conta de teste cheia de
  `Course 1` e `Course 2` não acha nada que a equipe já não soubesse.
- **Aberto: qualquer um que queira a novidade antes.** Muitas pessoas, pouca orientação, e os
  números da lição 12 mais do que as palavras delas.

## O que pedir

**Uma pergunta específica recebe resposta; "por favor, teste" recebe silêncio.** Cada build de
beta sai com uma frase dizendo o que mudou e o que experimentar: *"As sessões agora sincronizam
entre celular e tablet. Adicione uma sessão num e confira se ela aparece no outro em até um
minuto."* O campo *What to Test* do TestFlight e as notas da versão de uma faixa de teste do Play
existem para essa frase.

## Comentários são um canal, não uma caixa de entrada

Comentários que chegam e ninguém lê ensinam os testadores a parar de mandá-los. Uma pessoa os lê
todo dia de um beta, responde aos testadores que escreveram e transforma o que é real em issues.
**Um testador que recebe resposta continua testando**; um que não recebe vira um usuário de produção
que achou o bug primeiro e deixou uma avaliação no lugar.

## O que o teste não substitui

Um beta acha o que as pessoas percebem. Ele não acha o crash num modelo de celular que ninguém do
beta tem, a lentidão depois de três semanas de dados ou o bug num país com outro calendário. Esses
aparecem na produção, alguns por cento de cada vez, e é por isso que a lição 8 libera em etapas e
não de uma vez.
