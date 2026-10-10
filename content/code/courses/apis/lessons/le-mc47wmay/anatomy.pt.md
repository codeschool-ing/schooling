---
title: A anatomia de um documento
version: 1
---

**Um documento OpenAPI é um objeto só, aninhado em alguns níveis, e cada nível responde a uma
pergunta.** Que API é esta? Que endereços ela tem? O que cada método faz em cada endereço? O que
volta, com qual código? As respostas ficam umas dentro das outras nessa ordem, e as peças usadas em
mais de um lugar são escritas uma vez, no fim, e apontadas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 340\" role=\"img\" aria-label=\"O aninhamento do documento OpenAPI do shelf. No nível de cima ficam openapi, info, servers, paths e components. Dentro de paths está o endereço /books/{id}; dentro dele a operação get; dentro dela responses; dentro disso o código &quot;200&quot;; dentro dele content, application/json e por fim um schema que é só um $ref. O $ref aponta para components, onde schemas guarda Book, NewBook e Error, e responses e parameters guardam as peças usadas mais de uma vez.\"><defs><marker id=\"l06-nest-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"680\" height=\"320\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"22\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">openapi.yaml</text><rect x=\"130\" y=\"16\" width=\"104\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"182.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">openapi: 3.1.0</text><rect x=\"242\" y=\"16\" width=\"104\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"294.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">info</text><rect x=\"354\" y=\"16\" width=\"104\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"406.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">servers</text><rect x=\"22\" y=\"52\" width=\"420\" height=\"268\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">paths</text><text x=\"432\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma entrada por endereço</text><rect x=\"34\" y=\"80\" width=\"396\" height=\"230\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/books/{id}</text><text x=\"196\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parameters</text><rect x=\"46\" y=\"108\" width=\"372\" height=\"192\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"56\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">get</text><text x=\"408\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma operação; put, patch e delete ficam ao lado</text><rect x=\"58\" y=\"136\" width=\"348\" height=\"154\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"68\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">responses</text><rect x=\"70\" y=\"164\" width=\"324\" height=\"116\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;200&quot;</text><text x=\"384\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma entrada por código de status</text><rect x=\"82\" y=\"192\" width=\"300\" height=\"78\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"92\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">content: application/json</text><rect x=\"94\" y=\"222\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"194.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">schema: $ref</text><rect x=\"460\" y=\"52\" width=\"218\" height=\"268\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">components</text><text x=\"668\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escrito uma vez</text><rect x=\"472\" y=\"80\" width=\"194\" height=\"120\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">schemas</text><rect x=\"484\" y=\"106\" width=\"170\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"569.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Book</text><rect x=\"484\" y=\"136\" width=\"170\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"569.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NewBook</text><rect x=\"484\" y=\"166\" width=\"170\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"569.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Error</text><rect x=\"472\" y=\"210\" width=\"194\" height=\"44\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"482\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">responses</text><text x=\"482\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NotFound, Invalid, …</text><rect x=\"472\" y=\"264\" width=\"194\" height=\"44\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"482\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">parameters</text><text x=\"482\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Id</text><line x1=\"294\" y1=\"240\" x2=\"482\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l06-nest-ah)\"></line></svg>", "caption": "Cada chave é uma caixa dentro de outra, e o $ref é a única saída do aninhamento: ele nomeia um lugar em outra parte do mesmo documento."}
```

Ele é escrito em YAML ou em JSON, e a escolha não muda nada: YAML são os mesmos dados com menos
pontuação, e por isso quem escreve à mão prefere YAML e os programas que geram um documento
costumam escrever JSON. A próxima seção transforma o YAML do shelf em JSON com uma linha de Python
para mostrar isso.

## O nível de cima

| chave | o que guarda | obrigatória |
|---|---|---|
| `openapi` | a versão da especificação que o documento segue, como `3.1.0` | sim |
| `info` | o `title` da API e a `version` do próprio documento, mais uma `description` opcional | sim |
| `servers` | os endereços-base aos quais os caminhos são relativos | não; sem ela, `/` |
| `paths` | cada endereço e o que ele faz | uma de `paths`, `components` ou `webhooks` |
| `components` | schemas, respostas, parâmetros e o resto, definidos uma vez | idem |
| `security`, `tags` | quem pode chamar, e como as operações se agrupam numa página | não |

`info.version` engana todo mundo uma vez. Não é a versão da OpenAPI e não é o `/v1` da API. É a
versão desta descrição, e muda quando a descrição muda, mesmo que seja para corrigir um erro de
digitação num resumo.

## De um endereço até um schema

Dentro de `paths`, cada chave é um endereço, e uma parte entre chaves é um **parâmetro de
caminho**: `/books/{id}` cobre `/books/1` e `/books/99`. Dentro de cada endereço fica uma
**operação** por método, com o nome em minúsculas: `get`, `post`, `put`, `patch`, `delete`, mais
`head`, `options` e `trace`. Um método que não está na lista é um método que o documento não
descreve, o que é diferente de um método que o servidor recusa, e o teste de contrato desta lição
esbarra exatamente nessa diferença.

Uma operação traz quatro coisas que vale conhecer pelo nome:

- `operationId`, um nome para a operação, único no documento. Uma pessoa pode ignorá-lo; um
  gerador de código o transforma em nome de função, então ele faz parte do contrato para quem gera
  um cliente.
- `parameters`, cada um com um `name`, um `in` (`path`, `query`, `header` ou `cookie`) e um
  `schema`. Um parâmetro de caminho precisa dizer `required: true`. Uma lista de parâmetros escrita
  ao lado dos métodos, no nível do próprio endereço, vale para todos eles.
- `requestBody`, o que o cliente envia, por tipo de mídia: `content`, depois `application/json`,
  depois um `schema`.
- `responses`, com chave pelo código de status, cada uma com uma `description` e, quando há corpo,
  um `content` organizado como o da requisição. Uma resposta também pode listar `headers`.

**Os códigos de status são chaves e precisam estar entre aspas**, `"200"` e não `200`. A
especificação pede texto, e o YAML lê um número solto como número; algumas ferramentas perdoam e
outras não. No lugar de um código, `default` cobre todo código não listado, e a seção sobre erros
pesa o que isso custa.

## `components` e `$ref`

O jeito óbvio de descrever o livro que `GET /books/1` devolve é escrever os sete campos dele dentro
dessa resposta. Aí `GET /books` precisa deles de novo dentro de um array, e as respostas de POST, PUT
e PATCH também, e os livros de um autor: seis cópias, que vão discordar na segunda edição.

Por isso schemas, respostas, parâmetros e o resto são escritos uma vez em `components`, e usados
com **`$ref`**:

```yaml
schema: {$ref: "#/components/schemas/Book"}
```

O valor é um **ponteiro**, não uma cópia: `#` é a raiz deste documento, e cada segmento depois dele
é uma chave, então ele se lê como "o `Book` dentro de `schemas` dentro de `components`". Uma
ferramenta o segue quando precisa do schema. Se não houver nada lá, o documento está quebrado, e o
validador, duas seções adiante, diz isso. Um ponteiro também pode nomear outro arquivo,
`./book.yaml#/Book`, que é como uma API grande divide a sua descrição; a do shelf cabe num só.

O que fica na ponta de um ponteiro dentro de `schemas` é **JSON Schema** puro. A partir da 3.1, a
OpenAPI usa o JSON Schema como ele é, a mesma linguagem que o `python3-jsonschema` lê, e é por isso
que esta lição consegue conferir as respostas do shelf com uma biblioteca que não sabe nada de
OpenAPI. A versão 3.0 usava um dialeto próprio que diferia em detalhes, como o jeito de escrever um
campo que pode ser `null`, e essa diferença é um motivo comum para uma ferramenta feita para a 3.0
ler errado um arquivo 3.1.
