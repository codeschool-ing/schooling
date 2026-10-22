---
title: Arquivos .env, e o --env-file
version: 1
---

**Digitar quatro variáveis antes de cada comando é como os erros acontecem, então no computador de quem
desenvolve elas ficam num arquivo**, chamado por convenção de `.env`, um `NOME=valor` por linha. O
Node 22 lê um sozinho com `--env-file`, então nenhum pacote é necessário:

```
ana@dev:~/server/links$ printf 'PORT=4000\nGREETING=hello from the file\n' > demo.env
ana@dev:~/server/links$ node --env-file=demo.env -p 'process.env.PORT + " " + process.env.GREETING'
4000 hello from the file
ana@dev:~/server/links$ PORT=5000 node --env-file=demo.env -p 'process.env.PORT'
5000
ana@dev:~/server/links$ node --env-file=missing.env -p 'process.env.PORT'
node: missing.env: not found
ana@dev:~/server/links$ node --env-file-if-exists=missing.env -p 'process.env.PORT'
missing.env not found. Continuing without it.
undefined
ana@dev:~/server/links$ rm demo.env
```

**Uma variável que já está no ambiente vence o arquivo**, que é o que o segundo comando mostra: o
arquivo dá os valores padrão para o notebook de quem desenvolve, e um deploy que define o ambiente de
verdade nunca é sobrescrito por um arquivo que alguém esqueceu ali. **Um arquivo que falta é um erro**
com `--env-file`, e com `--env-file-if-exists` é um aviso e nada mais, que é o que um script de
`start` quer: um notebook tem um `.env`, um servidor tem o ambiente definido de outro jeito e arquivo
nenhum.

## Os dois arquivos que um projeto guarda

```schooling-example
{"language": "sh", "file": ".env.example", "parts": [
 {"code": "# Copy this file to .env and fill it in. .env itself is never committed.\nPORT=3000\nHOST=127.0.0.1", "note": "**O `.env.example` vai para o commit.** Ele lista cada variável que o serviço lê, com valores seguros ou nenhum, para que quem chega copie o arquivo para `.env` e saiba o que preencher."},
 {"code": "ADMIN_KEY=", "note": "Nenhum valor para a chave, de propósito: uma chave num arquivo de exemplo é uma chave no repositório."}
]}
```

**O `.env` nunca vai para o commit**, porque guarda os valores reais, segredos incluídos. Ele entra no
`.gitignore` antes de ser criado, o que a seção sobre segredos confere. O pacote `dotenv` fez esse
trabalho por anos e você vai vê-lo em projetos mais antigos; o `--env-file` faz o mesmo sem instalar
nada.
