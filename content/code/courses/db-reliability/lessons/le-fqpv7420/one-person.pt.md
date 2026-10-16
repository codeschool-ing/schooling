---
title: A pessoa que sabe
version: 1
---

Todo sistema tem alguém que sabe onde está tudo: qual servidor é o primário nesta semana, a ordem em
que as coisas devem voltar, a senha que não está no gerenciador de senhas. Na noite em que algo
quebra, essa pessoa está dormindo, num avião, doente, ou já saiu da empresa. Uma recuperação que
depende dela é uma recuperação com uma disponibilidade própria, e menor do que qualquer coisa na
tabela da lição 21.

A lição 1 contou a história de um time com cinco formas de recuperar os dados e nenhuma que
funcionasse; a outra metade daquela noite foram pessoas descobrindo, à mão e sob pressão, em que
estado estava cada cópia e o que dava para tentar em seguida. Cada passo que deram foi razoável, e
cada um foi decidido pela primeira vez naquele momento.

Um **runbook** leva essas decisões para uma tarde calma. É um documento por sistema que permite a
alguém competente, que nunca mexeu neste sistema, levá-lo de "está quebrado" até "está funcionando e
sabemos o que aconteceu", usando só o que o documento diz. Essa definição já contém o teste de se um
runbook presta: **entregue-o a outra pessoa, e observe.**

Três coisas fazem um runbook, e esta lição constrói cada uma delas para o cluster das lições 16 a 19:

- **Um formato** igual para todo cenário, para que ninguém precise ler a página inteira para achar o
  passo de que precisa.
- **Uma primeira página que se imprime sozinha**, porque o estado do sistema muda e uma página sobre
  ele não.
- **Uma checagem** de que a página continua verdadeira, feita por uma máquina, com calendário.
