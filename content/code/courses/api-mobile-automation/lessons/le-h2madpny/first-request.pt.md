---
title: Uma primeira requisição, e os painéis que respondem
version: 1
---

**Uma requisição no Postman é a requisição da lição 1 com cada parte num campo próprio.** O método é
uma lista suspensa, o endereço é uma caixa de texto, e os cabeçalhos e o corpo têm cada um a sua
aba. A resposta volta dividida do mesmo jeito: status, tempo e tamanho numa linha, e depois o corpo
e os cabeçalhos em abas logo abaixo. Nada de novo viaja; só a disposição muda.

## Mandando

Abra uma nova requisição HTTP: o botão **New**, depois *HTTP*. Abre uma aba com uma barra comprida
no alto. À esquerda dela fica o método, em `GET`; no meio, o endereço; à direita, **Send**. Embaixo
da barra ficam abas para os parâmetros de consulta, a autorização, os cabeçalhos, o corpo e os
scripts. Digite o endereço dos espetáculos e mande:

```
http://localhost:8080/v1/shows
```

O segundo terminal, o que roda o boxoffice, imprime uma linha para ela, como fez para cada
requisição do curl: `GET /v1/shows 200`. Essa linha é a prova de que a requisição saiu e foi
respondida, e vale uma olhada sempre que o aplicativo e o servidor parecerem discordar.

## Lendo a resposta

A metade de baixo da janela é a resposta. Leia na ordem que a lição 1 deu:

| o que você vê | onde | nos termos da lição 1 |
|---|---|---|
| `200 OK` | na linha acima do corpo, à direita | a linha de status |
| um tempo em milissegundos | ao lado do status | `curl -w '%{time_total}'` |
| um tamanho em bytes | ao lado do tempo | os cabeçalhos e o corpo somados |
| aba **Headers**, com uma contagem | embaixo da linha de status | as linhas `<` do `curl -v` |
| aba **Body**: *Pretty*, *Raw*, *Preview* | embaixo da linha de status | o JSON que o jq organizou |

Passar o mouse sobre o tempo o divide nas suas partes, e passar sobre o tamanho separa cabeçalhos de
corpo. Abra a aba Headers e procure `content-type: application/json` e `cache-control:
max-age=60`, os dois cabeçalhos que dizem como ler e como guardar esta resposta.

**Pretty não é o que o servidor mandou.** É o corpo interpretado e organizado de novo, um campo por
linha, do jeito que o jq organizou. O servidor mandou uma linha só, sem espaços. Na maioria dos dias
isso não faz diferença. Quando os bytes exatos importam, como num teste de espaços, de ordem dos
campos ou de um corpo que não é bem JSON, mude para *Raw*, que é o texto como chegou.

Agora peça um espetáculo que não existe, `http://localhost:8080/v1/shows/sh-999`. O status vira
`404 Not Found`, e a aba Headers diz `content-type: application/problem+json`, o formato de erro da
lição 2. Quem testa lê o rótulo de um erro com o mesmo cuidado que o de um sucesso, porque é por ele
que um cliente decide como interpretar o corpo.

## O que o Postman acrescenta à sua requisição

**O Postman manda mais cabeçalhos do que você digitou.** Ele acrescenta um `User-Agent` com o
próprio nome, um `Accept`, um `Postman-Token` com um valor aleatório e alguns sobre a conexão. Eles
aparecem na aba Headers da requisição, atrás de uma opção de cabeçalhos *ocultos*. O Console do
Postman, aberto pela barra de baixo, mostra cada requisição exatamente como saiu. Isso importa no
dia em que uma requisição funciona no Postman e falha no seu app: a diferença pode ser um cabeçalho
que o Postman acrescentou e o seu app não manda.

Não salve esta requisição ainda. A seção 06 importa uma coleção inteira, com esta requisição já
dentro, com um nome.
