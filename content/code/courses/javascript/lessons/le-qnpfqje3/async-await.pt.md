---
title: async e await
version: 1
---

**O `await` pausa uma função `async` até uma promessa se resolver, e devolve o valor dela.** As duas
leituras que precisavam de aninhamento com callbacks, e de uma corrente com promessas, viram duas
linhas comuns:

```schooling-example
{
  "language": "javascript",
  "file": "await.mjs",
  "parts": [
    {
      "code": "import { readFile } from \"node:fs/promises\";",
      "note": "A versão de `readFile` com promessa. Este arquivo é um ES module, então também pode usar `await` no nível de cima (aula 9)."
    },
    {
      "code": "async function describe(id) {\n  const book = JSON.parse(await readFile(`books/${id}.json`, \"utf8\"));\n  const author = JSON.parse(await readFile(`authors/${book.authorId}.json`, \"utf8\"));\n  return `${book.title} by ${author.name}`;\n}",
      "note": "`async` antes de uma função deixa ela usar `await` lá dentro. Cada `await` espera uma leitura, e a função segue com o valor, como se a leitura o tivesse devolvido direto."
    },
    {
      "code": "const result = describe(12);\nconsole.log(result);",
      "note": "Chamar uma função `async` devolve uma promessa na hora, que saiu como pendente. O valor do `return` vira o valor da promessa."
    },
    {
      "code": "console.log(await result);",
      "note": "O `await` nessa promessa deu a frase."
    },
    {
      "code": "try {\n  console.log(await describe(99));\n} catch (err) {\n  console.log(\"failed:\", err.code);\n}",
      "note": "Uma promessa rejeitada faz o `await` lançar erro, então um `try`/`catch` comum trata erros de trabalho assíncrono. O livro 99 não existe, e o `catch` recebeu o erro dele."
    }
  ],
  "output": "Promise { <pending> }\nDom Casmurro by Machado de Assis\nfailed: ENOENT"
}
```

## Ainda são promessas

**`async` e `await` são promessas com outra sintaxe**, não outro mecanismo:

- uma função `async` **sempre devolve uma promessa**, mesmo quando devolve um valor comum;
- o que vem depois de um `await` roda mais tarde, como **microtask** (aula 13), quando a promessa
  esperada se resolve. Enquanto a função está pausada, o resto do programa segue;
- `await` em algo que não é promessa só devolve o valor, depois de um microtask.

Então tudo da seção anterior continua valendo, e dá para misturar os dois estilos: dar `await` numa
função que devolve uma corrente de promessas, ou `.then` no resultado de uma função `async`.
**Escreva código novo com `await`**, porque lê de cima para baixo e os erros são pegos com o mesmo
`try`/`catch` de todo o resto. A única coisa que ele facilita errar é o assunto da próxima seção.
