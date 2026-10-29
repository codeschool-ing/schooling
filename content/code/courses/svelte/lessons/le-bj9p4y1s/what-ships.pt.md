---
title: O que sobra para o navegador
version: 1
---

**O `npm run build` produz o que você publicaria, e as últimas linhas dele dizem quanto JavaScript o
navegador baixa.** O servidor de desenvolvimento compila sob demanda e acrescenta ferramentas para
a substituição a quente; um build compila tudo uma vez, divide em arquivos nomeados pelo conteúdo e
os minifica. Pare primeiro o servidor de desenvolvimento com Ctrl-C, e então:

```
ana@dev:~/planner$ npm run build

> planner@0.0.1 build
> vite build

vite v8.3.5 building ssr environment for production...
transforming...
✓ 136 modules transformed.
rendering chunks...
computing gzip size...
.svelte-kit/output/server/.vite/manifest.json                  2.29 kB │ gzip:  0.43 kB
.svelte-kit/output/server/entries/pages/_page.svelte.js        0.28 kB │ gzip:  0.23 kB │ map:   0.28 kB
.svelte-kit/output/server/env.js                               0.29 kB │ gzip:  0.18 kB │ map:   0.57 kB
.svelte-kit/output/server/entries/fallbacks/error.svelte.js    1.02 kB │ gzip:  0.41 kB │ map:   2.58 kB
.svelte-kit/output/server/index.js                             2.24 kB │ gzip:  0.90 kB │ map:   3.32 kB
.svelte-kit/output/server/entries/pages/_layout.svelte.js      2.58 kB │ gzip:  1.06 kB │ map:   2.67 kB
.svelte-kit/output/server/chunks/server-errors.js             23.96 kB │ gzip:  4.49 kB │ map:  34.73 kB
.svelte-kit/output/server/chunks/server.js                    42.83 kB │ gzip: 11.91 kB │ map: 125.48 kB
.svelte-kit/output/server/remote-entry.js                     54.22 kB │ gzip: 11.79 kB │ map:  89.77 kB
.svelte-kit/output/server/chunks/internal.js                  86.95 kB │ gzip: 23.79 kB │ map: 191.42 kB
.svelte-kit/output/server/chunks/instance.js                 117.43 kB │ gzip: 31.63 kB │ map: 239.38 kB

✓ built in 206ms
Analysing routes
Building app
vite v8.3.5 building client environment for production...
transforming...
✓ 173 modules transformed.
rendering chunks...
computing gzip size...
.svelte-kit/output/client/_app/version.json                          0.02 kB │ gzip:  0.04 kB
.svelte-kit/output/client/.vite/manifest.json                        3.14 kB │ gzip:  0.55 kB
.svelte-kit/output/client/_app/immutable/entry/payload.DSmR2FwN.js   0.06 kB │ gzip:  0.07 kB
.svelte-kit/output/client/_app/immutable/nodes/2.DUiUs12v.js         0.21 kB │ gzip:  0.19 kB
.svelte-kit/output/client/_app/immutable/nodes/1.CJmELmRf.js         0.32 kB │ gzip:  0.24 kB
.svelte-kit/output/client/_app/immutable/entry/start.SwYmm2vB.js     0.52 kB │ gzip:  0.31 kB
.svelte-kit/output/client/_app/immutable/entry/app.Bx4PHhS8.js       1.06 kB │ gzip:  0.53 kB
.svelte-kit/output/client/_app/immutable/chunks/Bjy-W4x2.js          1.36 kB │ gzip:  0.65 kB
.svelte-kit/output/client/_app/immutable/chunks/CRzLMJPS.js          1.53 kB │ gzip:  0.80 kB
.svelte-kit/output/client/_app/immutable/nodes/0.D6mfru_B.js         2.38 kB │ gzip:  0.97 kB
.svelte-kit/output/client/_app/immutable/chunks/BxxUQ32s.js          4.29 kB │ gzip:  1.93 kB
.svelte-kit/output/client/_app/immutable/chunks/CyvJ4pxs.js         33.19 kB │ gzip: 12.89 kB
.svelte-kit/output/client/_app/immutable/chunks/DA9qkyNS.js         39.71 kB │ gzip: 14.64 kB

✓ built in 176ms

Run npm run preview to preview your production build locally.

> Using @sveltejs/adapter-auto
Could not detect a supported production environment. See https://svelte.dev/docs/kit/adapters to learn how to configure your app to run on the platform of your choosing
✔ done
```

Ele faz dois builds, como dizem as duas linhas `building … environment`: o ambiente **ssr** é o
código que renderiza as páginas no servidor, e o ambiente **client** é o que os navegadores baixam.
A coluna `gzip` é o tamanho que de fato passa pela rede, já que todo servidor web comprime
JavaScript.

O último parágrafo não é um erro. O `adapter-auto` procura uma plataforma de hospedagem que conheça,
não acha nenhuma no seu computador, e não produz nada publicável; a aula 15 o troca por um adaptador
que produz um servidor que dá para rodar. Tudo acima daquele parágrafo é o build, e ele deu certo.

## Somando

Os arquivos do cliente são o que esta página custa a um visitante. Os tamanhos em gzip somam uns
**33 kB** para uma página com um título e uma frase. Parece muito para tão pouco, então vale saber
para onde vai. **Dois arquivos são quatro quintos disso**, e nenhum dos dois é seu:

| arquivo | gzip | o que há nele |
|---|---|---|
| o chunk maior | 14,64 kB | o cliente do SvelteKit: o roteador, `history`, `popstate`, o pré-carregamento da próxima página |
| o seguinte | 12,89 kB | o runtime do Svelte: signals, efeitos, e o código que hidrata o HTML do servidor |
| `nodes/2…js` | 0,19 kB | a página do planner |

Os dois arquivos grandes têm o mesmo tamanho com uma página ou com cinquenta. O que cresce com a
app é a pasta `nodes`, um arquivo por página ou layout, cada um um componente compilado:

```
ana@dev:~/planner$ ls .svelte-kit/output/client/_app/immutable/nodes
0.D6mfru_B.js
1.CJmELmRf.js
2.DUiUs12v.js
ana@dev:~/planner$ cat .svelte-kit/output/client/_app/immutable/nodes/2.*.js
import{h as e,p as t}from"../chunks/CyvJ4pxs.js";var n=e(`<main><h1>Study planner</h1> <p>Three courses, six sessions, and one week to fit them in.</p></main>`);function r(e){var r=n();t(e,r)}export{r as component};
```

**Aquela uma linha é a página inteira.** Ela importa duas funções do chunk do runtime, `h` e `p`
depois da minificação, que são o `from_html` e o `append` da seção anterior; guarda a marcação como
um template; e exporta um componente que copia o template para a página. Nada nela descreve a página
uma segunda vez, e nada lê a marcação em tempo de execução.

Essa é a versão honesta da afirmação da primeira seção desta aula. O runtime do Svelte é pequeno
porque o compilador fez o trabalho, então um componente custa mais ou menos o que a sua própria
lógica custa. Uma aplicação SvelteKit ainda manda um roteador, e a aula 15 mostra a única
configuração que não manda JavaScript nenhum para uma página que não precisa de nenhum.

Faça o commit do que você tem antes do exercício:

```sh
git add -A && git commit -m "Lesson 1: the planner page, Counter and compile.mjs"
```
