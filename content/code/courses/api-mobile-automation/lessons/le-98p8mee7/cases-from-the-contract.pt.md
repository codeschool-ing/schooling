---
title: Casos de teste, lidos do contrato
version: 1
---

**Toda cláusula de um contrato é uma fonte de casos de teste, e tirá-los dali é mecânico.** As
técnicas são as que o `manual-testing` ensinou para um formulário numa tela: dividir as entradas em
classes que deveriam se comportar igual, pegar um valor de cada e acrescentar os valores de cada
borda. O que muda é de onde vêm as regras. Numa tela você as adivinha pelos rótulos; aqui elas estão
escritas, em `NewOrder`, uma por linha:

| cláusula em `NewOrder` | casos que ela dá |
|---|---|
| `seats: { type: integer, minimum: 1, maximum: 6 }` | 0 e 7 logo fora, 1 e 6 logo dentro; uma fração; o número como texto |
| `required: [show_id, seats]` | cada campo deixado de fora, um de cada vez |
| `additionalProperties: false` | um campo que o contrato não nomeia |
| `type: object` | um corpo que é JSON válido e nem é um objeto |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 220\" role=\"img\" aria-label=\"Uma reta de lugares de 0 a 7. O trecho de 1 a 6 está marcado como válido, respondido com 201; 0 e 7, logo fora dele, são respondidos com 422; 1 e 6 estão marcados como logo dentro. Embaixo, quatro valores que não estão na reta: 2.5 respondido com 422, o texto &quot;2&quot; respondido com 422, 2.0 respondido com 201 porque é o mesmo número que 2, e um pedido com seats ausente respondido com 422.\"><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">lugares num pedido, diante da regra de 1 a 6</text><rect x=\"136\" y=\"56\" width=\"398\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"335\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">válido: 201</text><text x=\"90\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">422</text><text x=\"580\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">422</text><line x1=\"60\" y1=\"96\" x2=\"610\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></line><line x1=\"90\" y1=\"91\" x2=\"90\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"90\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><line x1=\"160\" y1=\"91\" x2=\"160\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"160\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><line x1=\"230\" y1=\"91\" x2=\"230\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"230\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><line x1=\"300\" y1=\"91\" x2=\"300\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"300\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><line x1=\"370\" y1=\"91\" x2=\"370\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"370\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><line x1=\"440\" y1=\"91\" x2=\"440\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"440\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><line x1=\"510\" y1=\"91\" x2=\"510\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"510\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><line x1=\"580\" y1=\"91\" x2=\"580\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"580\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"90\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">logo fora</text><text x=\"160\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">logo dentro</text><text x=\"510\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">logo dentro</text><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">logo fora</text><text x=\"350\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">valores que nem estão na reta</text><rect x=\"30\" y=\"166\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"105\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.5</text><text x=\"105\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">422</text><rect x=\"195\" y=\"166\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"270\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"2\"</text><text x=\"270\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">422</text><rect x=\"360\" y=\"166\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"435\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.0</text><text x=\"435\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">201, o mesmo número que 2</text><rect x=\"525\" y=\"166\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">seats ausente</text><text x=\"600\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">422</text></svg>", "caption": "Os casos que um intervalo dá: os dois valores de cada borda, e os valores que nem são pontos da reta."}
```

Todo caso tem uma resposta esperada antes de ser mandado, e o contrato a dá: um `201` para os
válidos, um `422` para conteúdo que fere uma regra, um `400` para um corpo que não dá para ler como
pedido. Um caso sem resposta esperada não é um teste, é uma olhada.

## Uma função, para encurtar as requisições

Cada caso é a mesma requisição com um corpo diferente. Uma função do shell poupa digitá-la toda
vez; digite isto uma vez no seu terminal, depois do `TOKEN` da seção 02:

```
ana@laptop:~/boxoffice$ order() { curl -s -w '%{http_code}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d "$1"; }
```

`order` manda o argumento como corpo de um pedido e imprime o código de status na linha depois da
resposta. Ela dura até o terminal ser fechado. Todos os casos abaixo usam o `sh-101`, o espetáculo
de 120 lugares, para que nenhum falhe por falta de lugar.

## As bordas

```
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":0}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":1}'
{"id":"ord-1002","show_id":"sh-101","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-local-ord-1002"}
201
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":6}'
{"id":"ord-1003","show_id":"sh-101","seats":6,"total_cents":48000,"status":"confirmed","payment":"ch-local-ord-1003"}
201
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":7}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
```

`0` e `7` recusados com `422`, `1` e `6` aceitos. É a regra exatamente como está escrita, nas duas
bordas, e é o resultado que quem testa mais quer e menos vezes recebe: um limite programado como
`< 6` em vez de `<= 6` aparece aqui e em mais lugar nenhum.

## O tipo errado de valor

```
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":2.5}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":"2"}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":2.0}'
{"id":"ord-1004","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-local-ord-1004"}
201
```

Uma fração e um número escrito como texto são recusados, o que está certo. `2.0` é aceito, e
**isso também está certo**, não é defeito para relatar: a seção 03 mostrou que `2.0` e `2` são o
mesmo número JSON, e o `integer` do contrato é uma regra sobre o valor. Um relatório dizendo "o
boxoffice aceita decimais" seria fechado como não defeito, e custaria um pouco da credibilidade de
quem testa.

## Os campos obrigatórios

```
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101"}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
ana@laptop:~/boxoffice$ order '{"seats":2}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"there is no show undefined"}
422
```

Os dois recusados com `422`, o código que o contrato lista. A segunda resposta tem um problema
próprio, no texto: **`there is no show undefined`**. `undefined` é uma palavra de dentro do
JavaScript, o valor de um campo que nunca foi mandado, e ela vazou para uma frase escrita para uma
pessoa. O status está certo e um programa se viraria. Uma pessoa lendo isso num app não saberia que
esqueceu de escolher um espetáculo. É um defeito pequeno e real, e a correção é verificar se falta o
`show_id` antes de procurá-lo.

## Um campo que ninguém pediu

```
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":1,"price_cents":1}'
{"id":"ord-1005","show_id":"sh-101","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-local-ord-1005"}
201
```

O contrato diz `additionalProperties: false`: nenhum campo além dos dois que ele nomeia. O
boxoffice aceitou `price_cents` sem dizer nada e criou o pedido. Aqui não houve dano, porque o
boxoffice ignorou o campo e cobrou o preço real de 8000 centavos. O perigo está no cliente que o
mandou. **Um cliente que manda um campo que o servidor ignora acredita que foi obedecido**: um app
que manda `"seats_preferred": "front row"` e recebe `201` tem todos os motivos para achar que
reservou a primeira fila. Recusar campos desconhecidos com `422` transforma esse mal-entendido num
erro que alguém vê durante o desenvolvimento. Isso é uma discordância entre o contrato e o código, e
o relatório diz isso. A equipe pode decidir que é o contrato que muda, e esse também é um bom
desfecho.

## JSON válido que não é um pedido

A palavra `null` é um documento JSON completo e válido. Ela não é um objeto, então a resposta do
contrato é um `400` ou um `422`:

```
ana@laptop:~/boxoffice$ order 'null'
{"type":"about:blank","title":"Internal Server Error","status":500,"detail":"something broke on our side"}
500
```

**Um `500`.** O boxoffice quebrou com uma requisição que um cliente poderia mandar por engano, e a
resposta diz a esse cliente que a culpa foi do servidor e que tentar de novo pode ajudar, as duas
coisas falsas. A lição 1 chamou isso de dois defeitos em um. O segundo terminal mostra o que
aconteceu por dentro:

```
TypeError: Cannot read properties of null (reading 'show_id')
    at file:///home/ana/boxoffice/boxoffice.mjs:121:49
    at Array.find (<anonymous>)
    at createOrder (file:///home/ana/boxoffice/boxoffice.mjs:121:22)
    at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
POST /v1/orders 500
```

O programa leu `.show_id` de `null`, o que o JavaScript recusa. Repare no que chegou ao cliente:
`something broke on our side`, e nenhuma dessas linhas. **O corpo do erro não vazou o stack
trace**, que é a quarta verificação da seção 05, e ela passou. O log é o lugar do stack trace.

## O parâmetro de query

O contrato diz que `date` é um `format: date`, um dia escrito como `2026-11-08`, e lista um `400`
para uma requisição que ele não consegue ler. Uma data escrita do jeito que alguém no Brasil poderia
digitar:

```
ana@laptop:~/boxoffice$ curl -s -w '%{http_code}\n' 'localhost:8080/v1/shows?date=8-11-2026'
{"shows":[]}
200
```

Um `200` e uma lista vazia. O boxoffice nem confere o formato; ele fica com os espetáculos cujo
início começa com o texto mandado, e nenhum começa com `8-11-2026`. Um cliente com um erro de
digitação ouve que o teatro não tem nada naquele dia, uma resposta crível e errada.

## O que os casos acharam

| caso | o contrato diz | o boxoffice respondeu | veredito |
|---|---|---|---|
| 0, 1, 6, 7 lugares | `422`, `201`, `201`, `422` | o mesmo | como prometido |
| 2.5 e `"2"` lugares | `422` | `422` | como prometido |
| `2.0` lugares | `201` | `201` | como prometido |
| sem `seats` | `422` | `422` | como prometido |
| sem `show_id` | `422` | `422`, *there is no show undefined* | defeito na mensagem |
| `price_cents` a mais | `422` | `201` | discorda do contrato |
| `null` como corpo | `400` ou `422` | `500` | defeito |
| `date=8-11-2026` | `400` | `200`, lista vazia | discorda do contrato |

Quatro achados em doze requisições, nenhum visível em tela alguma, e cada um com a evidência na
transcrição acima dele. Registre cada um do jeito que o `manual-testing` ensinou: a requisição, a
resposta, a cláusula do contrato que ela quebra e a transcrição. O contrato é o que torna a terceira
parte possível. Sem ele, "o boxoffice aceitou um campo desconhecido" é uma opinião; com ele, é uma
linha do `openapi.yaml` que qualquer um pode apontar.
