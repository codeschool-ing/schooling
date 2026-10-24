---
title: O build, e com o que ele é servido
version: 1
---

**Os cabeçalhos que mais importam ficam no site empacotado, os arquivos que um host vai servir, então é
isso que esta aula testa.** O `npm run build` confere os tipos, e depois escreve os arquivos de produção
em `dist/`:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 8 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                 0.41 kB │ gzip: 0.27 kB
dist/assets/index-DOOv8gtv.css  0.49 kB │ gzip: 0.33 kB
dist/assets/index-QOiF0uY7.js   3.22 kB │ gzip: 1.55 kB

✓ built in 95ms
```

**Três arquivos e os dados.** O `index.html`, um arquivo JavaScript e uma folha de estilo, cada um com um
hash do conteúdo no nome, para que um navegador possa guardá-los para sempre e um build novo seja nomes
novos. O `public/` é copiado do jeito que está. E nenhum script inline em lugar nenhum: o Vite levou cada
linha do código do planner para `assets/`, e é isso que torna possível uma Content Security Policy
estrita.

O `vite preview` serve o `dist/` como um host estático serviria, na porta 4173, e usa o mesmo proxy para o
`/api`. Eis com o que ele responde hoje:

```
ana@dev:~/planner$ curl -s -I http://localhost:4173/
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
Cache-Control: no-cache
Etag: W/"1a1-oQnFYEXs7j/YT1F2ilqAR+fppH0"
Date: Fri, 23 Oct 2026 23:28:46 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**Nenhum cabeçalho de segurança**: o tipo do conteúdo, um validador de cache, a data. Um navegador lendo
esta página vai rodar qualquer script que a página pedir, de qualquer lugar, deixar qualquer outro site
pôr a página num frame, e adivinhar os tipos de conteúdo. A próxima seção escreve o teste que diz o que
ela deveria mandar.
