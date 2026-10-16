---
title: O que um pacote deixa você importar
version: 1
---

**O `package.json` de um pacote pode listar exatamente quais arquivos podem ser importados, com quais
nomes, e qual arquivo cada tipo de importador recebe.** Essa lista é o campo `exports`. Sem ele,
qualquer arquivo do pacote é alcançável pelo caminho; com ele, só o que ele nomeia é, e todo o resto
é recusado.

Para ver isso funcionando sem instalar nada, monte um pacote pequeno à mão em `node_modules`, do
jeito que o npm o teria descompactado:

```
ana@dev:~/server/modules/pkg$ mkdir -p node_modules/tidy/dist node_modules/tidy/src
```

e dê a ele este `package.json`, em `node_modules/tidy/`:

```json
{
  "name": "tidy",
  "version": "1.0.0",
  "exports": {
    ".": {
      "import": "./dist/tidy.mjs",
      "require": "./dist/tidy.cjs"
    },
    "./words": "./dist/words.mjs"
  }
}
```

Dois nomes são exportados. **O `"."` é o próprio pacote**, `tidy`, e ele é dado como **condições**:
um `import` recebe o build em ES module e um `require` recebe o build em CommonJS. O **`"./words"`**
é um *subcaminho*, `tidy/words`, ligado a um arquivo. Os três arquivos que ele nomeia têm uma linha
cada, e o `src` ganha um quarto que a lista não nomeia. Escreva-os, depois peça cada um:

```
ana@dev:~/server/modules/pkg$ echo 'exports.kind = "CommonJS build";' > node_modules/tidy/dist/tidy.cjs
ana@dev:~/server/modules/pkg$ echo 'export const kind = "ES module build";' > node_modules/tidy/dist/tidy.mjs
ana@dev:~/server/modules/pkg$ echo 'export const words = (s) => s.split(/\s+/).length;' > node_modules/tidy/dist/words.mjs
ana@dev:~/server/modules/pkg$ echo 'module.exports = "private";' > node_modules/tidy/src/internal.js
ana@dev:~/server/modules/pkg$ node -p 'require("tidy").kind'
CommonJS build
ana@dev:~/server/modules/pkg$ node --input-type=module -e 'import { kind } from "tidy"; console.log(kind)'
ES module build
ana@dev:~/server/modules/pkg$ node --input-type=module -e 'import { words } from "tidy/words"; console.log(words("three words here"))'
3
ana@dev:~/server/modules/pkg$ node -p 'require("tidy/src/internal.js")' 2>&1 | grep -E '^Error|code:'
Error [ERR_PACKAGE_PATH_NOT_EXPORTED]: Package subpath './src/internal.js' is not defined by "exports" in /home/ana/server/modules/pkg/node_modules/tidy/package.json
  code: 'ERR_PACKAGE_PATH_NOT_EXPORTED'
```

**O mesmo nome deu dois arquivos diferentes para dois tipos de importador**, que é como um pacote
atende os dois sistemas de módulos. E o `src/internal.js` existe no disco e mesmo assim é recusado:
`ERR_PACKAGE_PATH_NOT_EXPORTED`. Essa recusa é a ideia. O que um pacote deixa fora do `exports` é
assunto dele, livre para mudar em qualquer versão sem quebrar você, porque você nunca conseguiu
importar.

Duas coisas decorrem disso quando você usa um pacote:

- **um import que funcionava entrando na pasta de um pacote pode parar de funcionar quando o pacote
  acrescenta `exports`**, e a solução é importar o que ele exporta, não contornar a recusa;
- **as condições decidem qual build você roda.** Os dois builds de um pacote são dois módulos com dois
  estados, o problema contra o qual a seção anterior alertou; um pacote que oferece os dois toma
  cuidado de guardar o estado em um deles só.

## imports, para o seu próprio projeto

O campo espelho, `imports`, dá nomes a arquivos **de dentro do seu próprio projeto**, e os nomes
dele têm de começar com `#`. No `package.json` de um projeto:

```json
{
  "imports": {
    "#config": "./src/config.js"
  }
}
```

O `import config from "#config"` passa então a funcionar de qualquer arquivo do projeto, em
qualquer profundidade, no lugar de um `"../../config.js"` contado à mão. É opcional, e este curso
escreve caminhos relativos simples; você vai encontrar nomes com `#` em projetos maiores e agora sabe
o que são.
