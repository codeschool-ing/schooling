---
title: O que GitOps não é
version: 1
---

A palavra viaja mais longe que a ideia, então vale dizer o que não conta.

**Não é "guardamos nosso YAML no Git".** Quase todo mundo guarda manifestos no Git. Se uma pessoa ou
um pipeline ainda roda `kubectl apply` de um notebook ou de um job de CI, o repositório é um registro
do que alguém pretendia, e o cluster pode se afastar dele por meses. Os princípios que fazem disso
GitOps são o terceiro e o quarto: o estado é puxado, e o puxar nunca para.

**Não é deploy contínuo.** Deploy contínuo é uma decisão sobre *quando* as mudanças vão para a
produção: a cada merge, automaticamente. GitOps é sobre *como* elas chegam lá. Um time pode usar
GitOps e ainda publicar uma vez por semana, fazendo merge no diretório de produção uma vez por semana;
a aula 5 mostra como ambientes e promoção cabem num repositório.

**Não substitui o CI.** Alguma coisa ainda precisa testar o código, construir a imagem e enviá-la a
um registry. Num arranjo GitOps esse pipeline termina no registry, ou num commit que cita a imagem
nova; ele não toca mais no cluster. `testing-cicd` é o curso sobre esse pipeline.

**Não torna segura uma mudança ruim.** Um reconciliador aplica um manifesto quebrado com a mesma
fidelidade com que aplica um bom, e mais depressa do que uma pessoa aplicaria. O que ele muda é o que
acontece depois: a mudança quebrada é um commit com autor, pode ser revertida com outro commit, e a
reversão é aplicada pelo mesmo laço. A aula 2 é sobre pegá-la antes do merge, e a aula 3 sobre vê-la
depois.

**E não cobre tudo.** Parte do estado não pertence ao Git: os dados de um banco, os próprios
segredos, qualquer coisa gerada em tempo de execução. As aulas 9 a 11 tratam do mais importante
deles, os segredos, e de como manter uma referência a eles no repositório sem manter o segredo lá.

## Quando vale a pena

Os custos da seção sobre push e pull são reais: um agente para manter, um atraso entre o merge e o
deploy, um repositório que precisa ser guardado como a produção. Eles se pagam na proporção de
quantas pessoas mudam o sistema e de quanto dói não saber o que está rodando. Uma pessoa publicando
um serviço num cluster ganha pouco. Dez times publicando em staging e produção, com um auditor
perguntando quem mudou o quê, é o caso para o qual o resto deste curso foi escrito, e a aula 12
responde ao auditor.
