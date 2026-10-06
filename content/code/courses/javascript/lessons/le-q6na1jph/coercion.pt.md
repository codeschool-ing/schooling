---
title: Coerção: quando a linguagem converte por você
version: 1
---

Quando um operador recebe dois valores de tipos para os quais não foi feito, o JavaScript
**converte um deles sem perguntar**. Isso é coerção. Não é aleatório; segue uma lista curta de
regras, e estas nove linhas tocam nas que você vai encontrar:

```javascript
console.log("5" + 3);
console.log("5" - 3);
console.log("5" * "2");
console.log(true + 1);
console.log(null + 1, undefined + 1);
console.log([] + []);
console.log([1, 2] + [3]);
console.log({} + "!");
console.log("3" > "12", 3 > "12");
```

```
ana@dev:~/js$ node coerce.js
53
2
10
2
1 NaN

1,23
[object Object]!
true false
```

## O `+` prefere texto

**Se qualquer lado do `+` for string, o `+` junta.** `"5" + 3` transformou o 3 em `"3"` e produziu
`"53"`. Todo outro operador aritmético só significa aritmética, então `-` e `*` convertem os dois
lados em número: `"5" - 3` é `2`, e `"5" * "2"` é `10`. `true` vira `1`, `null` vira `0` e
`undefined` vira `NaN`, exatamente como o `Number()` fez na seção anterior.

## Objetos viram string primeiro

Um array ou um objeto encontrando o `+` vira string primeiro. **Um array vira os seus itens unidos
por vírgulas**, então `[] + []` são duas strings vazias, que saíram como uma linha vazia, e
`[1, 2] + [3]` é `"1,2" + "3"`. Um objeto simples vira `"[object Object]"`, que é o texto que você
vai ver numa página na primeira vez que imprimir um objeto onde se esperava uma string.

## Comparar duas strings compara texto

`"3" > "12"` é `true`, porque **duas strings são comparadas caractere por caractere, como num
dicionário**, e `"3"` vem depois de `"1"`. Quando um lado é número, o outro é convertido, e
`3 > "12"` compara 3 com 12. Ordenar é onde isso morde, e a aula 4 mostra.

## Onde acontece sem você ver

Um campo de formulário sempre te entrega uma string, mesmo quando guarda dígitos:

```html
<!doctype html>
<label>Copies <input id="copies" value="10"></label>
<script>
  const copies = document.querySelector("#copies").value;
  console.log(typeof copies);
  console.log(copies + 5);
  console.log(Number(copies) + 5);
</script>
```

```
ana@dev:~/js$ page form.html
string
105
15
```

**`copies + 5` é `"105"`**, e nada acusou erro: uma página mostraria feliz cento e cinco cópias.
`Number(copies) + 5` é o conserto, e o hábito que ele ensina é o assunto desta aula: **converta na
borda**, onde o texto entra no seu programa, e dali em diante todo valor já é do tipo que o código
espera.
