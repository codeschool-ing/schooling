---
title: Da causa à ação, e conferindo que funcionou
version: 1
---

**Uma análise termina quando uma ação é escolhida, tem dono e é conferida, não quando o diagrama é desenhado.** Uma
parede de causas sem ação embaixo é o registro de uma semana ruim, e a semana seguinte a repete.

## Ações boas e ações fracas

As causas da espinha de peixe da quarta produziram uma lista de ações possíveis. Não são igualmente boas.

| ação | força | por quê |
|---|---|---|
| "tomar mais cuidado com descontos" | fraca | pede às pessoas que se esforcem mais naquilo que já tentavam fazer |
| "a Lia revisa toda mudança de preço" | fraca | põe um portão na frente de uma pessoa, o gargalo da aula 5 |
| casos de combinação em todo planejamento, o hábito da aula 6 | média | muda o processo, e depende de alguém lembrar |
| um esboço de combinações de desconto que roda a cada mudança, da aula 17 | forte | é automático, e o próximo defeito de empilhamento falha nele no dia em que é escrito |
| uma coluna de desconto no relatório noturno | forte | torna o próximo visível mesmo se todos os outros passos falharem |

O padrão é o que a engenharia de segurança usa: ações que mudam o sistema valem mais que ações que pedem às pessoas
que se comportem diferente, e uma ação que torna uma falha *visível* vale a pena mesmo quando a falha deveria ser
prevenida em outro lugar.

## Toda ação tem dono e data

O Cine Aurora escreve cada ação escolhida no quadro com um nome e uma data: *esboço de combinações de desconto,
Rafael, até sexta*; *coluna de desconto no relatório, Tomás, próxima sprint*. Uma ação sem nome é de todos, ou seja,
de ninguém, e é a primeira coisa a cair da próxima sprint.

## Conferindo que funcionou

Uma ação é uma hipótese: *se fizermos isto, defeitos como aquele param*. Como qualquer hipótese, dá para testá-la, e a
retrospectiva um mês depois é o lugar. A Lia faz duas perguntas:

- **foi feita?** O esboço existe e roda a cada mudança; o relatório tem a coluna.
- **funcionou?** Desde então, algum defeito do mesmo tipo chegou a um cliente, ou foi pego mais tarde do que
  deveria?

A segunda pergunta precisa que os registros de defeito da aula 4 digam de que tipo cada defeito era. Esse é um dos
motivos de um relato de defeito ter campos e não só uma descrição: um mês depois, *quantos defeitos de desconto
chegaram à bilheteria desde o esboço?* é uma pergunta que alguém consegue responder.

## Raramente existe uma causa raiz só

O nome *análise de causa raiz* sugere que todo defeito tem uma raiz, esperando para ser desenterrada. A espinha de
peixe mostra por que isso engana: o defeito da quarta precisou de um requisito calado, um hábito de planejamento
faltando, uma revisão atrasada, nenhuma verificação automatizada e um relatório que escondia descontos, tudo ao
mesmo tempo. Tirar qualquer um deles o teria parado.

Alguns autores preferem o termo **causas contribuintes** exatamente por isso, e é o jeito mais saudável de pensar.
Um time caçando *a* causa raiz para na primeira plausível e se sente terminado. Um time procurando causas
contribuintes continua perguntando o que mais precisou ser verdade, e acaba com mais lugares onde agir, a maioria
baratos.

Esse é o argumento de quem testa a favor da análise de causa raiz, numa frase: **o teste acha o defeito; a análise
acha os motivos de o próximo estar a caminho, e é o teste mais barato que um time vai fazer.**
