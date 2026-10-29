---
title: Lazy loading, um arquivo por página
version: 1
---

**Uma rota cujo componente é escrito como `() => import('./views/CourseView.vue')` é carregada sob
demanda: o código dela não faz parte do primeiro arquivo que o navegador baixa, e é buscado na primeira
vez que alguém abre aquela página.** A semana é o que todo mundo vê primeiro, então é importada do jeito
normal; a página de um curso é carregada quando um curso é aberto.

O servidor de desenvolvimento mostra isso. Este é o clique da seção de parâmetros de novo, com a lista
de rede, e `CourseView.vue` e `CourseWeek.vue` chegam *depois* do clique, não com o resto da página:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --text - --network
net  GET /  200
net  GET /src/main.js  200
net  GET /@vite/client  200
net  GET /src/router.js  200
net  GET /node_modules/.vite/deps/vue.js?v=f3072b2a  200
net  GET /src/App.vue  200
net  GET /src/main.css  200
net  GET /node_modules/vite/dist/client/env.mjs  200
[vite] connecting...
net  GET /src/keys.js  200
net  GET /src/views/NotFound.vue  200
net  GET /src/views/HomeView.vue  200
[vite] connected.
net  GET /src/planner.js  200
net  GET /src/composables/usePlannerData.js  200
net  GET /src/composables/useToday.js  200
net  GET /src/components/AppFooter.vue  200
net  GET /node_modules/.vite/deps/vue-router.js?v=00952696  200
net  GET /src/App.vue?vue&type=style&index=0&scoped=7a7a37b1&lang.css  200
net  GET /@id/__x00__plugin-vue:export-helper  200
net  GET /src/components/CourseCard.vue  200
net  GET /src/components/SessionRow.vue  200
net  GET /src/components/PlannerPanel.vue  200
net  GET /node_modules/.vite/deps/vue.runtime.esm-bundler-CWNVreLk.js?v=6664c211  200
net  GET /src/components/SessionRow.vue?vue&type=style&index=0&scoped=b7ae2f26&lang.css  200
net  GET /src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css  200
net  GET /src/components/CourseCard.vue?vue&type=style&index=0&scoped=a191423e&lang.css  200
net  GET /src/components/PlannerPanel.vue?vue&type=style&index=0&scoped=0710be83&lang.css  200
net  GET /courses.json  200
-- click text=Spanish >> nth=0
net  GET /courses.json  200
net  GET /src/views/CourseView.vue  200
net  GET /src/views/CourseWeek.vue  200
net  GET /src/views/CourseView.vue?vue&type=style&index=0&scoped=62175599&lang.css  200
```

(A lista é longa porque, em desenvolvimento, o Vite serve cada módulo como um arquivo próprio; as linhas
a procurar são as últimas, depois de `-- click`.)

## No build

A diferença importa em produção, em que o Vite junta a aplicação em poucos arquivos. Faça o build:

```
ana@dev:~/vue/planner$ npm run build

> planner@0.0.0 build
> vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 43 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                       0.43 kB │ gzip:  0.29 kB
dist/assets/CourseView-DCK-DYkd.css   0.06 kB │ gzip:  0.08 kB
dist/assets/index-CiPQPnxa.css        0.78 kB │ gzip:  0.43 kB
dist/assets/CourseAll-DFaCYQ3J.js     0.50 kB │ gzip:  0.35 kB
dist/assets/CourseWeek-Cbc2IZvv.js    0.57 kB │ gzip:  0.39 kB
dist/assets/CourseView-CT3GQE2y.js    0.82 kB │ gzip:  0.51 kB
dist/assets/index-DZAU1O19.js        95.24 kB │ gzip: 37.07 kB

✓ built in 377ms
```

**Cada view importada sob demanda virou um arquivo próprio**, `CourseView-….js`, `CourseWeek-….js` e
`CourseAll-….js`, ao lado do `index-….js` principal. Um aluno que nunca abre um curso nunca os baixa. Os
caracteres depois do hífen são um hash do conteúdo de cada arquivo, então um arquivo que não mudou mantém
o nome entre um build e outro e fica no cache do navegador; a aula 17 é sobre o build, e explica o resto
desta saída.

## O que deixar sob demanda

Carregar sob demanda custa uma requisição no momento em que a página é aberta, então é uma troca:

- **Carregue sob demanda** as páginas que nem todo mundo visita, e as pesadas: uma página de
  configurações, uma área de administração, uma página com uma biblioteca de gráficos.
- **Carregue de imediato** a página em que todo mundo chega, e qualquer coisa pequena. Uma página de 2 kB
  sob demanda custa uma requisição que demora mais do que os 2 kB teriam demorado.

As views do planner são todas pequenas, e dividi-las serve para mostrar o mecanismo. A página de não
encontrado é importada de imediato de propósito: ela é o que aparece quando algo já deu errado, e esse
não é o momento de depender de mais uma requisição dar certo.
