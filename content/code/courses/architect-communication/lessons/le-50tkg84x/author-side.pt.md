---
title: A metade da revisão que cabe ao autor
version: 1
---

**Uma revisão ensina tanto quanto a mudança permite, e quem decide quanto é o autor.** Um pull request
de 2.000 linhas sem descrição recebe uma passada de olho e uma aprovação; um de 200 linhas que diz o
que faz e por quê é lido. O lado do autor na revisão consiste sobretudo em levar a atenção de quem
revisa para onde ela é necessária.

## Mudanças pequenas recebem revisões de verdade

Um estudo muito citado sobre revisão de código na Cisco, feito pela SmartBear em 2006, concluiu que a
capacidade dos revisores de encontrar defeitos caía bruscamente quando uma revisão passava de cerca de
400 linhas, e quando o revisor ia mais rápido do que cerca de 500 linhas por hora. Os números exatos
dependem do time e do código. A forma não está em dúvida, e todo revisor já a sentiu: **passado um
certo tamanho, quem revisa para de ler e começa a rolar a tela.**

Então o autor divide o trabalho. Uma mudança que renomeia um módulo, corrige um bug e acrescenta uma
funcionalidade são três pull requests, cada um pequeno o bastante para ser lido e revisável nos
próprios termos.

## A descrição é um documento curto

A aula 1 se aplica diretamente: a descrição de um pull request é lida primeiro por quem revisa, e por
quem rodar `git log` no arquivo daqui a um ano. O segundo pull request do Rafael, depois da revisão do
Diego, tinha esta descrição:

> **O quê.** As janelas de entrega param no horário de fechamento do depósito, que agora vem da tabela
> de horários de funcionamento em vez de uma constante.
>
> **Por quê.** Os motoristas recebiam janelas depois do fechamento (22:00 em diante). Ver a revisão do
> Diego no PR anterior.
>
> **Como verificar.** `test_slots.py` cobre 21:10 num dia útil, 18:30 num sábado (fecha às 19:00) e um
> domingo fechado.
>
> **Fora deste PR.** Feriados: a tabela ainda não os tem; issue separado no link.

Quatro blocos curtos: o que mudou, por quê, como verificar e o que ficou de fora de propósito. O último
evita o comentário mais comum numa revisão, "e os feriados?", porque responde a ele de antemão.

## Revise a sua própria mudança primeiro

Antes de pedir a alguém, leia o seu próprio diff na ferramenta de revisão, do jeito que o revisor vai
ver. É surpreendente com que frequência o autor encontra a linha de depuração esquecida, o bloco
comentado ou o teste que era para ter sido escrito. **Cada problema que o autor pega é um em que o
revisor não gasta um comentário**, e esse comentário pode ir para o design.

## Responder aos comentários

O autor deve uma resposta a cada comentário, nos mesmos três estados de um comentário de RFC da aula 2:
alterado, recusado com um motivo, ou registrado para depois. "Feito" é uma boa resposta para um
nitpick. Uma sugestão de que o autor discorda recebe um motivo, e **discordar de quem revisa faz parte
do trabalho**, inclusive um júnior discordando de um sênior, desde que o motivo seja o código.
