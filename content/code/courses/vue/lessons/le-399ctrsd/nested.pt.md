---
title: Rotas aninhadas, uma página dentro de uma página
version: 1
---

**Uma rota pode ter filhas, desenhadas num `<RouterView>` dentro do componente da rota mãe.** A página do
curso mantém o título e a meta, e embaixo deles mostra uma de duas listas: as sessões do curso nesta
semana, ou todas elas. A parte da página que fica é a mãe; a parte que muda é uma filha.

No `router.js` a rota do curso tem `children`, cada uma com um caminho relativo ao da mãe: `''` é o
próprio `/courses/:id`, e `'all'` é `/courses/:id/all`. Na `CourseView`, um segundo
`<RouterView :course="id" />` é onde a filha é desenhada, e ele repassa o curso como prop. As duas filhas:

```html
<!-- src/views/CourseWeek.vue -->
<script setup>
import { computed, inject } from 'vue'
import SessionRow from '../components/SessionRow.vue'
import { plannerKey } from '../keys.js'
import { weekStart, sessionsInWeek } from '../planner.js'

const { course } = defineProps({ course: { type: String, required: true } })
const { sessions, today, toggle } = inject(plannerKey)

const mine = computed(() =>
  sessionsInWeek(
    sessions.value.filter((s) => s.course === course),
    weekStart(new Date()),
  ),
)
</script>

<template>
  <ul v-if="mine.length > 0">
    <SessionRow v-for="s in mine" :key="s.id" :session="s" :today="s.date === today" @toggle="toggle" />
  </ul>
  <p v-else>Nothing planned this week.</p>
</template>
```

```html
<!-- src/views/CourseAll.vue -->
<script setup>
import { computed, inject } from 'vue'
import SessionRow from '../components/SessionRow.vue'
import { plannerKey } from '../keys.js'

const { course } = defineProps({ course: { type: String, required: true } })
const { sessions, today, toggle } = inject(plannerKey)

const mine = computed(() =>
  sessions.value.filter((s) => s.course === course).toSorted((a, b) => a.date.localeCompare(b.date)),
)
</script>

<template>
  <ul>
    <SessionRow v-for="s in mine" :key="s.id" :session="s" :today="s.date === today" @toggle="toggle" />
  </ul>
</template>
```

Direto para a segunda filha, pelo endereço:

```
ana@dev:~/vue/planner$ look http://localhost:5173/courses/spanish/all --clock 2026-10-21T10:00 --text main
[vite] connecting...
[vite] connected.
== the text of main
Spanish

Goal: 120 minutes a week

This week · All sessions
 19 October 2026, Spanish, 30 minutes
 23 October 2026, Spanish, 40 minutes
```

Spanish tem duas sessões, as duas nesta semana, então hoje as duas listas mostram as mesmas duas;
Statistics, com a sessão de 12 de outubro, é o curso em que elas diferem. Os links entre elas são
`<RouterLink :to="{ name: 'course-week', params: { id } }">`, pelo **nome** e não pelo caminho, para que
renomear `all` para `everything` um dia mude a rota e nada mais.

## O link ativo

O `<RouterLink>` põe a classe `router-link-active` num link cuja rota faz parte da atual, e
`router-link-exact-active` quando ela é exatamente a atual. O estilo scoped da `CourseView` deixa o exato
em negrito, o que mostra a um aluno que enxerga em qual lista ele está. Para um leitor de tela, o router
também põe `aria-current="page"` no exato, o que o anuncia como a página atual, sem você escrever nada.

```
ana@dev:~/vue/planner$ look http://localhost:5173/courses/spanish/all --html 'nav[aria-label=Sessions]' --text -
[vite] connecting...
[vite] connected.
== the HTML of nav[aria-label=Sessions]
<nav data-v-62175599="" aria-label="Sessions"><a data-v-62175599="" href="/courses/spanish" class="router-link-active">This week</a> · <a data-v-62175599="" aria-current="page" href="/courses/spanish/all" class="router-link-active router-link-exact-active">All sessions</a></nav>
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O endereço /courses/spanish/all, dividido em partes, e as caixas que cada parte preenche. App desenha o cabeçalho, o rodapé e um RouterView. O caminho /courses/spanish casa com a rota do curso, cujo CourseView preenche o RouterView de App e tem um RouterView próprio. O último segmento, all, casa com a rota filha, cujo CourseAll preenche o RouterView de CourseView.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">/courses/spanish</text><text x=\"156\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">/all</text><rect x=\"20\" y=\"40\" width=\"680\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">App.vue: cabeçalho e rodapé em toda página</text><rect x=\"40\" y=\"68\" width=\"640\" height=\"158\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"50\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;RouterView&gt;  →  CourseView</text><text x=\"50\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spanish · meta: 120 minutos por semana</text><rect x=\"60\" y=\"120\" width=\"600\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"70\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;RouterView&gt;  →  CourseAll</text><text x=\"70\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 October 2026, Spanish, 30 minutes</text><text x=\"70\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">23 October 2026, Spanish, 40 minutes</text></svg>", "caption": "Cada RouterView desenha um nível da rota encontrada: o nível do pai dentro de App, o do filho dentro do pai.", "same": ["19 October 2026, Spanish, 30 minutes", "23 October 2026, Spanish, 40 minutes"]}
```

## Quando aninhar

Aninhe quando parte da tela fica e parte muda com o endereço: as abas de uma página, os passos de um
formulário, uma lista com o item selecionado ao lado. Não aninhe só porque os caminhos parecem
aninhados: uma rota em `/courses/spanish/all` pode ser uma rota de primeiro nível com a própria página
inteira, se nada da página do curso precisar ficar em volta dela.
