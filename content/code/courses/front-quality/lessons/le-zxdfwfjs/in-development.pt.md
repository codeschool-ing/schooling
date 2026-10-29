---
title: Por que o servidor de desenvolvimento não recebe política
version: 1
---

**Os cabeçalhos foram para o servidor de preview e não para o de desenvolvimento, e isso foi de
propósito.** O servidor de desenvolvimento é outro programa servindo outra página: ele injeta o cliente
que recarrega a página a cada salvamento, e põe o CSS na página com elementos `<style>` criados por
JavaScript, que é como ele troca estilos sem recarregar. Uma política estrita recusa os dois.

Como experimento, dê ao servidor de desenvolvimento os mesmos cabeçalhos:

```
ana@dev:~/planner$ git diff vite.config.ts
diff --git a/vite.config.ts b/vite.config.ts
index 1d4af3d..dae0f3f 100644
--- a/vite.config.ts
+++ b/vite.config.ts
@@ -22,6 +22,7 @@ const securityHeaders = {
 export default defineConfig({
   server: {
     proxy: { "/api": "http://127.0.0.1:3000" },
+    headers: securityHeaders,
   },
   preview: {
     headers: securityHeaders,
```

```
ana@dev:~/planner$ node server/look.mjs http://localhost:5173/ "getComputedStyle(document.body).maxWidth"
console:  Applying inline style violates the following Content Security Policy directive 'style-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-v87a+Ohf0OBFYYXZLz7mQ5d74zDQIpY3VrMCOtCRpTo='), or a nonce ('nonce-...') is required to enable inline execution. The action has been blocked.
result:   none
```

**O estilo inline foi recusado**: o `style-src 'self'` permite arquivos de estilo da origem e nenhum
estilo inline, e em desenvolvimento o CSS do planner chega exatamente assim. A página funciona e desenha
sem os estilos: o `max-width` do body, 36rem no `style.css`, voltou como `none`. Relaxar a política para o
desenvolvimento funcionar, com `'unsafe-inline'`, ficaria então a uma cópia descuidada da produção.

Então a regra é: **a política é testada onde é servida, no build**, como o `e2e/headers.spec.ts` faz, e o
servidor de desenvolvimento fica livre para fazer o que o desenvolvimento precisa. O Vite também consegue
pôr um nonce nos elementos que cria, com a opção `html.cspNonce`, para um servidor que escreve um nonce
novo em cada página; o planner, um site estático, não precisa de um. Desfaça o experimento:

```
ana@dev:~/planner$ git checkout vite.config.ts
Updated 1 path from the index
```
