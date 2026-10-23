---
title: Um projeto, em versões exatas
version: 1
---

**O `ng new` escreve um projeto inteiro num comando: a configuração, o primeiro componente, um teste,
e a lista de pacotes de que ele precisa.** Depois ele roda o npm para instalá-los. No dia em que este
curso foi gravado, a segunda metade falhou, e vale ver a falha, porque ela é do tipo que você vai
encontrar de novo num projeto de verdade.

## Pedindo um

A CLI ainda não está instalada em lugar nenhum, então o `npx` a busca para este comando. A versão vem
no nome, `@21.2.28`, pelo motivo que a aula 1 deu:

```
ana@dev:~$ npx @angular/cli@21.2.28 new planner --style=css --ssr=false --zoneless --ai-config=none
npm warn exec The following package was not found and will be installed: @angular/cli@21.2.28
CREATE planner/.prettierrc (161 bytes)
CREATE planner/README.md (1461 bytes)
CREATE planner/.editorconfig (314 bytes)
CREATE planner/.gitignore (622 bytes)
CREATE planner/angular.json (1906 bytes)
CREATE planner/package.json (784 bytes)
CREATE planner/tsconfig.json (957 bytes)
CREATE planner/tsconfig.app.json (429 bytes)
CREATE planner/tsconfig.spec.json (441 bytes)
CREATE planner/.vscode/extensions.json (130 bytes)
CREATE planner/.vscode/launch.json (470 bytes)
CREATE planner/.vscode/mcp.json (179 bytes)
CREATE planner/.vscode/tasks.json (978 bytes)
CREATE planner/src/main.ts (222 bytes)
CREATE planner/src/index.html (293 bytes)
CREATE planner/src/styles.css (80 bytes)
CREATE planner/src/app/app.css (0 bytes)
CREATE planner/src/app/app.spec.ts (674 bytes)
CREATE planner/src/app/app.ts (289 bytes)
CREATE planner/src/app/app.html (20144 bytes)
CREATE planner/src/app/app.config.ts (313 bytes)
CREATE planner/src/app/app.routes.ts (77 bytes)
CREATE planner/public/favicon.ico (15086 bytes)
- Installing packages (npm)...
npm error Cannot read properties of null (reading 'edgesOut')
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-23T22_43_26_493Z-debug-0.log
✖ Package install failed, see above.
The Schematic workflow failed. See above.
```

As quatro opções respondem as perguntas que o `ng new` faria no terminal: CSS puro para os estilos,
sem renderização no servidor por enquanto (a aula 23 acrescenta), sem zone.js (a aula 7 explica o que
era isso), e sem arquivos de instrução para assistentes de código com IA. Num terminal, o `npx`
pergunta antes `Ok to proceed? (y)` para baixar a CLI; a gravação rodou sem terminal, e é por isso que
a transcrição mostra um aviso no lugar.

Cada linha `CREATE` é um arquivo escrito. Depois `Installing packages (npm)...`, e o npm parou com uma
mensagem que não cita nenhum dos seus pacotes.

## O que quebrou, e o que não precisa de conserto

`Cannot read properties of null (reading 'edgesOut')` não é um problema do projeto. É um erro de
JavaScript dentro do próprio npm, na parte que resolve as **dependências peer**: pacotes que outro
pacote espera que você tenha instalado ao lado dele, em vez de trazê-los junto. O Vitest, o executor
de testes, declara uma dúzia de peers opcionais, uma delas declara as suas, e o npm 10.9.4, a versão
que veio com o Node 22.22.0, tropeça na cadeia. O npm 11 não tropeça, e o Node 22.22.0 não vem com o
npm 11, então este curso contorna o problema em vez de instalar um segundo npm.

O contorno é uma configuração: **`legacy-peer-deps`** diz ao npm para não instalar dependências peer
por conta própria, o que pula a etapa que quebra. Ela tem um custo, e aqui ele é pequeno: o npm deixa
de acrescentar uma peer que você esqueceu. Todo pacote que este projeto usa já está listado no
`package.json` dele, então não há nada para esquecer. Os arquivos que o `ng new` escreveu estão todos
lá; entre na pasta (`cd planner` antes) e salve a configuração num arquivo chamado `.npmrc`, que o npm
lê em todo comando rodado dentro do projeto:

```ini
# .npmrc
legacy-peer-deps=true
save-exact=true
```

O `save-exact` é a segunda linha pelo mesmo motivo que a pasta de TypeScript da aula 1 usou
`--save-exact`: um pacote acrescentado depois é gravado como `1.2.3` e não `^1.2.3`.

## Versões exatas

O `ng new` escreveu `"@angular/core": "^21.2.0"`, e o `^` quer dizer *21.2.0 ou qualquer coisa mais
nova antes do 22*. Duas pessoas instalando com uma semana de diferença recebem código diferente. A
orientação desta trilha inteira é o contrário: toda versão exata, para que as suas transcrições batam
com estas. Troque o `package.json` por este, que traz as versões com que o curso foi gravado:

```schooling-example
{"language": "json", "file": "package.json", "parts": [
 {"code": "{\n  \"name\": \"planner\",\n  \"version\": \"0.0.0\",\n  \"scripts\": {\n    \"ng\": \"ng\",\n    \"start\": \"ng serve\",\n    \"build\": \"ng build\",\n    \"watch\": \"ng build --watch --configuration development\",\n    \"test\": \"ng test\"\n  },", "note": "O nome do projeto, e cinco atalhos. `npm start` roda `ng serve`, `npm test` roda `ng test`; este curso digita `npx ng ...` no lugar, o que roda a mesma CLI local e deixa à vista o que está rodando."},
 {"code": "  \"private\": true,\n  \"packageManager\": \"npm@10.9.4\",", "note": "`private` impede que ele seja publicado no npm por acidente. `packageManager` registra que gerenciador de pacotes, e em que versão, o projeto espera."},
 {"code": "  \"dependencies\": {\n    \"@angular/common\": \"21.2.25\",\n    \"@angular/compiler\": \"21.2.25\",\n    \"@angular/core\": \"21.2.25\",\n    \"@angular/forms\": \"21.2.25\",\n    \"@angular/platform-browser\": \"21.2.25\",\n    \"@angular/router\": \"21.2.25\",\n    \"rxjs\": \"7.8.2\",\n    \"tslib\": \"2.8.1\"\n  },", "note": "O que a aplicação precisa quando roda no navegador: os pacotes do framework, todos na 21.2.25, e as duas bibliotecas sobre as quais o próprio Angular é construído."},
 {"code": "  \"devDependencies\": {\n    \"@angular/build\": \"21.2.28\",\n    \"@angular/cli\": \"21.2.28\",\n    \"@angular/compiler-cli\": \"21.2.25\",\n    \"jsdom\": \"28.1.0\",\n    \"prettier\": \"3.9.10\",\n    \"typescript\": \"5.9.3\",\n    \"vitest\": \"4.1.12\"\n  }\n}", "note": "O que só o build e os testes precisam: a CLI e o sistema de build dela na 21.2.28, o compilador, o TypeScript, o executor de testes Vitest com o jsdom, uma imitação de navegador onde os testes rodam, e o Prettier, que formata código."}
]}
```

Os pacotes do framework e os da CLI têm números diferentes de propósito: são lançados pelo mesmo time
no mesmo calendário, mas o número de patch de cada pacote anda quando aquele pacote muda.

```
ana@dev:~/planner$ npm install

added 470 packages, and audited 471 packages in 17s

found 0 vulnerabilities
ana@dev:~/planner$ npm ls --depth=0
planner@0.0.0 /home/ana/planner
├── @angular/build@21.2.28
├── @angular/cli@21.2.28
├── @angular/common@21.2.25
├── @angular/compiler-cli@21.2.25
├── @angular/compiler@21.2.25
├── @angular/core@21.2.25
├── @angular/forms@21.2.25
├── @angular/platform-browser@21.2.25
├── @angular/router@21.2.25
├── jsdom@28.1.0
├── prettier@3.9.10
├── rxjs@7.8.2
├── tslib@2.8.1
├── typescript@5.9.3
└── vitest@4.1.12

ana@dev:~/planner$ du -sh node_modules
318M	node_modules
```

**O `package-lock.json` é o arquivo a guardar.** O `npm install` o escreveu ao lado do `package.json`,
com a versão exata de cada um daqueles pacotes, os que você listou e os que eles trouxeram. Rode
`npm ci` em outra máquina e ele reconstrói o `node_modules` a partir do lockfile e de mais nada, que é
como um segundo computador, ou um servidor de build, recebe o mesmo código que você tem. O `du` diz
quanto isso custa em disco, e o número é o que a tabela da aula 1 arredondou.

## Um repositório

O `ng new` transforma a pasta num repositório git quando termina sem erro. Este parou no meio, então
faça você mesmo, com o nome e o endereço que você deu ao git no curso `git`:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "A new Angular project"
ana@dev:~/planner$ git show --stat --oneline | tail -1
 25 files changed, 9394 insertions(+)
ana@dev:~/planner$ wc -l package-lock.json
8603 package-lock.json
```

O `.gitignore`, que o `ng new` escreveu, já deixa de fora o `node_modules` e a saída do build, então o
commit guarda o que a CLI gerou, o que você escreveu, e o lockfile: 25 arquivos, e 8.603 daquelas
9.394 linhas são o `package-lock.json`.
