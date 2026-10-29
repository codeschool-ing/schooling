---
title: O planner, como um projeto vazio
version: 1
---

**Um projeto SvelteKit é uma pasta criada por um comando, e tudo neste curso acontece nela.** O
comando é o `sv`, a ferramenta de linha de comando do próprio Svelte, rodada pelo `npx` para que
nada seja instalado globalmente. Rode a partir da sua home:

```sh
npx sv@1.1.1 create planner --template minimal --no-types --no-add-ons --install npm
```

Cada opção responde a uma pergunta que o `sv` faria. `--template minimal` é o menor projeto, com uma
página e nada para apagar. `--no-types` o deixa em JavaScript puro, que a aula 18 converte para
TypeScript. `--no-add-ons` recusa as ferramentas opcionais que ele oferece, como um linter e um
executor de testes, que este curso acrescenta por conta própria quando precisa: Vitest e Playwright
na aula 19. `--install npm` instala os pacotes do projeto na hora. Na primeira vez, o `npx` pergunta
antes de buscar o próprio `sv`; responda `y`. Ele desenha uma caixa de boas-vindas enquanto o npm
trabalha e termina com `You're all set!`.

## O que ele criou

```
ana@dev:~$ cd planner
ana@dev:~/planner$ ls -A
.gitignore
.npmrc
.svelte-kit
.vscode
README.md
jsconfig.json
node_modules
package-lock.json
package.json
src
static
vite.config.js
ana@dev:~/planner$ ls src src/routes src/lib
src:
app.html
lib
routes

src/lib:
assets
index.js

src/routes:
+layout.svelte
+page.svelte
ana@dev:~/planner$ npm pkg get devDependencies
{
  "@sveltejs/adapter-auto": "^8.0.0",
  "@sveltejs/kit": "^3.0.0",
  "@sveltejs/vite-plugin-svelte": "^7.2.0",
  "svelte": "^5.57.1",
  "vite": "^8.3.0"
}
```

**Quatro coisas aqui são suas para editar.** `src/routes` guarda as páginas, uma pasta por endereço,
e `+page.svelte` é a página em `/`. `src/lib` é para todo o resto que você escreve, e a aula 3
começa a enchê-la. `static` guarda arquivos servidos exatamente como são. `package.json` diz que
pacotes o projeto usa. O resto é gerado ou é configuração que você raramente vai tocar: `.svelte-kit`
é a pasta de trabalho do SvelteKit e `node_modules` guarda os pacotes.

O `^` na frente de cada versão quer dizer "esta ou qualquer 5.x posterior", ou 3.x, ou 8.x. Duas
pessoas que instalam em dias diferentes podem receber versões diferentes com o mesmo
`package.json`, e o `package-lock.json` é o que impede isso, registrando as versões exatas
instaladas. Este curso vai um passo além e grava as versões exatas no `package.json` também, para
que o próprio arquivo diga com o que as aulas foram gravadas:

```
ana@dev:~/planner$ npm install --save-dev --save-exact svelte@5.57.2 @sveltejs/kit@3.1.0 vite@8.3.5 @sveltejs/vite-plugin-svelte@7.3.1 @sveltejs/adapter-auto@8.0.0

added 2 packages, removed 1 package, and audited 50 packages in 2s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm config set save-exact true --location=project
ana@dev:~/planner$ cat .npmrc
engine-strict=true
save-exact=true
ana@dev:~/planner$ npm pkg get devDependencies
{
  "@sveltejs/adapter-auto": "8.0.0",
  "@sveltejs/kit": "3.1.0",
  "@sveltejs/vite-plugin-svelte": "7.3.1",
  "svelte": "5.57.2",
  "vite": "8.3.5"
}
```

`npm config set save-exact true --location=project` grava `save-exact=true` no `.npmrc` do próprio
projeto, ao lado do `engine-strict=true` que o `sv` pôs lá, então cada pacote que uma aula
acrescentar depois fica fixado do mesmo jeito sem ninguém lembrar da opção. `engine-strict` faz o npm
recusar instalar um pacote que declara uma versão de Node que você não tem, em vez de só avisar.

Depois, o primeiro commit, como o curso `git` ensinou a fazer:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -qm "A new SvelteKit project" && git log --oneline
8e9c4e9 A new SvelteKit project
```

O `.gitignore` veio do `sv` e já deixa de fora `node_modules` e `.svelte-kit`, então o commit guarda
o que você quer manter e nada que uma reinstalação recria.

## Rodando

`npm run dev` inicia o **servidor de desenvolvimento do Vite**. Ele compila cada componente quando o
navegador pede, e recompila no momento em que você salva o arquivo. Rode num segundo terminal e
deixe rodando pelo resto da aula:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:15:31 PM [vite] (ssr) connected.
7:15:31 PM [vite] (client) Forced re-optimization of dependencies

  VITE v8.3.5  ready in 1411 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

Os `(ssr)` e `(client)` na frente das duas primeiras linhas são os dois ambientes do Vite, um para o
código que renderiza páginas no servidor e outro para o navegador, o primeiro sinal de algo de que
trata a aula 15. A página está em `http://localhost:5173/`. De volta ao primeiro terminal:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- heading "Welcome to SvelteKit" [level=1]
- paragraph:
  - text: Visit
  - link "svelte.dev/docs/kit":
    - /url: https://svelte.dev/docs/kit
  - text: to read the documentation
```

Essa é a página que o `src/routes/+page.svelte` faz. Substitua esse arquivo pela primeira versão do
planner, que não passa de um título e uma frase dentro de um `<main>`:

```html
<!-- src/routes/+page.svelte -->
<main>
	<h1>Study planner</h1>
	<p>Three courses, six sessions, and one week to fit them in.</p>
</main>
```

Salve, e pergunte de novo:

```
ana@dev:~/planner$ look http://localhost:5173/
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph: Three courses, six sessions, and one week to fit them in.
```

**Nada foi reiniciado.** O Vite viu o arquivo mudar, compilou de novo e mandou a versão nova para
qualquer navegador que estava com a página aberta, o que se chama **substituição de módulos a quente**
(hot module replacement). Uma janela de navegador na sua área de trabalho se atualiza enquanto você
salva, sem recarregar, e esse ciclo é como você vai trabalhar pelo resto do curso. O `look` abre um
navegador novo a cada vez, então mostra a página nova de qualquer jeito.
