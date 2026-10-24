---
title: O vue-tsc, e onde a conferência acontece
version: 1
---

**O servidor de desenvolvimento não confere tipos, e o build também não, a não ser que você peça.** O
Vite remove os tipos de cada arquivo que serve e não confere nada, e é por isso que o planner
rodou no navegador durante toda esta aula enquanto o `vue-tsc` apontava dezenas de erros. Então a
conferência tem de ficar num lugar em que não dê para pulá-la.

## No build

O script `build` do `package.json` vira dois passos, o verificador primeiro:

```
ana@dev:~/vue/planner$ npm pkg set scripts.build='vue-tsc --noEmit && vite build'
```

O `&&` só roda o segundo comando se o primeiro deu certo, então **um erro de tipo agora para o
build**. Mostre isso com o escorregão da seção de emits tipados, e o `sed` que o desfaz:

```
ana@dev:~/vue/planner$ sed -i "s/emit('toggle'/emit('toggel'/" src/components/SessionRow.vue
ana@dev:~/vue/planner$ npm run build

> planner@0.0.0 build
> vue-tsc --noEmit && vite build

src/components/SessionRow.vue(23,68): error TS2345: Argument of type '"toggel"' is not assignable to parameter of type '"toggle"'.
ana@dev:~/vue/planner$ sed -i "s/emit('toggel'/emit('toggle'/" src/components/SessionRow.vue
```

O build parou no verificador, e o `vite build` nunca rodou. Os projetos TypeScript do `create-vue`
rodam os dois em paralelo com um pacote auxiliar e falham se qualquer um falhar; o planner os roda um
depois do outro, o que é alguns segundos mais lento e não precisa de nada instalado.

## Enquanto você trabalha

Três lugares para ver erros de tipo enquanto digita, em ordem de quão cedo eles avisam:

- **O editor.** O VS Code com a extensão *Vue (Official)* roda o mesmo verificador em segundo plano e
  sublinha o erro enquanto você o digita. É aqui que a maioria dos erros de tipo é encontrada e
  corrigida.
- **`npm run type-check`**, antes de um commit. Alguns segundos para um projeto deste tamanho.
- **A CI**, o pipeline que a aula 3 de `front-delivery` constrói, que roda o verificador em cada pull
  request para que um erro que ninguém viu localmente não possa ser mesclado.

O `vite-plugin-checker` põe o verificador dentro do servidor de desenvolvimento, com os erros no
terminal e por cima da página. Ele custa tempo de inicialização em projetos grandes e o curso não o
usa; o editor dá a mesma resposta mais cedo.

## O servidor de desenvolvimento, sem mudança

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --text main
[vite] connecting...
[vite] connected.
== the text of main
This week
Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

0 of 20 minutes done, goal 90

 0% of the weekly goal

Week of 19 October 2026
Previous weekNext week
Add a session
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes

75 of 195 minutes done
```

O planner em TypeScript é o planner: a mesma tela, os mesmos números. O que mudou é que a próxima
propriedade errada, prop que falta ou evento com o nome errado vai ser encontrado por um programa antes
de ser encontrado por uma pessoa.
