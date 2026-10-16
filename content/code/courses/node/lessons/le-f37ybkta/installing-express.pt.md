---
title: Instalando o Express, e o que veio junto
version: 1
---

**As aulas 6 e 7 tratam do Express, o framework web sobre o qual a maioria dos servidores Node é
construída, e instalá-lo é a primeira coisa a olhar de perto.** Um comando, um nome:

```
ana@dev:~/server/links$ npm install express@5.3.0

added 65 packages, and audited 66 packages in 723ms

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**Você pediu um pacote e recebeu 65.** O Express depende de parsers de corpo, um roteador, um parser
de cookies, tabelas de MIME e mais, cada um desses de outros, e o npm instalou a árvore inteira,
achatada em `node_modules` onde quer que dois pacotes pudessem dividir uma cópia. O `npm ls` mostra o
topo da árvore e o `--all` mostra tudo; a contagem de linhas é uma contagem aproximada da árvore:

```
ana@dev:~/server/links$ npm ls
links@0.1.0 /home/ana/server/links
└── express@5.3.0

ana@dev:~/server/links$ npm ls --all | wc -l
127
ana@dev:~/server/links$ du -sh node_modules
4.3M	node_modules
```

O `package.json` agora tem um campo `dependencies` que o npm escreveu, com `"express": "^5.3.0"`. **O
circunflexo é o padrão do npm**: você pediu 5.3.0 e o npm registrou uma faixa que aceita qualquer 5.x
posterior, porque supõe que o pacote segue o versionamento semântico e que nenhuma 5.x vai quebrar
você. O lockfile guarda o que foi de fato instalado, 5.3.0 exatamente, e essa é a versão que roda.

## Por que este pacote está aqui?

Cada um dos 65 é código que o seu servidor carrega e roda com as permissões do seu servidor. **O `npm
explain` diz quais pacotes trouxeram um deles**, e é o primeiro comando a rodar quando um nome que
você nunca pediu aparece num aviso:

```
ana@dev:~/server/links$ npm explain debug
debug@4.4.3
node_modules/debug
  debug@"^4.4.3" from body-parser@2.3.0
  node_modules/body-parser
    body-parser@"^2.3.0" from express@5.3.0
    node_modules/express
      express@"^5.3.0" from the root project
  debug@"^4.4.0" from express@5.3.0
  node_modules/express
    express@"^5.3.0" from the root project
  debug@"^4.4.0" from finalhandler@2.1.1
  node_modules/finalhandler
    finalhandler@"^2.1.0" from express@5.3.0
    node_modules/express
      express@"^5.3.0" from the root project
  debug@"^4.4.0" from router@2.2.0
  node_modules/router
    router@"^2.2.0" from express@5.3.0
    node_modules/express
      express@"^5.3.0" from the root project
  debug@"^4.4.3" from send@1.2.1
  node_modules/send
    send@"^1.1.0" from express@5.3.0
    node_modules/express
      express@"^5.3.0" from the root project
    send@"^1.2.0" from serve-static@2.2.1
    node_modules/serve-static
      serve-static@"^2.2.0" from express@5.3.0
      node_modules/express
        express@"^5.3.0" from the root project
```

O `debug` é pedido cinco vezes: o Express pede `^4.4.0` diretamente, e quatro das dependências dele
pedem também. Todas essas faixas aceitam a 4.4.3, então o npm instalou uma cópia e os cinco a dividem,
que é o achatamento de que o primeiro parágrafo falou.

## Um primeiro uso

Para mostrar que a instalação funciona, o `server.js` responde uma rota com um código novo. A aula 6
explica cada linha de uma aplicação Express; aqui, basta que ela rode:

```javascript
// server.js
import express from "express";
import { makeCode } from "./src/code.js";

const app = express();
app.get("/", (req, res) => res.send(`a new code: ${makeCode()}\n`));
app.listen(3000, "127.0.0.1", () => console.log("listening on http://127.0.0.1:3000"));
```

```
ana@dev:~/server/links$ node server.js
listening on http://127.0.0.1:3000
```

e de um segundo terminal:

```
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/
a new code: t25yvu
ana@dev:~/server/links$ curl -s http://127.0.0.1:3000/
a new code: aj69pv
```

Duas requisições, dois códigos. **Mantenha o `node_modules` fora do git**: são 4,3 MB de código de
outras pessoas que o `npm ci` repõe exatamente a partir do lockfile em poucos segundos, então um
`.gitignore` com a única linha `node_modules/` passa a fazer parte do projeto, ao lado de um
`package-lock.json` que vai para o commit.
