---
title: Nomes e formatos
version: 1
---

**Um contrato em JSON carrega decisões que nenhuma linguagem toma por você**: como os nomes são
escritos, como um instante é escrito, como um valor ausente aparece, e como uma lista é embrulhada.
Nenhuma delas tem uma única resposta certa. O erro é tomar cada uma duas vezes, de jeitos
diferentes, de modo que o cliente precise lembrar qual endpoint faz o quê.

## Uma grafia para todos os nomes

O raciocínio comum é que cada campo pode ter o nome que soa melhor na hora. Aí uma resposta tem
`author_id` e a seguinte tem `authorId`, e todo cliente carrega uma lista de exceções. Escolha um
padrão de caixa para a API inteira. As APIs do GitHub e do Stripe usam snake_case, como o shelf; o
guia de estilo de JSON do Google pede camelCase. Os dois funcionam; uma mistura dos dois nunca
funciona.

O mesmo vale para o significado. Se `price` é um objeto com `amount_cents` e `currency` num lugar,
ele é esse objeto em todo lugar, inclusive no corpo que o cliente envia.

## Horário com deslocamento

**Um timestamp é uma string em RFC 3339**, o perfil da ISO 8601 escrito para a internet: data, `T`,
hora e um deslocamento em relação ao UTC. O mesmo instante, escrito pelo `date` em São Paulo e em
UTC:

```
ana@api:~$ date -Iseconds; TZ=UTC date -Iseconds
2026-10-10T01:29:39-03:00
2026-10-10T04:29:39+00:00
```

As duas strings estão corretas e nomeiam o mesmo momento; qualquer leitor converte uma na outra. A
string que dá problema é a que não tem deslocamento, e ela é fácil de produzir:

```
ana@api:~$ python3 -c 'from datetime import datetime; print(datetime.now().isoformat(timespec="seconds"))'
2026-10-10T01:29:39
```

Isso é a hora local de São Paulo sem nada dizendo isso. Um leitor que assume UTC a coloca três horas
longe de quando aconteceu. Envie timestamps com deslocamento, de preferência `Z` ou `+00:00`, e envie
uma data de calendário que não tem hora, como a data de publicação de um livro, como data pura:
`"1899-01-01"`.

## Ausente, null e vazio são três respostas

Um campo pode faltar, estar presente com `null`, ou estar presente com um valor vazio, e muitos
leitores não distinguem os dois primeiros. O `jq` é um deles, a menos que você pergunte diretamente:

```
ana@api:~$ echo '{"subtitle": null}' | jq -c '[.subtitle, has("subtitle")]'
[null,true]
ana@api:~$ echo '{}' | jq -c '[.subtitle, has("subtitle")]'
[null,false]
```

`.subtitle` é `null` nas duas vezes; só o `has` vê a diferença. Então o contrato dá a cada um o seu
significado e o mantém. **Ausente** quer dizer "não faz parte desta mensagem" e, numa atualização
parcial, "deixe como está". **`null`** quer dizer "sabidamente sem valor": o JSON Merge Patch, RFC
7396, usa exatamente isso para remover um campo, porque ausente já quer dizer "sem mudança". **Uma
lista vazia é `[]`**, nunca `null` e nunca ausente, para que o cliente possa percorrê-la sem
conferir antes.

## Booleanos são booleanos

Um indicador enviado como string se lê certo para uma pessoa e errado para um programa. No `jq`, como
no Python e no JavaScript, qualquer string não vazia conta como verdadeira:

```
ana@api:~$ echo '{"in_stock": "false"}' | jq 'if .in_stock then "in stock" else "sold out" end'
"in stock"
```

O livro está esgotado e o cliente diz que tem em estoque. O catálogo do shelf envia
`"in_stock": false`, um booleano de verdade, e a mesma regra vale no outro sentido: o schema dele
recusa `"1891"` onde pede um ano.

## Enums são strings que podem crescer

Um valor de um conjunto fixo, como uma moeda ou o estado de um pedido, vai como string legível,
`"BRL"` ou `"shipped"`, nunca como um número cujo significado mora num documento. E o conjunto
cresce: no dia em que a loja vender em euros, aparece `"EUR"`. **O cliente deve tratar um valor que
não conhece como "outra coisa", e não como erro**, e o contrato deve dizer, ao lado do enum, que ele
pode crescer.

## Um envelope para listas, nenhum para itens

Um livro é enviado como o próprio livro, sem embrulho. Uma lista de livros é o contrário: um array
puro não tem onde pôr nada além dos livros, então no dia em que precisar de um link para a próxima
página, acrescentá-lo muda o tipo do corpo e quebra todo cliente. O catálogo do shelf embrulha as
listas desde o início:

```json
{"items": [ ... ], "next": "/v1/books?limit=2&after=WyJpZCIsIDIsIDJd"}
```

`next` está sempre presente, e é `null` na última página, que é o segundo significado acima posto em
uso: existe próxima página, ou se sabe que não existe nenhuma.

| decisão | a escolha do shelf |
|---|---|
| caixa dos nomes | snake_case em tudo, na entrada e na saída |
| timestamps | strings em RFC 3339 com deslocamento |
| um valor sem valor | `null`, presente; ausente quer dizer só "não enviado" |
| uma lista vazia | `[]` |
| indicadores | `true` e `false` |
| enums | strings, documentadas como abertas a valores novos |
| um item | o próprio objeto |
| uma lista | `{"items": [...], "next": ...}` |
