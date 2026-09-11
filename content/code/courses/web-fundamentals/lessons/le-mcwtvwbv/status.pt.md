---
title: Três dígitos, e de quem é a culpa
version: 1
---

Toda resposta abre com um número de três dígitos, e o primeiro dígito é a família. Aprenda as cinco
famílias e você consegue ler um código que nunca viu.

| família | quer dizer | quem está com o problema |
|---|---|---|
| `1xx` | espere, esta ainda não é a resposta | ninguém; você raramente vê estes |
| `2xx` | funcionou | ninguém |
| `3xx` | está em outro lugar | o cliente, que deveria ir lá |
| `4xx` | você pediu errado | o cliente |
| `5xx` | eu quebrei | o servidor |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"As cinco famílias de código de status como cinco faixas: cem ainda não é a resposta, duzentos funcionou, trezentos está em outro lugar, quatrocentos é erro de quem chamou e quinhentos é falha do servidor. Só a última deveria acordar alguém.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"60\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">1xx</text> <text x=\"320\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">espere — raramente vistos</text> <rect x=\"20\" y=\"74\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"60\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">2xx</text> <text x=\"320\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">funcionou</text> <rect x=\"20\" y=\"118\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect> <text x=\"60\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3xx</text> <text x=\"320\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">está em outro lugar — vá lá</text> <rect x=\"20\" y=\"162\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"60\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4xx</text> <text x=\"320\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">você pediu errado — quem chamou conserta</text> <rect x=\"20\" y=\"206\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".34\" stroke=\"var(--amber)\"></rect> <text x=\"60\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">5xx</text> <text x=\"320\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">eu quebrei — este é o que acorda alguém</text> </svg>", "caption": "O primeiro dígito responde à única pergunta que decide o que vem depois: de quem é este problema?"}
```

A linha entre `4xx` e `5xx` é a que mais importa na prática, e não é sobre gravidade. É sobre **de
quem é a culpa**, e portanto sobre quem deveria ser acordado. Uma parede de `404` são visitantes
seguindo links velhos; uma parede de `500` é problema seu, hoje à noite.

## Os que você vai encontrar de verdade

De dezenas definidos, um punhado responde por quase tudo.

`200 OK` — aqui está. `201 Created` — feito, e a coisa nova está no endereço do cabeçalho
`Location`. `204 No Content` — feito, e deliberadamente não há nada a devolver, que é a resposta
certa para um `DELETE` que deu certo.

`301` e `302` mandam você para outro lugar, e se comportam de forma tão diferente que têm uma seção
própria mais adiante nesta aula. `304 Not Modified` diz *o que você já tem continua atual*, e é o
ponto inteiro do cache da próxima aula.

`400 Bad Request` — não consegui entender isso. `401 Unauthorized` — não sei quem você é. `403
Forbidden` — sei quem você é, e não. `404 Not Found` — não há nada aqui. `405 Method Not Allowed` —
esse endereço existe, essa palavra não se aplica a ele. `409 Conflict` — alguém mudou isso desde que
você leu. `429 Too Many Requests` — devagar, e o cabeçalho `Retry-After` diz o quanto.

`500 Internal Server Error` — algo estourou e ninguém pegou. `502 Bad Gateway` — sou um proxy e a
coisa atrás de mim respondeu bobagem. `503 Service Unavailable` — estou de pé e deliberadamente não
servindo, geralmente sobrecarregado ou em manutenção. `504 Gateway Timeout` — sou um proxy e a coisa
atrás de mim não respondeu nada.

Esses três últimos merecem mais atenção do que costumam receber, porque cada um nomeia um lugar
diferente. `502` e `504` dizem que a falha está atrás do proxy, e dizem se ele respondeu mal ou não
respondeu. Lê-los direito é a diferença entre reiniciar o serviço certo e reiniciar todos.

## Os três que se confundem

`401`, `403` e `404` são, nesta ordem: *não sei quem você é*, *sei quem você é e você não pode* e
*não há nada aqui*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três códigos distinguidos. Quatrocentos e um quer dizer que o servidor não sabe quem você é e convida você a dizer. Quatrocentos e três quer dizer que ele sabe e recusa. Quatrocentos e quatro quer dizer que não há nada naquele endereço, e às vezes é dado no lugar de uma recusa para não confirmar nada.\"> <rect x=\"20\" y=\"34\" width=\"215\" height=\"126\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"127\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">401</text> <text x=\"127\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não sei quem você é</text> <text x=\"127\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um convite: tente de novo</text> <text x=\"127\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">com credenciais</text> <rect x=\"252\" y=\"34\" width=\"215\" height=\"126\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"359\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\">403</text> <text x=\"359\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sei quem você é, e não</text> <text x=\"359\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma recusa: as mesmas</text> <text x=\"359\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">credenciais não ajudam</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"126\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"592\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">404</text> <text x=\"592\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não há nada aqui</text> <text x=\"592\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e às vezes uma recusa</text> <text x=\"592\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vestindo este número</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um 403 confirma que a coisa existe; um 404 não confirma nada</text> <text x=\"360\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">é por isso que alguns sistemas respondem 404 de propósito, e pagam por isso nos próprios logs</text> </svg>", "caption": "Dois destes são sobre quem chamou e um é sobre o endereço, e o terceiro às vezes é emprestado para esconder o segundo."}
```

O `401` é um convite — vem com um cabeçalho dizendo como se autenticar, e o próximo passo esperado
é tentar de novo com credenciais. O `403` é uma recusa; mandar as mesmas credenciais de novo não
vai ajudar.

E há um uso deliberado do `404` que vale entender. Um documento privado que responde `403` confirmou
que existe. Dependendo de como os endereços são, isso pode bastar para mapear um sistema, ou para
revelar que uma pessoa em particular tem conta. Então uma aplicação que prefere não confirmar nada
responde `404` tanto para *você não pode ver isto* quanto para *não há nada aqui*. É uma mentirinha,
contada de propósito, e o preço é que seus próprios logs ficam mais difíceis de ler.

## A mentira que custa mais caro

O erro mais comum com códigos de status é responder `200` e pôr o erro no corpo.

Parece inofensivo — o cliente lê a mensagem de um jeito ou de outro — e quebra quatro coisas de uma
vez. Um cache pode guardar a falha e servi-la a todo mundo. Uma biblioteca cliente repete em `5xx` e
isto não é um, então ela não vai repetir. Um painel de monitoramento vê um serviço saudável. E cada
pedaço de software entre você e quem chamou acredita que funcionou, porque a única coisa que
qualquer um deles olha é o número.

A linha de status não é um resumo para humanos. É a parte sobre a qual máquinas agem, e há mais
delas entre você e quem chamou do que você imagina.

## Códigos que você escolhe

Parte disso é fixa e parte é julgamento, e ajuda saber qual é qual.

Que uma página que não existe é `404` não é decisão de ninguém. Que um formulário com formato válido
e valor impossível seja `400` ou `422` é uma discussão que times realmente têm, e qualquer das duas
respostas é defensável desde que a mesma escolha seja feita em todo lugar.

O que não é defensável é a inconsistência: um cliente escrito contra uma interface que diz `400`
aqui e `422` ali para a mesma classe de problema tem que tratar os dois e não confiar em nenhum, que
é como uma escolha bem-intencionada vira a condição permanente de outra pessoa.
