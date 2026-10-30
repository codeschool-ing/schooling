---
title: Levando um projeto baseado em módulos para o standalone
version: 1
---

**O Angular traz uma migração que converte um projeto baseado em módulos para standalone, em três
passos, e cada passo deixa um projeto que ainda compila.** É isso que a torna usável no trabalho: você
roda um passo, faz commit, publica, e roda o próximo no mês que vem. Esta seção roda os três em
`~/legacy`.

Comece de um commit, para que as mudanças de cada passo sejam a única coisa no `git diff`, o hábito
que o `ng update` da aula 2 exigiu:

```
ana@dev:~/legacy$ git init -q && git add -A && git commit -q -m "A module-based project"
```

A migração é um schematic, então quem a roda é o `ng generate`, e o `--mode` escolhe o passo. Cada
execução abre com três linhas parabenizando você e lembrando de conferir o resultado; o `tail -n +4`
as deixa fora das transcrições abaixo, e o lembrete é bom.

## Passo 1: converter as declarações

```
ana@dev:~/legacy$ npx ng generate @angular/core:standalone --mode=convert-to-standalone 2>&1 | tail -n +4
UPDATE src/app/session-list/session-list.ts (198 bytes)
UPDATE src/app/app-module.ts (488 bytes)
ana@dev:~/legacy$ git diff
diff --git a/src/app/app-module.ts b/src/app/app-module.ts
index 4952227..62e5838 100644
--- a/src/app/app-module.ts
+++ b/src/app/app-module.ts
@@ -6,8 +6,8 @@ import { App } from './app';
 import { SessionList } from './session-list/session-list';
 
 @NgModule({
-  declarations: [App, SessionList],
-  imports: [BrowserModule, AppRoutingModule],
+  declarations: [App],
+  imports: [BrowserModule, AppRoutingModule, SessionList],
   providers: [provideBrowserGlobalErrorListeners()],
   bootstrap: [App],
 })
diff --git a/src/app/session-list/session-list.ts b/src/app/session-list/session-list.ts
index ef498c6..ad1bb7e 100644
--- a/src/app/session-list/session-list.ts
+++ b/src/app/session-list/session-list.ts
@@ -2,7 +2,6 @@ import { Component } from '@angular/core';
 
 @Component({
   selector: 'app-session-list',
-  standalone: false,
   templateUrl: './session-list.html',
   styleUrl: './session-list.css',
 })
```

O `SessionList` perdeu o `standalone: false`, então agora é standalone, e o módulo o passou de
`declarations` para `imports`: **um módulo pode importar um componente standalone** como se fosse um
módulo. O `App` ficou como estava, porque é o componente que o módulo inicia, e isso é assunto do
passo 3.

## Passo 2: remover os módulos de que ninguém precisa

```
ana@dev:~/legacy$ npx ng generate @angular/core:standalone --mode=prune-ng-modules 2>&1 | tail -n +4
Nothing to be done.
```

Nada a fazer aqui, e essa é uma resposta de verdade: este passo apaga módulos que ficaram vazios, que
não declaram nada e só repassam imports, e o `AppModule` ainda inicia o `App`. Numa aplicação grande,
este é o passo que apaga uma dúzia de arquivos.

## Passo 3: iniciar sem módulo

```
ana@dev:~/legacy$ npx ng generate @angular/core:standalone --mode=standalone-bootstrap 2>&1 | tail -n +4
DELETE src/app/app-module.ts
UPDATE src/main.ts (481 bytes)
UPDATE src/app/app.ts (296 bytes)
```

```
ana@dev:~/legacy$ cat src/main.ts
import { platformBrowser, BrowserModule, bootstrapApplication } from '@angular/platform-browser';

import { provideBrowserGlobalErrorListeners, importProvidersFrom } from '@angular/core';
import { AppRoutingModule } from './app/app-routing-module';
import { App } from './app/app';

bootstrapApplication(App, {
  providers: [
    importProvidersFrom(BrowserModule, AppRoutingModule),
    provideBrowserGlobalErrorListeners(),
  ],
}).catch((err) => console.error(err));
```

O `AppModule` sumiu. O `main.ts` agora chama o `bootstrapApplication`, como o do planner, e o `App`
lista o `RouterOutlet` no próprio `imports`. O build é a conferência que o lembrete pediu:

```
ana@dev:~/legacy$ npx ng build 2>&1 | tail -3

Output location: /home/ana/legacy/dist/legacy
```

**Mas leia o que a migração deixou.** Ela não escreveu `provideRouter(routes)`, o jeito como o planner
configura o router; ela envolveu os módulos antigos em `importProvidersFrom(BrowserModule,
AppRoutingModule)`, o que funciona e não é o que alguém escreveria hoje. O trabalho de uma migração é
manter a aplicação rodando, e arrumar o resultado é com você. A próxima seção explica por que esse
invólucro existe.
