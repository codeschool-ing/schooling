---
title: Organizando um projeto de servidor
version: 1
---

**Um módulo deve fazer um trabalho só, e a organização das pastas deve dizer qual arquivo faz o
quê.** Essa é a regra inteira, e o resto é convenção. O serviço que este curso constrói a partir da
aula 5, um encurtador de links, termina a aula 10 organizado assim:

```localised
links/
├── package.json        o projeto: nome, tipo, scripts e dependências (aula 4)
├── package-lock.json   as versões exatas instaladas (aula 4)
├── server.js           o inicia: lê a configuração e escuta (aulas 9, 10)
├── src/
│   ├── app.js          monta a aplicação Express, e não escuta (aula 6)
│   ├── links.js        as rotas sob /links (aulas 6, 7)
│   ├── store.js        guarda os links, na memória e depois num arquivo (aulas 6, 8)
│   ├── admin.js        confere a chave de administração (aulas 6, 9)
│   └── config.js       lê e confere o ambiente, uma vez (aula 9)
└── test/
    └── links.test.js   faz perguntas à app numa porta livre (aulas 4, 6)
```

Três escolhas nela merecem nome, porque cada uma é um erro que as pessoas cometem uma vez.

**O `app.js` monta a aplicação e o `server.js` a inicia.** Um teste precisa da aplicação sem a porta
de verdade: ele importa o `app.js`, a inicia numa porta que o sistema escolhe, manda requisições, e a
fecha. Se o mesmo arquivo também chamasse `listen` na porta 3000, todo teste brigaria por essa porta e
deixaria o processo rodando, o quebra-cabeça da seção da aula 2 sobre
quando um processo decide que terminou.

**O `store.js` esconde onde os dados ficam.** As rotas chamam `store.add` e `store.find` e nunca sabem
se aquilo é um array ou um arquivo. A aula 8 muda o interior do `store.js` de um para o outro, e
nenhuma rota muda. Um curso mais adiante sobre bancos de dados o muda de novo.

**O `config.js` é lido uma vez.** Ele lê o `process.env`, confere cada valor, e exporta um objeto.
Como um módulo roda uma vez e fica no cache, todo arquivo que o importa recebe o mesmo objeto,
conferido uma vez, na inicialização.

## Pastas por tipo ou por funcionalidade

A organização acima agrupa os arquivos **pelo que eles são**: rotas, armazenamento, configuração. Um
serviço grande agrupa **por funcionalidade** — `links/`, `users/`, `billing/`, cada um com as próprias
rotas e o próprio armazenamento — para que uma mudança mexa numa pasta só. As duas servem, e um
serviço de cinco arquivos não é grande. O erro é uma terceira organização: nenhuma, com um `utils.js`
que cresce até todo arquivo importá-lo e ele importar tudo de volta, que é como nascem os ciclos da
seção desta aula sobre o cache.
