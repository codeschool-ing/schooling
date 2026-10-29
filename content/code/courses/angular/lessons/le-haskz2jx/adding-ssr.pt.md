---
title: Acrescentando SSR ao planner
version: 1
---

**O `ng add @angular/ssr` instala a renderização no servidor e escreve os arquivos de que ela
precisa.** Pare o `ng serve` antes com Ctrl-C, porque o comando muda o `angular.json`, que um dev
server rodando não lê de novo. Como na aula 21, a versão vai escrita por inteiro e as perguntas são
puladas:

```
ana@dev:~/planner$ npx ng add @angular/ssr@21.2.28 --skip-confirmation --interactive=false
❯ Determining Package Manager
› Using package manager: npm
✔ Determining Package Manager
❯ Loading package information
✔ Loading package information
❯ Installing package
✔ Installing package
                        Package dependency "@angular/ssr" already exists with a different specifier. "21.2.28" will be replaced with "^21.2.28".
CREATE src/main.server.ts (292 bytes)
CREATE src/app/app.config.server.ts (426 bytes)
CREATE src/app/app.routes.server.ts (166 bytes)
CREATE src/server.ts (1609 bytes)
UPDATE angular.json (2412 bytes)
UPDATE tsconfig.app.json (447 bytes)
UPDATE package.json (1073 bytes)
UPDATE src/app/app.config.ts (890 bytes)
- Installing packages (npm)...
✔ Packages installed successfully.
```

Uma linha do meio pede leitura. O CLI instalou o `@angular/ssr` exatamente em `21.2.28`, como o
`.npmrc` do projeto pede; depois o passo de configuração, que edita o `package.json` por conta
própria, pôs um circunflexo na frente. Fez o mesmo com os três pacotes que acrescentou:

```
ana@dev:~/planner$ git diff package.json
diff --git a/package.json b/package.json
index c10b1b0..c24238f 100644
--- a/package.json
+++ b/package.json
@@ -6,7 +6,8 @@
     "start": "ng serve",
     "build": "ng build",
     "watch": "ng build --watch --configuration development",
-    "test": "ng test"
+    "test": "ng test",
+    "serve:ssr:planner": "node dist/planner/server/server.mjs"
   },
   "private": true,
   "packageManager": "npm@10.9.4",
@@ -18,7 +19,10 @@
     "@angular/forms": "21.2.25",
     "@angular/material": "21.2.14",
     "@angular/platform-browser": "21.2.25",
+    "@angular/platform-server": "21.2.25",
     "@angular/router": "21.2.25",
+    "@angular/ssr": "^21.2.28",
+    "express": "^5.1.0",
     "rxjs": "7.8.2",
     "tslib": "2.8.1"
   },
@@ -26,6 +30,8 @@
     "@angular/build": "21.2.28",
     "@angular/cli": "21.2.28",
     "@angular/compiler-cli": "21.2.25",
+    "@types/express": "^5.0.1",
+    "@types/node": "^20.17.19",
     "jsdom": "28.1.0",
     "prettier": "3.9.10",
     "typescript": "5.9.3",
```

**`^21.2.28` quer dizer "21.2.28 ou qualquer 21 posterior"**, então o próximo `npm install` em outro
computador pode escolher uma versão diferente da que este projeto testou. O conserto é instalar os
quatro de novo, em versões exatas. Aproveitando, o `@types/node` deve descrever o Node.js em que o
projeto roda, que é o 22, e não o 20 que a configuração escreveu:

```
ana@dev:~/planner$ npm install --save-exact @angular/ssr@21.2.28 express@5.3.0 @types/express@5.0.6 @types/node@22.20.5

changed 1 package, and audited 491 packages in 1s

2 vulnerabilities (1 moderate, 1 high)

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
```

Só o `@types/node` mudou no disco; os outros três já estavam instalados nessas versões, e o que mudou
para eles foi a linha no `package.json`. As duas vulnerabilidades são as que a aula 22 leu no
`@angular/build`, não algo que este comando trouxe. O que sobra do diff é o que o projeto ganhou:

```
ana@dev:~/planner$ git diff package.json | grep '^[-+] '
-    "test": "ng test"
+    "test": "ng test",
+    "serve:ssr:planner": "node dist/planner/server/server.mjs"
+    "@angular/platform-server": "21.2.25",
+    "@angular/ssr": "21.2.28",
+    "express": "5.3.0",
+    "@types/express": "5.0.6",
+    "@types/node": "22.20.5",
```

O `@angular/platform-server` entrou sem circunflexo porque é um dos pacotes do próprio Angular, e o
CLI escreve esses na versão que o projeto já tem. O `express` é o servidor web sobre o qual o
`server.ts` é construído; o `@types/express` e o `@types/node` dão ao TypeScript o formato das funções
dele e das do Node.

## Os arquivos

```
ana@dev:~/planner$ git status --short
 M angular.json
 M package-lock.json
 M package.json
 M src/app/app.config.ts
 M tsconfig.app.json
?? src/app/app.config.server.ts
?? src/app/app.routes.server.ts
?? src/main.server.ts
?? src/server.ts
```

| arquivo | o que é |
| --- | --- |
| `src/main.server.ts` | a entrada do servidor: o mesmo `App`, iniciado com a configuração do servidor |
| `src/app/app.config.server.ts` | a configuração da aplicação, mais o `provideServerRendering` |
| `src/app/app.routes.server.ts` | como cada rota é renderizada, o assunto da próxima seção |
| `src/server.ts` | um servidor Express que serve os arquivos do build e renderiza todo o resto |
| `angular.json` | `outputMode: "server"`, as duas entradas, e um bloco `security` |
| `src/app/app.config.ts` | `provideClientHydration(withEventReplay())`, para o navegador |
| `tsconfig.app.json` | `"types": ["node"]`, para o `server.ts` poder usar os módulos do próprio Node |

O `app.config.server.ts` é curto o bastante para ler inteiro. Ele pega a configuração do navegador e
acrescenta, então todo provider que o planner tem, o roteador e o `HttpClient` inclusive, está também
no servidor:

```
ana@dev:~/planner$ cat src/app/app.config.server.ts
import { mergeApplicationConfig, ApplicationConfig } from '@angular/core';
import { provideServerRendering, withRoutes } from '@angular/ssr';
import { appConfig } from './app.config';
import { serverRoutes } from './app.routes.server';

const serverConfig: ApplicationConfig = {
  providers: [provideServerRendering(withRoutes(serverRoutes))],
};

export const config = mergeApplicationConfig(appConfig, serverConfig);
```

Inicie o dev server de novo, no terminal dele, com o mesmo comando de sempre. A partir de agora ele
renderiza cada página no servidor antes de mandá-la.
