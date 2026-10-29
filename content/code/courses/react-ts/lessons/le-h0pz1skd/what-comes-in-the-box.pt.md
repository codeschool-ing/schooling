---
title: O que vem na caixa
version: 1
---

**A aula 1 disse que a diferença entre o React e o Angular não é tamanho, e sim quem decide.** O tamanho
ainda é um número que vale olhar, e os quatro builds podem medi-lo em pé de igualdade. O Vite e o Angular
imprimem cada um uma estimativa própria, então um comando comprime todo arquivo JavaScript que cada build
escreveu, do mesmo jeito para os quatro:

```
ana@dev:~$ for d in sessions-react/dist sessions-vue/dist sessions-svelte/dist sessions-angular/dist/sessions-angular/browser; do printf "%-45s %6s bytes\n" "$d" "$(cat $d/assets/*.js $d/*.js 2>/dev/null | gzip -9 | wc -c)"; done
sessions-react/dist                            67948 bytes
sessions-vue/dist                              24687 bytes
sessions-svelte/dist                           13095 bytes
sessions-angular/dist/sessions-angular/browser  60798 bytes
```

```schooling-figure
{"svg": "<svg data-fig=\"sizes\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O JavaScript que cada build de produção escreveu, comprimido com gzip -9: Svelte 13.095 bytes, Vue 24.687, Angular 60.798 e React 67.948, para o mesmo componente.\"><text x=\"96\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Svelte</text><rect x=\"108\" y=\"30\" width=\"91\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"209\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">13.095 bytes</text><text x=\"96\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Vue</text><rect x=\"108\" y=\"76\" width=\"171\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"289\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">24.687 bytes</text><text x=\"96\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Angular</text><rect x=\"108\" y=\"122\" width=\"421\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"539\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">60.798 bytes</text><text x=\"96\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">React</text><rect x=\"108\" y=\"168\" width=\"470\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"588\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">67.948 bytes</text></svg>", "caption": "Para um componente pequeno, o tamanho é o do framework, não o do seu código.", "same": ["Svelte", "Vue", "Angular", "React"]}
```

Para um componente, quase tudo isso é o próprio framework, que todo app paga uma vez, seja qual for o
tamanho que ele alcance. **O Svelte é o menor porque a maior parte dele rodou no build**, e o código que
sobrou é o que este componente usa. O Vue carrega um runtime que compara templates. O React carrega o
`react-dom`, que compara e desenha o que os componentes devolvem. O número do Angular inclui o roteador,
que o `app.config.ts` gerado ainda configura, embora nenhuma página o use. Numa aplicação de verdade essas
diferenças diminuem, porque o seu código cresce e o framework não.

**O que vem com cada um é a diferença maior**, e é aquela com que a aula 1 começou:

- O **Angular** é uma caixa de um time só. O roteador, os formulários, o cliente HTTP, o jeito de entregar
  serviços aos componentes que precisam deles, o build e o comando de testes vêm todos em pacotes
  `@angular/…` lançados juntos, e a documentação ensina um jeito de fazer cada coisa.
- O **Vue** é um núcleo menor com companheiros oficiais: o Vue Router para os endereços, o Pinia para o
  estado compartilhado, e o Nuxt como o framework completo em volta deles, todos mantidos pelas pessoas por
  trás do Vue.
- O **Svelte** tem o SvelteKit, do próprio time: rotas, carregamento de dados e renderização no servidor.
- O **React** tem o React, e este curso acrescentou o resto peça por peça: o React Router na aula 17, o
  React Query na aula 11, o React Hook Form e o Zod na aula 10, o Zustand na aula 9, e o Next.js na aula
  18 como o framework que fecha a maior parte dessas perguntas de uma vez. Cada um veio de um time
  diferente.

**Então, qual?** A pergunta que este curso foi escrito para deixar você responder não é qual é o melhor, e
sim o que cada um pede de você. O React pede que você escolha suas peças e entenda um modelo em que tudo
roda de novo. Em troca, as escolhas são suas, as peças são trocáveis, e é a opção com mais código escrito
para ela e mais bibliotecas. O Angular pede que você aprenda mais no começo e aceite o jeito dele; em
troca, dois projetos Angular se parecem, o que times grandes valorizam. O Vue e o Svelte ficam no meio, com
signals e templates, um núcleo menor que o do Angular e respostas oficiais para as perguntas comuns.

Tendo escrito o mesmo componente nos quatro, você tem a parte que vale para todos: estado, valores
derivados dele, uma lista com chaves, um evento que muda o estado, um build e uma conferência dos tipos.
Cada um dos quatro escreve isso de um jeito, e todos têm isso.
