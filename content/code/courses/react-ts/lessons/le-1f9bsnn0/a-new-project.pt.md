---
title: Um projeto novo, com cada versão fixada
version: 1
---

**Um comando cria o projeto, e mais quatro o tornam reproduzível.** O `create-vite` escreve um app
de React e TypeScript numa pasta nova; o npm então instala o que ele pede, em versões que você fixa à
mão, para que o seu projeto e o destas transcrições sejam feitos do mesmo código.

## Criando

Da sua pasta pessoal:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template react-ts --no-interactive
npm warn exec The following package was not found and will be installed: create-vite@9.3.1

> npx
> cva planner --template react-ts --no-interactive


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/planner...
│
└  Done. Now run:

  cd planner
  npm install
  npm run dev

```

`npm create vite@9.3.1` baixa o pacote `create-vite` nessa versão e o roda. Tudo depois do `--` vai
para ele e não para o npm: a pasta a criar, o modelo, e `--no-interactive`, que aceita os padrões em
vez de fazer perguntas. Sem a versão, o npm buscaria o `create-vite` mais novo no dia em que você
digitasse, e o modelo dele talvez não fosse o mesmo contra o qual este curso foi escrito.

Entre com `cd planner` e veja o que ele escreveu:

```
ana@dev:~/planner$ ls -A
.gitignore
.oxlintrc.json
README.md
index.html
package.json
public
src
tsconfig.app.json
tsconfig.json
tsconfig.node.json
vite.config.ts
```

`index.html` é a página, e `src/` é o app; `src/main.tsx` era o arquivo da primeira seção. `public/`
guarda arquivos servidos exatamente como estão. Os três `tsconfig` configuram o TypeScript, um para
o app e um para a configuração do build, unidos pelo terceiro; a aula 19 os lê. `vite.config.ts`
configura o Vite, e `.oxlintrc.json` configura o Oxlint, um linter que a aula 23 apresenta.

## O que ele pede, e o que isso significa

```
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "oxlint",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^19.3.1",
    "react-dom": "^19.3.1"
  },
  "devDependencies": {
    "@types/node": "^24.19.2",
    "@types/react": "^19.3.0",
    "@types/react-dom": "^19.3.0",
    "@vitejs/plugin-react": "^6.1.2",
    "oxlint": "^1.88.0",
    "typescript": "~6.0.3",
    "vite": "^8.3.4"
  }
}
```

Dois pacotes rodam no navegador, `react` e `react-dom`, em `dependencies`. Os sete em
`devDependencies` são ferramentas que rodam no seu computador enquanto você trabalha e nunca chegam a
um visitante.

Os caracteres na frente dos números são faixas, e a aula 21 do `javascript` os explicou. **`^19.3.1`
quer dizer qualquer 19 a partir de 19.3.1**, então um `npm install` no mês que vem pode buscar a
19.4. `~6.0.3` quer dizer qualquer 6.0 a partir de 6.0.3. Uma faixa é o modelo sendo educado: ela
deixa você receber correções sem pedir. Também quer dizer que duas pessoas que instalam o mesmo
`package.json` em dias diferentes podem receber código diferente, e um curso cujas transcrições
precisam bater com as suas não pode ter isso.

Uma das entradas também está na versão errada para este computador. O `@types/node` descreve as
interfaces do próprio Node para o TypeScript, e o modelo pede as descrições do Node 24, enquanto este
curso roda o Node 22. Elas só descrevem a configuração do build, então nada quebra hoje, e a versão
certa continua sendo a que corresponde ao Node que você roda.

## Fixando

Primeiro, diga ao npm para escrever versões exatas neste projeto daqui em diante. `--location=project`
põe a configuração num arquivo desta pasta, o `.npmrc`, para que ela viaje com o projeto e não mude
o comportamento do npm em nenhum outro lugar:

```
ana@dev:~/planner$ npm config set save-exact true --location=project
ana@dev:~/planner$ cat .npmrc
save-exact=true
```

Depois instale cada pacote na versão que este curso usa. Dar o nome das versões substitui as faixas:

```
ana@dev:~/planner$ npm install react@19.3.1 react-dom@19.3.1

added 27 packages, and audited 28 packages in 12s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm install --save-dev typescript@6.0.3 vite@8.3.5 @vitejs/plugin-react@6.1.2 @types/react@19.3.0 @types/react-dom@19.3.0 @types/node@22.20.5 oxlint@1.88.0

added 2 packages, changed 4 packages, and audited 30 packages in 11s

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O primeiro `npm install` leu o `package.json` inteiro, além dos dois nomes da linha dele, e por isso
instalou tudo o que o modelo pedia. O segundo trocou quatro desses pacotes, da versão que a faixa
tinha escolhido para a indicada, entre eles o `@types/node`. Agora o arquivo diz exatamente uma
versão para cada um:

```
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "oxlint",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "19.3.1",
    "react-dom": "19.3.1"
  },
  "devDependencies": {
    "@types/node": "22.20.5",
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "@vitejs/plugin-react": "6.1.2",
    "oxlint": "1.88.0",
    "typescript": "6.0.3",
    "vite": "8.3.5"
  }
}
ana@dev:~/planner$ npm ls
planner@0.0.0 /home/ana/planner
├── @types/node@22.20.5
├── @types/react-dom@19.3.0
├── @types/react@19.3.0
├── @vitejs/plugin-react@6.1.2
├── oxlint@1.88.0
├── react-dom@19.3.1
├── react@19.3.1
├── typescript@6.0.3
└── vite@8.3.5

```

**O React é o 19.3.1, o TypeScript o 6.0.3 e o Vite o 8.3.5**, e cada aula que acrescenta um pacote
o acrescenta do mesmo jeito. O TypeScript mais novo no npm no dia desta gravação era o 7.0.2; o
modelo pede o 6.0, e o curso fica com a escolha do modelo em vez de adivinhar melhor.

O `package.json` dá o nome dos seus pacotes, e esses pacotes têm pacotes próprios: 30 ao todo, a
partir de duas linhas de `dependencies`. **O `package-lock.json` é o arquivo que registra cada um
deles**, na versão instalada e com uma soma de verificação do conteúdo:

```
ana@dev:~/planner$ ls -A
.gitignore
.npmrc
.oxlintrc.json
README.md
index.html
node_modules
package-lock.json
package.json
public
src
tsconfig.app.json
tsconfig.json
tsconfig.node.json
vite.config.ts
```

**Faça commit do lockfile junto com o projeto, e nunca do `node_modules`**, que o `.gitignore` do
modelo já deixa de fora. Quem clonar o projeto roda então `npm ci`, que instala exatamente o que o
lockfile diz e se recusa a começar se ele discordar do `package.json`.

## Rodando

O servidor de desenvolvimento fica rodando enquanto você trabalha, então dê a ele um terminal só
dele:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 301 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Abra `http://localhost:5173/` no seu navegador.** Você recebe a página do modelo: dois logos, um
título, e um botão que conta quantas vezes foi apertado. Deixe o servidor rodando. Quando você salva
um arquivo em `src/`, a página no navegador muda sem recarregar, e a aula 20 explica como.

A página que o Vite manda não é bem o `index.html` da pasta. De um segundo terminal:

```
ana@dev:~/planner$ curl -s http://localhost:5173/ | head -n 12
<!doctype html>
<html lang="en">
  <head>
    <script type="module">import { injectIntoGlobalHook } from "/@react-refresh";
injectIntoGlobalHook(window);
window.$RefreshReg$ = () => {};
window.$RefreshSig$ = () => (type) => type;</script>

    <script type="module" src="/@vite/client"></script>

    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
```

O servidor de desenvolvimento acrescentou dois scripts no topo. O `/@vite/client` mantém uma conexão
aberta com o servidor e é avisado quando um arquivo muda; o `/@react-refresh` deixa a versão nova de
um componente substituir a antiga na página que está rodando, sem perder o que está na tela. Nenhum
dos dois existe no build que você publicaria, que a aula 20 gera e compara.
