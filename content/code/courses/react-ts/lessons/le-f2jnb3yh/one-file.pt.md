---
title: Tudo num arquivo só
version: 1
---

**O `npm run build` transforma o projeto nos arquivos que um servidor web entrega a um navegador**, e
até agora isso foi um arquivo JavaScript com tudo dentro. O servidor de desenvolvimento que você usou
até aqui manda cada módulo separado e o compila sob pedido; um build é o que um deploy de verdade
serve. Rode:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 174 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.45 kB │ gzip:   0.29 kB
dist/assets/index-C0qAAZg_.css    0.43 kB │ gzip:   0.25 kB
dist/assets/index-CkcBpHKM.js   371.14 kB │ gzip: 115.09 kB

✓ built in 558ms
```

O `tsc -b` conferiu os tipos primeiro, e só então o Vite fez o build, então um erro de tipo para o
build antes de qualquer arquivo ser escrito. Depois, três arquivos em `dist/`:

- `index.html`, a página, que carrega os outros dois.
- `index-C0qAAZg_.css`, a folha de estilo.
- **`index-CkcBpHKM.js`, 371 kB de JavaScript**, 115 kB depois de comprimido com gzip, que é mais ou
  menos o que trafega pela rede. Ele contém React, React DOM, TanStack Query, React Hook Form, Zod e o
  código do próprio planejador.

A parte estranha de cada nome é um **hash**, calculado a partir do conteúdo do arquivo. Mude um
caractere do código e o arquivo JavaScript ganha um nome novo. Isso deixa um servidor dizer aos
navegadores que guardem um arquivo pelo tempo que quiserem: uma versão nova é um nome novo, então um
navegador nunca fica preso a uma antiga.

Olhe o que há nesse arquivo do lado do estudante. Quem abre o planejador para ver a semana baixa tudo
isso antes de a primeira tela poder ser desenhada, inclusive **o React Hook Form e o Zod, que só a tela
do curso usa**, no formulário do rodapé. Quem nunca abre um curso paga pelo formulário mesmo assim.

A correção é cortar o arquivo em dois: o código de que a primeira tela precisa, carregado na hora, e o
código da tela do curso, carregado quando alguém abre um. Isso é **code splitting**, e no React leva
duas peças: `lazy`, que carrega o código de um componente na primeira vez que ele é desenhado, e
`Suspense`, que diz o que mostrar enquanto esse código está a caminho.
