---
title: O que o build grava
version: 1
---

**`npm run build` transforma o projeto na pasta que um host serve, e nada além dela vai para o ar.** O
script no `package.json` é `tsc && vite build`: primeiro o compilador do TypeScript confere todos os
tipos e não grava nada, depois o Vite empacota. O `&&` quer dizer que o segundo só roda se o primeiro deu
certo, então um erro de tipo para o build antes de um único arquivo ser gravado.

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 7 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                 0.48 kB │ gzip: 0.31 kB
dist/assets/index-DXSNtWuR.css  0.18 kB │ gzip: 0.15 kB
dist/assets/index-BVi82VJx.js   3.04 kB │ gzip: 1.41 kB

✓ built in 240ms
```

O Vite imprimiu cada arquivo que gravou, o tamanho dele e o tamanho comprimido com gzip, que é mais
perto do que viaja pela rede, já que todo host comprime texto antes de enviar. O app inteiro tem uns 3 kB
de JavaScript.

## Quatro arquivos

```
ana@dev:~/planner$ find dist -type f | sort
dist/assets/index-BVi82VJx.js
dist/assets/index-DXSNtWuR.css
dist/courses.json
dist/favicon.svg
dist/index.html
```

`courses.json` e `favicon.svg` vieram de `public/`, copiados como estavam. O script e a folha de estilo
são novos: cada módulo que o app importa, `main.ts`, `planner.ts`, `view.ts` e o CSS, foi parar num
arquivo JavaScript e num arquivo CSS. E o `index.html` não é o que você escreveu:

```
ana@dev:~/planner$ cat dist/index.html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-BVi82VJx.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-DXSNtWuR.css">
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

O `<script>` que apontava para `/src/main.ts` agora aponta para o pacote, e um `<link>` para a folha de
estilo foi acrescentado. **A página cita os arquivos pelos nomes novos**, então ela precisa ser construída
com eles e servida com eles; copiar um `dist/index.html` de um build ao lado dos assets de outro dá uma
página que pede arquivos que não estão lá.

## O nome muda quando o conteúdo muda

Os oito caracteres antes de `.js` são um hash do conteúdo do arquivo. Construa duas vezes sem mudar nada e
os nomes são os mesmos; mude uma palavra do código e só o nome do script muda, enquanto a folha de estilo
fica com o dela:

```
ana@dev:~/planner$ ls dist/assets
index-BVi82VJx.js
index-DXSNtWuR.css
ana@dev:~/planner$ npm run build > /dev/null && ls dist/assets
index-BVi82VJx.js
index-DXSNtWuR.css
ana@dev:~/planner$ sed -i 's/All courses/Every course/' src/view.ts
ana@dev:~/planner$ npm run build > /dev/null && ls dist/assets
index-DXSNtWuR.css
index-j59TGUSA.js
ana@dev:~/planner$ git checkout src/view.ts
Updated 1 path from the index
```

É isso que permite a um host dizer aos navegadores que guardem um arquivo por um ano: uma versão nova é
um nome novo, então uma cópia velha nunca é confundida com a atual. Quais cabeçalhos dizem isso, e por
que o `index.html` recebe o tratamento oposto, é a aula 9 de front-performance. O que esta aula precisa
disso é a consequência para um deploy: **uma versão publicada é a pasta inteira de uma vez**, nunca um
arquivo dela.

## Um erro de tipo o interrompe

A conferência de tipos é o primeiro passo por um motivo. Mude um tipo no `planner.ts`, digamos o
`minutes` de uma sessão para `string`, e construa:

```
ana@dev:~/planner$ sed -i 's/minutes: number;/minutes: string;/' src/planner.ts
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

src/planner.ts(17,11): error TS2322: Type 'Session | { id: number; course: string; date: string; minutes: number; done: false; }' is not assignable to type 'Session'.
  Type '{ id: number; course: string; date: string; minutes: number; done: false; }' is not assignable to type 'Session'.
    Types of property 'minutes' are incompatible.
      Type 'number' is not assignable to type 'string'.
src/planner.ts(17,44): error TS2322: Type 'string | number' is not assignable to type 'string'.
  Type 'number' is not assignable to type 'string'.
src/planner.ts(35,58): error TS2769: No overload matches this call.
  Overload 1 of 3, '(callbackfn: (previousValue: Session, currentValue: Session, currentIndex: number, array: Session[]) => Session, initialValue: Session): Session', gave the following error.
    Type 'string' is not assignable to type 'Session'.
  Overload 2 of 3, '(callbackfn: (previousValue: number, currentValue: Session, currentIndex: number, array: Session[]) => number, initialValue: number): number', gave the following error.
    Type 'string' is not assignable to type 'number'.
src/planner.ts(36,12): error TS2322: Type 'Session' is not assignable to type 'number'.
src/planner.ts(36,32): error TS2322: Type 'Session' is not assignable to type 'number'.
ana@dev:~/planner$ git checkout src/planner.ts
Updated 1 path from the index
```

O `tsc` achou cinco erros, nas três linhas que constroem ou somam os minutos de uma sessão, e saiu com
erro, então o `vite build` nunca rodou e `dist/` continua com o último build bom. **Esse é o
comportamento que você quer de toda máquina que constrói o seu site**: um commit quebrado não gera
deploy, em vez de gerar um deploy quebrado. A aula 3 faz a mesma conferência rodar em todo push, numa
máquina que não é a sua.

`vite build` sozinho não confere tipos. Ele os remove e empacota o que sobra, e é por isso que um
projeto cujo script é só `vite build` pode publicar código que o editor sublinha em vermelho.
