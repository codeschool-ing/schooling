---
title: Módulos no navegador
version: 1
---

O mesmo `import` e `export` funcionam numa página. **Uma tag de script com `type="module"` carrega um
módulo**, e ele mesmo importa os outros:

```javascript
export function label(title, year) {
  return `${title} (${year})`;
}
```

```javascript
import { label } from "./format.js";

const heading = document.querySelector("h1");
console.log(heading.textContent, "/", label("Iracema", 1865));
console.log(typeof this, typeof window.label, document.readyState);
```

```html
<!doctype html>
<head>
  <script type="module" src="app.js"></script>
</head>
<body>
  <h1>Catalogue</h1>
</body>
```

```
ana@dev:~/js$ cd web && page index.html
Catalogue / Iracema (1865)
undefined undefined interactive
ana@dev:~/js$ cd web && page index.html --file
[error] Access to script at 'file:///home/ana/js/web/app.js' from origin 'null' has been blocked by CORS policy: Cross origin requests are only supported for protocol schemes: chrome, chrome-untrusted, data, http, https.
[error] Failed to load resource: net::ERR_FAILED
```

## Quatro diferenças em relação a um script clássico

A primeira execução mostra três delas:

- **um script de módulo é adiado.** Ele estava no `<head>`, acima do `<h1>`, e mesmo assim achou o
  título: o navegador espera a página ser lida antes de rodar módulos, e `document.readyState` diz
  `interactive`, o momento entre ler a página e terminar todas as imagens. Um script clássico no
  mesmo lugar teria rodado antes de o `<h1>` existir;
- **ele tem escopo próprio**, então `label` não virou `window.label`;
- **o `this` dele é `undefined`**, como no Node.

A segunda execução, com `--file`, abriu a mesma página por `file://`, que é o que um duplo clique num
arquivo HTML na área de trabalho faz:

- **um módulo não carrega por `file://`.** O navegador trata um arquivo aberto do disco como sem
  origem, e se recusa a buscar módulos para ele. A página carregou e o script não, com um erro no
  console e nada na página dizendo isso. No laboratório, o `page` serve `~/js` por
  `http://127.0.0.1:8080` exatamente por isso; em casa, qualquer servidor estático pequeno faz o
  mesmo, e editores costumam ter um embutido.

## Caminhos no navegador

`./format.js` é uma URL, relativa ao módulo que a importa, e **o navegador a busca como está
escrita**: não há procura, nem adivinhação de extensão, nem `node_modules`. Um nome solto como
`import { x } from "lodash"` falha no navegador a menos que um **import map** na página diga que URL
esse nome representa. A maioria dos projetos nunca escreve um, porque uma ferramenta de build (os
frameworks dos próximos cursos vêm cada um com a sua) transforma muitos módulos em poucos arquivos
antes de a página ser servida.
