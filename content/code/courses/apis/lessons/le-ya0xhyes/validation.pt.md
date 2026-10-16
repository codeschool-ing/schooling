---
title: Validação com JSON Schema
version: 1
---

**As regras do que um cliente pode enviar ficam num arquivo, não espalhadas por `if`s.** JSON Schema
é um vocabulário para escrever essas regras em JSON: que campos um objeto tem, quais são
obrigatórios, que tipo e que faixa cada um aceita. Uma biblioteca então confere um corpo contra o
arquivo, e o mesmo arquivo pode ser entregue a quem escreve um cliente.

O `rest.py` da aula 1 conferia na mão, e o jeito como ele respondia mostra o custo. Ele procurava
campos desconhecidos, depois tipos errados, depois campos faltando, e respondia no primeiro tipo de
erro que achava. Um cliente que manda um corpo com quatro erros fica sabendo de um tipo, corrige,
manda de novo, e fica sabendo do próximo. **Um validador deve relatar todos os erros numa resposta
só.**

## O schema

Este é o contrato de um livro que o cliente envia ao catálogo. Salve-o em `~/shelf` como
`book.schema.json`, com o `nano` como antes. JSON não tem comentários, então este é o único arquivo
do curso que não pode começar com o próprio caminho.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://shelf.example/schemas/book.schema.json",
  "title": "A book, as a client sends it to POST /v1/books",
  "type": "object",
  "additionalProperties": false,
  "required": ["isbn", "title", "author_id", "year", "price"],
  "properties": {
    "isbn": {"type": "string", "pattern": "^97[89][0-9]{10}$"},
    "title": {"type": "string", "minLength": 1, "maxLength": 200},
    "author_id": {"type": "integer", "minimum": 1},
    "year": {"type": "integer", "minimum": 1450},
    "price": {
      "type": "object",
      "additionalProperties": false,
      "required": ["amount_cents", "currency"],
      "properties": {
        "amount_cents": {"type": "integer", "minimum": 0},
        "currency": {"enum": ["BRL"]}
      }
    },
    "stock": {"type": "integer", "minimum": 0, "default": 0}
  }
}
```

Lido de cima para baixo:

| palavra-chave | o que ela diz aqui |
|---|---|
| `$schema` | em que versão do JSON Schema isto está escrito: 2020-12, a atual |
| `$id` | um nome para o schema, para que outros documentos possam se referir a ele; nada é baixado dali |
| `type: object` | o corpo é um objeto, então um array ou uma string é recusado antes de tudo |
| `required` | os cinco campos sem os quais um livro não é criado; `stock` pode ficar de fora |
| `additionalProperties: false` | **qualquer campo fora da lista é erro** |
| `pattern` | um ISBN-13 é 978 ou 979 e mais dez dígitos |
| `minLength`, `maxLength`, `minimum` | as faixas: um título não é vazio, um ano não é anterior à imprensa |
| `enum` | a única moeda aceita hoje, `BRL` |
| `default` | documenta o que um `stock` ausente significa; não o preenche |

A última linha pega muita gente. `default` é uma anotação: o validador a lê e não faz nada com ela,
então o próprio `catalogue.py` escreve `value.get("stock", 0)`.

`additionalProperties: false` é a que mais muda o comportamento. Sem ela, um cliente que digita
`pirce` em vez de `price` recebe um livro criado sem nenhum problema de preço relatado, porque
`pirce` é um campo a mais que ninguém olha, e o cliente acredita que definiu um preço. **Na entrada,
um campo desconhecido é recusado.** A seção sobre compatibilidade explica por que a mesma regra está
errada do outro lado, no que o cliente lê.

## Conferindo um corpo

O `python3-jsonschema` traz um comando, `jsonschema`, que confere um arquivo contra um schema. Um
livro com vários erros ao mesmo tempo:

```
ana@api:~/shelf$ echo '{"isbn": "978650000007", "title": "", "year": "1891", "price": {"amount_cents": 39.90}, "colour": "red"}' > bad.json
ana@api:~/shelf$ jsonschema -i bad.json book.schema.json; echo "exit $?"
{'isbn': '978650000007', 'title': '', 'year': '1891', 'price': {'amount_cents': 39.9}, 'colour': 'red'}: Additional properties are not allowed ('colour' was unexpected)
{'isbn': '978650000007', 'title': '', 'year': '1891', 'price': {'amount_cents': 39.9}, 'colour': 'red'}: 'author_id' is a required property
978650000007: '978650000007' does not match '^97[89][0-9]{10}$'
: '' is too short
1891: '1891' is not of type 'integer'
{'amount_cents': 39.9}: 'currency' is a required property
39.9: 39.9 is not of type 'integer'
exit 1
```

Sete erros, um por linha, e status de saída 1. Cada linha começa pela parte do corpo de que o erro
trata, impressa do jeito que o Python imprime, e depois diz o que está errado. São o `colour`
desconhecido, o `author_id` ausente, um ISBN de doze dígitos, um título vazio, um ano enviado como
texto, um preço sem moeda e um preço que não é número inteiro. Um livro correto não imprime nada e
sai com 0:

```
ana@api:~/shelf$ echo '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price": {"amount_cents": 3990, "currency": "BRL"}}' > good.json
ana@api:~/shelf$ jsonschema -i good.json book.schema.json; echo "exit $?"
exit 0
```

## O que `integer` quer dizer

Mais um arquivo, o mesmo livro com o preço escrito como `3990.0`:

```
ana@api:~/shelf$ echo '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price": {"amount_cents": 3990.0, "currency": "BRL"}}' > float.json
ana@api:~/shelf$ jsonschema -i float.json book.schema.json; echo "exit $?"
exit 0
```

Passa. O JSON tem um tipo de número só, como a primeira seção desta aula mostrou, então o JSON
Schema define `integer` como **um número sem parte fracionária**, e `3990.0` não tem. Se isso é
aceitável é uma questão para o código que o lê. Aqui é: o valor vai para uma coluna `INTEGER`, e o
SQLite guarda `3990.0` ali como o número inteiro `3990`. Um leitor que o mantivesse como float
precisaria de uma conferência própria.

O `catalogue.py`, na próxima seção, carrega este schema quando inicia e passa todo corpo de POST por
ele. A aula 6 põe a mesma linguagem de schema dentro de um documento OpenAPI, onde ela descreve todo
corpo que a API envia e recebe.
