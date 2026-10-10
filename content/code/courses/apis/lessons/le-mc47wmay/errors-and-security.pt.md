---
title: Descrevendo erros e segurança
version: 1
---

**As respostas que um cliente mais tende a tratar errado são as recusas, e são as que um documento
mais deixa de fora.** Uma resposta de sucesso é o caso que todo mundo escreve primeiro. O 404, o 409
e o 422 são aquilo em que um cliente precisa decidir o que fazer, e um documento que lista só o 200
diz aos seus leitores que nada mais acontece.

## Erros

O documento do shelf os trata em três camadas. Toda recusa tem o mesmo corpo, então há um schema
`Error`. As cinco recusas diferem no significado, então há cinco entradas em `components/responses`,
cada uma com a sua descrição. E cada operação lista os códigos que pode de fato devolver, por
referência, então `GET /books/{id}` lista 404 e não 409, porque ler um livro não conflita com nada.

O que o corpo de um erro deve conter é uma questão à parte. O do shelf é uma frase num campo chamado
`error`, e a lição 2 dá aos erros um formato que um programa consegue ler. Existe também um formato
padrão com um tipo de mídia próprio, `application/problem+json`. Seja qual for o formato, o documento
o enuncia uma vez em `components` e toda operação aponta para ele.

**`default` é o atalho tentador.** No lugar de um código, uma operação pode listar `default`, que quer
dizer "qualquer status não listado aqui", com o schema de erro dentro:

```yaml
responses:
  "200": {$ref: "#/components/responses/OneBook"}
  default: {$ref: "#/components/responses/AnyError"}
```

Ele é honesto sobre uma coisa: um servidor sempre pode falhar de jeitos que ninguém listou, um 500 ou
um 503 de um proxy na frente dele. Mas ele também esconde a diferença entre uma recusa que alguém
projetou e uma que ninguém esperava. Se `PATCH /books/{id}` quebrasse amanhã e respondesse 500, uma
operação com `default` teria esse 500 listado, e um teste de contrato que respeita o `default` o
aprovaria. O documento do shelf não tem `default`, e o `check_contract.py` procura os códigos um por
um, então qualquer código que o `rest.py` mande sem que ninguém o tenha projetado sai como não
listado. Se você usar `default`, guarde-o para as falhas que você de fato não consegue nomear, e
liste mesmo assim todo código que conseguir.

## Esquemas de segurança

O shelf não pergunta a ninguém quem é; a lição 7 é onde isso começa. Mas é aqui que um documento
diria como um cliente prova quem é, e vale reconhecer a forma desde já. Ela tem duas partes: um
esquema definido uma vez em `components/securitySchemes`, e uma lista `security` que diz onde ele
vale, para a API inteira no nível de cima ou para uma operação:

```yaml
components:
  securitySchemes:
    staffKey:
      type: apiKey
      in: header
      name: X-Api-Key
security:
  - staffKey: []
paths:
  /books:
    get:
      security: []
```

Leia em dois passos. O `security` do nível de cima diz que toda operação precisa da chave chamada
`staffKey`. Depois `GET /books` o sobrescreve com uma lista vazia, que quer dizer "nenhum esquema
necessário", então a lista de livros continua pública enquanto todo o resto precisa de chave. O
esquema diz só por onde a chave viaja, num cabeçalho chamado `X-Api-Key`. **Ele nunca contém uma
chave**, e uma chave de verdade escrita num exemplo do documento seria publicada junto com a página
de documentação.

Os tipos de esquema são poucos, e todos menos um são assunto de uma lição deste curso:

| `type` | o que o cliente envia | lição |
|---|---|---|
| `apiKey` | uma chave num cabeçalho, numa query string ou num cookie | 7 |
| `http` com `scheme: basic` ou `scheme: bearer` | um cabeçalho `Authorization` com uma senha ou um token | 7 e 8 |
| `oauth2`, `openIdConnect` | um token obtido por um dos fluxos do OAuth | 9 |
| `mutualTLS` | um certificado, conferido durante o handshake do TLS | fora deste curso |

**Descrever um esquema não impõe nada.** O documento pode dizer que `POST /books` precisa de uma
chave, e o `rest.py` vai continuar aceitando livros de qualquer um, porque o documento é lido por
pessoas e ferramentas, e o `rest.py` nunca o abre. Os dois se ligam do mesmo jeito que todo o resto
desta lição: um teste de contrato que manda a requisição sem chave e espera 401. Quando uma API
confere chaves, que é o assunto da lição 7, essa requisição é uma linha a mais num teste como o
`check_contract.py`, e o 401 é uma resposta a mais no documento contra o qual ele confere.
