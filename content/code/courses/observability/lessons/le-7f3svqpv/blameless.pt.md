---
title: Por que o postmortem é sem culpados
version: 1
---

Um **postmortem** é a revisão escrita de um incidente: o que aconteceu, por quê, quanto custou e o que
vai mudar. **Sem culpados** (blameless) significa que ele procura as condições que tornaram a falha
possível, e nunca uma pessoa para responsabilizar.

Isso não é gentileza, é método. A revisão de um incidente depende de as pessoas dizerem exatamente o que
fizeram, incluindo o comando que rodaram sem conferir e o aviso que dispensaram. **Se dizer isso pode
custar algo a elas, elas não vão dizer**, e a revisão vai explicar o incidente com os fatos que é seguro
admitir, que raramente são os úteis. Uma equipe que culpa ganha postmortems mais curtos, menos quase
acidentes relatados, e os mesmos incidentes de novo.

O segundo argumento é que a culpa costuma estar errada nos fatos. **Uma pessoa cometeu um erro porque o
sistema deixou**: a versão não tinha canary, a reversão não estava documentada, o alerta disparou vinte
minutos atrasado, o comando perigoso parecia o seguro. Trocar a pessoa não muda nada disso, e a próxima
comete o mesmo erro. Perguntar *como o sistema tornou isso fácil?* acha algo para mudar; perguntar *quem
fez isso?* acha alguém para culpar e para.

O que sem culpados não significa:

- **Não significa que ninguém fez nada.** O postmortem nomeia ações e decisões com clareza, com
  horários; ele as descreve como as escolhas razoáveis que pareciam ser com o que se sabia então.
- **Não significa ausência de responsabilidade.** As pessoas respondem por participar com honestidade e
  pelas ações que assumem depois.
- **Não desculpa negligência ou má-fé**, que são raras, e são assunto de gestão, não da revisão do
  incidente.

O teste de uma cultura sem culpados é o que acontece com a pessoa que causa o próximo incidente. Se ela
mesma escreve o postmortem, em detalhe, e é agradecida por isso, está funcionando.
