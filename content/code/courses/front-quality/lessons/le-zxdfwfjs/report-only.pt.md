---
title: Primeiro só relatar, depois aplicar
version: 1
---

**Uma política acrescentada a um site no ar quebra o que o site fazia e ninguém lembrava**: uma tag de
analytics, um tratador inline num template que ninguém abre há um ano. Então uma política vai ao ar em
dois passos. O mesmo cabeçalho com `-Report-Only` no nome faz o navegador relatar toda violação e não
bloquear nenhuma.

Como experimento, mude o nome do cabeçalho no `vite.config.ts`:

```
ana@dev:~/planner$ git diff vite.config.ts
diff --git a/vite.config.ts b/vite.config.ts
index 1d4af3d..581d486 100644
--- a/vite.config.ts
+++ b/vite.config.ts
@@ -2,7 +2,7 @@
 import { configDefaults, defineConfig } from "vitest/config";
 
 const securityHeaders = {
-  "Content-Security-Policy": [
+  "Content-Security-Policy-Report-Only": [
     "default-src 'self'",
     "script-src 'self'",
     "style-src 'self'",
```

```
ana@dev:~/planner$ node server/look.mjs http://localhost:4173/ "$(cat server/witness.js)"
console:  Executing inline script violates the following Content Security Policy directive 'script-src 'self''. Either the 'unsafe-inline' keyword, a hash ('sha256-pEY6BBBxZAVxAefxgixuyIDc9Sf/P5B1/XuTyDX/02k='), or a nonce ('nonce-...') is required to enable inline execution. The policy is report-only, so the violation has been logged but no further action has been taken.
result:   an inline script ran
```

**O script rodou, e o console relatou**, com a mesma frase que uma política aplicada dá e um final
diferente: a política é só de relatório, então a violação foi registrada e nada mais foi feito.

O navegador também consegue mandar esses relatórios ao servidor, para eles chegarem de cada visitante e
não só de quem abriu o console: a diretiva `report-to` nomeia um endereço, e o servidor junta o que
chega. Uma semana de relatórios sem nada inesperado é a prova para tirar o `-Report-Only`. A política do
planner foi testada num navegador de verdade desde a primeira linha, então vai direto para a aplicação, e
o experimento volta:

```
ana@dev:~/planner$ git checkout vite.config.ts
Updated 1 path from the index
```
