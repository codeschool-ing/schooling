---
title: De onde o Vite veio
version: 1
---

**Toda página do planner chegou ao navegador pelo Vite, do `npm run dev` da aula 1 ao build da aula
16, e esta aula olha para ele diretamente.** Evan You, que escreveu o Vue, escreveu o Vite em 2020, e
o nome é a palavra francesa para *rápido*. O planner usou o Vite 8 o tempo todo:

```
ana@dev:~/vue/planner$ npx vite --version
vite/8.3.5 linux-x64 node-v22.22.0
```

## O problema para o qual ele foi escrito

Antes do Vite, um projeto Vue era criado pelo Vue CLI, que rodava o webpack. O webpack é um
**bundler**: ele lê cada arquivo que a aplicação importa, segue cada import até o próximo arquivo e
junta tudo em um ou poucos arquivos grandes que o navegador consegue carregar. Isso era necessário,
porque durante a maior parte dos anos 2010 os navegadores não conseguiam carregar módulos sozinhos, e
tinha um custo que crescia com o projeto. O servidor de desenvolvimento empacotava a aplicação inteira
antes de servir a primeira página, e empacotava de novo depois de cada arquivo salvo. Num projeto
grande, iniciar levava um minuto e uma mudança levava segundos para aparecer.

Em 2020, todo navegador em uso já carregava módulos ES nativamente, `<script type="module">` e
`import` incluídos. A ideia do Vite foi **parar de empacotar durante o desenvolvimento**: servir cada
arquivo como um módulo próprio, quando o navegador pede, convertido só o bastante para o navegador
rodá-lo. Iniciar o servidor deixa de depender do tamanho da aplicação, porque nada é feito até uma
página pedir um arquivo, e uma mudança converte de novo um arquivo, e não o bundle. Para o build, em
que o navegador deve buscar poucos arquivos em vez de dezenas, o Vite continua empacotando. O Vue CLI
está em manutenção agora, e o `create-vue`, a ferramenta da aula 1, cria projetos Vite.

## Agora usado por todo mundo

O título da aula é a parte que dá para medir. O `create-vite` é o gerador de projetos do próprio Vite,
e a sua lista de templates é uma lista dos frameworks que fazem build com ele:

```
ana@dev:~/vue$ npm create vite@9.3.1 -- --help

> npx
> cva --help

Usage: create-vite [OPTION]... [DIRECTORY]

Create a new Vite project in JavaScript or TypeScript.
When running in TTY, the CLI will start in interactive mode.

Options:
  -t, --template NAME                   use a specific template
  -i, --immediate / --no-immediate      install dependencies and start dev
  --eslint / --no-eslint                use ESLint instead of Oxlint (only for React templates)
  --overwrite                           remove existing files if target directory is not empty
  --interactive / --no-interactive      force interactive / non-interactive mode
  -h, --help                            display this help message

Available templates:
vanilla-ts          vanilla
vue-ts              vue
react-ts            react
react-compiler-ts   react-compiler
preact-ts           preact
lit-ts              lit
svelte-ts           svelte
solid-ts            solid
qwik-ts             qwik
```

O Vue é uma linha de nove. React, Preact, Lit, Svelte, Solid e Qwik também estão lá, cada um em
JavaScript e em TypeScript. Além dessa lista, o Nuxt é construído sobre o Vite (aula 18), o SvelteKit
também, e o Angular CLI usa o Vite como servidor de desenvolvimento desde o Angular 17. O Vitest, o
executor de testes da aula 21, é o Vite rodando testes. Quem sai deste curso para qualquer um deles
leva consigo a maior parte do que esta aula diz.

## Do que o Vite é feito

O Vite é um servidor de desenvolvimento, um comando de build e um sistema de plugins em volta deles, e
o trabalho pesado nos dois é feito por um bundler escrito em Rust, o **Rolldown**. O planner já o tem,
instalado pelo Vite:

```
ana@dev:~/vue/planner$ npm ls rolldown
planner@0.0.0 /home/ana/vue/planner
├─┬ vite@8.3.5
│ └── rolldown@1.2.15
└─┬ vue-router@5.4.0
  └─┬ unplugin@3.4.0
    └── rolldown@1.2.15 deduped
```

Versões anteriores do Vite usavam duas ferramentas, o esbuild no desenvolvimento e o Rollup no build,
e um projeto podia se comportar um pouco diferente em cada uma. O Vite 8 usa o Rolldown nas duas. O
Rolldown mantém a interface de plugins do Rollup, então a maioria dos plugins escritos para o Rollup ao
longo dos anos funciona com ele, e o plugin do próprio planner, no fim desta aula, é escrito nessa
interface.
