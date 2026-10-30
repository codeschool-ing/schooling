---
title: Como um time escolhe
version: 1
---

**O framework raramente é a pergunta que decide.** O que decide é o time, o código que já existe, e aquilo
em que o app precisa ser melhor.

| se… | a escolha de costume |
|---|---|
| o time escreve React para a web, e o app divide lógica e pessoas com um site | React Native |
| o visual do app é próprio, muito animado, idêntico em todo lugar, e o time vai aprender Dart | Flutter |
| dois apps nativos já existem, e a parte duplicada é a lógica | Kotlin Multiplatform, um módulo por vez |
| o app vive dos recursos mais novos de uma plataforma, widgets, relógio, carro, o visual do próprio sistema | nativo, naquela plataforma |
| o time são duas pessoas e as duas plataformas são necessárias no próximo trimestre | qualquer um dos três primeiros que elas já conheçam |

Três coisas que valem seja qual for o caminho escolhido, e às quais este curso dedicou a maior parte do
tempo:

- **O lado nativo não vai embora.** Gradle, Xcode, assinatura, permissões, revisão das lojas e uma falha em
  Kotlin ou Swift fazem parte de todo caminho. O planner encontrou todos eles.
- **A qualidade está nos hábitos.** Medir antes de otimizar, testar o que uma tela faz com cada resposta,
  conferir os dados na porta, pedir uma permissão no momento em que é preciso: nenhum deles é do React
  Native, e todos se transferem.
- **A decisão pode ser revista.** O React Native e o Kotlin Multiplatform podem ser acrescentados a um app
  nativo existente, uma tela ou um módulo por vez, e uma tela nativa a um app React Native também. Poucas
  decisões aqui são permanentes; o custo está em mudá-las com frequência.
