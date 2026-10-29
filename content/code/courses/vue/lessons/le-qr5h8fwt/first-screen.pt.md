---
title: A primeira tela do planner
version: 1
---

**A primeira tela do planner lista os seus cursos, e ela é escrita no `App.vue` e em mais um
componente.** Tudo nela ainda é texto fixo. A aula 2 a torna reativa e carrega os cursos de um
arquivo, em vez de escrevê-los dentro do componente.

Troque o `src/App.vue` por este:

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport AppFooter from './components/AppFooter.vue'\n\nconst title = 'Study planner'\nconst courses = [\n  { id: 'statistics', title: 'Statistics', goal: 180 },\n  { id: 'spanish', title: 'Spanish', goal: 120 },\n  { id: 'guitar', title: 'Guitar', goal: 90 },\n]\n</script>", "note": "O script declara o que o template lê. Um `const` declarado no `<script setup>` fica visível no template pelo nome, sem `return` e sem export."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p>{{ courses.length }} courses this term</p>\n  </header>", "note": "Chaves duplas põem um valor no texto. A expressão dentro delas é JavaScript, então `courses.length` funciona."},
 {"code": "  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in courses\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>Goal: {{ course.goal }} minutes a week</p>\n      </li>\n    </ul>\n  </main>", "note": "O `v-for` repete o elemento uma vez por curso. A aula 5 trata dele, e do `:key`, que diz ao Vue qual item é qual."},
 {"code": "  <AppFooter />\n</template>", "note": "Um componente importado é usado como tag. O nome dele no template é o nome com que você o importou."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "O `scoped` mantém estas regras dentro deste componente. A próxima seção mostra como."}
]}
```

E crie a pasta `src/components` com o rodapé dentro:

```schooling-example
{"language": "html", "file": "src/components/AppFooter.vue", "parts": [
 {"code": "<script setup>\nimport { version } from 'vue'\n</script>\n\n<template>\n  <footer>\n    <p>Built with Vue {{ version }}</p>\n  </footer>\n</template>", "note": "O `version` é exportado pelo próprio Vue: a versão que roda na página."},
 {"code": "<style scoped>\np {\n  color: #666;\n  font-size: 0.875rem;\n}\n</style>", "note": "Uma regra para `p` neste arquivo, e outra diferente no `App.vue`. Cada uma vale só no seu próprio componente."}
]}
```

Salve os dois, e a página no seu navegador muda sem recarregar. No terminal:

```
ana@dev:~/vue/planner$ look http://localhost:5173/
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

3 courses this term

Statistics

Goal: 180 minutes a week

Spanish

Goal: 120 minutes a week

Guitar

Goal: 90 minutes a week

Built with Vue 3.5.44
```

**O rodapé diz 3.5.44**, que é o Vue do `package.json` e do lockfile. Essa é a primeira frase que
este curso não poderia ter escrito por você: é o seu projeto falando de si mesmo.

## O que é um componente, até aqui

O `AppFooter.vue` é um componente, e o `App.vue` também. **Um componente é um pedaço da tela com a
sua própria marcação, o seu próprio estado e os seus próprios estilos**, usado pelo nome dentro de
outro. O planner vai ganhar um componente para cada coisa na tela que tenha uma função própria: um
cartão de curso na aula 6, um painel com slots na aula 7, um formulário na aula 14.

Os nomes seguem uma convenção. **O arquivo de um componente é nomeado em PascalCase, e a tag
também.** `AppFooter` tem duas palavras porque nomes de uma palavra só, como `Footer`, colidem com os
elementos HTML que existem ou que podem existir um dia, e o guia de estilo do Vue pede duas.
