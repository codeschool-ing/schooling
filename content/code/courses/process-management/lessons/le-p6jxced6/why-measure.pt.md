---
title: Para que serve uma medida
version: 1
---

Um time que não mede nada discute por impressões: "andamos lentos ultimamente", "os releases parecem arriscados". Um time que mede tudo se afoga em painéis que ninguém lê. Entre os dois fica uma lista curta de números escolhidos porque cada um **responde a uma pergunta que alguém precisa decidir**. Esse é o teste que esta aula aplica: uma medida vale ser mantida quando muda uma decisão, e só então.

## Três usos, e um a recusar

Medidas de entrega servem a três propósitos legítimos:

- **Prever**: quando isto fica pronto? O tempo de ciclo da aula 3 e a velocidade da aula 10 foram medidas usadas assim.
- **Melhorar**: a mudança que fizemos no jeito de trabalhar está ajudando? Um time que limita o trabalho em progresso deveria ver o tempo de ciclo cair; se não cai, a mudança não era a resposta.
- **Perceber**: alguma coisa está dando errado que ainda não sentimos? Um lead time subindo devagar ao longo de três meses aparece num gráfico muito antes de alguém reclamar.

O quarto uso, que a sexta seção desta aula recusa, é **julgar pessoas**. É o uso mais comum na prática, e destrói os outros três.

## A lei de Goodhart

Charles Goodhart, economista que assessorava o Banco da Inglaterra, observou em 1975 que qualquer regularidade estatística tende a desmoronar quando se faz pressão sobre ela para fins de controle. A antropóloga Marilyn Strathern deu depois a forma que todo mundo cita: **quando uma medida vira meta, ela deixa de ser uma boa medida.**

A aula 10 a encontrou na velocidade, que sobe quando vira meta sem nada mais mudar. Ela vale para todo número desta aula. Um time premiado pela frequência de deploy pode fazer deploy de mudanças vazias; um time premiado por uma taxa baixa de falha de mudanças pode parar de fazer deploy. Os números só continuam úteis enquanto ninguém tenta mexer neles diretamente, o que quer dizer que pertencem primeiro ao time que os produz.

## Meça o sistema, não as pessoas

As medidas desta aula descrevem **um time e o processo dele** — como o trabalho flui, com que frequência as mudanças chegam aos usuários, com que frequência quebram. Elas não dizem nada sobre a contribuição de nenhum indivíduo, e nem deveriam. Isso é uma qualidade: um time dono dos próprios números consegue olhar um mês ruim com honestidade, porque o número aponta para o sistema que o time pode mudar e não para uma pessoa que vai se defender.
