---
title: Valores falsy, e o operador para os que faltam
version: 1
---

Um `if` não precisa de um booleano. Ele converte o que receber, e **a conversão é a mesma que o
`Boolean()` faz**. Um valor que vira `false` se chama **falsy**, e existem exatamente oito. Todo o
resto é **truthy**:

```javascript
const values = [false, 0, -0, 0n, "", null, undefined, NaN, "0", "false", " ", [], {}, -1];

for (const v of values) {
  const shown = typeof v === "string" ? JSON.stringify(v) : Array.isArray(v) ? "[]" : typeof v === "object" && v ? "{}" : Object.is(v, -0) ? "-0" : typeof v === "bigint" ? `${v}n` : String(v);
  console.log(shown.padEnd(10), Boolean(v));
}
```

```
ana@dev:~/js$ node falsy.js
false      false
0          false
-0         false
0n         false
""         false
null       false
undefined  false
NaN        false
"0"        true
"false"    true
" "        true
[]         true
{}         true
-1         true
```

## A lista para lembrar

`false`, `0`, `-0`, `0n`, `""`, `null`, `undefined` e `NaN`. **São todos.** As seis linhas de baixo
mostram os valores que as pessoas esperam que sejam falsy e não são: as strings `"0"` e `"false"`,
uma string com um espaço, um array vazio e um objeto vazio são todos truthy. `if (list)` é
verdadeiro para uma lista vazia, então para perguntar se um array tem itens, pergunte
`list.length > 0`.

## O `||` devolve um valor

`||` e `&&` não se limitam a `true` e `false`. **Eles devolvem um dos dois operandos**:

```javascript
console.log("Iracema" && 1865);
console.log("" && 1865);
console.log(null || "no title");
console.log(!!"Iracema", !!"");
```

```
ana@dev:~/js$ node andor.js
1865

no title
true false
```

`a && b` dá `a` se ele for falsy e `b` caso contrário; `a || b` dá `a` se ele for truthy e `b` caso
contrário. A linha vazia da saída é `""`, devolvida pelo `&&` porque era falsy. `!!` transforma
qualquer valor no seu booleano, que é o que a última linha imprimiu.

## O `||` para padrões, e onde ele erra

O hábito de escrever `value || fallback` para "use o reserva se não houver valor" está em toda
parte em código antigo, e **ele trata todo valor falsy como ausente**. Uma configuração de zero é
uma configuração de verdade:

```javascript
function shelfSize(settings) {
  const withOr = settings.perShelf || 20;
  const withNullish = settings.perShelf ?? 20;
  console.log(withOr, withNullish);
}

shelfSize({ perShelf: 35 });
shelfSize({ perShelf: 0 });
shelfSize({});
```

```
ana@dev:~/js$ node defaults.js
35 35
20 0
20 20
```

Com `perShelf: 0`, **o `||` jogou o zero fora e usou 20**. O `??`, o operador de coalescência nula,
só recorre ao reserva para `null` e `undefined`, então manteve o zero. A terceira chamada não tinha
configuração nenhuma, e os dois concordaram.

**Use `??` para padrões.** Recorra ao `||` quando uma string vazia ou um zero devem mesmo ser
substituídos, e escreva um comentário dizendo isso, porque quem ler depois vai estranhar. A aula 4
acrescenta o `?.`, o companheiro dele, para ler uma propriedade de algo que pode não estar lá.
