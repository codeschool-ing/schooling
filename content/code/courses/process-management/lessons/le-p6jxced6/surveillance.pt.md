---
title: Medidas que viram vigilância
version: 1
---

O jeito mais rápido de tornar inúteis as medidas de entrega é usá-las para julgar indivíduos. É também o mais tentador, porque os dados estão lá: o controle de versão sabe quem commitou o quê, o quadro sabe quem moveu qual cartão, o log de deploy sabe de quem foi a mudança que falhou.

## O que dá errado

**Os números descrevem o sistema, não as pessoas.** A contagem de commits de um desenvolvedor depende de como o trabalho dele foi dividido, do que lhe foi atribuído e de quanto da semana foi para revisar mudanças dos outros e resolver um incidente. Uma falha de mudança atribuída a quem fez o deploy em geral foi causada por um teste que ninguém escreveu, uma revisão que deixou passar algo e um processo de deploy que dificultava reverter. Ordenar pessoas por esses números mede a sorte delas nas atribuições, não a contribuição.

**As pessoas respondem ao que é medido.** É a lei de Goodhart de novo, com uma pessoa na ponta. Meça commits, e os commits ficam menores e mais frequentes. Meça linhas de código, e o código fica mais longo. Meça a taxa de falha de mudanças por pessoa, e as pessoas param de fazer deploy de qualquer coisa arriscada, ou começam a fazer deploy por meio de outra pessoa. Cada resposta é racional para o indivíduo e prejudicial para o time.

**A confiança vai primeiro.** Um time que sabe que os números são usados para ordenar seus membros para de discutir semanas ruins com honestidade, e o ciclo de melhoria da primeira seção desta aula para de funcionar, porque ninguém oferece a descoberta que o faria parecer mal.

## SPACE

Em 2021, Nicole Forsgren e colegas do GitHub e da Microsoft publicaram o framework **SPACE**, um argumento de que a produtividade de desenvolvedores não cabe num número só e precisa de várias dimensões ao mesmo tempo: **S**atisfação e bem-estar (satisfaction), desem**P**enho (performance), **A**tividade, **C**omunicação e colaboração, e **E**ficiência e fluxo. O conselho prático é medir pelo menos três dimensões juntas, incluir percepções colhidas perguntando às pessoas além de dados de ferramentas, e desconfiar acima de tudo de contagens de atividade. O curso `delivery-metrics` dedica ao SPACE, e à armadilha de medir a produtividade de um indivíduo, uma aula própria, a oitava.

## Regras que mantêm as medidas honestas

Um líder ou arquiteto consegue segurar a linha com algumas regras, ditas abertamente:

- **Só no nível do time.** As medidas descrevem o time; o nome de ninguém aparece num gráfico de entrega.
- **O time vê primeiro.** Números que vão para a gestão antes de o time olhá-los viram boletim escolar.
- **Tendências, não metas.** "Nosso lead time dobrou neste trimestre, por quê?" é uma pergunta útil; "o lead time tem de cair 20%" é um convite a manipular.
- **Nunca numa avaliação de desempenho.** O desempenho individual é uma conversa sobre comportamento e contribuição, que o curso `people-leadership` cobre, e números de entrega são a evidência errada para ela.
