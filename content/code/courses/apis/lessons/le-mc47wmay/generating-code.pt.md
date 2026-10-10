---
title: Gerando clientes e servidores
version: 1
---

**Um documento preciso o bastante para um teste é preciso o bastante para gerar código.** Toda
operação tem um método, um endereço, parâmetros com tipo, um corpo com tipo e respostas com tipo, e
um programa consegue transformar isso em código de forma mecânica. Três tipos de código saem dele:

| o que é gerado | a partir de qual parte | o que você ainda escreve |
|---|---|---|
| uma **biblioteca cliente** | uma função por operação, um tipo por schema | o programa que chama essas funções |
| um **esqueleto de servidor** | as rotas, os tipos das requisições, um handler vazio por operação | o corpo de cada handler |
| **validação** na frente de um servidor | os schemas de cada corpo de requisição e de cada parâmetro | nada; ela recusa o que o documento recusa |

As ferramentas são muitas e nenhuma está no repositório do Ubuntu, então nenhuma é rodada neste
curso. O OpenAPI Generator é a mais abrangente, com geradores para dezenas de linguagens, e nasceu do
Swagger Codegen. Outras fazem bem uma linguagem só: oapi-codegen para Go, openapi-typescript para
tipos de TypeScript, datamodel-code-generator para classes Python.

## No que o `operationId` se transforma

Os nomes num cliente gerado vêm do documento. `operationId: createBook` vira uma função chamada
`createBook`, ou `create_book`, conforme a linguagem, e `NewBook` vira um tipo chamado `NewBook`. Isso
faz algumas edições no documento quebrarem o código mesmo quando nada muda no HTTP. Renomeie
`createBook` para `addBook` porque soa melhor, e todo programa construído sobre o cliente gerado para
de compilar no dia em que ele é gerado de novo, embora `POST /v1/books` se comporte exatamente como
antes. Um documento a partir do qual clientes geram código tem dois contratos dentro, o do HTTP e o
dos nomes.

## Os riscos

**Código gerado é tão certo quanto o documento, e mais confiante do que deveria.** O documento do
shelf diz que um ISBN tem treze dígitos. Um cliente gerado com validação ligada recusaria
`978-65-00000-08-5` antes de enviar, enquanto o servidor o aceita; um esqueleto de servidor com
validação recusaria o que o `rest.py` aceita. Nenhum dos dois está errado sobre o documento, e os dois
discordam da API que você de fato roda. O teste de contrato continua sendo o que diz qual.

Os outros são práticos, e cada um tem um hábito que responde a ele:

| o risco | o que acontece | o hábito |
|---|---|---|
| editar arquivos gerados | a próxima geração apaga a edição, em silêncio | manter o código gerado num diretório próprio e nunca editá-lo; envolvê-lo em vez disso |
| um gerador sem versão fixa | o mesmo documento produz código diferente depois de uma atualização | fixar a versão do gerador, como esta lição fixou a do validador |
| suporte desigual | `oneOf`, `anyOf`, `additionalProperties` e campos que aceitam null saem diferentes, ou nem saem, de um gerador para outro | ler o que foi gerado para o seu schema mais difícil antes de confiar no resto |
| um esqueleto gerado uma vez | os handlers são preenchidos, o documento segue em frente, e os dois se desencontram como se nada tivesse sido gerado | gerar de novo as interfaces a cada mudança e implementá-las, em vez de gerar um ponto de partida |
| tamanho | poucas operações viram dezenas de arquivos e uma dependência nova | numa API pequena, comparar com escrever o cliente à mão |

**A última linha é uma escolha real para uma API do tamanho do shelf.** Oito operações são um cliente
que uma pessoa escreve numa tarde. Gerar um começa a compensar quando a API tem centenas de
operações, várias linguagens a chamam, ou o documento muda toda semana e ninguém consegue manter um
cliente escrito à mão em dia. Abaixo disso, o documento continua pagando o que custa como aquilo que
o teste confere e a página que as pessoas leem, que é o que esta lição construiu.
