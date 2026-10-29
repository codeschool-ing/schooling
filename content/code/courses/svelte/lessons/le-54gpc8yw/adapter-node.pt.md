---
title: Um adaptador, e um servidor que você consegue rodar
version: 1
---

**Um adaptador transforma o build em algo que um tipo específico de hospedagem consegue rodar.** O build
do SvelteKit é o mesmo para qualquer hospedagem; o adaptador é o último passo, e decide a forma do que sai:
um servidor Node, uma pasta de arquivos estáticos, funções no formato que uma plataforma de nuvem espera. A
aula 1 terminou com o `adapter-auto` dizendo que "could not detect a supported production environment",
que é a resposta certa num notebook: ele reconhece plataformas de nuvem, e um notebook não é uma.

O planner lê e escreve um arquivo no computador em que roda, então precisa de um servidor de vida longa
com um disco, e o adaptador para isso é o **`adapter-node`**. Pare o servidor de desenvolvimento com
Ctrl-C, já que esta aula usa aquele terminal para o servidor do build, e troque os adaptadores, instalando
um e removendo o outro. O `.npmrc` tem `save-exact=true` desde a aula 1, então a versão fica escrita
exatamente:

```
ana@dev:~/planner$ npm install --save-dev @sveltejs/adapter-node@6.0.0

added 1 package, removed 2 packages, changed 1 package, and audited 51 packages in 3s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm uninstall @sveltejs/adapter-auto

removed 1 package, and audited 50 packages in 469ms

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O adaptador é escolhido no `vite.config.js`. Os comentários que o `sv` escreveu sobre o `adapter-auto`
deixam de ser verdade, então saem. Substitua o arquivo:

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import adapter from '@sveltejs/adapter-node';\nimport { sveltekit } from '@sveltejs/kit/vite';\nimport { defineConfig } from 'vite';\n\nexport default defineConfig({\n\tplugins: [\n\t\tsveltekit({\n\t\t\tcompilerOptions: {\n\t\t\t\t// Force runes mode for the project, except for libraries. Can be removed in svelte 6.\n\t\t\t\trunes: ({ filename }) =>\n\t\t\t\t\tfilename.split(/[/\\\\]/).includes('node_modules') ? undefined : true\n\t\t\t},"},
 {"code": "\t\t\t// adapter-node builds a Node server: `npm run build`, then `node build`.\n\t\t\tadapter: adapter()\n\t\t})\n\t]\n});", "note": "A única mudança que importa: `adapter` agora é o `adapter-node`, importado na primeira linha."}
]}
```

Faça o build:

```
ana@dev:~/planner$ npm run build 2>&1 | tail -5

> Using @sveltejs/adapter-node
Copying assets
Compressing and hashing assets
✔ done
```

**`build` é um programa Node.** `node build` roda o `build/index.js`, que inicia um servidor na porta 3000
e responde cada requisição como o servidor de desenvolvimento respondia, a partir de código compilado uma
vez: sem Vite, sem compilar sob demanda, sem atualizar enquanto você salva. Inicie-o no segundo terminal:

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
```

e peça a semana a ele:

```
ana@dev:~/planner$ curl -s http://localhost:3000/ | grep -o '<title>.*</title>'
<title>225 min this week · Study planner</title>
```

Ele lê o `data/planner.json` a partir da pasta em que foi iniciado, como o servidor de desenvolvimento
fazia, então o `node build` deve ser rodado na pasta do projeto. Uma publicação copia o `build`, o
`package.json` e a pasta de dados juntos e inicia o servidor de onde eles estão.

## Um formulário que falha

Acrescente uma sessão no servidor do build, com o JavaScript ligado:

```
ana@dev:~/planner$ look http://localhost:3000/courses/guitar --fill 'Date=2026-10-22' --click 'Add session'
-- fill Date=2026-10-22
-- click Add session
at /courses/guitar
title: 403 · Study planner
- main:
  - heading "Something went wrong" [level=1]
  - paragraph: Cross-site POST form submissions are forbidden
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

**Um 403, e uma frase sobre formulários entre sites.** O mesmo formulário funcionava um minuto atrás no
servidor de desenvolvimento. A próxima seção trata de por que o servidor do build o recusou, e de por que
ele tem razão.
