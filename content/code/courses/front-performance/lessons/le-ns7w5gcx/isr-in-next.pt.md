---
title: Regeneração no Next.js
version: 1
---

**No Next.js 16 a idade de uma página é a idade dos dados em cache que ela leu.** O `getPlan()` do
projeto fica em cache com `cacheLife("hours")`, e a tabela de rotas do build disse o que isso quer
dizer: revalidar depois de uma hora, expirar depois de um dia. Para ver uma regeneração acontecer sem
esperar uma hora, dê aos dados um tempo de vida de dez segundos. No `lib/plan.ts`, mude uma linha:

```typescript
  cacheLife({ revalidate: 10, expire: 3600 });
```

`revalidate` é o primeiro número da seção anterior, em segundos, e `expire` o segundo. Um terceiro
campo, `stale`, é por quanto tempo o roteador do navegador pode reaproveitar uma página sem perguntar
nada ao servidor; ele fica no padrão de cinco minutos, porque **um `stale` abaixo de trinta segundos
tira os dados da pré-renderização de vez**, e o build então recusa a página como fora de cache. Faça
o build e veja a tabela:

```
ana@dev:~/meta/next$ npm run build 2>&1 | sed -n '/^Route/,$p' | head -8
Route (app)                Revalidate  Expire
┌ ○ /                             10s      1h
├ ○ /_not-found
├ ƒ /api/revalidate
└   /courses/[slug]
  ├ ◐ /courses/[slug]
  ├ ○ /courses/html-css           10s      1h
  ├ ○ /courses/javascript         10s      1h
```

Ligue o `npx next start -p 3001` no segundo terminal. O comando abaixo pede a página do Git e imprime
dois dos seus cabeçalhos e o seu título; ele roda quatro vezes em volta de uma mudança nos dados:

```
ana@dev:~/meta/next$ look() { curl -s -D - -o /tmp/page.html http://localhost:3001/courses/git | grep -iE '^(x-nextjs-cache|cache-control):'; grep -o '<h1>[^<]*</h1>' /tmp/page.html; }
ana@dev:~/meta/next$ look
x-nextjs-cache: HIT
Cache-Control: s-maxage=10, stale-while-revalidate=3590
<h1>Git</h1>
ana@dev:~/meta/next$ sed -i 's/"title": "Git"/"title": "Git and GitHub"/' courses.json
ana@dev:~/meta/next$ look
x-nextjs-cache: HIT
Cache-Control: s-maxage=10, stale-while-revalidate=3590
<h1>Git</h1>
ana@dev:~/meta/next$ sleep 11; look
x-nextjs-cache: STALE
Cache-Control: s-maxage=10, stale-while-revalidate=3590
<h1>Git</h1>
ana@dev:~/meta/next$ sleep 1; look
x-nextjs-cache: HIT
Cache-Control: s-maxage=10, stale-while-revalidate=3590
<h1>Git and GitHub</h1>
```

Leia as quatro respostas em ordem:

1. **`HIT`, *Git*.** O arquivo do build.
2. **`HIT`, *Git*, depois de os dados mudarem.** Nada pediu uma nova renderização, e a cópia tem
   menos de dez segundos.
3. **`STALE`, *Git*, onze segundos depois.** A cópia passou dos seus dez segundos, então o Next.js a
   serviu mesmo assim e começou uma renderização em segundo plano. Esta é a requisição que vê a
   página velha.
4. **`HIT`, *Git and GitHub*, um segundo depois.** A renderização terminou, e a cópia nova é servida.

`Cache-Control: s-maxage=10, stale-while-revalidate=3590` é o mesmo par de números escrito para
qualquer cache que fique na frente do servidor: fresca por dez segundos, e utilizável velha pelo
resto da hora. A aula 9 lê esse cabeçalho direito. Devolva o título e o `cacheLife("hours")` antes
da próxima seção.
