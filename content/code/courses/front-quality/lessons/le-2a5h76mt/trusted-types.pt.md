---
title: Trusted Types, o navegador aplicando a lista
version: 1
---

**A tabela da seção anterior é um hábito, e hábitos escorregam; o Trusted Types é uma linha de Content
Security Policy que faz o navegador recusar um texto simples em cada um desses sinks.** Com
`require-trusted-types-for 'script'` na política, o `innerHTML = "…"` lança um erro em vez de
interpretar. O único jeito de escrever marcação é por um objeto de política que o site cria de
propósito, então cada lugar onde marcação é construída fica num lugar do código, nomeado e revisável.

Ele tem suporte nos navegadores baseados no Chromium, e os outros ignoram a diretiva em vez de quebrar,
então é uma defesa que dá para acrescentar hoje. Experimente no planner empacotado: acrescente a diretiva
à política no `vite.config.ts`, empacote de novo, e abra a página de um curso.

```
ana@dev:~/planner$ git diff vite.config.ts
diff --git a/vite.config.ts b/vite.config.ts
index 1d4af3d..0d9b638 100644
--- a/vite.config.ts
+++ b/vite.config.ts
@@ -12,6 +12,7 @@ const securityHeaders = {
     "base-uri 'self'",
     "form-action 'self'",
     "frame-ancestors 'none'",
+    "require-trusted-types-for 'script'",
   ].join("; "),
   "X-Content-Type-Options": "nosniff",
   "Referrer-Policy": "strict-origin-when-cross-origin",
ana@dev:~/planner$ npm run build > /dev/null
```

```
ana@dev:~/planner$ node server/look.mjs 'http://localhost:4173/#/course/javascript' 'document.querySelectorAll("form").length'
console:  This document requires 'TrustedHTML' assignment. The action has been blocked.
result:   0
```

**A página do curso não conseguiu desenhar, e o console diz por quê.** A anotação já saiu desse arquivo,
então o texto que o navegador recusou é o do **formulário**: o `view.ts` escreve os três campos com
`innerHTML`, a partir de um template fixo, como a aula 1 o escreveu. Essa marcação é do próprio site e
inofensiva, e o Trusted Types a recusa mesmo assim, porque o navegador não distingue um template fixo do
texto de uma pessoa. Esse é o ponto dele: **ele troca a pergunta "este é seguro?" por "por que isto é um
texto?"**

O planner não o aplica neste curso; tire o experimento de novo:

```
ana@dev:~/planner$ git checkout vite.config.ts
Updated 1 path from the index
```

Para adotá-lo, o formulário seria montado com `el()` como todo o resto do `view.ts`, uma mudança de poucas
linhas, e a política então recusaria qualquer `innerHTML` que alguém acrescentasse depois. Uma aplicação
grande o liga do jeito que a aula 8 fez com a sua política: primeiro só relatando, com
`Content-Security-Policy-Report-Only`, até os relatórios não citarem nenhum sink que ninguém quis.
