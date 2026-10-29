---
title: Escolhendo um adaptador
version: 1
---

**O `adapter-static` escreve toda página num arquivo no build, e o resultado não precisa de servidor
nenhum**, só de algo que entregue arquivos: GitHub Pages, um armazenamento de objetos, qualquer servidor
web. Ele é o adaptador para um site em que toda página pode ser pré-renderizada. O planner não é um, e o
jeito mais claro de ver o que isso quer dizer é pedir mesmo assim. Instale-o:

```
ana@dev:~/planner$ npm install --save-dev @sveltejs/adapter-static@4.0.0

added 1 package, removed 1 package, and audited 51 packages in 2s

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

e, por um momento, use-o no lugar. Substitua o `vite.config.js`:

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import adapter from '@sveltejs/adapter-static';\nimport { sveltekit } from '@sveltejs/kit/vite';\nimport { defineConfig } from 'vite';\n\nexport default defineConfig({\n\tplugins: [\n\t\tsveltekit({\n\t\t\tcompilerOptions: {\n\t\t\t\t// Force runes mode for the project, except for libraries. Can be removed in svelte 6.\n\t\t\t\trunes: ({ filename }) =>\n\t\t\t\t\tfilename.split(/[/\\\\]/).includes('node_modules') ? undefined : true\n\t\t\t},\n\n\t\t\t// A trial: adapter-static writes every page to a file, or refuses to build.\n\t\t\tadapter: adapter(),\n\n\t\t\t// The address the planner is served at, given when it is built:\n\t\t\t//   ORIGIN=http://localhost:3000 npm run build\n\t\t\tpaths: { origin: process.env.ORIGIN }\n\t\t})\n\t]\n});", "note": "Um teste. O import e o comentário acima de `adapter()` são as únicas mudanças."}
]}
```

```
ana@dev:~/planner$ npm run build 2>&1 | grep -A3 'adapter-static:'
@sveltejs/adapter-static: all routes must be fully prerenderable, but found the following routes that are dynamic:
  - src/routes/(planner)
  - src/routes/(planner)/courses/[id=slug]
```

**Duas rotas dinâmicas**, a semana e as páginas de curso, que é a resposta da seção anterior vinda de outra
direção. O resto da mensagem lista as saídas, e cada uma delas abre mão de algo de que o planner precisa:
uma página de `fallback` transforma o planner numa aplicação de página única que renderiza no navegador,
sem formulários que funcionem sem JavaScript e sem servidor para recebê-los. Ponha o `vite.config.js` de
volta como "A verificação que recusou o formulário" o deixou, com o `adapter-node`, e remova o teste:

```
ana@dev:~/planner$ npm uninstall @sveltejs/adapter-static

removed 2 packages, and audited 50 packages in 478ms

11 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## A pergunta que escolhe

**Onde os dados moram, e o que a hospedagem consegue guardar entre duas requisições?** O resto vem daí:

| adaptador | o que ele produz | serve para |
|---|---|---|
| `adapter-node` | um servidor Node, que roda até ser parado | uma aplicação com servidor, numa máquina ou num contêiner que você roda, com disco se precisar: o planner |
| `adapter-static` | uma pasta de HTML, CSS e JavaScript | um site em que toda página é a mesma para todo mundo: documentação, um blog, um portfólio |
| `adapter-vercel`, `adapter-netlify`, `adapter-cloudflare` | funções no formato da própria plataforma, iniciadas para uma requisição e paradas depois dela | uma aplicação cujos dados ficam num banco de dados ou num serviço, nunca num arquivo ao lado do código |
| `adapter-auto` | qualquer uma da linha anterior que ele detectar | começar um projeto antes de escolher |

A terceira linha é onde o planner, do jeito que está escrito, quebraria em silêncio: uma função nessas
plataformas muitas vezes consegue escrever um arquivo, e o arquivo some quando a função para, ou nunca é
visto pela próxima cópia dela. A fila em `src/lib/server/planner.js` também não ajudaria, já que cada cópia
tem a sua. Isso não é defeito dessas plataformas. É a mesma lição da nota da aula 14 sobre bancos de dados,
encontrada na publicação em vez de no código: um planner que mais de uma pessoa usa guarda as suas sessões
num banco de dados, e aí qualquer um dos adaptadores acima que consiga rodar um servidor serve.
