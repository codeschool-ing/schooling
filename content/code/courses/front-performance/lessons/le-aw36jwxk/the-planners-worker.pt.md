---
title: O worker do planner
version: 1
---

**O service worker do planner é um arquivo, `public/sw.js`**, JavaScript puro, porque o Vite copia os
arquivos de `public/` como estão e o navegador busca este pelo endereço. A próxima seção explica as três
estratégias dele uma a uma; aqui ele está inteiro, para salvar e ler:

```schooling-example
{"language": "javascript", "file": "public/sw.js", "parts": [
 {"code": "// public/sw.js: the planner's service worker. It sits between the planner's pages and\n// the network, and answers from a cache of its own when the network is slow or gone.\nconst CACHE = \"planner-v1\";", "note": "Um cache, com nome e versão. Uma versão nova deste arquivo nomeia um cache novo, e é assim que as cópias velhas são liberadas."},
 {"code": "self.addEventListener(\"install\", (event) => {\n  event.waitUntil(caches.open(CACHE).then((cache) => cache.add(\"/offline.html\")));\n});", "note": "O install roda uma vez por versão. O waitUntil mantém o worker instalando até a promise se resolver, e uma falha aqui quer dizer que ele não foi instalado."},
 {"code": "self.addEventListener(\"activate\", (event) => {\n  event.waitUntil(caches.keys().then((names) =>\n    Promise.all(names.filter((name) => name !== CACHE).map((name) => caches.delete(name)))));\n});", "note": "O activate roda quando esta versão assume: todo cache com outro nome é de uma versão anterior."},
 {"code": "self.addEventListener(\"fetch\", (event) => {\n  const { request } = event;\n  if (request.method !== \"GET\" || new URL(request.url).origin !== location.origin) return;\n  if (new URL(request.url).pathname.startsWith(\"/assets/\")) event.respondWith(cacheFirst(request));\n  else if (request.mode === \"navigate\") event.respondWith(networkFirst(request));\n  else event.respondWith(staleWhileRevalidate(event, request));\n});", "note": "Toda requisição de uma página controlada chega aqui. Um tratador que não chama respondWith deixa a requisição para o navegador, como se o worker não existisse: o beacon para /vitals e o que for para outro servidor vão por esse caminho."},
 {"code": "async function cacheFirst(request) {\n  const cache = await caches.open(CACHE);\n  return (await cache.match(request)) ?? fetchAndKeep(cache, request);\n}", "note": "Arquivos com hash: a cópia, se houver, que está sempre certa."},
 {"code": "async function networkFirst(request) {\n  const cache = await caches.open(CACHE);\n  try {\n    return await fetchAndKeep(cache, request);\n  } catch {\n    return (await cache.match(request)) ?? (await cache.match(\"/offline.html\"));\n  }\n}", "note": "Páginas: a rede primeiro, para um visitante online ver a página mais nova; a última cópia quando ela falha; a página offline quando não há cópia."},
 {"code": "async function staleWhileRevalidate(event, request) {\n  const cache = await caches.open(CACHE);\n  const kept = await cache.match(request);\n  const fresh = fetchAndKeep(cache, request);\n  event.waitUntil(fresh.catch(() => {}));\n  return kept ?? fresh;\n}", "note": "Todo o resto: a cópia na hora, e uma nova buscada para a próxima vez. Offline a nova falha, que é o caso para o qual isto existe, então essa falha é deixada passar de propósito; sem cópia para responder, a mesma falha chega à página."},
 {"code": "async function fetchAndKeep(cache, request) {\n  const response = await fetch(request);\n  if (response.ok) await cache.put(request, response.clone());\n  return response;\n}", "note": "Uma resposta só pode ser lida uma vez, então o cache recebe um clone. Só uma resposta bem-sucedida é guardada: uma página de erro guardada seria servida como se fosse a página."}
]}
```

## A página offline

O `install` busca um arquivo antes de qualquer outra coisa: a página para mostrar num endereço de que o
worker não tem cópia. Salve-a como `public/offline.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Offline · Study planner</title>
  </head>
  <body style="font: 16px/1.5 system-ui, sans-serif; max-width: 40rem; margin: 0 auto; padding: 1rem">
    <h1>You are offline</h1>
    <p>This page has not been opened on this device yet, so there is no copy of it here.
      The pages you have opened before still work. <a href="/">All courses</a></p>
  </body>
</html>
```

O estilo dela é inline, porque ela precisa funcionar sem mais nada no cache.

## Registrando

No fim do `src/main.ts`:

```typescript

// The service worker, registered once the page has loaded, so that its first download
// does not compete with the page's own.
const register = () => navigator.serviceWorker.register("/sw.js");
if ("serviceWorker" in navigator) {
  if (document.readyState === "complete") register();
  else addEventListener("load", register);
}
```

O `load` é o momento em que a página terminou as próprias requisições, então o download do worker, e as
requisições que ele faz ao instalar, não competem com elas.

## Uma coisa de que o server.ts nunca precisou

**O `server.ts` nunca serviu um arquivo `.html`**, então a tabela de tipos dele não tem entrada para um, e
ele mandaria a página offline como `application/octet-stream`: um arquivo para baixar, não uma página. A
tabela também não tem os tipos das imagens e fontes da aula 7, que saem como octet-stream desde então, e
funcionaram porque os navegadores olham dentro de um arquivo sobre o qual não lhes disseram nada. Troque a
tabela por uma que diga o que cada arquivo é:

```typescript
const types: Record<string, string> = {
  ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml",
  ".html": "text/html; charset=utf-8", ".avif": "image/avif", ".webp": "image/webp", ".jpg": "image/jpeg",
  ".png": "image/png", ".woff2": "font/woff2",
};
```

Faça o build e reinicie o `server.ts`. As próximas seções tiram o navegador da rede para ver o que o worker
faz.
