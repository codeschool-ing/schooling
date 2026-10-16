---
title: A escala
version: 1
---

Alguém tem que atender quando a cobrança no cartão quebra às duas da manhã. O **plantão** é o arranjo que decide quem, com antecedência, para que a resposta nunca seja "quem por acaso vir a mensagem". A pessoa de plantão carrega o pager, que hoje é um app no celular, e se compromete a atendê-lo em minutos, a qualquer hora, durante um turno inteiro.

## O formato de uma escala

A **escala** é a ordem em que as pessoas se revezam. A maioria dos times usa as mesmas poucas peças:

- **um primário**, acionado primeiro e de quem se espera a resposta;
- **um secundário**, acionado se o primário não reconhece o acionamento, e que pode ser chamado quando uma pessoa não basta;
- **uma duração de turno**, quase sempre uma semana, porque turnos mais curtos querem dizer mais trocas de plantão e turnos mais longos desgastam as pessoas;
- **um dia de troca de plantão** no meio da semana, quarta ou quinta, para que ninguém comece um turno numa segunda de manhã direto em tudo o que o fim de semana deixou para trás.

A escala do time de Billing é de uma semana para cada um, em revezamento, com troca às quartas: Duda, Inês, Rafa, Téo, Caio, e de novo do começo. O secundário é quem foi primário na semana anterior, porque sabe o que aconteceu por último. A Bia, a tech lead, é o último nível de escalada e não está na escala, uma escolha à qual as próximas seções voltam.

## De que tamanho uma escala precisa ser

Dois números do livro de SRE do Google são a referência usual, e os dois são sobre pessoas, não sobre sistemas.

- **Ninguém deveria passar mais de um quarto do tempo de plantão.** Além disso, o plantão deixa de ser um dever e vira o trabalho, e o resto do trabalho não é feito.
- **Uma escala que cobre todas as horas a partir de um só lugar precisa de umas oito pessoas** para cumprir a primeira regra e deixar espaço para férias, doença e a semana em que nasce o filho de alguém.

O time de Billing tem cinco. Uma semana em cinco é 20%, dentro da primeira regra, mas só enquanto os cinco estão presentes: umas férias fazem disso uma semana em quatro, e duas ao mesmo tempo, uma em três. Um time de cinco consegue carregar um pager, e carrega sem nenhuma margem, o que vale dizer em voz alta antes que alguém marque férias em dezembro.

## O que uma escala não é

Uma escala não é uma lista de quem culpar. A pessoa de plantão é a primeira a responder, não a pessoa que tem que consertar tudo sozinha. **O trabalho dela é reconhecer, avaliar e, se o problema é maior que uma pessoa, pedir ajuda**: os papéis de incidente da aula 13 existem exatamente para isso, e o primário muitas vezes é quem declara o incidente e passa o comando para outra pessoa.

Também não é motivo para parar de consertar as coisas. Uma escala que aciona alguém toda noite não é um problema de pessoal a resolver com mais gente; é um sistema dizendo ao time onde trabalhar, e a aula 18 é sobre ouvi-lo.
