---
title: Desenvolvimento, teste e produção
version: 1
---

**O mesmo código roda em três lugares, e cada um tem o seu jeito de receber as variáveis.** Nenhum
deles precisa de um arquivo de código diferente, e nenhum é escolhido por uma variável que diz em qual
lugar está:

| onde | como as variáveis chegam | o que muda |
|---|---|---|
| desenvolvimento, o seu notebook | o `.env`, lido com `--env-file-if-exists` | uma chave sua; dados em `data/` |
| teste, o `npm test` | o `test.env`, no commit, sem nada secreto | uma chave descartável; dados em `test/tmp/` |
| produção, um servidor | o gerenciador de serviço ou a plataforma | a chave real; dados onde o servidor os guarda |

A linha do teste é a que faltava. Desde a aula 8 o store grava um arquivo, então **os testes da aula 6
vêm gravando os links deles no mesmo `data/links.json` que você usa à mão**. Um teste que muda os dados
de quem desenvolve é um teste que ninguém quer rodar. O `test.env` dá aos testes um arquivo próprio e
uma chave que pode ir para o commit porque não guarda nada:

```schooling-example
{"language": "sh", "file": "test.env", "parts": [
 {"code": "# The environment of npm test. Nothing here is a secret.\nADMIN_KEY=only-for-tests-and-not-a-secret\nDATA_FILE=test/tmp/links.json", "note": "**Vai para o commit de propósito**: estes valores não guardam nada e existem para que o `npm test` funcione num clone novo, sem preparação."}
]}
```

Os scripts do `package.json` escolhem o arquivo. Três linhas de `npm pkg set` os reescrevem:

```
ana@dev:~/server/links$ npm pkg set scripts.start='node --env-file-if-exists=.env server.js'
ana@dev:~/server/links$ npm pkg set scripts.dev='node --env-file-if-exists=.env --watch server.js'
ana@dev:~/server/links$ npm pkg set scripts.test='node --env-file=test.env --test --test-reporter=spec'
ana@dev:~/server/links$ ls data
ls: cannot access 'data': No such file or directory
```

```
ana@dev:~/server/links$ npm test 2>&1 | grep -E "^(✔|✖|ℹ (tests|pass|fail))"
✔ a code has the right length (0.713149ms)
✔ a code uses only the alphabet (5.573364ms)
✔ isCode refuses what makeCode would never make (0.155228ms)
✔ a new link answers 201 with its location (47.567979ms)
✔ following a link redirects and counts the visit (11.781897ms)
✔ a url that is not a web address is refused (2.735758ms)
✔ deleting needs the admin key (14.30293ms)
ℹ tests 7
ℹ pass 7
ℹ fail 0
ana@dev:~/server/links$ ls data test/tmp
ls: cannot access 'data': No such file or directory
test/tmp:
links.json
```

**Os testes passaram, e o `data/links.json` não foi tocado**: os links deles foram para `test/tmp/`,
que o `.gitignore` já deixa de fora. Em produção, o `npm start` não acha `.env`, lê o que o
gerenciador de serviço pôs no ambiente, e o `config.js` se recusa a iniciar se isso estiver
incompleto.
