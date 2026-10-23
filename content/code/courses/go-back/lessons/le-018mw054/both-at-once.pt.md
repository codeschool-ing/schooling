---
title: Um serviço, as duas portas
version: 1
---

O boxoffice já serve os dois estilos, e o jeito como faz isso merece um nome de padrão: **dois adaptadores
finos sobre um núcleo só.**

- O **store** é o núcleo: a interface `Store` da aula 6 e o `pgStore` por trás dela. Ele conhece eventos,
  vendas e ingressos, e nada de HTTP ou gRPC.
- Os **handlers HTTP** das aulas 1 a 3 traduzem requisições HTTP em chamadas ao store e erros do store em
  status e problem details.
- Os **métodos gRPC** da aula 10 traduzem requisições gRPC nas mesmas chamadas ao store e os mesmos erros em
  códigos gRPC, pelo `toStatus`.

Nenhum adaptador contém regra de negócio. **Uma venda é o mesmo `Sell`, venha pela porta que vier**, e é
por isso que a aula 10 seção 07 viu uma compra por HTTP chegar a um observador gRPC meio segundo depois.
Uma regra acrescentada ao store, por exemplo um limite de dez ingressos por e-mail por evento, vale para os
dois de uma vez.

## Quem usa qual

A divisão segue os clientes, não as funcionalidades:

| cliente | porta | por quê |
|---|---|---|
| o site público de ingressos, num navegador | HTTP, `:8080` | navegadores falam HTTP e JSON; o CORS da aula 2 é para eles |
| ferramentas e scripts da equipe | HTTP, `/admin/` | `curl` e um token são tudo de que precisam |
| os leitores na porta | gRPC, `:9090` | um stream por porta, um cliente gerado, um prazo em cada leitura |
| a tela ao vivo da bilheteria | gRPC, `:9090` | streaming de disponibilidade pelo servidor |

## O que custa

Duas portas, dois conjuntos de middlewares ou interceptors, dois lugares para pôr autenticação e log, dois
formatos de erro. **Toda preocupação que atravessa as requisições agora é escrita duas vezes**, uma por
porta, e o log da aula 12 e as métricas da aula 17 vão ter de cobrir as duas. Esse custo é real, e é o
motivo para não acrescentar um segundo protocolo antes de um cliente precisar. O boxoffice o acrescentou
porque os leitores e a tela são programas da própria casa, construídos sobre um contrato que ela controla,
com streams que o REST teria de imitar.

Uma alternativa que algumas equipes preferem é um protocolo só e uma tradução na frente: escrever o serviço
em gRPC e gerar a face REST com o grpc-gateway, ou escrevê-lo com Connect e servir os dois a partir de um
handler. Isso move a duplicação do seu código para código gerado, o que é uma boa troca quando a API é
grande.
