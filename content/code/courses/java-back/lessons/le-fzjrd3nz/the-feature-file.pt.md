---
title: Gherkin, lido linha a linha
version: 1
---

Um arquivo de *feature* é texto puro com um punhado de palavras-chave no começo das linhas. Tudo o
que vem depois de uma palavra-chave é inglês livre, que o Cucumber entrega ao código sem tentar
entender. Crie `src/test/resources/features/ordering.feature`:

```
Feature: Ordering books
  A customer orders books from the catalogue, and the shop
  never sells a copy it does not have.

  Background:
    Given the customer "ana" has signed in

  Scenario: An order takes copies out of stock
    Given the shop has 5 copies of "The War of the Worlds"
    When she orders 2 copies of "The War of the Worlds"
    Then the order is accepted with a total of 6400 cents
    And "The War of the Worlds" has 3 copies left

  Scenario Outline: An order for more copies than the shop has is refused
    Given the shop has <stock> copies of "Persuasion"
    When she orders <ordered> copies of "Persuasion"
    Then the order is refused as out of stock
    And "Persuasion" has <stock> copies left

    Examples:
      | stock | ordered |
      | 5     | 6       |
      | 0     | 1       |
```

Leia de cima para baixo.

**`Feature:`** dá nome ao assunto do arquivo, e as linhas recuadas embaixo dela são uma descrição. O
Cucumber as imprime e nunca as executa: elas são para quem abrir o arquivo daqui a um ano querendo
saber qual regra ele protege. Um arquivo guarda uma *feature*.

**`Background:`** guarda passos que rodam antes de cada cenário do arquivo, como se estivessem
escritos no topo de cada um. Aqui ele faz o login da ana, então cada cenário começa com um token
próprio. Mantenha um *background* curto e sobre o contexto de quem lê; um que monta metade do banco
é sinal de que os cenários embaixo dele compartilham coisa demais.

**`Scenario:`** é um exemplo da conversa, com um título que diz o que ele mostra. Cada passo dele
começa com uma palavra-chave:

| palavra-chave | o que o passo diz |
|---|---|
| `Given` | o mundo antes de qualquer coisa acontecer |
| `When` | a única coisa que alguém faz |
| `Then` | o que dá para observar depois |
| `And`, `But` | mais um passo do mesmo tipo que o de cima |

O primeiro cenário é o primeiro exemplo palavra por palavra: cinco exemplares, dois pedidos, 6400
centavos, três sobrando. **Um `When` por cenário** é a regra que vale manter, porque um cenário com
duas ações são dois exemplos, e quando ele falha ninguém sabe dizer qual dos dois quebrou.

**`Scenario Outline:`** é um cenário com buracos. Os nomes entre sinais de menor e maior, `<stock>`
e `<ordered>`, são preenchidos pela tabela **`Examples:`** logo abaixo, e o esquema roda uma vez por
linha. Os outros dois exemplos da conversa só diferem nos números, então viram um esquema com duas
linhas: cinco exemplares contra um pedido de seis, e nenhum contra um pedido de um. O arquivo guarda,
portanto, três cenários, e o *background* roda três vezes.

## Escreva o que acontece, não como

Cada passo diz o que a cliente faz, nas palavras da loja: *she orders 2 copies of "Persuasion"*. Ele
não diz *ela manda um POST para /orders com um corpo JSON cujo bookId é 4*, embora seja exatamente
isso que o código por trás dele vai fazer. O primeiro tipo de passo se chama **declarativo** e o
segundo **imperativo**, e a diferença decide por quanto tempo o arquivo continua útil.

Uma URL nova, um campo renomeado, duas requisições onde havia uma: a frase declarativa sobrevive a
tudo isso, e só o método por trás dela muda. A imperativa precisa ser reescrita a cada vez, e um
arquivo cheio de URLs e JSON é um arquivo que quem conhece o negócio para de ler, o que tira o
motivo de ele ter sido escrito em frases.

As partes de uma frase que mudam de um exemplo para outro são escritas de um jeito que dê para
separá-las: um título entre aspas duplas, um número sozinho. A próxima seção mostra como o código as
encontra.

## Em português, também

As palavras-chave do Gherkin existem em umas oitenta línguas, e um arquivo cuja primeira linha é
`# language: pt` é lido com as portuguesas: `Funcionalidade`, `Contexto`, `Cenário`,
`Esquema do Cenário`, `Exemplos`, `Dado`, `Quando`, `Então`, `E` e `Mas`. O Cucumber traduz as palavras-chave e
mais nada; as frases são na língua que as pessoas da conversa falam. Este curso mantém o arquivo de
*feature* da livraria em inglês, como o resto do código.
