---
title: Hoisting: nomes existem antes da sua linha
version: 1
---

A imagem comum de um programa é que uma linha roda, depois a seguinte. Ela está certa para o que as
linhas **fazem** e errada para o que elas **declaram**. Antes de um bloco ou uma função começar a
rodar, o motor o lê inteiro e **cria todo nome declarado em qualquer parte dele**. Esse passo se
chama hoisting, como se as declarações fossem içadas para o topo, embora nada no seu arquivo se
mova.

O que cada nome guarda enquanto isso depende de como foi declarado.

## `var`: criado como `undefined`

```javascript
console.log(title);
var title = "Iracema";
console.log(title);
```

```
ana@dev:~/js$ node hoist-var.js
undefined
Iracema
```

A primeira linha lê `title` antes de a linha 2 rodar, e recebe `undefined`. **Um `var` é criado e
recebe `undefined` na hora**; a parte `= "Iracema"` fica na sua própria linha e roda quando o
programa chega lá. Ler uma variável cedo demais não falha, só devolve o valor errado em silêncio, o
que é a pior das opções.

## Declarações de função: criadas inteiras

```javascript
console.log(greet("ana"));

function greet(name) {
  return `hello, ${name}`;
}

console.log(typeof later);
later();

var later = function () {
  return "too late";
};
```

```
ana@dev:~/js$ node hoist-function.js 2>&1 | head -n 7
hello, ana
undefined
/home/ana/js/hoist-function.js:8
later();
^

TypeError: later is not a function
```

`greet` é chamada na linha 1 e escrita na linha 3, e funcionou. **Uma declaração de função é
içada com o corpo**, então pode ser chamada em qualquer lugar do seu escopo. É isso que deixa um
arquivo pôr a lógica principal em cima e as funções auxiliares embaixo, o que lê bem.

`later` é outro caso. É um `var` cujo valor por acaso é uma função, então foi içado do jeito do
`var`: como `undefined`. `typeof later` imprimiu `undefined`, e chamá-lo deu
**`TypeError: later is not a function`**, uma mensagem que faz sentido quando você sabe que o nome
existia e não guardava nada que pudesse ser chamado.

## `let`, `const` e `class`: criados, mas intocáveis

Eles também são içados. **O motor cria o nome no começo do bloco e recusa todo uso dele até a linha
da própria declaração ter rodado.** A próxima seção trata desse trecho do bloco, que tem nome
próprio.

| declarado com | existe a partir de | guarda antes da sua linha |
|---|---|---|
| `var` | o começo da função | `undefined` |
| declaração `function` | o começo do escopo | a função inteira |
| `let`, `const`, `class` | o começo do bloco | nada: lê-lo lança erro |
