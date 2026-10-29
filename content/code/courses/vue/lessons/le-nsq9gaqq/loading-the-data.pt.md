---
title: O planner carrega os seus dados
version: 1
---

**O planner deixa de carregar os cursos dentro do componente e passa a lê-los, para dentro de refs, de
um arquivo que o servidor de desenvolvimento serve.** Três cursos e seis sessões de estudo, todas em
outubro de 2026, num único arquivo JSON. Estes são os dados que todas as aulas seguintes usam, e os
planners dos outros três cursos de framework da trilha leem a mesma forma.

## O arquivo

Tudo o que está na pasta `public` do projeto é servido como está, na raiz do endereço. Salve isto como
`public/courses.json` no planner:

```schooling-example
{"language": "json", "file": "public/courses.json", "parts": [
 {"code": "{\n  \"courses\": [\n    { \"id\": \"statistics\", \"title\": \"Statistics\", \"goal\": 180 },\n    { \"id\": \"spanish\", \"title\": \"Spanish\", \"goal\": 120 },\n    { \"id\": \"guitar\", \"title\": \"Guitar\", \"goal\": 90 }\n  ],", "note": "Cada curso tem um id, que é para onde uma sessão aponta, um título para as pessoas e uma meta semanal em minutos."},
 {"code": "  \"sessions\": [\n    { \"id\": \"s1\", \"course\": \"statistics\", \"date\": \"2026-10-12\", \"minutes\": 50, \"done\": true },\n    { \"id\": \"s2\", \"course\": \"statistics\", \"date\": \"2026-10-19\", \"minutes\": 45, \"done\": true },\n    { \"id\": \"s3\", \"course\": \"spanish\", \"date\": \"2026-10-19\", \"minutes\": 30, \"done\": true },\n    { \"id\": \"s4\", \"course\": \"statistics\", \"date\": \"2026-10-21\", \"minutes\": 60, \"done\": false },\n    { \"id\": \"s5\", \"course\": \"guitar\", \"date\": \"2026-10-22\", \"minutes\": 20, \"done\": false },\n    { \"id\": \"s6\", \"course\": \"spanish\", \"date\": \"2026-10-23\", \"minutes\": 40, \"done\": false }\n  ]\n}", "note": "Seis sessões: uma na semana de 12 de outubro e cinco na semana de 19 de outubro, três delas feitas. As datas são escritas AAAA-MM-DD, que ordenadas como texto ficam em ordem de data."}
]}
```

## O componente

O `App.vue` agora começa com dois refs vazios e os preenche quando o arquivo chega:

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')", "note": "Dois refs, vazios no começo, e um terceiro para uma mensagem de erro. O template desenha o que eles guardam, então primeiro desenha uma lista vazia."},
 {"code": "fetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    sessions.value = data.sessions\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n</script>", "note": "A requisição começa durante o setup, que roda uma vez. Quando os dados chegam, atribuir `.value` redesenha tudo o que leu os refs. A aula 16 de `javascript` trata do `fetch` e de por que a verificação do status vem primeiro."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>{{ courses.length }} courses, {{ sessions.length }} sessions planned</p>\n  </header>\n  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in courses\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>Goal: {{ course.goal }} minutes a week</p>\n      </li>\n    </ul>\n  </main>\n  <AppFooter />\n</template>", "note": "`v-if`, `v-else-if` e `v-else` escolhem um de três parágrafos. A aula 5 é sobre eles; aqui eles dizem carregando, falhou ou carregado."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "O estilo não mudou desde a aula 1."}
]}
```

Com o servidor de desenvolvimento do planner rodando (pare o da sandbox antes, ou ele terá ocupado a
porta 5173):

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --network
net  GET /  200
net  GET /src/main.js  200
net  GET /src/App.vue  200
net  GET /node_modules/.vite/deps/vue.js?v=74705bde  200
net  GET /src/App.vue?vue&type=style&index=0&scoped=7a7a37b1&lang.css  200
net  GET /@id/__x00__plugin-vue:export-helper  200
net  GET /src/components/AppFooter.vue  200
net  GET /@vite/client  200
net  GET /src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css  200
net  GET /node_modules/vite/dist/client/env.mjs  200
[vite] connecting...
net  GET /courses.json  200
[vite] connected.
== the text of #app
Study planner

3 courses, 6 sessions planned

Statistics

Goal: 180 minutes a week

Spanish

Goal: 120 minutes a week

Guitar

Goal: 90 minutes a week

Built with Vue 3.5.44
```

A requisição de `/courses.json` é a última, depois de todos os módulos da página: o componente
tinha de existir antes que o setup dele pudesse pedir qualquer coisa. **Nesse intervalo, a página dizia
"Loading…"**, e é por isso que o cabeçalho tem três estados e não um.

## A falha que responde 200

Tire o arquivo do lugar e carregue a página de novo:

```
ana@dev:~/vue/planner$ mv public/courses.json /tmp/courses.json
ana@dev:~/vue/planner$ look http://localhost:5173/
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

Could not load the courses: Unexpected token '<', "<!DOCTYPE "... is not valid JSON

Built with Vue 3.5.44
ana@dev:~/vue/planner$ curl -si http://localhost:5173/courses.json | head -n 3
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
ana@dev:~/vue/planner$ mv /tmp/courses.json public/
```

O erro não é "não encontrado". **O servidor de desenvolvimento respondeu 200 com o HTML da página**,
porque uma aplicação com as próprias rotas (aula 12) quer que todo endereço desconhecido carregue a
aplicação, e o Vite faz isso para qualquer coisa que ele não tem. Então `response.ok` era verdadeiro, e
`response.json()` falhou no primeiro caractere, `<`. A mensagem diz isso, `"<!DOCTYPE "... is not
valid JSON`, e vale a pena reconhecer essa frase: **ela quer dizer que a requisição chegou a uma página
em vez de aos dados**, quase sempre porque o endereço está errado.

Ponha o arquivo de volta com `mv /tmp/courses.json public/`, e a página mostra os cursos de novo.

## O que mudou e o que não mudou

O template é o mesmo template, e a lista é desenhada pelo mesmo `v-for`. O que mudou é que `courses` é
um ref, então o template leu `courses.value` sem dizer, e foi desenhado de novo quando o valor foi
trocado. O cabeçalho conta as sessões além dos cursos, e o planner ainda não faz nada com elas. A aula
3 soma a semana a partir delas.
