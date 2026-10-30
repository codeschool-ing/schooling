---
title: Source maps
version: 1
---

**Um arquivo construído é ilegível de propósito.** A aula 13 o encontrou numa pilha de erro, em que os
componentes do planejador se chamavam `Vt` e `Wt`. Um **source map** é a chave que o lê de volta: um
arquivo que diz, para cada posição do código construído, de que arquivo, linha e nome seu ela veio. As
ferramentas de desenvolvedor dos navegadores e os serviços de relatório de erros o leem e mostram o seu
código no lugar do minificado.

O `vite build` não escreve nenhum por padrão. O `--sourcemap` os pede:

```
ana@dev:~/planner$ npx vite build --sourcemap | grep -E 'assets|built'
dist/assets/index-ims8OhNo.css          0.57 kB │ gzip:   0.31 kB
dist/assets/CourseScreen-jvv40fJe.js  111.87 kB │ gzip:  35.01 kB │ map:   739.71 kB
dist/assets/index-R8L4SX4s.js         356.90 kB │ gzip: 112.12 kB │ map: 1,847.19 kB
✓ built in 636ms
ana@dev:~/planner$ tail -c 60 dist/assets/index-*.js; echo
,f as s,Vo as t};
//# sourceMappingURL=index-R8L4SX4s.js.map
ana@dev:~/planner$ npx vite build --sourcemap hidden > /dev/null && ls dist/assets
CourseScreen-jvv40fJe.js
CourseScreen-jvv40fJe.js.map
index-R8L4SX4s.js
index-R8L4SX4s.js.map
index-ims8OhNo.css
ana@dev:~/planner$ tail -c 60 dist/assets/index-*.js; echo
as c,so as i,c as l,ko as n,ot as o,Ao as r,f as s,Vo as t};
ana@dev:~/planner$ npm run build > /dev/null && ls dist/assets
CourseScreen-jvv40fJe.js
index-R8L4SX4s.js
index-ims8OhNo.css
```

- **O primeiro build** escreveu um `.map` ao lado de cada arquivo JavaScript, 1,8 MB para o principal,
  cinco vezes o código que ele descreve, porque carrega as suas fontes dentro dele. A última linha do
  arquivo construído o nomeia: `//# sourceMappingURL=index-R8L4SX4s.js.map`. As ferramentas de
  desenvolvedor seguem esse comentário, então qualquer um que as abra no site lê o seu código como você
  o escreveu, comentários inclusive.
- **`--sourcemap hidden`** escreveu os mapas e deixou o comentário de fora. Os navegadores não os acham,
  mas os arquivos existem, para serem enviados a um serviço de relatório de erros, que os usa para
  transformar a pilha minificada de um usuário na sua. Essa é a escolha de costume em produção.
- **O build simples** do fim não tem mapa nenhum, que é de onde o planejador publica a partir de agora.

Para a escolha ficar permanente em vez de ser uma flag, ela vai no `vite.config.ts` como `build: {
sourcemap: 'hidden' }`.
