---
title: O código com NgModule que você ainda vai encontrar
version: 1
---

**Antes dos componentes standalone, todo componente pertencia a um NgModule, e o módulo, não o
componente, decidia o que o template dele podia usar.** Os componentes standalone chegaram como
prévia no Angular 14, ficaram estáveis no 15 e viraram o padrão no 19, mas uma aplicação escrita em
2020 que ainda dá dinheiro em 2026 está cheia de módulos, e o primeiro chamado que você pegar no
trabalho pode muito bem estar num deles. Esta seção constrói um pequeno para que você tenha visto cada
parte antes de encontrá-las no código de outra pessoa.

## Um projeto do jeito antigo

`--standalone=false` pede ao `ng new` uma aplicação baseada em módulos. É um segundo projeto, então
ele recebe os dois consertos do planner, o `.npmrc` e as versões exatas, copiados de `~/planner` em
vez de digitados de novo:

```
ana@dev:~$ npx @angular/cli@21.2.28 new legacy --standalone=false --style=css --ssr=false --zoneless --ai-config=none --skip-install --skip-git
CREATE legacy/.prettierrc (161 bytes)
CREATE legacy/README.md (1460 bytes)
CREATE legacy/.editorconfig (314 bytes)
CREATE legacy/.gitignore (622 bytes)
CREATE legacy/angular.json (2156 bytes)
CREATE legacy/package.json (783 bytes)
CREATE legacy/tsconfig.json (957 bytes)
CREATE legacy/tsconfig.app.json (429 bytes)
CREATE legacy/tsconfig.spec.json (436 bytes)
CREATE legacy/.vscode/extensions.json (130 bytes)
CREATE legacy/.vscode/launch.json (470 bytes)
CREATE legacy/.vscode/mcp.json (179 bytes)
CREATE legacy/.vscode/tasks.json (978 bytes)
CREATE legacy/src/main.ts (198 bytes)
CREATE legacy/src/index.html (292 bytes)
CREATE legacy/src/styles.css (80 bytes)
CREATE legacy/src/app/app-routing-module.ts (245 bytes)
CREATE legacy/src/app/app-module.ts (437 bytes)
CREATE legacy/src/app/app.css (0 bytes)
CREATE legacy/src/app/app.spec.ts (801 bytes)
CREATE legacy/src/app/app.ts (234 bytes)
CREATE legacy/src/app/app.html (20144 bytes)
CREATE legacy/public/favicon.ico (15086 bytes)
```

```
ana@dev:~/legacy$ cp ../planner/.npmrc .
ana@dev:~/legacy$ sed 's/"planner"/"legacy"/' ../planner/package.json > package.json
ana@dev:~/legacy$ npm install

added 470 packages, and audited 471 packages in 20s

found 0 vulnerabilities
```

Desta vez com `--skip-install`, porque a instalação falharia exatamente como na aula 2, e o `sed`
grava o `package.json` do planner só com o nome trocado. O projeto ocupa cerca de 320 MB depois de
instalado; o fim desta aula o apaga.

## O módulo

```
ana@dev:~/legacy$ cat src/app/app-module.ts
import { NgModule, provideBrowserGlobalErrorListeners } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing-module';
import { App } from './app';

@NgModule({
  declarations: [
    App
  ],
  imports: [
    BrowserModule,
    AppRoutingModule
  ],
  providers: [
    provideBrowserGlobalErrorListeners(),
  ],
  bootstrap: [App]
})
export class AppModule { }
```

Cinco campos, e cada um é uma lista:

| campo | o que ele lista |
|---|---|
| `declarations` | os componentes, diretivas e pipes que **pertencem** a este módulo. Cada um pertence a exatamente um |
| `imports` | outros módulos cujas peças exportadas os templates deste módulo podem usar |
| `exports` | quais das suas próprias peças, ou dos seus imports, outros módulos podem usar. Vazio aqui, então nada é oferecido |
| `providers` | o que pode ser injetado; a aula 10 trata disso |
| `bootstrap` | o componente a desenhar na inicialização, só no módulo raiz |

**O escopo do template é o do módulo.** Todo componente declarado no `AppModule` pode usar tudo o que
está declarado nele e tudo o que os imports dele exportam, e nenhum componente tem lista própria. Essa
é a única ideia que o standalone mudou: o escopo saiu do módulo e foi para o componente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois jeitos de decidir o que um template pode usar. À esquerda, um módulo: uma caixa, AppModule, declara App e SessionList e importa BrowserModule e RouterModule, e os dois componentes dividem esse escopo. À direita, standalone: cada componente traz a própria lista de imports, App importando RouterOutlet e Week, e Week importando WeekSummary.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">NgModule: o módulo decide</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">standalone: cada componente decide</text><line x1=\"360\" y1=\"8\" x2=\"360\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><rect x=\"30\" y=\"34\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"180\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">AppModule</text><text x=\"180\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um escopo, dividido por tudo o que é declarado</text><rect x=\"50\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"190\" y=\"90\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SessionList</text><text x=\"180\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">declarations</text><rect x=\"50\" y=\"168\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"110\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BrowserModule</text><rect x=\"190\" y=\"168\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"250\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RouterModule</text><text x=\"180\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imports</text><rect x=\"390\" y=\"50\" width=\"300\" height=\"82\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">App</text><text x=\"406\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imports:</text><rect x=\"476\" y=\"82\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"524\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">RouterOutlet</text><rect x=\"580\" y=\"82\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"628\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Week</text><rect x=\"390\" y=\"150\" width=\"300\" height=\"82\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">Week</text><text x=\"406\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imports:</text><rect x=\"476\" y=\"182\" width=\"96\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"524\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">WeekSummary</text><text x=\"540\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum módulo em lugar nenhum</text></svg>", "caption": "O standalone levou a lista do que um template pode usar do módulo para o componente."}
```

O componente diz isso no decorator, e o código de inicialização pede um módulo em vez de um
componente:

```
ana@dev:~/legacy$ cat src/app/app.ts
import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  standalone: false,
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('legacy');
}
```

`standalone: false` é a linha que marca o modelo antigo. Em código escrito antes do Angular 19 você
não vai vê-la, porque então esse era o padrão; vai ver `standalone: true` nos componentes que já
tinham migrado.

O `AppRoutingModule` é um módulo cujo único trabalho é configurar o router, com
`RouterModule.forRoot(routes)`, e exportar o `RouterModule` para os templates poderem usar o
`<router-outlet>`. Toda aplicação baseada em módulos tem um, e `forRoot` contra `forChild` é o detalhe
que separa as rotas da raiz das de uma funcionalidade.

## Um componente, declarado

Gere um componente neste projeto e a CLI faz o que um projeto baseado em módulos precisa:

```
ana@dev:~/legacy$ npx ng generate component session-list
CREATE src/app/session-list/session-list.css (0 bytes)
CREATE src/app/session-list/session-list.spec.ts (572 bytes)
CREATE src/app/session-list/session-list.ts (215 bytes)
CREATE src/app/session-list/session-list.html (27 bytes)
UPDATE src/app/app-module.ts (513 bytes)
```

`UPDATE src/app/app-module.ts` é a CLI acrescentando o `SessionList` às `declarations`. Esqueça essa
linha, num projeto em que as pessoas acrescentam componentes à mão, e o template que usa
`<app-session-list>` falha com o mesmo `NG8001` que você viu na seção anterior. Num projeto baseado em
módulos o conserto vai no **módulo**, seja nas `declarations` ou nos `imports` de um módulo que o
exporte, e essa é a primeira pergunta a fazer quando encontrar o erro no trabalho: que módulo declara
isto, e ele o exporta?

Aplicações maiores se dividem em **módulos de funcionalidade**, um por área, e um `SharedModule` que
declara os botões e pipes que todo mundo usa e exporta todos. Funciona, e tem um custo conhecido: todo
componente que importa o `SharedModule` pode usar tudo o que está nele, então ninguém consegue dizer,
olhando um componente, de que ele depende de verdade. Esse custo é o que o standalone veio remover.
