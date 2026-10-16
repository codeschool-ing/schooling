---
title: A chave de partição e a chave de ordenação
version: 1
---

**Uma tabela do DynamoDB não é uma tabela relacional sem os joins.** O hábito que `sql-databases`
deixa é modelar as entidades primeiro e confiar no planejador de consultas para achar as linhas,
qualquer que seja a pergunta. O DynamoDB não tem planejador. Uma leitura rápida nomeia uma chave, e
uma leitura que não nomeia lê a tabela inteira. Então a chave é o projeto, e ela tem duas partes.

**A chave de partição passa por um hash, e o hash escolhe a partição.** O DynamoDB guarda uma tabela
em partições, fatias de armazenamento que ele gerencia e replica em várias zonas da região, e cria
mais conforme a tabela cresce. Quando um item é escrito, o valor da chave de partição passa por uma
função de hash interna, e o resultado decide qual partição o guarda. Duas coisas decorrem disso de
imediato. Todo item com a mesma chave de partição mora no mesmo lugar. E itens cujas chaves parecem
vizinhas, `CUSTOMER#c-17` e `CUSTOMER#c-18`, caem onde o hash de cada um mandar, então não existe uma
leitura do tipo "os clientes de c-17 a c-40".

**A chave de ordenação ordena os itens que dividem uma chave de partição**, e esse grupo se chama
**coleção de itens** (*item collection*). Dentro de uma coleção os itens ficam ordenados pela chave de
ordenação: pelos bytes UTF-8 numa string, a mesma ordem que o S3 usou para as chaves na lição 1, e
pelo valor num número. Uma tabela com as duas partes tem uma chave primária composta, e o par tem de
ser único; uma tabela só com chave de partição guarda um item por valor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três chaves de partição, CUSTOMER#c-17, c-18 e c-19, passam pela função de hash, e cada uma cai numa partição diferente: c-18 na partição 1 com seus 5 itens, c-19 na partição 2 com seus 13, c-17 na partição 3 com seus 12. Chaves que parecem vizinhas não ficam juntas; todo item com a mesma chave de partição fica.\" data-fig=\"l09-partitions\"><defs><marker id=\"l09-partitions-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"20\" y=\"45\" width=\"170\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"105\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CUSTOMER#c-17</text><line x1=\"190\" y1=\"62\" x2=\"262\" y2=\"135\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"20\" y=\"120\" width=\"170\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"105\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CUSTOMER#c-18</text><line x1=\"190\" y1=\"137\" x2=\"262\" y2=\"135\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"20\" y=\"195\" width=\"170\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"105\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CUSTOMER#c-19</text><line x1=\"190\" y1=\"212\" x2=\"262\" y2=\"135\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"264\" y=\"108\" width=\"120\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"324\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">função de hash</text><rect x=\"450\" y=\"20\" width=\"250\" height=\"66\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"462\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição 1</text><rect x=\"462\" y=\"46\" width=\"226\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"472\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CUSTOMER#c-18</text><text x=\"678\" y=\"61\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">5 itens</text><line x1=\"384\" y1=\"135\" x2=\"448\" y2=\"61\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"450\" y=\"100\" width=\"250\" height=\"66\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"462\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição 2</text><rect x=\"462\" y=\"126\" width=\"226\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"472\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CUSTOMER#c-19</text><text x=\"678\" y=\"141\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">13 itens</text><line x1=\"384\" y1=\"135\" x2=\"448\" y2=\"141\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/><rect x=\"450\" y=\"180\" width=\"250\" height=\"66\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"462\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição 3</text><rect x=\"462\" y=\"206\" width=\"226\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"472\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CUSTOMER#c-17</text><text x=\"678\" y=\"221\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">12 itens</text><line x1=\"384\" y1=\"135\" x2=\"448\" y2=\"221\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-partitions-ah)\"/></svg>", "caption": "O hash da chave de partição escolhe a partição, e cada coleção de itens fica inteira dentro de uma. Em qual partição cada chave cai está desenhado só para ilustrar; o moto não tem partição nenhuma."}
```

## A tabela

A tabela da Quitanda se chama `quitanda`, e os dois atributos de chave têm nomes propositalmente sem
graça, `pk` e `sk`, por um motivo que a seção sobre tabela única explica:

```sh
aws dynamodb create-table --table-name quitanda \
  --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=sk,AttributeType=S \
  --key-schema AttributeName=pk,KeyType=HASH AttributeName=sk,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST > /dev/null
```

`HASH` é a palavra da API para a chave de partição e `RANGE` para a de ordenação.
**`--attribute-definitions` nomeia os atributos de chave e mais nada**: não é uma lista de colunas, e
nomear ali um atributo que nenhuma chave ou índice usa é recusado. `PAY_PER_REQUEST` é a cobrança sob
demanda, assunto da lição 11.

```
ana@laptop:~/aws$ aws dynamodb describe-table --table-name quitanda --query "Table.[TableStatus,KeySchema,AttributeDefinitions]" --output text
ACTIVE
pk	HASH
sk	RANGE
pk	S
sk	S
ana@laptop:~/aws$ aws dynamodb create-table --table-name orders-test --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=total_cents,AttributeType=N --key-schema AttributeName=pk,KeyType=HASH --billing-mode PAY_PER_REQUEST

aws: [ERROR]: An error occurred (ValidationException) when calling the CreateTable operation: One or more parameter values were invalid: Number of attributes in KeySchema does not exactly match number of attributes defined in AttributeDefinitions
```

A tabela responde `ACTIVE` na mesma linha, o que na AWS leva alguns segundos e aqui não leva nenhum.
Por trás da resposta o moto guarda um dicionário por tabela e nenhuma partição. O que ele reproduz
fielmente é tudo de que esta lição depende: a ordem dentro de uma coleção, as condições de chave e as
recusas.

## Um item tem a chave, e o que mais quiser

Todo atributo além da chave é assunto do próprio item. Escreva à mão o perfil de um cliente, a partir
de um arquivo. `profile.json`:

```json
{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "PROFILE"}, "name": {"S": "Ana"}, "district": {"S": "Lapa"}}
```

Cada valor leva o seu tipo: `S` para string, `N` para número, e outros para binário, booleano, lista,
mapa e conjunto. A linha de comando fala essa forma tipada, e o programa em Python de uma seção
adiante não precisa falar.

```
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda --item file://profile.json
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "PROFILE"}}'
{
    "Item": {
        "pk": {
            "S": "CUSTOMER#c-17"
        },
        "sk": {
            "S": "PROFILE"
        },
        "name": {
            "S": "Ana"
        },
        "district": {
            "S": "Lapa"
        }
    }
}
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda --key '{"pk": {"S": "CUSTOMER#c-17"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the GetItem operation: Validation Exception
```

**O `get-item` precisa da chave inteira, as duas metades.** Só com a chave de partição ele é recusado,
porque a tabela pode ter muitos itens sob `CUSTOMER#c-17` e o `get-item` devolve exatamente um. A
mensagem do moto é um `Validation Exception` seco; a AWS recusa a mesma requisição com uma frase sobre
a chave não bater com o esquema. Ler parte de uma coleção é outra operação, a `query`, e ela vem duas
seções adiante.
