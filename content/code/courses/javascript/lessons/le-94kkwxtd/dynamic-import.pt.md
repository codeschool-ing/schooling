---
title: import() quando precisar
version: 1
---

Um `import` estático fica no topo do arquivo e é carregado antes de qualquer código rodar. Às vezes
um módulo só é necessário num caminho, como um relatório que ninguém pediu ou uma página do site que
o visitante nunca abre. **O `import()` carrega um módulo quando a linha é alcançada**, e devolve uma
promessa dos exports dele:

```javascript
console.log("report.mjs loaded");
export function render(rows) {
  return rows.map((r) => `- ${r}`).join("\n");
}
```

```javascript
const wantsReport = process.argv[2] === "report";
console.log("start");

if (wantsReport) {
  const { render } = await import("./report.mjs");
  console.log(render(["Iracema", "Dom Casmurro"]));
}
console.log("end");
```

```
ana@dev:~/js$ node lazy/main.mjs
start
end
ana@dev:~/js$ node lazy/main.mjs report
start
report.mjs loaded
- Iracema
- Dom Casmurro
end
```

Sem o argumento `report`, `report.mjs` **nunca foi carregado**: `report.mjs loaded` não saiu. Com
ele, o módulo carregou no meio do programa, entre `start` e `end`, e `render` foi desestruturado do
que voltou.

## Duas coisas a ler nesse programa

- `import()` parece uma chamada de função e não é: é sintaxe, e funciona tanto em ES modules quanto
  em arquivos CommonJS, o que o tornou a ponte entre os dois antes de o `require` conseguir carregar
  um ES module;
- **o `await` está no nível de cima do arquivo**, fora de qualquer função. Isso é permitido num ES
  module, e só nele; pausa o módulo até o import terminar. Uma promessa é o que o `import()` devolve,
  e o `await` espera por uma; a aula 14 é a aula das duas coisas, e isto é uma prévia do formato.

No navegador, o `import()` é como uma aplicação grande carrega o código de uma tela só quando o
usuário vai até ela, para a primeira página chegar mais cedo. As ferramentas de build dos cursos de
framework fazem isso por você quando uma rota é declarada como preguiçosa; o que elas geram é uma
chamada de `import()`.
