---
title: defineStore, do jeito setup
version: 1
---

**O `defineStore(id, setup)` define uma store com uma função escrita exatamente como um `<script setup>`:
as refs são o estado, os valores computados são os getters, as funções são as actions, e o que ela
retorna é a store.** Essa forma se chama *setup store*, e é a que este curso usa, porque é a Composition
API que você já conhece, sem nada novo para aprender.

A store do planner, que a última seção desta aula põe no lugar:

```schooling-example
{"language": "javascript", "file": "src/stores/planner.js", "parts": [
 {"code": "// src/stores/planner.js: the planner's data, in one place for every page.\nimport { ref, computed, watch } from 'vue'\nimport { defineStore } from 'pinia'\nimport { toggleDone } from '../planner.js'\n\nconst STORAGE_KEY = 'planner.sessions'", "note": "Uma store mora em `src/stores`, um arquivo para cada uma, com o nome do que ela guarda. O `planner.js` que ela importa é o arquivo de regras da aula 3."},
 {"code": "export const usePlannerStore = defineStore('planner', () => {", "note": "`'planner'` é o id da store: único na aplicação, e o nome que as ferramentas de desenvolvimento mostram. `usePlannerStore` segue a convenção de nomes dos composables da aula 10."},
 {"code": "  // State\n  const courses = ref([])\n  const sessions = ref([])\n  const error = ref('')\n  const source = ref('')", "note": "Estado: quatro refs, as mesmas quatro que o `usePlannerData` tinha."},
 {"code": "  // Getters\n  const titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))\n  const hasCourse = computed(() => (id) => courses.value.some((c) => c.id === id))", "note": "Getters: valores computados. `hasCourse` retorna uma função, que é como um getter recebe um argumento."},
 {"code": "  // Actions\n  let loading = null\n  function load() {\n    // One request, however many pages and guards ask for the data.\n    loading ??= fetch('/courses.json')\n      .then((response) => {\n        if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n        return response.json()\n      })\n      .then((data) => {\n        courses.value = data.courses\n        const saved = localStorage.getItem(STORAGE_KEY)\n        sessions.value = saved ? JSON.parse(saved) : data.sessions\n        source.value = saved ? 'this browser' : 'courses.json'\n      })\n      .catch((e) => {\n        error.value = `Could not load the courses: ${e.message}`\n      })\n    return loading\n  }", "note": "Uma action que carrega os dados uma vez. O `??=` só atribui se `loading` ainda for `null`, então todos que chamam depois recebem a mesma promise, e só uma requisição é enviada."},
 {"code": "  function toggle(id) {\n    sessions.value = toggleDone(sessions.value, id)\n  }", "note": "Uma action que altera o estado, pela regra da aula 3."},
 {"code": "  // The store keeps its own copy in this browser, whoever changes the sessions.\n  watch(sessions, (list) => {\n    localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n  })", "note": "Um watcher dentro da store salva as sessões, seja quem for que as alterou."},
 {"code": "  return { courses, sessions, error, source, titles, hasCourse, load, toggle }\n})", "note": "Só o que é retornado faz parte da store. Uma ref deixada de fora seria privada, e as ferramentas do Pinia não a veriam."}
]}
```

## Três palavras, mapeadas

| Pinia | numa setup store | lido de um componente como |
|---|---|---|
| state | `ref()` | `planner.sessions`, desembrulhado |
| getter | `computed()` | `planner.titles` |
| action | uma função | `planner.toggle('s4')` |

**Uma store é um objeto `reactive`**: as suas refs são desembrulhadas quando lidas por ela, então um
componente escreve `planner.sessions`, nunca `planner.sessions.value`, e o template lê
`planner.courses.length`. A regra da aula 2 sobre desestruturar um objeto `reactive` também vale, e a
quarta seção desta aula trata disso.

## Regras que uma setup store segue

- **Retorne todo o estado.** O Pinia só consegue salvar, inspecionar e reiniciar o que ele enxerga. Uma ref
  mantida privada funciona, e fica invisível para as ferramentas de desenvolvimento e para a renderização
  no servidor.
- **Watchers e valores computados funcionam como num componente.** Os hooks do ciclo de vida não cabem nela:
  uma store sobrevive a todo componente, mas um `onMounted` dentro dela se prende ao componente que por
  acaso criou a store, e para junto com ele; e se a store é criada pela primeira vez onde nenhum
  componente está sendo montado, num guard por exemplo, o hook não se prende a nada e o Vue avisa, como a
  aula 10 mostrou.
- **Chame `usePlannerStore()` dentro do setup, ou depois de o Pinia estar instalado.** A store precisa
  achar o contêiner da aplicação, e antes de `app.use(createPinia())` não existe nenhum.
