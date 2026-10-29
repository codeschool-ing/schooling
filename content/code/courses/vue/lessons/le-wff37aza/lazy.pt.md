---
title: Lazy, e o que mostrar enquanto espera
version: 1
---

**Por padrão, uma navegação espera o `useFetch` da próxima página: o router não mostra a página até os
dados dela chegarem.** No próprio servidor do planner essa espera é de alguns milissegundos e ninguém
a vê. Numa API lenta, é um clique que parece não fazer nada. Para ver isso, deixe a rota do curso
lenta, dois segundos antes de responder:

```
ana@dev:~/vue/planner-nuxt$ sed -i 's#defineEventHandler((event) => {#defineEventHandler(async (event) => {\n  await new Promise((resolve) => setTimeout(resolve, 2000))#' 'server/api/courses/[id].get.ts'
```

Clique num curso e leia o título um instante depois:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --do 'click text=Spanish' --text 'main h1'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
-- click text=Spanish
== the text of main h1
This week
```

**Ainda *This week***: o clique aconteceu, e a página antiga fica pelos dois segundos que a nova
espera. O `lazy: true` muda isso. A navegação segue na hora, e os dados vêm depois:

```
ana@dev:~/vue/planner-nuxt$ sed -i 's#useFetch(() => `/api/courses/${route.params.id}`)#useFetch(() => `/api/courses/${route.params.id}`, { lazy: true })#' 'app/pages/courses/[id].vue'
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --do 'click text=Spanish' --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
-- click text=Spanish
== the text of main
Goal: minutes a week
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --do 'click text=Spanish' --do 'wait 2500' --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
-- click text=Spanish
-- wait 2500
== the text of main
Spanish

Goal: 120 minutes a week

 19 October 2026, Spanish, 30 minutes
 23 October 2026, Spanish, 40 minutes
```

**A página do curso na hora, sem nada nela**, e dois segundos depois o curso. Nenhum dos dois jeitos
é bom sozinho: esperar parece um clique que não fez nada, e o lazy parece vazio enquanto a requisição
dura, com
`Goal: minutes a week` dizendo isso. Lazy é só metade de uma decisão; a outra metade é um template que
usa `status`:

```html
<p v-if="status === 'pending'">Loading the course…</p>
```

`useLazyFetch(url)` é o mesmo que `useFetch(url, { lazy: true })`. Mais uma opção costuma vir junto,
`server: false`, que pula a busca durante a renderização do servidor: a página chega sem os dados e o
navegador os busca, que é o client-only da aula 19, aplicado a um dado.

## A escolha do planner

O planner fica como está, sem lazy: o servidor dele responde em milissegundos, então esperar não custa
nada, e uma página que chega completa não tem estado de carregamento para desenhar. Ponha os dois
arquivos de volta:

```
ana@dev:~/vue/planner-nuxt$ sed -i 's#, { lazy: true })#)#' 'app/pages/courses/[id].vue'
ana@dev:~/vue/planner-nuxt$ sed -i '/setTimeout(resolve, 2000)/d; s#async (event)#(event)#' 'server/api/courses/[id].get.ts'
```

Quando os dados vêm de um lugar lento, uma API de terceiros, um relatório que leva segundos para ser
calculado, lazy com um estado de carregamento de verdade é a troca melhor, e às vezes também é não
buscá-los durante a renderização do servidor. As perguntas são as mesmas da renderização na aula 19: o
que a página precisa mostrar no momento em que aparece, e o que pode vir depois.
