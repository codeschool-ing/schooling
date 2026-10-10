---
title: Páginas
version: 1
---

**Uma coleção é enviada uma página por vez, a página tem um tamanho máximo, e a resposta diz onde
está a próxima.** Seis livros cabem numa resposta; sessenta mil não, e uma API que manda a tabela
inteira para todo cliente que pede a lista para de responder no dia em que a tabela cresce. A
questão é como o cliente pede "a próxima página", e a resposta óbvia é a que falha.

## Offset e limit

A resposta óbvia é uma posição: `?offset=40&limit=20`, pule quarenta linhas e envie vinte. É fácil de
escrever, e deixa o cliente pular direto para a página 37. Mas uma posição só aponta para a mesma
linha enquanto nada muda, e uma coleção em que as pessoas escrevem muda entre uma requisição e a
seguinte.

## Um cursor no lugar

Um cursor pergunta do outro jeito: pelas linhas **depois da última linha da página anterior**, pelos
valores dela e não pela posição. "Livros com id abaixo de 5", não "linhas três e quatro". O
`catalogue.py` pagina assim, e a diferença aparece assim que a coleção muda entre duas páginas.

Aqui estão os livros do mais novo para o mais antigo, dois por página, dos dois jeitos ao mesmo
tempo: o `sqlite3` mostra o que uma consulta por offset devolve, e o `catalogue.py` é chamado com
`sort=-id`. A primeira página é a mesma nos dois:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT id, title FROM books ORDER BY id DESC LIMIT 2 OFFSET 0'
6|Americanah
5|Ensaio sobre a Cegueira
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=-id&limit=2' | jq -c '.items[].id, .next'
6
5
"/v1/books?sort=-id&limit=2&after=WyItaWQiLCA1LCA1XQ"
```

Agora alguém acrescenta um livro:

```
ana@api:~/shelf$ curl -s -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price": {"amount_cents": 3990, "currency": "BRL"}}' | jq -c '{id, title}'
{"id":7,"title":"Quincas Borba"}
```

E os dois pedem a segunda página:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT id, title FROM books ORDER BY id DESC LIMIT 2 OFFSET 2'
5|Ensaio sobre a Cegueira
4|Perto do Coração Selvagem
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?sort=-id&limit=2&after=WyItaWQiLCA1LCA1XQ' | jq -c '.items[].id, .next'
4
3
"/v1/books?sort=-id&limit=2&after=WyItaWQiLCAzLCAzXQ"
```

O livro 7 chegou na frente da lista e empurrou cada linha uma posição para trás, então a segunda
página do offset, linhas três e quatro, agora é 5 e 4. **O livro 5 aparece duas vezes.** Se um livro
tivesse sido apagado, tudo teria andado para a frente e um livro nunca teria aparecido. Nenhum dos
casos produz erro; um cliente que copia a lista para o próprio banco acaba, em silêncio, com uma
duplicata ou uma lacuna.

A segunda página do cursor pediu ids abaixo de 5 e recebeu 4 e 3, sem efeito nenhum da inserção. O
livro 7 nem está nesta caminhada: ele chegou na frente de onde ela começou, e está na primeira página
da próxima.

Um offset tem um segundo custo. Para responder `OFFSET 100000`, o banco ainda percorre as cem mil
linhas que depois joga fora, então as páginas ficam mais lentas quanto mais fundo o cliente lê. Um
cursor vira uma condição `WHERE` e, com um índice no campo de ordenação, a milésima página custa o
mesmo que a primeira.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Três fileiras de livros, do mais novo para o mais antigo. A primeira página, antes da inserção, são os livros 6 e 5. Depois que o livro 7 entra na frente, o offset 2 conta duas posições e devolve os livros 5 e 4, então o livro 5 aparece duas vezes. O cursor pede ids abaixo de 5 e devolve os livros 4 e 3.\"><text x=\"272.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"324.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"376.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"428.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"480.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"532.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"584.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"236\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">posição</text><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">página 1, antes da inserção</text><text x=\"20\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">limit=2</text><rect x=\"250\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"272.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><rect x=\"302\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"324.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">5</text><rect x=\"354\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"376.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><rect x=\"406\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"428.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text><rect x=\"458\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><rect x=\"510\" y=\"40\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"532.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"20\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">página 2 por offset</text><text x=\"20\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">offset=2</text><rect x=\"250\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"272.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">7</text><rect x=\"302\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"324.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><rect x=\"354\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"376.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">5</text><rect x=\"406\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"428.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><rect x=\"458\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"480.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text><rect x=\"510\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"532.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><rect x=\"562\" y=\"130\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"584.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"20\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">página 2 por cursor</text><text x=\"20\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">after=(id 5)</text><rect x=\"250\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"272.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">7</text><rect x=\"302\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"324.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><rect x=\"354\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"376.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">5</text><rect x=\"406\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"428.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><rect x=\"458\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text><rect x=\"510\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"532.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text><rect x=\"562\" y=\"220\" width=\"44\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"584.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"376.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">mostrado duas vezes</text><text x=\"612\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o livro 7 chegou:</text><text x=\"612\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">toda linha andou</text><text x=\"612\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">ids abaixo de 5:</text><text x=\"612\" y=\"251\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nada andou</text></svg>", "caption": "Um offset conta posições, e uma inserção move todas as posições depois dela. Um cursor nomeia a última linha vista, e uma inserção não a move."}
```

## Como a próxima página é anunciada

O `catalogue.py` dá o endereço da próxima página duas vezes, no corpo como `next` e num cabeçalho
`Link` com `rel="next"`, a forma que a RFC 8288 define e que a API do GitHub, entre outras, usa. A
ordenação padrão é por id:

```
ana@api:~/shelf$ curl -si 'localhost:8000/v1/books?limit=2'
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:42 GMT
Content-Type: application/json
Content-Length: 433
Link: </v1/books?limit=2&after=WyJpZCIsIDIsIDJd>; rel="next"

{"items": [{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price": {"amount_cents": 3990, "currency": "BRL"}, "stock": 12, "in_stock": true}, {"id": 2, "isbn": "9786500000023", "title": "Memórias Póstumas de Brás Cubas", "author_id": 1, "year": 1881, "price": {"amount_cents": 4490, "currency": "BRL"}, "stock": 7, "in_stock": true}], "next": "/v1/books?limit=2&after=WyJpZCIsIDIsIDJd"}
```

O cursor dentro do link guarda três coisas: a ordenação, o valor da última linha para ela e o id da
última linha, em JSON codificado em base64 seguro para URL:

```
ana@api:~/shelf$ echo WyJpZCIsIDIsIDJd | base64 -d; echo
["id", 2, 2]
```

O contrato o chama de **opaco**: o cliente o copia do link `next` e nunca monta nem lê um, então o
servidor fica livre para mudar o que vai dentro. Opaco não quer dizer secreto, como o `base64 -d`
mostra; nada num cursor pode ser algo que o cliente não deveria ver.

O cliente segue `next` até ele ser `null`:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?limit=2&after=WyJpZCIsIDIsIDJd' | jq -c '.items[].id, .next'
3
4
"/v1/books?limit=2&after=WyJpZCIsIDQsIDRd"
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?limit=2&after=WyJpZCIsIDQsIDRd' | jq -c '.items[].id, .next'
5
6
"/v1/books?limit=2&after=WyJpZCIsIDYsIDZd"
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?limit=2&after=WyJpZCIsIDYsIDZd' | jq -c '.items[].id, .next'
7
null
```

Uma página também tem teto. `limit` vale 20 por padrão e vai até 100, e um cliente que pede mais
fica sabendo, em vez de receber o servidor inteiro em linhas:

```
ana@api:~/shelf$ curl -s 'localhost:8000/v1/books?limit=500' | jq -r .detail
limit is a whole number from 1 to 100
```

Algumas APIs baixam em silêncio um limite alto demais; o cliente então recebe menos linhas do que
pediu e precisa perceber. Recusar é a escolha que não dá para ler errado.

| | offset e limit | cursor |
|---|---|---|
| uma linha acrescentada ou removida entre páginas | linhas se repetem ou são puladas | nada se move |
| pular direto para a página 37 | sim | não; as páginas são percorridas em ordem |
| custo de uma página no fundo da lista | cresce com o offset | o mesmo da primeira página, havendo índice |
| o que o cliente envia de volta | um número que ele calcula | o link que recebeu |
