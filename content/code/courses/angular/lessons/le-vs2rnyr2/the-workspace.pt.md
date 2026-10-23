---
title: O que o ng new escreveu
version: 1
---

**Um projeto Angular é um punhado de arquivos de configuração em cima e uma aplicação em `src/`.**
Você vai editar quase nada lá em cima e quase tudo em `src/`, e saber qual arquivo faz o quê poupa a
tarde que alguém passa procurando uma configuração no lugar errado.

```
ana@dev:~/planner$ ls -A
.editorconfig
.git
.gitignore
.npmrc
.prettierrc
.vscode
README.md
angular.json
node_modules
package-lock.json
package.json
public
src
tsconfig.app.json
tsconfig.json
tsconfig.spec.json
```

## Os arquivos de cima

| arquivo | para que serve |
|---|---|
| `package.json`, `package-lock.json`, `.npmrc` | os pacotes, as versões exatas deles, e como o npm os instala; a seção anterior |
| `angular.json` | a configuração da própria CLI: o que `ng build`, `ng serve` e `ng test` fazem |
| `tsconfig.json`, `tsconfig.app.json`, `tsconfig.spec.json` | as configurações do TypeScript, para tudo, para a aplicação e para os testes |
| `.editorconfig`, `.prettierrc` | indentação e aspas, para o seu editor e para o Prettier |
| `.vscode/` | sugestões para o Visual Studio Code: a extensão da aula 1, e como rodar e depurar |
| `.gitignore` | o que o git deixa de fora: `node_modules`, a saída do build, caches |
| `README.md` | uma página com os comandos abaixo, para quem abrir o projeto em seguida |

O `angular.json` é longo, e quase tudo nele são valores padrão escritos por extenso. O centro dele são
três **targets**, um por comando, cada um nomeando o **builder**, o programa que faz o trabalho:

```
ana@dev:~/planner$ node -e "console.log(Object.keys(require('./angular.json').projects.planner.architect))"
[ 'build', 'serve', 'test' ]
```

O `ng build` roda o target `build`, o `ng serve` o target `serve`, e assim por diante. Um target tem
**configurations**: `production` e `development` para o build, com respostas diferentes a perguntas
como se deve minificar. As seções abaixo usam cada uma.

O `tsconfig.json` abre com `"strict": true`, a opção que a aula 1 passou ao `tsc` à mão, e as
`angularCompilerOptions` dele ligam o `strictTemplates`: **os templates têm os tipos conferidos com o
mesmo rigor do código**, coisa em que a aula 4 se apoia.

## A aplicação

```
ana@dev:~/planner$ find src public -type f | sort
public/favicon.ico
src/app/app.config.ts
src/app/app.css
src/app/app.html
src/app/app.routes.ts
src/app/app.spec.ts
src/app/app.ts
src/index.html
src/main.ts
src/styles.css
```

O navegador pede uma página, `src/index.html`, e ela está quase vazia:

```
ana@dev:~/planner$ cat src/index.html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Planner</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
</head>
<body>
  <app-root></app-root>
</body>
</html>
```

`<app-root></app-root>` não é um HTML que o navegador conheça. É o lugar onde a aplicação se desenha,
e o nome vem do `selector` do componente raiz. Nada mais na página é escrito por você; o build
acrescenta as tags `<script>` e `<link>`.

O `src/main.ts` é o primeiro código que roda:

```
ana@dev:~/planner$ cat src/main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
```

O `bootstrapApplication` recebe o componente raiz, `App`, e uma configuração, constrói a aplicação, e
desenha o `App` onde está o `<app-root>`. Se falhar, o `catch` imprime o motivo no console do
navegador, que é o primeiro lugar a olhar quando uma página fica em branco.

A configuração fica num arquivo próprio:

```
ana@dev:~/planner$ cat src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes)
  ]
};
```

`providers` é uma lista de coisas que a aplicação pode receber quando pede: o router, aqui, e um
ouvinte que manda os erros que ninguém tratou para o tratador de erros do Angular. A aula 10 é sobre o
que é um provider; por enquanto, leia a lista como as configurações da aplicação, escritas como
chamadas de função.

E o próprio componente raiz, que a aula 3 desmonta linha a linha:

```
ana@dev:~/planner$ cat src/app/app.ts
import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('planner');
}
```

`templateUrl` e `styleUrl` apontam para os dois arquivos ao lado, `app.html` e `app.css`. O `app.html`
é a página de boas-vindas, com todos os seus 20 kilobytes, e a próxima seção a substitui. O
`app.spec.ts` é o teste deste componente, e a seção sobre o `ng test` o quebra de propósito. O
`app.routes.ts` é a lista de endereços do router, vazia até a aula 17. O `public/` é copiado para o
build como está; os dados do planner vão para lá na próxima seção.
