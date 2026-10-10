---
title: A especificação do shelf
version: 1
---

**Esta é a versão 1 do shelf inteira, como documento.** Todo endereço que o `rest.py` atende sob
`/v1`, todo método que cada um aceita, os corpos nos dois sentidos e os códigos com que um cliente
pode agir. A versão 2 fica de fora. Ela é um recurso só de leitura, e descrever as duas versões num
arquivo só poria uma versão na frente de todo caminho por causa dela; uma segunda versão costuma
ganhar um documento próprio.

Salve-o ao lado dos dois arquivos Python, no primeiro terminal, com `nano openapi.yaml`. Ele é
comprido porque é completo, e cada parte tem uma nota ao lado; o botão de copiar leva o arquivo
inteiro sem as notas.

```schooling-example
{
  "language": "yaml",
  "file": "shelf/openapi.yaml",
  "parts": [
    {
      "code": "# shelf/openapi.yaml\nopenapi: 3.1.0\ninfo:\n  title: shelf\n  version: 1.0.0\n  description: The bookshop's REST API, version 1, as rest.py serves it.\nservers:\n  - url: http://127.0.0.1:8000/v1",
      "note": "`openapi` diz qual versão da especificação o documento segue. `info.version` é outro número: a versão desta descrição, que você aumenta sempre que ela muda. O endereço do servidor termina em `/v1`, então todo caminho abaixo é relativo a ele."
    },
    {
      "code": "\npaths:\n  /books:\n    get:\n      operationId: listBooks\n      summary: Every book, or the books of one author\n      parameters:\n        - name: author_id\n          in: query\n          required: false\n          schema: {type: integer}\n      responses:\n        \"200\":\n          description: The books, ordered by id\n          content:\n            application/json:\n              schema:\n                type: array\n                items: {$ref: \"#/components/schemas/Book\"}",
      "note": "`paths` tem uma entrada por endereço e, dentro de cada uma, uma **operação** por método. `GET /books` aceita um `author_id` opcional e responde 200 com um array de livros. O `$ref` aponta para o schema de um livro, escrito uma vez só perto do fim."
    },
    {
      "code": "    post:\n      operationId: createBook\n      summary: Add a book\n      requestBody:\n        required: true\n        content:\n          application/json:\n            schema: {$ref: \"#/components/schemas/NewBook\"}\n      responses:\n        \"201\":\n          description: Created\n          headers:\n            Location:\n              required: true\n              description: The new book's address\n              schema: {type: string}\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Book\"}\n        \"400\": {$ref: \"#/components/responses/BadJson\"}\n        \"409\": {$ref: \"#/components/responses/Conflict\"}\n        \"415\": {$ref: \"#/components/responses/NotJson\"}\n        \"422\": {$ref: \"#/components/responses/Invalid\"}",
      "note": "Criar um livro: o que o cliente envia em `requestBody` e o que volta. O 201 marca `Location` como cabeçalho obrigatório, e as quatro recusas apontam para respostas reutilizáveis. Os códigos estão entre aspas porque a especificação os quer como texto, e o YAML leria um `201` solto como número."
    },
    {
      "code": "\n  /books/{id}:\n    parameters:\n      - $ref: \"#/components/parameters/Id\"\n    get:\n      operationId: getBook\n      summary: One book\n      responses:\n        \"200\":\n          description: The book\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Book\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}",
      "note": "`{id}` transforma o caminho num modelo. Uma lista `parameters` neste nível vale para todas as operações do caminho, e o parâmetro em si é definido uma vez em `components`, porque três endereços o usam."
    },
    {
      "code": "    put:\n      operationId: replaceBook\n      summary: Replace a book; a field left out is not kept\n      requestBody:\n        required: true\n        content:\n          application/json:\n            schema: {$ref: \"#/components/schemas/NewBook\"}\n      responses:\n        \"200\":\n          description: The book as it is now\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Book\"}\n        \"400\": {$ref: \"#/components/responses/BadJson\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}\n        \"409\": {$ref: \"#/components/responses/Conflict\"}\n        \"415\": {$ref: \"#/components/responses/NotJson\"}\n        \"422\": {$ref: \"#/components/responses/Invalid\"}\n    patch:\n      operationId: changeBook\n      summary: Change some fields of a book\n      requestBody:\n        required: true\n        content:\n          application/json:\n            schema: {$ref: \"#/components/schemas/BookChange\"}\n      responses:\n        \"200\":\n          description: The book as it is now\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Book\"}\n        \"400\": {$ref: \"#/components/responses/BadJson\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}\n        \"409\": {$ref: \"#/components/responses/Conflict\"}\n        \"415\": {$ref: \"#/components/responses/NotJson\"}\n        \"422\": {$ref: \"#/components/responses/Invalid\"}",
      "note": "PUT e PATCH diferem onde o rest.py os faz diferir, no corpo. O PUT recebe um `NewBook`, em que todo campo menos `stock` é obrigatório, e o PATCH um `BookChange`, em que nenhum é."
    },
    {
      "code": "    delete:\n      operationId: deleteBook\n      summary: Remove a book\n      responses:\n        \"204\":\n          description: Gone, and no body\n        \"404\": {$ref: \"#/components/responses/NotFound\"}",
      "note": "Uma resposta com `description` e sem `content` é o jeito de a especificação dizer que não há corpo, que é o que 204 significa."
    },
    {
      "code": "\n  /authors/{id}:\n    parameters:\n      - $ref: \"#/components/parameters/Id\"\n    get:\n      operationId: getAuthor\n      summary: One author\n      responses:\n        \"200\":\n          description: The author\n          content:\n            application/json:\n              schema: {$ref: \"#/components/schemas/Author\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}\n\n  /authors/{id}/books:\n    parameters:\n      - $ref: \"#/components/parameters/Id\"\n    get:\n      operationId: listAuthorBooks\n      summary: The books of one author\n      responses:\n        \"200\":\n          description: The author's books, ordered by id\n          content:\n            application/json:\n              schema:\n                type: array\n                items: {$ref: \"#/components/schemas/Book\"}\n        \"404\": {$ref: \"#/components/responses/NotFound\"}",
      "note": "Os dois endereços de autor. O rest.py não tem uma lista de autores, então o documento também não tem; descrever `GET /authors` prometeria uma resposta que o servidor dá como 404."
    },
    {
      "code": "\ncomponents:\n  parameters:\n    Id:\n      name: id\n      in: path\n      required: true\n      schema: {type: integer, minimum: 1}",
      "note": "`components` guarda tudo o que é definido uma vez e referenciado por `$ref`. Um parâmetro de caminho precisa dizer `required: true`, porque um endereço com um buraco não é um endereço."
    },
    {
      "code": "\n  schemas:\n    NewBook:\n      type: object\n      additionalProperties: false\n      required: [isbn, title, author_id, year, price_cents]\n      properties:\n        isbn: {type: string, pattern: \"^[0-9]{13}$\"}\n        title: {type: string}\n        author_id: {type: integer}\n        year: {type: integer}\n        price_cents: {type: integer, minimum: 0}\n        stock: {type: integer, minimum: 0, default: 0}\n    BookChange:\n      type: object\n      additionalProperties: false\n      properties:\n        isbn: {type: string, pattern: \"^[0-9]{13}$\"}\n        title: {type: string}\n        author_id: {type: integer}\n        year: {type: integer}\n        price_cents: {type: integer, minimum: 0}\n        stock: {type: integer, minimum: 0}",
      "note": "O que um cliente pode enviar. No OpenAPI 3.1 um schema é **JSON Schema**, a linguagem que o `python3-jsonschema` lê. `additionalProperties: false` faz de um campo desconhecido um erro, como o 422 do rest.py para `colour`. O `pattern` do ISBN é uma regra que o rest.py não confere, e o teste de contrato descobre quanto isso custa."
    },
    {
      "code": "    Book:\n      type: object\n      required: [id, isbn, title, author_id, year, price_cents, stock]\n      properties:\n        id: {type: integer}\n        isbn: {type: string, pattern: \"^[0-9]{13}$\"}\n        title: {type: string}\n        author_id: {type: integer}\n        year: {type: integer}\n        price_cents: {type: integer, minimum: 0}\n        stock: {type: integer, minimum: 0}\n    Author:\n      type: object\n      required: [id, name, country]\n      properties:\n        id: {type: integer}\n        name: {type: string}\n        country: {type: string, pattern: \"^[A-Z]{2}$\"}\n    Error:\n      type: object\n      required: [error]\n      properties:\n        error: {type: string, description: A sentence for a person to read}",
      "note": "O que o servidor devolve. Um `Book` sempre traz os sete campos e não proíbe outros, então um campo acrescentado à resposta um dia não reprova um cliente que valida com este schema. `Error` é o formato único de toda recusa do rest.py."
    },
    {
      "code": "\n  responses:\n    BadJson:\n      description: The body is not JSON, or not a JSON object\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}\n    NotJson:\n      description: The body is not labelled application/json\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}\n    NotFound:\n      description: No such book or author\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}\n    Conflict:\n      description: Another book already has this ISBN\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}\n    Invalid:\n      description: The JSON is fine and its content breaks a rule\n      content:\n        application/json:\n          schema: {$ref: \"#/components/schemas/Error\"}",
      "note": "Cinco respostas que diferem só na descrição. Escritas aqui uma vez, viram dezoito referências de uma linha lá em cima em vez de dezoito cópias de quatro linhas."
    }
  ]
}
```

## O que fica de fora, de propósito

Uma descrição diz aquilo em que os clientes podem confiar, que não é tudo o que o servidor por acaso
faz. Três coisas que o `rest.py` faz não estão nela:

- As respostas 405. `DELETE /v1/books` recebe um 405 com um cabeçalho `Allow`, como a lição 1
  mostrou, mas o documento não lista nenhum `delete` em `/books`, e um método que ele não lista é um
  que o cliente não deve enviar. Descrever um seria listar o método com um 405 como única resposta,
  o que anuncia uma operação que ninguém consegue usar.
- A versão 2, pelo motivo acima.
- O 501 que a biblioteca do Python manda para `OPTIONS`. Ninguém o escolheu, então ninguém pensaria
  em escrevê-lo, e o teste de contrato desta lição o encontra exatamente por isso.

E uma coisa está nele que o `rest.py` não faz. O `pattern` do ISBN, treze dígitos, é a regra da
loja: todo livro que o `db.py` criou a segue. O `rest.py` confere que um ISBN é uma string e mais
nada. Um documento pode dizer o que a API deveria fazer, desde que alguma coisa depois confira se ela
faz.

## O documento é dado

Nada no arquivo é exclusivo das ferramentas de OpenAPI. Ele é YAML, então o `python3-yaml` o lê, e
depois de lido ele pode ser escrito como JSON e entregue ao `jq`, como qualquer resposta do shelf.
Primeiro o nível de cima, depois cada operação, por método e endereço:

```
ana@api:~/shelf$ python3 -c 'import json, sys, yaml; json.dump(yaml.safe_load(sys.stdin), sys.stdout)' < openapi.yaml | jq -c 'keys'
["components","info","openapi","paths","servers"]
ana@api:~/shelf$ python3 -c 'import json, sys, yaml; json.dump(yaml.safe_load(sys.stdin), sys.stdout)' < openapi.yaml | jq -r '.paths | to_entries[] | .key as $p | .value | keys_unsorted[] | select(. != "parameters") | ascii_upcase + " " + $p'
GET /books
POST /books
GET /books/{id}
PUT /books/{id}
PATCH /books/{id}
DELETE /books/{id}
GET /authors/{id}
GET /authors/{id}/books
```

Oito operações, e cada linha é uma que um cliente do shelf pode enviar. Essa lista é o que um gerador
transforma em oito funções, o que uma página de documentação transforma em oito painéis, e o que o
teste de contrato confere uma requisição de cada vez.
