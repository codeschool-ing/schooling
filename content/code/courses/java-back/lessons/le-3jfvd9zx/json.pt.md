---
title: Records entram, JSON sai, com o Jackson 3
version: 1
---

Os passos 2 e 4 do `DispatcherServlet` entregam o corpo a um conversor de mensagens, e para JSON esse
conversor é o **Jackson**, a biblioteca que transforma objetos Java em JSON e de volta. Você nunca o
acrescentou. O starter web depende dele, e a árvore de dependências do Maven mostra o caminho:

```
(pending jackson-tree)
```

`-Dincludes` limita a árvore aos grupos citados, e `grep jackson` descarta as outras linhas do Maven.
O que sobra diz duas coisas que vale saber antes de ler qualquer outro tutorial.

**O Spring Boot 4 roda sobre o Jackson 3**, aqui o 3.1.5, e o Jackson 3 mudou do grupo e do pacote
`com.fasterxml.jackson` para `tools.jackson`. Um tutorial que importa
`com.fasterxml.jackson.databind.ObjectMapper` foi escrito para o Jackson 2 e para o Spring Boot 3 ou
anterior; neste projeto essa classe é `tools.jackson.databind.ObjectMapper`. A exceção são as
anotações, o `jackson-annotations` 2.21 acima, que mantiveram o grupo e o pacote antigos para que uma
mesma classe anotada funcione com as duas versões. `@JsonProperty` continua sendo importada de
`com.fasterxml.jackson.annotation`.

## Como um record é escrito

`python3 -m json.tool` lê JSON da entrada padrão e o imprime com uma propriedade por linha, o que deixa
a lista legível. O Python 3 vem com o Ubuntu.

```
(pending json-list)
```

As regras que o Jackson aplicou, todas visíveis acima:

- todo componente do record vira uma propriedade, **com o nome do componente**, na ordem em que o
  record os declara;
- `long` e `int` viram números JSON, `String` uma string JSON, uma `List` um array;
- nada precisou de anotação, porque um record declara os componentes e o Jackson os lê.

Um nome na transmissão diferente do nome Java, `price_cents` por exemplo, é
`@JsonProperty("price_cents")` no componente. A livraria mantém os nomes Java.

O preço é um número inteiro de **centavos**, 3990 em vez de 39.90. Dinheiro num número de ponto
flutuante binário é um jeito clássico de perder um centavo, porque 0,10 não tem forma binária exata, e
uma contagem inteira da menor unidade não tem esse problema.

## Ler é mais rígido em um ponto e mais frouxo em outro

`@RequestBody` roda a mesma máquina ao contrário: o Jackson monta um record a partir do JSON, chamando
o construtor dele com as propriedades que encontrou. Dois padrões do Jackson 3 decidem o que acontece
com um corpo que não se encaixa, e os dois aparecem nesta aula:

- uma propriedade para a qual o record **não tem componente é ignorada**, sem erro; a seção sobre POST
  envia um `id` assim e o vê sumir;
- um **valor ausente ou um `null` para um primitivo** como `int` é recusado, porque não há um `int`
  honesto para pôr ali; a seção sobre validação começa exatamente dessa recusa.
