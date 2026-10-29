---
title: Chaves, e por que um Symbol
version: 1
---

**A chave sob a qual um valor é provido pode ser uma string ou um Symbol, e numa aplicação de qualquer
tamanho ela deve ser um Symbol exportado de um módulo só.** As demos desta aula usaram `unitKey` e
`plannerKey` do `keys.js` desde o início; esta seção é o porquê.

## Uma chave string é um nome que qualquer um pode usar

`provide('unit', 'hours')` funciona, e `inject('unit')` o encontra. Ele também encontra qualquer outra
coisa provida como `'unit'` mais perto na árvore, por qualquer componente, inclusive um de dentro de uma
biblioteca que você instalou e que por acaso usa a mesma palavra para uma configuração própria. Os dois
nunca se encontram no código, e quem injeta recebe o que estiver mais perto. Strings colidem em
silêncio, porque duas strings iguais são a mesma chave.

**Dois Symbols nunca são iguais**, mesmo com a mesma descrição:

```
ana@dev:~/vue/sandbox$ node -e "console.log(Symbol('unit') === Symbol('unit'), 'unit' === 'unit')"
false true
```

Uma chave Symbol só pode ser usada por código que importa exatamente aquele Symbol, então o único jeito
de chegar ao valor é pelo módulo que o exporta.

## Por que um módulo só

Pôr todas as chaves num arquivo, o `keys.js`, dá três coisas fáceis de subestimar:

- **Uma lista de tudo o que é provido**, num lugar só. O provide é o único fluxo de dados do Vue que não
  aparece no template, e o arquivo de chaves é onde um leitor começa.
- **Um import para achar todos os usuários.** Uma busca por `unitKey` mostra todo componente que provê
  ou injeta a unidade, coisa que uma busca pela string `'unit'` enterraria no meio de tudo o mais que se
  chama unit.
- **Um lugar para tipos.** A aula 16 dá a uma chave o tipo do valor que ela carrega, com
  `InjectionKey`, para que se saiba que `inject(unitKey)` devolve uma string, ou `undefined` quando ninguém a
  provê, sem ninguém precisar dizer.

O planner ganha o seu próprio `src/keys.js` no fim desta aula, com uma chave dentro.

## Quando uma string serve

A chave string é a forma antiga, e você vai vê-la em código mais velho e nos exemplos mais curtos da
documentação. Dentro de uma biblioteca pequena de componentes em que cada chave tem um prefixo próprio,
como `'my-tabs:active'`, ela funciona na prática. O Symbol custa um import e torna a pergunta
desnecessária.
