---
title: Acrescentando o Angular Material
version: 1
---

**O Angular Material é a biblioteca de componentes prontos da equipe do Angular: botões, caixas de
seleção, diálogos, menus, seletores de data, tabelas, construídos segundo o sistema Material Design e
os padrões de acessibilidade de que cada tipo de controle precisa.** Embaixo dele fica o **CDK**, o
Component Dev Kit: o comportamento sem a aparência, que esta aula também usa sozinho. Nenhum dos dois
faz parte de um projeto novo; os dois são pacotes, acrescentados em versões exatas como todo o resto.

O tamanho da aplicação antes, para comparar no fim:

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'Initial total|courses-routes'
                      | Initial total  | 294.50 kB |                81.56 kB
chunk-RJNJDY6E.js     | courses-routes |  44.80 kB |                10.34 kB
```

O `ng add` instala um pacote e roda a configuração dele. A versão é a que combina com o Angular 21 do
projeto, escrita por inteiro. O `--skip-confirmation` e o `--interactive=false` aceitam os padrões em
vez de perguntar, que é o que uma transcrição precisa; num terminal seu, as perguntas são sobre as
cores e podem ser respondidas de qualquer jeito:

```
ana@dev:~/planner$ npx ng add @angular/material@21.2.14 --skip-confirmation --interactive=false
❯ Determining Package Manager
› Using package manager: npm
✔ Determining Package Manager
❯ Loading package information
✔ Loading package information
❯ Installing package
✔ Installing package
UPDATE package.json (845 bytes)
- Installing packages (npm)...
✔ Packages installed successfully.
CREATE src/material-theme.scss (1179 bytes)
UPDATE angular.json (2183 bytes)
UPDATE src/index.html (626 bytes)
```

```
ana@dev:~/planner$ git status --short
 M angular.json
 M package-lock.json
 M package.json
 M src/index.html
?? src/material-theme.scss
```

Dois pacotes no `package.json`, `@angular/material` e `@angular/cdk`, em versões exatas porque o
`.npmrc` do projeto diz `save-exact`. Um tema, `src/material-theme.scss`, acrescentado aos estilos do
build no `angular.json`:

```
ana@dev:~/planner$ cat src/material-theme.scss
// Include theming for Angular Material with `mat.theme()`.
// This Sass mixin will define CSS variables that are used for styling Angular Material
// components according to the Material 3 design spec.
// Learn more about theming and how to use it for your application's
// custom components at https://material.angular.dev/guide/theming
@use '@angular/material' as mat;

html {
  height: 100%;
  @include mat.theme(
    (
      color: (
        primary: mat.$azure-palette,
        tertiary: mat.$blue-palette,
      ),
      typography: Roboto,
      density: 0,
    )
  );
}

body {
  // Default the application to a light color theme. This can be changed to
  // `dark` to enable the dark color theme, or to `light dark` to defer to the
  // user's system settings.
  color-scheme: light;

  // Set a default background, font and text colors for the application using
  // Angular Material's system-level CSS variables. Learn more about these
  // variables at https://material.angular.dev/guide/system-variables
  background-color: var(--mat-sys-surface);
  color: var(--mat-sys-on-surface);
  font: var(--mat-sys-body-medium);

  // Reset the user agent margin.
  margin: 0;
  height: 100%;
}
```

O `mat.theme` transforma três escolhas, cores, uma fonte e uma densidade, nas propriedades CSS
customizadas que todo componente do Material lê, `--mat-sys-surface`, `--mat-sys-on-surface` e as
outras, e a regra do `body` as usa para a página. É Sass, que o build do Angular lê sem precisar de
mais nada.

**E o `index.html`, que agora carrega duas folhas de estilo de `fonts.googleapis.com`.** Toda visita ao
planner pediria uma fonte ao Google, contando a ele quem abriu o planner e quando, e um planner sem
conexão ficaria esperando por ela. O tema cai na fonte sem serifa do próprio sistema sem elas, então o
planner mantém o `index.html` como estava:

```
ana@dev:~/planner$ git checkout -- src/index.html
```

Uma fonte que você queira pode ser instalada com a aplicação, como um arquivo em `public/` e uma regra
`@font-face`, servida da mesma origem que todo o resto. O servidor de desenvolvimento lê o
`angular.json` quando inicia, então pare-o com `Ctrl-C` e inicie o `npx ng serve` de novo.
