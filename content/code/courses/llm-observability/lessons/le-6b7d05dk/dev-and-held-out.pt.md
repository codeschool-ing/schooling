---
title: Desenvolvimento e reservado
version: 2
---

Todo caso da versão 2 pertence a uma de duas **divisões**, decidida só pelo seu id: um em cada três ids
fica **reservado** (*held-out*), o resto é de **desenvolvimento** (*dev*). Ela dá 22 e 10.

As duas divisões respondem a perguntas diferentes:

- **Desenvolvimento** é onde uma equipe olha enquanto muda as coisas. Todo caso reprovado é lido, o
  prompt ou a recuperação é ajustado, e a nota é medida de novo. Depois de algumas rodadas as mudanças
  têm a forma destes casos, e a nota neles deixa de estimar qualquer coisa além destes casos.
- **Reservado** não é olhado enquanto se muda as coisas. Ele roda quando uma mudança está pronta,
  para dizer se a melhora no desenvolvimento vale para perguntas que não moldaram a mudança. Um limiar
  escolhido sobre todas as respostas rotuladas, sem nada reservado, fica encaixado nelas e não diz
  nada sobre as próximas.

Uma divisão decidida pelo id e não ao acaso tem uma propriedade que vale mais que equilíbrio: **um caso
nunca muda de divisão**. Os casos novos entram pela mesma regra, e um caso que estava reservado no ano
passado está reservado agora, então ninguém ajusta nele sem querer.

## Quantos casos bastam

A aritmética da aula 9 vale para um conjunto como vale para uma amostra. Com 10 casos reservados, uma
taxa de aprovação de 70% é conhecida com cerca de ±28 pontos; com 22, cerca de ±19. Um conjunto deste
tamanho mostra uma versão que quebra um terço das respostas, e não mostra uma que quebra um décimo.

Duas coisas decorrem disso. **Um conjunto nunca fica pronto**: a coleta de cada semana é uma fonte de
casos, e uma equipe que acrescenta alguns por semana tem algumas centenas dentro de um ano. E **um
conjunto pequeno ainda vale a pena**, porque o que lhe falta em precisão ele compensa sendo o mesmo toda
vez: as mesmas 32 perguntas, rodadas em toda versão, acham uma mudança que quebra um caso de vez, que é o
tipo de que a aula 14 trata.
