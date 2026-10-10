---
title: JSON, e as três coisas que ele erra por você
version: 1
---

**O JSON tem seis tipos de valor: string, número, booleano, null, array e objeto.** Esse é o
formato inteiro, e toda resposta do boxoffice é feita desses seis. A simplicidade é a armadilha: o
formato não sabe dizer *dinheiro*, *data* nem *identificador*, então uma API precisa escolher como
escrever cada um deles com os seis, e cada escolha é algo que quem testa confere.

O `type` do jq dá o tipo de cada campo, que é a primeira coisa a olhar numa resposta desconhecida:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq -r 'to_entries[] | "\(.key): \(.value | type)"'
id: string
title: string
starts_at: string
price_cents: number
seats_left: number
```

Três strings e dois números. `starts_at` é uma data e `id` parece um código, e o JSON chama os dois
de string; o que eles significam é uma promessa que a API faz em outro lugar, que a seção 04 põe
por escrito.

## Ausente não é null

Um campo pode estar ausente, ou presente com o valor `null`, e **os dois casos não querem dizer a
mesma coisa**: um pedido sem o campo `payment` não foi cobrado, enquanto `"payment": null` diria que
alguém procurou e não achou nada. O jq esconde a diferença. Quando você pede um campo que não está
lá, ele responde `null`, e só o `has` separa os casos:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-103 | jq '.discount, has("discount")'
null
false
ana@laptop:~/boxoffice$ echo '{"discount": null}' | jq '.discount, has("discount")'
null
true
```

A primeira resposta não tem `discount` nenhum; a segunda tem um, com valor `null`. As duas imprimem
`null`. **Um teste que confere `.discount == null` passa nas duas**, então um servidor que perdeu um
campo obrigatório passaria por ele sem problema. Quando o contrato diz que um campo é obrigatório,
confira que ele está presente, e não só o que ele contém.

## Só existe um tipo de número

O JSON não separa números inteiros de frações. `2`, `2.0` e `2e0` são três grafias do mesmo número:

```
ana@laptop:~/boxoffice$ echo '[2, 2.0, 2e0]' | jq -c 'map(. == 2)'
[true,true,true]
```

Então "um inteiro" numa API é uma regra sobre o valor, não um tipo que o formato consiga carregar.
Isso importa na seção 06, quando o boxoffice recebe `2.0` lugares.

## Dinheiro viaja em centavos

Um número JSON é lido, em JavaScript e na maioria das linguagens, como ponto flutuante binário, e
ponto flutuante binário não consegue guardar um décimo exato. O erro é pequeno e real:

```
ana@laptop:~/boxoffice$ node -e 'console.log(0.1 + 0.2)'
0.30000000000000004
ana@laptop:~/boxoffice$ node -e 'console.log(80.10 * 3)'
240.29999999999998
ana@laptop:~/boxoffice$ node -e 'console.log(8010 * 3)'
24030
```

Três ingressos a R$ 80,10 dão 240.29999999999998 reais. Arredondado para uma tela, parece certo;
comparado com `===` num teste, ou somado ao longo de mil pedidos num relatório, não fica certo.
**O boxoffice manda todo valor como um número inteiro de centavos**, `price_cents: 8000` para
R$ 80,00, e inteiros desse tamanho são exatos. A última linha é a mesma conta em centavos, e dá
exatamente 24030.

O que quem testa confere: os valores são inteiros, o nome do campo diz a unidade, e um total é o
preço vezes a quantidade, até o centavo. O pedido da seção 02 tem 2 lugares de um espetáculo de
8000 centavos e diz `"total_cents":16000`, que está certo.

## Datas levam o deslocamento

`starts_at` está escrito em ISO 8601, `2026-11-08T18:00:00-03:00`: a data, um `T`, a hora e o
**deslocamento** em relação ao UTC, aqui três horas atrás, que é o de São Paulo. Sem o deslocamento,
o mesmo texto significa um momento diferente em cada máquina que o lê. Aqui está o início da sessão
de 8 de novembro lido três vezes, com o `TZ` definindo o fuso em que o computador acredita estar:

```
ana@laptop:~/boxoffice$ TZ=UTC node -e 'console.log(new Date("2026-11-08T18:00:00").toISOString())'
2026-11-08T18:00:00.000Z
ana@laptop:~/boxoffice$ TZ=America/Sao_Paulo node -e 'console.log(new Date("2026-11-08T18:00:00").toISOString())'
2026-11-08T21:00:00.000Z
ana@laptop:~/boxoffice$ TZ=UTC node -e 'console.log(new Date("2026-11-08T18:00:00-03:00").toISOString())'
2026-11-08T21:00:00.000Z
```

A primeira leitura acredita estar em UTC e a segunda em São Paulo. Com a data sem deslocamento, as
duas discordam em três horas sobre o mesmo texto. A terceira recebe o deslocamento e chega ao
momento certo qualquer que seja o fuso do próprio computador. **Uma data sem deslocamento é um
defeito esperando um usuário em outro fuso**, e toda data do boxoffice leva o seu.

## Identificadores são strings

Os ids do boxoffice são `sh-103` e `ord-1001`, que nunca poderiam ser números. Uma API cujos ids são
números grandes tem um problema mais silencioso: o JavaScript lê todo número JSON como ponto
flutuante com 53 bits de precisão, e um inteiro maior que isso é trocado sem aviso pelo mais próximo
que ele consegue guardar:

```
ana@laptop:~/boxoffice$ node -e 'console.log(JSON.parse("{\"id\": 9007199254740993}").id)'
9007199254740992
```

O id termina em 993 no texto e em 992 depois de lido. Um app escrito em JavaScript pediria o pedido
errado e receberia o de outra pessoa, ou nada. Ids mandados como string não podem ser arredondados,
e é por isso que uma API cuidadosa os escreve assim mesmo quando são feitos só de dígitos.
