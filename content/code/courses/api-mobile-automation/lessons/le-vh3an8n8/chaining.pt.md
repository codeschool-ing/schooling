---
title: Encadeamento, uma resposta alimentando a próxima requisição
version: 1
---

**Encadear é um script guardar um valor de uma resposta, e uma requisição posterior lê-lo como
variável.** A lição 4 fez isso com as suas mãos: copiar o token, colar no ambiente; confiar que o
pedido é `ord-1001`. A coleção agora faz as duas coisas nos scripts, e cada uma ocupa uma linha.

## O token

As duas últimas linhas do script de **Get token**, depois dos três testes:

```js
pm.collectionVariables.set('token', body.access_token);
pm.collectionVariables.set('tokenExpires', Date.now() + (body.expires_in - 30) * 1000);
```

A primeira guarda o token onde a autorização `bearer` da coleção procura `{{token}}`, então toda
requisição de `orders` o manda dali em diante. A segunda anota quando o token deixa de valer, em
milissegundos desde 1970, que é a unidade de `Date.now()`: `expires_in` segundos a partir de agora,
menos trinta segundos de folga. A seção 05 é o script que lê isso.

**O `set` fica fora dos testes de propósito.** Dentro de um `pm.test`, uma asserção que falha
interrompe a função, e um `set` escrito depois dela seria pulado justamente quando a resposta veio
estranha. Fora, ele sempre roda. Se a requisição de token respondeu `401`, `body.access_token` é
`undefined` e é isso que fica guardado, e os testes de token acima já disseram, pelo nome, o que deu
errado.

## Por que uma variável da coleção

O Postman consegue guardar em qualquer escopo: `pm.environment.set`, `pm.globals.set`,
`pm.collectionVariables.set` e `pm.variables.set` para o escopo local de uma requisição. O token
pertence a uma execução desta coleção, então é na coleção que ele fica. O ambiente é configuração
que você compartilha com um time, e um script escrevendo nele muda valores que todo mundo que usa
aquele ambiente vê. É também por isso que o ambiente não pode definir `token` de jeito nenhum, como
a seção 02 descobriu. Um nome no escopo mais estreito esconde o que o script escreveu, seja qual for
o valor.

## O pedido

A última linha de **Create order** guarda o endereço que o boxoffice deu ao pedido novo:

```js
pm.collectionVariables.set('orderUrl', pm.response.headers.get('location'));
```

`location` traz `/v1/orders/ord-1001`, ou seja lá qual for o nome deste pedido. Então as três
requisições depois dele são escritas `{{baseUrl}}{{orderUrl}}`, e leem, cancelam e leem de novo **o
pedido que esta execução criou**, qualquer que seja o número. O `orderId` da lição 4 sumiu: um id
fixo só funcionava num boxoffice recém-iniciado, e uma vez só.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 710 264\" role=\"img\" aria-label=\"Cinco requisições rodam em ordem: Get token, Create order, Read order, Cancel order e Read cancelled. Get token guarda token nas variáveis da coleção, e Create order o lê como token Bearer. Create order guarda orderUrl a partir do cabeçalho location, /v1/orders/ord-1001, e as três últimas requisições o leem como {{baseUrl}}{{orderUrl}}.\"><defs><marker id=\"f05chain-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Get token</text><rect x=\"160\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"215\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Create order</text><rect x=\"300\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Read order</text><rect x=\"440\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"495\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Cancel order</text><rect x=\"580\" y=\"30\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Read cancelled</text><line x1=\"130\" y1=\"50\" x2=\"160\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"270\" y1=\"50\" x2=\"300\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"410\" y1=\"50\" x2=\"440\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"550\" y1=\"50\" x2=\"580\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"355\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a execução, na ordem do arquivo</text><rect x=\"20\" y=\"170\" width=\"185\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"215\" y=\"170\" width=\"475\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"112\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">token</text><text x=\"452\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orderUrl = /v1/orders/ord-1001</text><text x=\"452\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">copiado do cabeçalho location</text><line x1=\"75\" y1=\"70\" x2=\"75\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"81\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">guarda</text><line x1=\"180\" y1=\"168\" x2=\"180\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"174\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Bearer</text><line x1=\"245\" y1=\"70\" x2=\"245\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"251\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">guarda</text><line x1=\"355\" y1=\"168\" x2=\"355\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"495\" y1=\"168\" x2=\"495\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><line x1=\"635\" y1=\"168\" x2=\"635\" y2=\"72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f05chain-ah)\"></line><text x=\"425\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">{{baseUrl}}{{orderUrl}}</text><text x=\"355\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dois ficam nas variáveis da coleção, e uma requisição só lê o que uma anterior guardou</text></svg>", "caption": "Dois valores guardados por scripts, lidos pelas requisições depois deles."}
```

O preço do encadeamento é a ordem. **Read order não significa nada sozinho**: rode-o isolado, antes de
qualquer Create order, e `orderUrl` fica indefinido. Isso é aceitável dentro de uma coleção, onde a
ordem está escrita e o Newman a segue. Não é aceitável entre coleções, ou entre arquivos de teste,
que é o assunto da lição 12.
