---
title: Navegadores, e APIs para estranhos
version: 1
---

## Um navegador não chama a porta gRPC do boxoffice

O gRPC precisa de duas coisas do HTTP/2 que uma página web não controla: ele manda o próprio enquadramento
e lê **trailers**, os cabeçalhos que chegam depois do corpo e trazem o `grpc-status`. Navegadores falam
HTTP/2, e o `fetch` não dá à página acesso nem aos trailers nem ao enquadramento. **Então uma página web não
consegue ser cliente gRPC do boxoffice do jeito que ele está**, seja qual for a biblioteca que carregue.

Há contornos, e cada um põe algo entre a página e o serviço:

- **gRPC-Web**, uma variante do protocolo que o navegador fala, com um proxy como o Envoy traduzindo para
  gRPC de verdade na frente do servidor;
- **Connect**, um protocolo e um conjunto de bibliotecas que servem gRPC, gRPC-Web e uma forma simples de
  JSON sobre HTTP a partir dos mesmos handlers, para o navegador chamar com um `fetch` comum;
- **grpc-gateway**, que gera uma frente REST e JSON para um serviço gRPC a partir de anotações no `.proto`.

Nenhum deles foi rodado neste curso. Todos funcionam, e **todos são um segundo protocolo para operar só para
que um navegador alcance o primeiro**. Num serviço cujo cliente principal é uma página web, esse costuma ser
o momento de perguntar por que ele é gRPC.

## APIs para gente que você nunca vai conhecer

Uma API pública, contra a qual parceiros e estranhos escrevem programas, tem clientes em toda linguagem, em
toda plataforma, com toda ferramenta. **O que todos têm em comum é HTTP e JSON.** Um desenvolvedor avaliando
a sua API cola num terminal a linha de `curl` da documentação; com gRPC ele instala uma ferramenta, busca o
seu `.proto` e aprende um protocolo primeiro. Cada hora que isso custa é uma hora que parte deles não vai
gastar.

Algumas APIs públicas são oferecidas em gRPC, quase sempre ao lado de uma forma REST, por empresas cujos
clientes são outras equipes de infraestrutura. **No caso geral, uma API pública é REST e JSON**, com uma
descrição OpenAPI para que ainda se possa gerar clientes, o que guarda a principal vantagem de um contrato
sem a cadeia de ferramentas dele.

## Cache

Mais uma propriedade da web de que o gRPC abre mão: **um `GET` HTTP pode ir para cache** no navegador, numa
CDN, em qualquer proxy no caminho, sob regras que o curso `servers-cache` cobre. Toda chamada gRPC é um
`POST` em HTTP/2, e nenhum cache no meio a guarda. Um catálogo público de eventos lido por milhares é
exatamente a resposta que uma CDN deveria servir, e ela só consegue isso por REST.
