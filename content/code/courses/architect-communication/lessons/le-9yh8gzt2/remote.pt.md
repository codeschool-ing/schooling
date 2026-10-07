---
title: Pareando a distância
version: 1
---

**O pareamento remoto funciona tão bem quanto o pareamento na mesma mesa quando três coisas estão
resolvidas: as duas pessoas conseguem digitar, as duas se ouvem sem esforço, e a troca leva segundos,
não minutos.** Metade dos engenheiros da Marola trabalha de casa na maioria dos dias, então quase todo
o pareamento ali é remoto, e as falhas quase sempre são uma dessas três.

## As duas pessoas conseguem digitar

O pior arranjo é uma pessoa compartilhando a tela enquanto a outra assiste a um vídeo dela. O
navegador não consegue apontar nada a não ser descrevendo ("não, a linha de cima, a outra"), e a
troca exige parar o compartilhamento, enviar um branch, puxá-lo e compartilhar de novo. Pares que
trabalham assim param de trocar, e a sessão vira uma demonstração.

O que funciona é uma sessão de edição compartilhada, que a maioria dos editores e ambientes de
desenvolvimento já oferece, ou um branch de vida curta em que as duas pessoas fazem push a cada troca,
com uma ferramenta que faz o push e o pull num comando só. **O teste é se a troca leva menos de dez
segundos.** Se levar mais, as pessoas param de trocar.

## As duas se ouvem

O áudio importa mais que o vídeo. Um headset, uma sala silenciosa e o combinado de pedir "pode
repetir?" sem se desculpar. O vídeo ajuda nos primeiros minutos e nos momentos de discordância, quando
um rosto carrega o que as palavras não carregam; no resto da sessão, muitos pares desligam a câmera e
deixam o editor ocupando a tela inteira.

## Um timer, e pausas

Na mesma mesa, as pessoas percebem quando a outra está cansada. A distância, não percebem, então a
estrutura tem de fazer isso por elas:

- **um timer para as trocas**, visível para os dois, a cada vinte e cinco minutos mais ou menos;
- **uma pausa a cada hora**, de verdade, longe da tela;
- **um fim combinado**, dito no começo: "até o almoço", "até o teste passar".

## Anotando onde vocês pararam

Pares remotos muitas vezes terminam no meio da tarefa, num horário diferente para cada um. Os últimos
cinco minutos vão para uma nota no pull request ou no ticket: o que foi feito, o que vem a seguir e
qualquer decisão tomada que ainda não está no código. **Essa nota é a diferença entre um par que
consegue retomar amanhã e um que passa a primeira meia hora reconstruindo o dia anterior.**
