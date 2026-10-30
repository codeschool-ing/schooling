---
title: O que um build produz
version: 1
---

**Um build transforma o projeto em arquivos que qualquer servidor web consegue mandar.** A aula 13 olhou
para ele para ver o código dividido; desta vez, o `dist/` inteiro:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 264 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                         0.45 kB │ gzip:   0.29 kB
dist/assets/index-ims8OhNo.css          0.57 kB │ gzip:   0.31 kB
dist/assets/CourseScreen-jvv40fJe.js  111.82 kB │ gzip:  34.97 kB
dist/assets/index-R8L4SX4s.js         356.86 kB │ gzip: 112.08 kB

✓ built in 622ms
ana@dev:~/planner$ ls dist dist/assets
dist:
assets
courses.json
favicon.svg
index.html

dist/assets:
CourseScreen-jvv40fJe.js
index-R8L4SX4s.js
index-ims8OhNo.css
ana@dev:~/planner$ cat dist/index.html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>planner</title>
    <script type="module" crossorigin src="/assets/index-R8L4SX4s.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-ims8OhNo.css">
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
```

Três tipos de arquivo:

- **`index.html`, reescrito.** O `<script>` que apontava para `/src/main.tsx` agora aponta para
  `/assets/index-R8L4SX4s.js`, e a folha de estilo que o `main.tsx` importava virou um `<link>`, então o
  navegador começa a buscá-la antes de qualquer JavaScript rodar. O `<title>` continua `planner`, do
  modelo: o planejador define o título da aba ele mesmo, pelo efeito da aula 5.
- **`assets/`, com um hash em todo nome.** O JavaScript, dividido onde a aula 17 o dividiu, e o CSS. Um
  build novo com qualquer mudança dá ao arquivo mudado um nome novo, então um servidor pode dizer aos
  navegadores que guardem esses arquivos por um ano.
- **`courses.json` e `favicon.svg`**, que estavam em `public/`. **Tudo em `public/` é copiado como está**,
  com o mesmo nome e sem hash, para arquivos cujo endereço não pode mudar: um ícone, um `robots.txt`, os
  dados iniciais que a aula 5 buscava.

Publicar o planejador é pôr esses arquivos num servidor que manda o `index.html` para todo endereço que
não for um arquivo, como a aula 17 disse, mais a API em algum lugar que o navegador alcance em `/api`.
Nada em `dist/` roda no servidor: é tudo para o navegador.
