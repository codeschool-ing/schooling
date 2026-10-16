---
title: REST ou GraphQL
version: 1
---

**Nenhum substitui o outro.** Eles dividem o mesmo trabalho de jeitos diferentes: o REST fixa o
formato de cada resposta no servidor e deixa o HTTP fazer muita coisa de graça, e o GraphQL entrega o
formato ao cliente e obriga o servidor a se defender. A loja agora tem os dois, sobre o mesmo banco, e
cada linha desta tabela é algo que você viu um deles fazer:

| | REST, `rest.py` | GraphQL, `graph.py` |
|---|---|---|
| endereços | um por recurso | um, `/graphql` |
| quem decide o formato da resposta | o servidor, por endpoint | o cliente, por consulta |
| uma página que precisa de três recursos | três requisições, ou um endpoint novo | uma requisição |
| caches HTTP | funcionam como projetados com `GET` | precisam de `GET` e consultas persistidas |
| o código de status | leva o resultado | 200 para tudo o que rodou; leia `errors` |
| trabalho que uma requisição pode causar | fixado pelo endpoint | escolhido pelo cliente, então precisa de limites |
| o contrato | escrito ao lado do código, aula 6 | o esquema, que o servidor sabe descrever |
| mudanças | uma versão nova no caminho | um esquema que cresce, com `@deprecated` |

## Onde cada um se encaixa

**O GraphQL compensa o custo quando uma equipe atende muitas telas que ela mesma escreve.** Um app
web, um app Android e um app de iPhone querem cada um uma fatia diferente dos mesmos dados, e cada um
muda a cada poucas semanas. Uma camada GraphQL na frente dos serviços, muitas vezes chamada de
**backend for frontend**, deixa cada tela pedir exatamente a sua fatia sem um endpoint novo. Como
todos os clientes são seus, as consultas persistidas também podem transformar a linguagem aberta numa
lista fixa. É o caso para o qual o GraphQL foi criado.

**O REST é o padrão mais seguro para uma API que estranhos chamam.** Uma API pública é usada por
programas que você nunca vai ver, escritos em linguagens que você não escolheu, muitas vezes com nada
além do `curl`. Eles ganham com endereços que podem guardar, códigos de status com que podem decidir,
respostas que qualquer cache HTTP entende e um custo por requisição que você decidiu antes. O GitHub
publica uma API REST e uma GraphQL, o que é um bom resumo da troca: os mesmos dados, para dois tipos
de cliente.

Entre serviços dentro de um mesmo sistema, onde o cliente não é nem a tela nem o estranho, existe uma
terceira resposta, e a aula 4 trata dela.
