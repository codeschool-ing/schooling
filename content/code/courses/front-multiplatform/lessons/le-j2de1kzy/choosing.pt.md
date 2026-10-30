---
title: Escolhendo entre elas, para uma equipe web
version: 1
---

**Para uma equipe que já tem uma aplicação web e gente de web, a ordem das ferramentas é quase a ordem de
quanto elas reaproveitam**, e cada degrau abaixo nessa ordem é um degrau acima no custo, que tem que
comprar alguma coisa.

| pergunta | aponta para |
|---|---|
| o app web funciona, e o celular acrescenta alguns recursos | Capacitor, e Ionic se as telas devem ter cara de celular |
| o núcleo são listas, gestos e a sensação da própria plataforma | React Native com Expo |
| o núcleo são interfaces da plataforma, alcançadas pelo TypeScript | NativeScript, ou React Native com módulos nativos |
| um visual só em toda plataforma, pixel por pixel, e uma equipe pronta para aprender Dart | Flutter |
| tudo o que é novo no dia em que sai, e duas equipes nativas | Swift e Kotlin |

**O que o planner mostrou nesta aula é o reaproveitamento, medido.** O Capacitor o levou inteiro. O React
Native levou o `planner.ts` byte por byte. O Flutter não levou nada: as regras foram escritas de novo, e
duas cópias das mesmas regras são dois lugares para um bug, um custo que cresce cada vez que as regras
mudam. A semana saiu 75 e 105 de 125 toda vez, que é para isso que servem os testes quando a mesma lógica
mora em duas linguagens.

**A decisão também é sobre pessoas.** Uma ferramenta que a equipe consegue manter vale mais que uma melhor
que ninguém da equipe conhece. A aula 16 pede que você escolha uma para o seu próprio app, e os motivos que
você escreve ali importam mais do que qual você escolhe.
