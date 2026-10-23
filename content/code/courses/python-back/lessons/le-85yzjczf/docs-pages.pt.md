---
title: Duas páginas de documentação, e o que elas carregam
version: 1
---

O FastAPI serve duas páginas que mostram o esquema para pessoas: **`/docs`**, o Swagger UI, onde cada
operação tem um botão *Try it out* que manda uma requisição de verdade, e **`/redoc`**, o ReDoc, uma
página de referência feita para leitura. Abra-as num navegador pelo túnel da aula 5, na porta 8001.

Nenhuma das duas está no pacote do FastAPI. Cada uma é um arquivo HTML pequeno que carrega o programa
de verdade de outro lugar:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/docs | grep -oE "https://[^\"]+"
https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css
https://fastapi.tiangolo.com/img/favicon.png
https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/redoc | grep -oE "https://[^\"]+"
https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700
https://fastapi.tiangolo.com/img/favicon.png
https://cdn.jsdelivr.net/npm/redoc@2/bundles/redoc.standalone.js
```

**As duas carregam JavaScript de `cdn.jsdelivr.net`, e o ReDoc carrega fontes do Google**, toda vez que
alguém abre a página. Isso tem três consequências que vale conhecer antes de decidir onde as páginas
são servidas:

- uma máquina sem acesso à internet mostra uma página em branco, embora a API funcione;
- o navegador de quem lê a documentação contata essas empresas, o que uma política de privacidade pode
  ter de dizer;
- a versão é `swagger-ui-dist@5` e `redoc@2`, ou seja, o que essas versões principais forem no dia, e
  não um arquivo que você escolheu e revisou.

A documentação do FastAPI mostra como servir as duas páginas a partir de arquivos seus, com
`docs_url=None` e uma rota que devolve o HTML apontando para as suas cópias. E uma API que não é
pública pode desligar tudo, `FastAPI(docs_url=None, redoc_url=None, openapi_url=None)`, o que tira as
páginas e o esquema com uma linha, desde que nada mais precise do esquema.
