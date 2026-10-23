---
title: Um package.json para uma aplicação
version: 1
---

**O projeto que este curso constrói daqui em diante é um encurtador de links chamado `links`, e ele
começa como um arquivo.** O `npm init -y` escreveria um `package.json` para você, com `main`,
`keywords` e `license` de que uma biblioteca precisa e um servidor não. Escreva este à mão, numa pasta
nova `~/server/links`:

```schooling-example
{"language": "json", "file": "package.json", "parts": [
 {"code": "{\n  \"name\": \"links\",\n  \"version\": \"0.1.0\",", "note": "O nome e a versão. Ninguém instala um servidor pelo nome, então a versão é um rótulo para você; ela nunca vai para um registry."},
 {"code": "  \"private\": true,", "note": "**O `private` faz o `npm publish` recusar**, então o código de um servidor não pode ser publicado no registry público por um escorregão dos dedos."},
 {"code": "  \"type\": \"module\",\n  \"description\": \"A small link shortener, built in the node course\",", "note": "Todo arquivo `.js` do projeto é um ES module, como a aula 3 explicou."},
 {"code": "  \"scripts\": {\n    \"start\": \"node server.js\",\n    \"dev\": \"node --watch server.js\",\n    \"test\": \"node --test --test-reporter=spec\",\n    \"format\": \"prettier --write server.js src test\"\n  },", "note": "Os comandos do projeto, que são o assunto da próxima seção."},
 {"code": "  \"engines\": {\n    \"node\": \">=22\"\n  }\n}", "note": "O Node para o qual ele foi escrito. A seção sobre engines faz o npm cobrar isso de você."}
]}
```

Não há `main`: o `main` diz qual arquivo outro pacote recebe quando importa este, e nada importa um
servidor. Também não há `dependencies` ainda. **O npm escreve essa parte sozinho** quando você instala
algo, e nada nela deve ser digitado à mão.

O npm consegue ler qualquer campo de volta, que é como um script ou uma pessoa confere um projeto sem
abri-lo:

```
ana@dev:~/server/links$ npm pkg get name version type
{
  "name": "links",
  "version": "0.1.0",
  "type": "module"
}
```

## Os dois primeiros arquivos

O serviço distribui códigos curtos, então o primeiro módulo dele faz um. Ele mora em `src/`, como a
organização da aula 3 dizia:

```javascript
// src/code.js: the short codes the links service hands out.
import { randomInt } from "node:crypto";

export const ALPHABET = "23456789abcdefghjkmnpqrstuvwxyz"; // no 0, 1, i, l or o
export const LENGTH = 6;

export function makeCode(length = LENGTH) {
  let code = "";
  for (let i = 0; i < length; i++) code += ALPHABET[randomInt(ALPHABET.length)];
  return code;
}

export function isCode(text) {
  return typeof text === "string" && text.length === LENGTH && [...text].every((c) => ALPHABET.includes(c));
}
```

O alfabeto deixa de fora os cinco caracteres que as pessoas confundem entre si, então um código lido
em voz alta ou digitado num celular sobrevive. O `randomInt` vem do `node:crypto` e não do
`Math.random`, porque um código de link que pode ser previsto é um link que qualquer um adivinha.

```
ana@dev:~/server/links$ node -e 'import("./src/code.js").then((m) => console.log(m.makeCode(), m.ALPHABET.length))'
327nuk 31
```

Trinta e um caracteres, seis deles por código: 31 elevado a 6, quase 890 milhões de códigos. A seção
sobre o test runner confere as regras que este arquivo promete.
