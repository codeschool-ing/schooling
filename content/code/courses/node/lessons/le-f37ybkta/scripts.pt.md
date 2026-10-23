---
title: Scripts, os comandos do próprio projeto
version: 1
---

**Os `scripts` do `package.json` dão nome aos comandos com que um projeto é rodado, para que ninguém
precise lembrá-los.** O `npm run` sem nada depois os lista:

```
ana@dev:~/server/links$ npm run
Lifecycle scripts included in links@0.1.0:
  start
    node server.js
  test
    node --test --test-reporter=spec
available via `npm run-script`:
  dev
    node --watch server.js
  format
    prettier --write server.js src test
```

`start` e `test` são scripts de ciclo de vida, que o npm conhece pelo nome: `npm start` e `npm test`
os rodam sem a palavra `run`. Os outros precisam dela: `npm run dev`, `npm run format`. **Quem clona o
projeto digita `npm test` e não precisa saber que os testes usam o runner do próprio Node** com um
reporter específico; o script é a documentação, e está sempre atualizado porque é o que roda.

## O que um script enxerga

Um script roda num shell, com dois acréscimos ao ambiente:

- **o `node_modules/.bin` está no `PATH` dele.** Todo pacote que tem um comando o põe ali, então o
  `prettier` do script `format` é a cópia do próprio projeto, a versão exata do lockfile, e não o que
  quer que esteja instalado em outro lugar do computador.
- **o npm define variáveis** descrevendo a execução e o pacote, como `npm_lifecycle_event`, o nome do
  script, e `npm_package_version`.

```
ana@dev:~/server/links$ npm run format

> links@0.1.0 format
> prettier --write server.js src test

server.js 31ms
src/code.js 8ms
test/code.test.js 4ms
```

O Prettier não reescreveu nada que não precisasse e listou o que olhou. Argumentos para o comando de
dentro de um script vão depois de `--`, para que o npm não os leia como seus: `npm test -- --test-only`
entrega o `--test-only` ao `node --test`.

## node --run

O Node 22 consegue rodar um script sozinho, sem o npm, e começa mais rápido porque o npm não é
carregado antes:

```
ana@dev:~/server/links$ npm pkg set scripts.hello='echo hello from $npm_lifecycle_event'
ana@dev:~/server/links$ npm run hello

> links@0.1.0 hello
> echo hello from $npm_lifecycle_event

hello from hello
ana@dev:~/server/links$ node --run hello
hello from
ana@dev:~/server/links$ npm pkg delete scripts.hello
```

Mesmo script, dois executores, e a segunda linha não imprimiu nada depois de `from`. **O `node --run`
não define nenhuma das variáveis do npm**, e não roda os scripts `pre` e `post` que o npm roda em
volta de um script de mesmo nome. Para um script que só chama um programa, ele é o jeito mais rápido;
para qualquer coisa que dependa do que o npm acrescenta, o `npm run` é o que funciona. Este curso usa
o `npm`, e o script hello vai embora com `npm pkg delete scripts.hello`.

## dev, e --watch

O `npm run dev` inicia o servidor com `node --watch`, que o reinicia sempre que um arquivo que ele
carregou muda. Ele substitui as ferramentas que antes eram instaladas para isso, e é uma comodidade
de desenvolvimento apenas: em produção o processo deve mudar quando alguém faz deploy, não quando um
arquivo é tocado.
