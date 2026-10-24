---
title: As mesmas ideias, com quatro jogos de nomes
version: 1
---

**React, Vue, Angular e Svelte resolvem o mesmo problema**: manter uma página em dia com os dados por
trás dela, em pedaços pequenos o bastante para se pensar sobre eles. Por isso quase tudo o que este curso
ensinou tem um equivalente em cada um dos outros três, com outro nome e com regras próprias. Conhecer essa
correspondência é a maior parte do que é preciso para ler código escrito neles, e é a primeira coisa a
aprender quando se passa de um para outro.

| Svelte, neste curso | React | Vue | Angular |
|---|---|---|---|
| um componente, `.svelte` (aula 5) | uma função que devolve JSX | um componente de arquivo único, `.vue` | uma classe com `@Component` |
| `$state` (aula 3) | `useState` | `ref`, `reactive` | `signal()` |
| `$derived` (aula 3) | calculado durante o render, ou `useMemo` | `computed` | `computed()` |
| `$effect` (aula 3) | `useEffect` | `watch`, `watchEffect` | `effect()` |
| `$props` (aula 5) | o argumento da função | `defineProps` | `input()` |
| `bind:value` (aula 5) | um input controlado: um valor e um `onChange` | `v-model` | `[(ngModel)]`, `model()` |
| snippets e `{@render}` (aula 6) | `children` e render props | slots | projeção de conteúdo, `<ng-content>` |
| `{#each … (key)}` (aula 8) | `.map()` com uma `key` | `v-for` com `:key` | `@for` com `track` |
| contexto (aula 11) | contexto, `useContext` | `provide`, `inject` | injeção de dependências |
| SvelteKit (aulas 12 a 17) | Next.js | Nuxt | o router e o SSR do Angular |

Cada um dos outros três tem um curso neste catálogo, construído em torno do mesmo planner de estudos,
então a mesma funcionalidade pode ser lida de quatro jeitos. O curso de React trata do modelo de
renderização na aula 3 e do `useState` na aula 4; o de Vue trata do seu sistema de reatividade na aula 2;
o de Angular trata de signals na aula 6 e da detecção de mudanças na aula 7. Cada um deles termina, como
este, com um olhar sobre os outros a partir de onde está.

**Uma tabela como essa esconde as diferenças que importam**, que são sobre quando o código roda e o que o
framework sabe. O resto desta aula é sobre elas: o que cada um manda para o navegador, como cada um
descobre o que atualizar, e o que o framework de aplicação de cada um faz com um formulário.
