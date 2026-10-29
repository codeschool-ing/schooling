---
title: prerender, e páginas escritas uma vez no build
version: 1
---

**`export const prerender = true` renderiza uma página enquanto a aplicação está sendo construída e salva o
HTML num arquivo**, que o servidor então manda do jeito que está, sem rodar nenhum componente nem função
load para a requisição. A About diz a mesma coisa para todo mundo, toda vez, então o resultado de
renderizá-la a cada requisição é o mesmo arquivo toda vez. Renderize-a uma vez. Substitua o
`src/routes/(info)/about/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(info)/about/+page.js", "parts": [
 {"code": "// +page.js: page options for About."},
 {"code": "export const prerender = true;\nexport const csr = false;", "note": "Renderizada uma vez, quando o `npm run build` roda, e salva como arquivo."}
]}
```

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A1 Prerendering
Prerendering
```

```
ana@dev:~/planner$ find build -name '*.html'
build/prerendered/about.html
```

**`build/prerendered/about.html`.** O `adapter-node` o serve para `/about`, antes das rotas que ele
renderiza sob demanda, e qualquer servidor de arquivos estáticos também poderia servi-lo. Pré-renderizar é
como se faz um site SvelteKit sem servidor nenhum, que a próxima seção examina, e a regra para quais
páginas podem ser pré-renderizadas é a que a documentação diz com todas as letras: **duas pessoas quaisquer
que peçam a página precisam receber o mesmo conteúdo.**

## As páginas do planner não podem

Experimente a outra ponta, e peça que toda página seja pré-renderizada. Uma opção de página no layout raiz
vale para todas as páginas abaixo dele, então salve isto como `src/routes/+layout.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/+layout.js", "parts": [
 {"code": "// +layout.js: a trial. Prerender every page. (Deleted again below.)\nexport const prerender = true;", "note": "No layout raiz, uma opção de página vale para todas as páginas da aplicação."}
]}
```

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A2 'SvelteKit error'
SvelteKit error: url_search_unavailable_prerender
Cannot access `url.searchParams` on a page with prerendering enabled
https://svelte.dev/e/kit/url_search_unavailable_prerender
```

**O build falha, e tem razão.** A página da semana lê `?week` do endereço, e uma página renderizada no
build não tem endereço para ler: ninguém a pediu ainda. A semana é o primeiro motivo pelo qual as páginas do
planner não podem ser arquivos, e não o único. O conteúdo delas muda a cada sessão acrescentada, o que um
arquivo escrito no build não veria. E os formulários delas enviam para actions, que precisam de um servidor
escutando quando o formulário chega. Apague o arquivo de teste:

```
ana@dev:~/planner$ rm src/routes/+layout.js
```

O `prerender = 'auto'` existe para o meio-termo, uma rota que deve ser pré-renderizada nos endereços que o
build consegue encontrar e renderizada sob demanda no resto, o que combina mais com um blog de mil posts do
que com um planner.
