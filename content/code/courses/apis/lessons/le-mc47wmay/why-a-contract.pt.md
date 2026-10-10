---
title: O contrato por escrito
version: 1
---

**O shelf já tem um contrato, e ninguém o escreveu.** Toda API tem. Os endereços que ela atende, os
métodos que cada um aceita, os campos de um livro e os códigos de status de cada recusa ficam fixos
no momento em que o servidor roda, porque um cliente que depende deles quebra quando eles mudam. O
que varia é onde o contrato mora. No shelf ele mora em umas 200 linhas do `rest.py`, e os únicos
jeitos de conhecê-lo são ler Python ou mandar requisições e observar.

A imagem comum é que documentação é uma página escrita para pessoas, depois do código, por quem
tiver tempo. Essa página importa, mas as pessoas são um leitor entre três. Um contrato escrito num
formato que um programa consegue ler serve a todos eles:

| leitor | do que precisa | o que faz com o documento |
|---|---|---|
| uma pessoa | quais endereços existem, o que enviar, o que volta | lê uma página renderizada e escreve um cliente |
| uma ferramenta | cada campo, tipo e código, sem ambiguidade | desenha a página, gera código de cliente, confere requisições num gateway |
| um teste | o mesmo, como regras que possa aplicar | chama a API e falha quando uma resposta desrespeita o documento |

**O terceiro leitor é o que mantém os outros dois honestos.** Uma página para pessoas é verdadeira
no dia em que é escrita. Depois disso, nada percebe quando um campo é renomeado no código e não na
página, e a página continua se lendo perfeitamente. Um documento que um teste compara com a API em
execução falha no mesmo commit que o torna falso. É isso que **documentação viva** quer dizer nesta
aula: documentação que falha quando deixa de ser verdade.

No shelf, "cada campo e cada código" é uma lista definida. A aula 1 passou por toda ela, uma seção
de cada vez: quatro endereços sob `/v1`, oito operações neles, os sete campos de um livro, os três de
um autor, e os códigos 200, 201, 204, 400, 404, 405, 409, 415 e 422. Esta aula põe essa lista num
arquivo só, o `openapi.yaml`, e depois faz programas o lerem.

## OpenAPI e Swagger

O formato é a **OpenAPI Specification**, e você vai ouvir chamarem de Swagger com a mesma
frequência, porque esse era o nome dela até 2015. O Swagger começou como uma especificação com
ferramentas em volta; em 2015 a especificação foi entregue à OpenAPI Initiative, um projeto da Linux
Foundation, e renomeada. A versão 2.0 é a última chamada Swagger, a 3.0 (2017) é a primeira chamada
OpenAPI, e a 3.1 (2021) é a que esta aula escreve.

As ferramentas ficaram com o nome antigo. Por isso hoje as duas palavras querem dizer coisas
diferentes:

| nome | o que é |
|---|---|
| **OpenAPI** | a especificação: as regras que um documento de descrição segue |
| **Swagger UI**, **Swagger Editor**, **Swagger Codegen** | ferramentas que leem um documento assim, mantidas por uma empresa, a SmartBear |

A primeira linha de um documento diz de que geração ele é. Um arquivo que começa com
`swagger: "2.0"` está no formato antigo, ainda comum em projetos mais velhos, e um que começa com
`openapi: 3.1.0` está no atual. "O arquivo do Swagger" costuma querer dizer qualquer um dos dois, o
que não faz mal numa conversa e vale corrigir num ticket, porque uma ferramenta que lê 3.1 pode
recusar 2.0.

A OpenAPI descreve APIs sobre HTTP, do tipo que a aula 1 construiu. Os outros estilos deste curso
têm contratos próprios: o schema do GraphQL na aula 3, o arquivo `.proto` do gRPC na aula 4 e o
WSDL do SOAP na aula 5. A ideia é a mesma nos quatro, e o motivo de ela importar também: **um
contrato que só uma pessoa consegue ler é um contrato que só uma pessoa consegue conferir**, e
pessoas conferem de vez em quando.
