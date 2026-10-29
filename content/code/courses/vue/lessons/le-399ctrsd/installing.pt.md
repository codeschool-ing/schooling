---
title: Um router, instalado
version: 1
---

**Um router liga o endereço na barra do navegador aos componentes na tela, e troca a tela quando o
endereço muda, sem carregar uma página nova.** Até aqui o planner teve uma tela só. A partir desta aula
ele tem três tipos de página: a semana, um curso e uma página para um endereço que não leva a lugar
nenhum. Cada uma tem o próprio endereço, então pode ir para os favoritos, ser compartilhada e ser
alcançada com o botão de voltar do navegador, que é o que faz uma aplicação parecer a web, e não um
programa que por acaso está num navegador.

O router do Vue é o **Vue Router**, do time do Vue. A versão 5 é a atual; a API dela para escrever rotas
à mão, que esta aula usa, é a API da versão 4, e quase tudo o que você lê na internet sobre a versão 4
vale sem mudança. O que a versão 5 acrescentou foi o roteamento por arquivo, em que a estrutura de pastas
de `src/pages` escreve as rotas por você; o Nuxt também faz isso, e a aula 18 encontra a ideia lá.

Pare o servidor de desenvolvimento do planner e instale o router, fixado como todo o resto:

```
ana@dev:~/vue/planner$ npm install --save-exact vue-router@5.4.0

added 44 packages, and audited 81 packages in 6s

23 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O `package.json` ganha `"vue-router": "5.4.0"` em `dependencies`, sem circunflexo, e o lockfile registra
isso. Inicie o servidor de desenvolvimento de novo.

## Dando um router à aplicação

Um router é um plugin: um objeto que a aplicação instala uma vez, com `app.use()`, e que fica disponível
para todo componente. O `main.js` ganha duas linhas:

```javascript
// src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import { router } from './router.js'
import './main.css'

createApp(App).use(router).mount('#app')
```

O `app.use(router)` faz três coisas. Registra os dois componentes que toda aplicação com rotas usa,
`<RouterView>` e `<RouterLink>`; fornece o router a todo componente, pelo `provide` da aula 8, para que
`useRouter()` e `useRoute()` o encontrem; e começa a escutar a barra de endereço, para que a primeira
tela desenhada seja a que o endereço indica.

O router em si é definido em `src/router.js`, o assunto da próxima seção. A ordem só importa de um jeito:
o `createRouter` precisa ter rodado antes do `app.use(router)`, e um import no topo do `main.js` garante
isso.

## O que muda para o aluno

O aluno que abre `http://localhost:5173/` vê o que via antes. O que é novo fica invisível até ele clicar:
os títulos dos cursos viram links, um curso tem a própria página em `/courses/statistics`, o botão de
voltar retorna à semana, e um endereço digitado errado diz isso em vez de mostrar a semana como se nada
estivesse errado. Cada uma dessas coisas é uma seção desta aula.
