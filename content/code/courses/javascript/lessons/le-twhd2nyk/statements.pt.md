---
title: Instruções, e os ponto e vírgulas que dá para omitir
version: 1
---

Um programa é uma lista de **instruções**, executadas uma depois da outra. Uma instrução faz algo:
declara um nome, chama uma função, escolhe entre dois caminhos. Dentro de muitas instruções ficam
**expressões**, os pedaços que produzem um valor: `2 + 3`, `"Dom" + " Casmurro"`, `year < 1900`. O
`node -p` imprimiu o valor de uma expressão; um arquivo executa instruções.

Comentários são para quem lê, e o motor os pula. `//` vai até o fim da linha, e `/* … */` pode
cobrir várias.

## O ponto e vírgula

Uma instrução termina com `;`. **JavaScript também deixa você omiti-lo**, e o preenche por você onde
uma quebra de linha deixa a instrução completa. A regra se chama inserção automática de ponto e
vírgula, e é por isso que metade do código que você vai ler tem ponto e vírgula e a outra metade
não tem. As duas coisas estão certas. O que não está certo é não conhecer os dois lugares onde a
regra faz algo que você não quis.

## Onde uma quebra de linha termina a instrução que você queria continuar

```javascript
function book() {
  return
  {
    title: "Dom Casmurro"
  };
}

console.log(book());
```

```
ana@dev:~/js$ node asi-return.js
undefined
```

**Uma quebra de linha logo depois de `return` termina a instrução ali.** A função não devolve nada,
o que é `undefined`, e o objeto de baixo nunca é alcançado. O conserto é começar o objeto na mesma
linha do `return`: `return {`.

## Onde uma quebra de linha não termina a instrução que você queria terminar

```javascript
const shelf = "fiction"
const label = shelf
(function () {
  console.log("sorting the shelf")
})()
```

```
ana@dev:~/js$ node asi-join.js 2>&1 | head -n 5
/home/ana/js/asi-join.js:2
const label = shelf
              ^

TypeError: shelf is not a function
```

A ana quis três instruções. O JavaScript viu duas, porque uma linha que começa com `(` pode
continuar a de cima: `shelf(function () { … })` é uma chamada. **Então a string `"fiction"` foi
chamada como função**, e o erro aponta para a linha 2, que parece inocente. O mesmo acontece com uma
linha que começa com `[` ou com uma crase.

## Que estilo escolher

**Escreva os ponto e vírgulas, e deixe um formatador fazer isso.** Uma equipe escolhe um estilo e
uma ferramenta como o Prettier o aplica a cada salvamento, para ninguém discutir isso na revisão.
Se você entrar num código sem ponto e vírgula, o hábito a manter é o segundo caso: uma linha que
começa com `(`, `[` ou crase ganha um `;` na frente.
