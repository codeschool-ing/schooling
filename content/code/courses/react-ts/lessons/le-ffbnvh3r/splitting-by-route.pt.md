---
title: Dividindo por rota
version: 1
---

**Uma rota é o lugar natural para cortar o código**, como a aula 13 prometeu: cada tela é um pedaço de que
algumas visitas nunca precisam. A rota do curso já faz isso, com a propriedade `lazy` no `main.tsx`:

```tsx
lazy: async () => ({ Component: (await import('./CourseScreen')).CourseScreen }),
```

O `lazy` é chamado na primeira vez que a rota é necessária, e devolve as partes da rota que ficaram fora da
lista: aqui, o `Component` dela. É o mesmo `import()` dinâmico da aula 13, mas **é o roteador que o chama**,
e ele desenha a tela quando o código e os dados do loader estão ambos lá. Não há `Suspense` a posicionar:
até lá, o roteador mantém a tela antiga.

Faça o build, e abra um curso pelo servidor de preview:

```
ana@dev:~/planner$ npm run build | grep -E "assets|built"
dist/assets/index-ims8OhNo.css          0.57 kB │ gzip:   0.31 kB
dist/assets/CourseScreen-Cl8g1eB6.js  111.69 kB │ gzip:  34.90 kB
dist/assets/index-BcPNGV8E.js         356.60 kB │ gzip: 112.00 kB
✓ built in 510ms
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --network --do 'click link Organic chemistry' | grep -E 'assets|api|^-- |heading'
net  GET /assets/index-ims8OhNo.css  200
net  GET /assets/index-BcPNGV8E.js  200
net  GET /api/planner  200
-- click link Organic chemistry
net  GET /assets/CourseScreen-Cl8g1eB6.js  200
  - heading "Organic chemistry" [level=1]
```

**O `CourseScreen-BH827cGS.js` é buscado no clique e não antes**, como na aula 13, agora sem o `lazy`, o
`Suspense` e o efeito de preload que o `App` carregava. O arquivo principal cresceu dos 262 kB da aula 13
para 357 kB: a maior parte é o próprio React Router, de que toda tela precisa.

O loader, ao contrário, está no arquivo principal, importado pelo `main.tsx`. São poucas linhas, então
quase não custa nada ali. Uma rota pode carregar o loader sob demanda também, pela mesma função `lazy`,
quando o loader é grande.
