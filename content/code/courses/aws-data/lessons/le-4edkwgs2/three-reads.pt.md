---
title: get-item, query e scan
version: 1
---

**Há três jeitos de ler uma tabela, e só dois usam a chave.** O `get-item` devolve um item, nomeado
pela chave inteira. A `query` devolve um trecho de uma coleção de itens: recebe exatamente uma chave de
partição, com `=`, e opcionalmente uma condição na chave de ordenação. O `scan` lê todo item da tabela,
numa ordem em que ninguém deveria confiar, e pode filtrar o que devolve. Os dois primeiros custam o que
devolvem; o terceiro custa a tabela inteira toda vez.

## A query, e as condições que ela aceita

**As condições da chave de ordenação são `=`, `<`, `<=`, `>`, `>=`, `BETWEEN` e `begins_with`, e a lista
é essa.** Nada de `contains`, nada de `OR`, nenhuma condição num segundo atributo. Cada uma descreve um
trecho contínuo da coleção ordenada, e é por isso que são baratas: o DynamoDB acha o começo do trecho e
lê para frente. O padrão A3, um pedido e suas linhas, é um prefixo:

```
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}, ":o": {"S": "ORDER#2026-10-05#o-10002"}}' --query 'Items[].[sk.S,total_cents.N,product.S,qty.N]' --output text
ORDER#2026-10-05#o-10002	23490	None	None
ORDER#2026-10-05#o-10002#LINE#1	None	coffee-500g	3
ORDER#2026-10-05#o-10002#LINE#2	None	rice-5kg	3
ORDER#2026-10-05#o-10002#LINE#3	None	eggs-12	3
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND sk BETWEEN :a AND :b' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}, ":a": {"S": "ORDER#2026-10-01"}, ":b": {"S": "ORDER#2026-10-08"}}' --query '[Count,ScannedCount]' --output text
8	8
```

**A primeira query é o A3 e a segunda é o A2.** `begins_with` com o prefixo do pedido devolveu o pedido e
suas três linhas, quatro itens numa requisição. `BETWEEN ORDER#2026-10-01 AND ORDER#2026-10-08` devolveu
os dois pedidos da primeira semana com as linhas: oito itens. O `BETWEEN` inclui as duas pontas, e a
ponta de cima funciona aqui porque nenhuma chave de ordenação é exatamente `ORDER#2026-10-08`; todo
pedido daquele dia seria `ORDER#2026-10-08#o-…`, que vem depois e fica de fora. É a ordem de bytes
fazendo o trabalho de uma comparação de datas. `Count` é o que voltou e `ScannedCount` o que foi lido,
e numa query sem filtro os dois são o mesmo número.

As duas condições que o DynamoDB recusa são as que não podem ser um trecho contínuo:

```
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'sk = :s' --expression-attribute-values '{":s": {"S": "PROFILE"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the Query operation: Query condition missed key schema element: pk
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'begins_with(pk, :p)' --expression-attribute-values '{":p": {"S": "CUSTOMER#"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the Query operation: Query key condition not supported
```

Uma chave de ordenação sozinha não nomeia partição nenhuma, e `begins_with` numa chave de partição
significaria toda partição cujo hash começa num lugar qualquer. As duas são recusadas antes de qualquer
leitura.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A coleção de itens de CUSTOMER#c-17: doze itens na ordem da chave de ordenação, três pedidos, cada um seguido das suas linhas, e PROFILE por último. A2, BETWEEN ORDER#2026-10-01 AND ORDER#2026-10-08, cobre os oito primeiros itens. A3, begins_with o prefixo do pedido o-10002, cobre os itens cinco a oito. A4, lendo do mais novo para o mais antigo sob ORDER# com limite um, para no item onze, a segunda linha do pedido o-10003, e não num pedido. A1, get-item em PROFILE, é o décimo segundo item.\" data-fig=\"l09-collection\"><defs><marker id=\"l09-collection-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"120\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">pk = CUSTOMER#c-17</text><rect x=\"120\" y=\"40\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001</text><rect x=\"120\" y=\"62\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001#LINE#1</text><rect x=\"120\" y=\"84\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001#LINE#2</text><rect x=\"120\" y=\"106\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-03#o-10001#LINE#3</text><rect x=\"120\" y=\"128\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002</text><rect x=\"120\" y=\"150\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002#LINE#1</text><rect x=\"120\" y=\"172\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002#LINE#2</text><rect x=\"120\" y=\"194\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-05#o-10002#LINE#3</text><rect x=\"120\" y=\"216\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"226.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-12#o-10003</text><rect x=\"120\" y=\"238\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-12#o-10003#LINE#1</text><rect x=\"120\" y=\"260\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"/><text x=\"128\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ORDER#2026-10-12#o-10003#LINE#2</text><rect x=\"120\" y=\"282\" width=\"250\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"/><text x=\"128\" y=\"292.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PROFILE</text><line x1=\"95\" y1=\"44.0\" x2=\"95\" y2=\"298.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l09-collection-ah)\"/><text x=\"88\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ordenado por sk</text><path d=\"M384,42 H392 V212 H384\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"/><path d=\"M412,130 H420 V212 H412\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"/><line x1=\"392\" y1=\"94.0\" x2=\"446\" y2=\"94.0\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"452\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A2, entre duas datas: 8 itens</text><line x1=\"420\" y1=\"182.0\" x2=\"446\" y2=\"182.0\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"452\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A3, um pedido e suas linhas: 4</text><line x1=\"372\" y1=\"270.0\" x2=\"446\" y2=\"270.0\" stroke=\"var(--amber)\" stroke-width=\"1\"/><text x=\"452\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">A4, mais novo primeiro, limite 1: uma linha</text><line x1=\"372\" y1=\"292.0\" x2=\"446\" y2=\"292.0\" stroke=\"var(--wire)\" stroke-width=\"1\"/><text x=\"452\" y=\"292.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A1, get-item: exatamente um</text></svg>", "caption": "Uma coleção de itens, e as quatro leituras desta lição como trechos dela. Uma query é sempre um trecho contínuo, e é por isso que o A4 cai numa linha."}
```

## Do mais novo primeiro, e a linha que voltou no lugar

**`--no-scan-index-forward` lê uma coleção de trás para frente**, e com `--limit 1` é o padrão A4, o
pedido mais recente:

```
ana@laptop:~/aws$ aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{":p": {"S": "CUSTOMER#c-17"}, ":o": {"S": "ORDER#"}}' --no-scan-index-forward --limit 1 --query 'Items[].[sk.S,product.S]' --output text
ORDER#2026-10-12#o-10003#LINE#2	eggs-12
```

**Voltou uma linha, não um pedido.** O último item sob `ORDER#` na coleção de c-17 é a segunda linha do
pedido de 12 de outubro, porque as linhas ficam depois do pedido e a leitura ao contrário as encontra
primeiro. A query fez exatamente o que foi pedido; o projeto é que não servia para a pergunta. Há dois
consertos. Um é na leitura: pedir quatro itens do mais novo para o mais antigo, o que cobre um pedido
com suas três linhas, e ficar com o primeiro cuja chave não tem `#LINE#`, pagando pelas linhas em toda
chamada. O outro é na chave, onde ele pertence: se o item do próprio pedido ficasse depois das linhas,
sob uma chave como `ORDER#2026-10-12#o-10003#ORDER`, o último item sob `ORDER#` seria sempre um pedido.
Achar isso quando os padrões são escritos custa uma frase; achar depois que a tabela tem um milhão de
clientes custa uma migração.

## O scan, e o que um filtro não economiza

**Um filtro é aplicado depois da leitura, então decide o que você recebe e não o que você paga.**
Procurar um cliente pelo nome não é um dos padrões, e a tabela responde do único jeito que pode:

```
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression 'name = :n' --expression-attribute-values '{":n": {"S": "Gabi"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the Scan operation: Invalid ConditionExpression: Attribute name is a reserved keyword; reserved keyword: name
ana@laptop:~/aws$ aws dynamodb scan --table-name quitanda --filter-expression '#n = :n' --expression-attribute-names '{"#n": "name"}' --expression-attribute-values '{":n": {"S": "Gabi"}}' --query '[Count,ScannedCount,Items[0].pk.S]' --output text
1	30	CUSTOMER#c-17
```

**O primeiro scan foi recusado antes de ler qualquer coisa, porque `name` é uma palavra reservada.** O
DynamoDB reserva várias centenas de palavras da sua linguagem de expressões, e entre elas estão `name`,
`status`, `date`, `total`, `count` e `size`, exatamente os nomes que as pessoas dão a atributos. O
conserto é um marcador: `#n` na expressão e `{"#n": "name"}` ao lado. O moto mantém a lista da AWS e
recusa as mesmas palavras.

**O segundo scan achou um item e leu trinta.** `Count` é 1 e `ScannedCount` é 30: a tabela inteira foi
lida, e o filtro jogou 29 itens fora depois. Em trinta itens isso não é nada; numa tabela com todo
cliente da Quitanda é a tabela inteira a cada busca, e a lição 10 põe preço nisso. O moto também devolve
um scan em ordem de chave, um efeito colateral do dicionário dele. A AWS devolve na ordem dos hashes das
partições, então um programa que confia na ordem de um scan funciona aqui e não lá.
