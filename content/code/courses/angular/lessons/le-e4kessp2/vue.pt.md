---
title: Vue
version: 1
---

**O Vue é um framework de interfaces cujos componentes guardam script, template e estilos num
arquivo só, e cuja reatividade rastreia leituras como os signals do Angular.** O Vite foi escrito pelo
autor do Vue, e um projeto Vue sai do gerador dele, na mesma versão que o do React:

```
ana@dev:~/compare$ npm create vite@9.3.1 -- vue --template vue-ts --no-immediate

> npx
> cva vue --template vue-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/compare/vue...
│
└  Done. Now run:

  cd vue
  npm install
  npm run dev
```

```
ana@dev:~/compare/vue$ npm install

added 53 packages, and audited 54 packages in 4s

found 0 vulnerabilities
```

```
ana@dev:~/compare/vue$ npm install --save-exact vue@3.5.44 @vitejs/plugin-vue@6.0.10 @vue/tsconfig@0.9.1 @types/node@22.20.5 typescript@6.0.3 vite@8.3.5 vue-tsc@3.3.14

added 2 packages, changed 2 packages, and audited 56 packages in 2s

found 0 vulnerabilities
```

```
ana@dev:~/compare/vue$ rm -r src/App.vue src/components src/style.css
```

O cartão:

```schooling-example
{"language": "html", "file": "src/WeekCard.vue", "parts": [
 {"code": "<!-- src/WeekCard.vue: one course's week, the Vue way -->\n<script setup lang=\"ts\">\nimport { computed, ref } from 'vue';\n", "note": "Um componente de arquivo único: script, template e, quando há, estilos, num arquivo `.vue`."},
 {"code": "console.log('Vue: setup runs');\nconst sessions = ref([\n  { id: 3, date: 'Tue 20 Oct', minutes: 60, done: true },\n  { id: 5, date: 'Sat 24 Oct', minutes: 50, done: false },\n]);\nconst planned = computed(() => sessions.value.reduce((sum, s) => sum + s.minutes, 0));\nconst done = computed(() => sessions.value.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));\n</script>\n", "note": "O `<script setup>` roda uma vez, quando o componente é criado. O `ref` é o signal do Vue, lido e escrito por `.value`; `computed` é a mesma palavra para a mesma ideia do Angular."},
 {"code": "<template>\n  <section>\n    <h2>JavaScript</h2>\n    <ul>\n      <li v-for=\"s in sessions\" :key=\"s.id\">\n        <label><input v-model=\"s.done\" type=\"checkbox\" /> {{ s.date }}, {{ s.minutes }} minutes</label>\n      </li>\n    </ul>\n    <p>{{ done }} of {{ planned }} minutes done</p>\n  </section>\n</template>", "note": "O template lê refs sem `.value`. O `v-for` é o laço, o `:key` o `track` dele, e o `v-model` liga a caixa nos dois sentidos: marcá-la escreve `s.done` direto, o que o Vue vê porque a lista é reativa até o fundo."}
]}
```

```typescript
// src/main.ts: the card, and nothing else, in the page's #app
import { createApp } from 'vue';
import WeekCard from './WeekCard.vue';

createApp(WeekCard).mount('#app');
```

```
ana@dev:~/compare/vue$ look http://localhost:5173/ --do 'check Sat 24 Oct, 50 minutes' --text body
[vite] connecting...
Vue: setup runs
[vite] connected.
-- check Sat 24 Oct, 50 minutes
JavaScript
 Tue 20 Oct, 60 minutes
 Sat 24 Oct, 50 minutes

110 of 110 minutes done
```

**Uma vez**, como no Angular. O setup do Vue rodou quando o cartão foi criado, e a marcação mudou um
campo de uma sessão; os dois `computed` leem essa lista, então ficaram desatualizados, e só as partes
do template que os leem foram desenhadas de novo. Pare o dev server.
