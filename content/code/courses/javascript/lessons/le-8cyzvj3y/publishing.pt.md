---
title: Publicando um pacote
version: 1
---

**Publicar envia uma pasta para o registro com um nome e uma versão, e esse par nunca mais pode
guardar outro código.** A ana escreve um pacote pequeno dela:

```json
{
  "name": "shelf-count",
  "version": "1.0.0",
  "description": "Counts books by decade.",
  "type": "module",
  "exports": "./index.js",
  "files": ["index.js"],
  "license": "MIT"
}
```

```javascript
export function byDecade(books) {
  const counts = {};
  for (const { year } of books) {
    const decade = Math.floor(year / 10) * 10;
    counts[decade] = (counts[decade] ?? 0) + 1;
  }
  return counts;
}
```

```javascript
import assert from "node:assert/strict";
import { byDecade } from "./index.js";

assert.deepEqual(byDecade([{ year: 1956 }, { year: 1958 }, { year: 1977 }]), { 1950: 2, 1970: 1 });
console.log("byDecade: ok");
```

- **`exports`** nomeia o arquivo que um import de `shelf-count` carrega, e nada mais do pacote pode
  ser importado de fora;
- **`files`** lista o que entra no pacote publicado. Sem ele o npm manda quase tudo da pasta, testes
  e anotações incluídos, e um `.env` esquecido com uma senha dentro já foi publicado assim mais de
  uma vez;
- **`license`** diz aos outros o que eles podem fazer com o código.

## Antes de publicar

```
ana@dev:~/js/shelf-count$ node index.test.js
byDecade: ok
ana@dev:~/js/shelf-count$ npm whoami
ana
ana@dev:~/js/shelf-count$ npm pack --dry-run 2>&1 | tail -n +3
npm notice Tarball Contents
npm notice 207B index.js
npm notice 186B package.json
npm notice Tarball Details
npm notice name: shelf-count
npm notice version: 1.0.0
npm notice filename: shelf-count-1.0.0.tgz
npm notice package size: 360 B
npm notice unpacked size: 393 B
npm notice shasum: ca192e5fd49921d899c85611eba034847c851102
npm notice integrity: sha512-AIRRh++jaYTaQ[...]MmXLkDYYcoM3w==
npm notice total files: 2
npm notice
shelf-count-1.0.0.tgz
```

`npm whoami` responde com a conta com que o npm vai publicar. No laboratório, o login da ana é
preparado: a montagem escreveu o token dela em `~/.npmrc`, que é o que o `npm login` faz depois de
pedir uma senha.

`npm pack --dry-run` monta o pacote sem enviá-lo e lista o que tem dentro. Dois arquivos, porque
`files` nomeou um e o npm sempre acrescenta o `package.json`; o teste ficou em casa. O npm começa
essa lista com uma linha que tem um emoji de pacote que a fonte da escola não desenha, e
`tail -n +3` começa a saída na terceira linha.

## Publicando

```
ana@dev:~/js/shelf-count$ npm publish --loglevel=warn
+ shelf-count@1.0.0
ana@dev:~/js/shelf-count$ npm view shelf-count versions
1.0.0
```

`--loglevel=warn` deixa só a linha que diz o que foi publicado. Publicar a mesma versão duas vezes é
recusado, porque uma versão é a promessa de que o conteúdo dela nunca muda:

```
ana@dev:~/js/shelf-count$ npm publish --loglevel=warn 2>&1 | head -n 2
npm error code E409
npm error 409 Conflict - PUT http://127.0.0.1:4873/shelf-count - this package is already present
ana@dev:~/js/shelf-count$ npm version patch
v1.0.1
ana@dev:~/js/shelf-count$ npm publish --loglevel=warn
+ shelf-count@1.0.1
ana@dev:~/js/shelf-count$ npm view shelf-count versions
[ '1.0.0', '1.0.1' ]
```

`npm version patch` subiu `1.0.0` para `1.0.1` no `package.json`. Num repositório git ele também
faria commit dessa mudança e a marcaria com a tag `v1.0.1`; esta pasta não é um, então ele só editou
o arquivo. `npm version minor` e `npm version major` sobem as outras duas partes e zeram as que vêm
depois.

Depois que uma versão sai, alguém pode já depender dela. **Corrija um erro publicando uma versão
nova, não removendo a antiga.** O registro público só deixa despublicar uma versão dentro de uma
janela curta, e `npm deprecate` anexa um aviso no lugar.

## Usando

```
ana@dev:~/js/first$ npm install shelf-count

added 1 package in 407ms
```

```javascript
import { byDecade } from "shelf-count";

const books = [
  { title: "Dom Casmurro", year: 1899 },
  { title: "Grande Sertão: Veredas", year: 1956 },
  { title: "Vidas Secas", year: 1938 },
  { title: "A Hora da Estrela", year: 1977 },
  { title: "O Tempo e o Vento", year: 1949 },
  { title: "Sagarana", year: 1946 },
];
console.log(byDecade(books));
```

```
ana@dev:~/js/first$ node decades.js
{ '1890': 1, '1930': 1, '1940': 2, '1950': 1, '1970': 1 }
```

As chaves saem em ordem crescente mesmo que os livros não estivessem, porque o JavaScript lista as
chaves de objeto com cara de inteiro em ordem numérica, antes de qualquer outra chave. Publicar no registro
privado de uma organização funciona do mesmo jeito, com o endereço dele no `.npmrc`; o
`front-delivery`, na aula 7, trata de versionar e publicar pacotes internos para uma equipe.
