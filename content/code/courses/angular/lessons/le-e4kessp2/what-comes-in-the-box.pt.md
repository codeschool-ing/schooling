---
title: O que vem na caixa, e quanto pesa
version: 1
---

**O Angular é um framework no sentido completo: o roteador, os formulários, o HTTP, os testes, a
renderização no servidor e a ferramenta de linha de comando que os amarra são dele, lançados juntos,
numa versão só.** O planner usou todos eles, e cada um veio de `@angular/` e andou junto com o
`ng update`. O React é uma biblioteca para a camada de visão, e o resto se escolhe: um roteador, uma
biblioteca de busca de dados, uma de formulários, um framework como o Next.js para renderizar no
servidor. O Vue e o Svelte ficam no meio: cada um tem um roteador oficial e um framework completo
oficial, o Nuxt e o SvelteKit, mas são projetos separados.

| | Angular | React | Vue | Svelte |
| --- | --- | --- | --- | --- |
| rotas | `@angular/router` | escolhido: React Router, ou Next.js | Vue Router, oficial | SvelteKit, oficial |
| formulários | `@angular/forms`, de dois tipos | escolhido, ou à mão | `v-model`, e uma biblioteca para validar | `bind:`, e as form actions do SvelteKit |
| HTTP | `HttpClient`, interceptors, `httpResource` | `fetch`, ou uma biblioteca como o React Query | `fetch`, ou o `useFetch` do Nuxt | `fetch`, no `load` do SvelteKit |
| renderização no servidor | `@angular/ssr`, aula 23 | Next.js | Nuxt | SvelteKit |
| injeção de dependência | embutida, aula 10 | nenhuma; context para passar valores para baixo | `provide` e `inject` | context |
| ferramenta do projeto | o Angular CLI | o Vite, ou a do framework | o Vite, ou a do Nuxt | o Vite, ou a do SvelteKit |

**A caixa tem um custo, e parte dele está na página.** Faça o build de produção dos quatro cartões:

```
ana@dev:~/compare$ for p in react vue svelte; do (cd $p && npm run build > /dev/null); done; (cd angular && npx ng build > /dev/null)
```

e pese o JavaScript de cada um, como está e comprimido do jeito que um servidor o manda:

```
ana@dev:~/compare$ for f in react/dist/assets/*.js vue/dist/assets/*.js svelte/dist/assets/*.js angular/dist/angular/browser/main-*.js; do printf "%-48s %7d bytes, %6d gzipped\n" $f $(wc -c < $f) $(gzip -9c $f | wc -c); done
react/dist/assets/index-DwWj_paF.js               220160 bytes,  67959 gzipped
vue/dist/assets/index-DNFEJ_tG.js                  64641 bytes,  25078 gzipped
svelte/dist/assets/index-DUPjO2ko.js               33776 bytes,  13278 gzipped
angular/dist/angular/browser/main-XUCHBYB5.js     106457 bytes,  35520 gzipped
```

O mesmo cartão, o mesmo comportamento, e, comprimido, um fator de cinco entre o mais leve e o mais
pesado. **A maior parte de cada número é o framework, não o cartão**: os 68 kB comprimidos do React
são o React e o React DOM, seja o que for que a página tenha, e o cartão acrescenta umas centenas de
bytes. O Svelte é o mais leve porque compilou a maior parte do trabalho dentro do próprio cartão, e
guarda só um runtime pequeno; essa vantagem diminui conforme a aplicação cresce, já que cada
componente leva o próprio código de atualização compilado. O do Angular fica no meio. O planner, com o
roteador, os formulários, o Material e todo o resto deste curso, pesava 344 kB antes da compressão na
aula 23, com as páginas do curso carregadas à parte.

Então o número é um custo fixo pago uma vez por visita, e para uma aplicação que uma pessoa abre para
trabalhar o dia inteiro, raramente é o que decide. Para uma página que alguém acha por uma busca num
celular lento, uma vez, pode ser.

## Onde os outros três são ensinados

Os outros cursos de framework desta trilha terminam com esta mesma aula, do lado deles, com o mesmo
cartão:

- **`react-ts`**, 24 aulas. A aula 1 dele é *por que o React é uma biblioteca onde o Angular é um
  framework, e o que você monta sozinho*, a tabela acima vista da outra ponta; a aula 18 é o Next.js.
- **`vue`**, 22 aulas. A aula 2 dele compara a reatividade com a do React, a aula 17 é o Vite, e as
  aulas 18 a 20 são o Nuxt.
- **`svelte`**, 20 aulas. A aula 1 dele é o compilador como framework, e a aula 14, form actions que
  funcionam com o JavaScript desligado, é uma ideia que nenhum dos outros três ensina.

E o `front-performance`, depois deste ponto da trilha, leva a renderização no servidor pelos quatro
na aula 2 dele: o Angular SSR ao lado do Next.js, do Nuxt e do SvelteKit.
