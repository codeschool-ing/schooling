---
title: O planner, criado
version: 1
---

**Um projeto Vue é uma pasta que uma ferramenta chamada create-vue escreve para você, e este curso faz
crescer uma delas, um planner de estudos, desta seção até a aula 21.** O planner é pequeno de
propósito. Ele lista os cursos que você está fazendo, abre um deles, deixa você adicionar sessões de
estudo com uma data e uma duração, marca as que foram feitas e soma a semana. Cada ideia do curso chega
como algo de que o planner precisa.

## create-vue

O `npm create vue` baixa o create-vue e o roda. Chamado sem opções, ele faz uma série de perguntas;
chamado com um recurso nomeado, não pergunta nada. O `--default` dele dá um projeto TypeScript, que é
o assunto da aula 16, então este curso nomeia o único recurso que quer: o **Prettier**, um programa
que formata o seu código, e o jeito mais barato de dizer "JavaScript, por favor" sem responder a
perguntas. O `--bare` deixa de fora os componentes de exemplo com que um projeto novo começaria.

```
ana@dev:~/vue$ npm create vue@3.24.0 -- --prettier --bare planner
npm warn exec The following package was not found and will be installed: create-vue@3.24.0

> npx
> create-vue --prettier --bare planner

┌  Vue.js - The Progressive JavaScript Framework

Scaffolding project in /home/ana/vue/planner...
│
└  Done. Now run:

   cd planner
   npm install
   npm run format
   npm run dev

| Optional: Initialize Git in your project directory with:

   git init && git add -A && git commit -m "initial commit"
```

O `@3.24.0` fixa a versão do próprio create-vue, e o `--` entrega tudo o que vem depois dele ao
create-vue em vez de ao npm. Isto é o que ele escreveu:

```
ana@dev:~/vue/planner$ find . -type f | sort
./.gitignore
./.prettierrc.json
./.vscode/extensions.json
./.vscode/settings.json
./README.md
./index.html
./jsconfig.json
./package.json
./public/favicon.ico
./src/App.vue
./src/main.js
./vite.config.js
ana@dev:~/vue/planner$ cat package.json
{
  "name": "planner",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "format": "prettier --write --experimental-cli src/"
  },
  "dependencies": {
    "vue": "^3.5.42"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^6.0.8",
    "prettier": "3.9.6",
    "vite": "^8.2.2",
    "vite-plugin-vue-devtools": "^8.2.1"
  },
  "engines": {
    "node": "^22.18.0 || >=24.12.0"
  }
}
```

**Olhe as versões.** `^3.5.42` quer dizer "3.5.42 ou qualquer 3.x posterior", então duas pessoas que
rodem `npm install` com um mês de diferença podem acabar com Vues diferentes. Essa é a conveniência
que o npm escolheu por padrão, e este curso a desliga: cada pacote é fixado na versão exata com que
foi gravado. Troque o `package.json` por este:

```schooling-example
{"language": "json", "file": "package.json", "parts": [
 {"code": "{\n  \"name\": \"planner\",\n  \"version\": \"0.0.0\",\n  \"private\": true,\n  \"type\": \"module\",\n  \"scripts\": {\n    \"dev\": \"vite\",\n    \"build\": \"vite build\",\n    \"preview\": \"vite preview\",\n    \"format\": \"prettier --write --experimental-cli src/\"\n  },", "note": "Nome, scripts e tipo de módulo ficam como o create-vue os escreveu. O `npm run dev` roda `vite`."},
 {"code": "  \"dependencies\": {\n    \"vue\": \"3.5.44\"\n  },", "note": "O próprio Vue, fixado em 3.5.44: sem circunflexo, então nenhuma versão posterior entra escondida."},
 {"code": "  \"devDependencies\": {\n    \"@vitejs/plugin-vue\": \"6.0.10\",\n    \"prettier\": \"3.9.6\",\n    \"vite\": \"8.3.5\"\n  },", "note": "As ferramentas que constroem o projeto e nunca chegam a um navegador. O vite-plugin-vue-devtools saiu; o próximo parágrafo diz por quê."},
 {"code": "  \"engines\": {\n    \"node\": \"^22.18.0 || >=24.12.0\"\n  }\n}", "note": "As versões do Node em que o Vite 8 roda. O 22.22.0 está dentro da primeira faixa."}
]}
```

**O create-vue também acrescentou um plugin que põe as ferramentas de desenvolvedor do Vue dentro da
página.** Ele é útil, e enche toda página de requisições e de um botão flutuante que não têm nada a
ver com o seu código. Este curso o deixa de fora, e o arquivo de configuração perde a linha que o
carregava. As mesmas ferramentas existem como extensão de navegador, *Vue.js devtools*, para Chrome e
Firefox, se você as quiser no seu próprio navegador.

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import { fileURLToPath, URL } from 'node:url'\n\nimport { defineConfig } from 'vite'\nimport vue from '@vitejs/plugin-vue'", "note": "A configuração do Vite é um módulo JavaScript. O `defineConfig` só ajuda um editor a sugerir as opções."},
 {"code": "// https://vite.dev/config/\nexport default defineConfig({\n  plugins: [vue()],", "note": "O único plugin que sobrou ensina ao Vite o que é um arquivo `.vue`. A aula 17 o abre."},
 {"code": "  resolve: {\n    alias: {\n      '@': fileURLToPath(new URL('./src', import.meta.url)),\n    },\n  },\n})", "note": "`@` é um nome curto para a pasta `src`, então `import x from '@/planner.js'` funciona de qualquer profundidade."}
]}
```

E a página que o navegador abre primeiro, agora com um idioma e um título de verdade:

```schooling-example
{"language": "html", "file": "index.html", "parts": [
 {"code": "<!DOCTYPE html>\n<html lang=\"en\">\n  <head>\n    <meta charset=\"UTF-8\">\n    <link rel=\"icon\" href=\"/favicon.ico\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>Study planner</title>\n  </head>", "note": "O `lang=\"en\"` diz a um leitor de tela que voz usar. O create-vue o deixou vazio."},
 {"code": "  <body>\n    <div id=\"app\"></div>\n    <script type=\"module\" src=\"/src/main.js\"></script>\n  </body>\n</html>", "note": "O Vue vai assumir este único elemento. Tudo o que você escrever acaba dentro dele."}
]}
```

## Instalando e iniciando

```
ana@dev:~/vue/planner$ npm install

added 36 packages, and audited 37 packages in 8s

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/planner$ ls
README.md
index.html
jsconfig.json
node_modules
package-lock.json
package.json
public
src
vite.config.js
ana@dev:~/vue/planner$ npm ls
planner@0.0.0 /home/ana/vue/planner
├── @vitejs/plugin-vue@6.0.10
├── prettier@3.9.6
├── vite@8.3.5
└── vue@3.5.44
```

O `npm install` leu o `package.json`, baixou esses pacotes e tudo de que eles precisam para o
`node_modules` e escreveu o **`package-lock.json`**, que registra a versão exata de cada um deles,
inclusive os que você não nomeou. **Guarde o lockfile com o seu projeto e faça commit dele**: é ele
que faz o próximo `npm install`, em qualquer máquina, baixar a mesma árvore. O `npm ls` mostra o topo
dessa árvore, e cada versão é a que foi fixada acima.

Agora o servidor de desenvolvimento. Inicie-o num **segundo terminal**, porque ele continua rodando
até você apertar Ctrl-C:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 430 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

O **Vite** é o programa que serve o projeto enquanto você trabalha nele; a aula 17 trata do que ele
faz e de por que o autor do Vue o escreveu. Abra `http://localhost:5173/` no seu próprio navegador e
você verá um título. No primeiro terminal, o `look` abre o mesmo endereço no Chromium e imprime o
texto da página:

```
ana@dev:~/vue/planner$ look http://localhost:5173/
[vite] connecting...
[vite] connected.
== the text of #app
You did it!

Visit vuejs.org to read the documentation
```

Duas linhas vieram antes do texto. Elas são o console da página: o próprio script do Vite na página,
conectando-se de volta ao servidor de desenvolvimento para poder empurrar as suas edições ao navegador
à medida que você salva.
