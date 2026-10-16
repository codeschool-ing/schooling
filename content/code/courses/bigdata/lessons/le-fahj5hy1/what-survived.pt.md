---
title: O que sobreviveu
version: 1
---

**O MapReduce como jeito de escrever programas quase sumiu. As ideias dele estão em todo motor que o
substituiu**, e reconhecê-las é o que torna o resto deste curso mais fácil de ler.

- **O shuffle.** Particionar por chave, ordenar ou fazer hash, buscar em cada produtor. O `groupBy`
  do Spark, os joins e o `repartition` terminam todos num, e a aula 7 lê o tamanho dele nos próprios
  contadores do Spark. Nada sobre distribuir um agrupamento achou um jeito de evitar levar cada chave
  a um lugar só.
- **Levar o processamento até os dados.** Tarefas de map rodavam onde estava o bloco. Os níveis de
  localidade do Spark, que a aula 3 leu, são a mesma preferência.
- **Recuperar rodando de novo.** Uma tarefa que falha roda de novo a partir da entrada, que ainda
  existe, porque tarefas são funções determinísticas da entrada. A aula 2 viu o Spark fazer isso, e a
  aula 5 dá nome ao registro que o Spark mantém para tornar isso possível.
- **O combiner.** Todo motor agrega parcialmente antes de um shuffle quando a agregação permite.
- **Contadores como primeiro diagnóstico.** Registros que entram e saem, bytes embaralhados,
  registros despejados em disco: a interface do Spark reporta as mesmas quantidades por estágio, e as
  aulas 7 e 14 as leem do jeito que a seção anterior leu as do Hadoop.

**E uma restrição sobreviveu como regra de projeto**: escrever o trabalho como funções da entrada,
sem estado escondido e sem efeitos colaterais. O MapReduce obrigava. O Spark só pede, e um programa
que ignora o pedido continua rodando, até uma tarefa ser repetida, como mostrou a pergunta do e-mail
na aula 2.
