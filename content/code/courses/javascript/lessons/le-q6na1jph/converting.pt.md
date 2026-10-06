---
title: Convertendo de propósito
version: 1
---

Um texto que parece número continua sendo texto. Um valor digitado num formulário, lido de um
arquivo ou tirado de um endereço web chega como **string**, e antes de calcular com ele você o
transforma em número. **Faça isso você mesmo, explicitamente**, para que a conversão aconteça onde
dá para ver. São três ferramentas, e elas discordam:

```javascript
const inputs = ["42", "42px", "3.14", "1,5", "", " ", "0x1A", "08", null, undefined, true, []];

console.log("input".padEnd(11), "Number()".padEnd(10), "parseInt()".padEnd(11), "parseFloat()");
for (const v of inputs) {
  const shown = typeof v === "string" ? JSON.stringify(v) : Array.isArray(v) ? "[]" : String(v);
  console.log(
    shown.padEnd(11),
    String(Number(v)).padEnd(10),
    String(parseInt(v, 10)).padEnd(11),
    String(parseFloat(v)),
  );
}
```

```
ana@dev:~/js$ node convert.js
input       Number()   parseInt()  parseFloat()
"42"        42         42          42
"42px"      NaN        42          42
"3.14"      3.14       3           3.14
"1,5"       NaN        1           1
""          0          NaN         NaN
" "         0          NaN         NaN
"0x1A"      26         0           0
"08"        8          8           8
null        0          NaN         NaN
undefined   NaN        NaN         NaN
true        1          NaN         NaN
[]          0          NaN         NaN
```

## Três regras, lidas da tabela

**`Number()` converte o valor inteiro ou desiste.** `"42px"` é `NaN` por causa do `px`. Em geral é
isso que você quer de uma entrada digitada por uma pessoa: um campo que diz `42px` não é um número,
e o `NaN` deixa você perceber.

**`parseInt` e `parseFloat` leem da esquerda e param no primeiro caractere que não conseguem
usar.** `"42px"` dá `42`. Isso serve para um texto que você sabe que começa com número, como um
valor de CSS. Também significa que `"3.14"` passado por `parseInt` vira `3` sem aviso, e `"1,5"`
vira `1`.

**A string vazia é a armadilha.** `Number("")` e `Number(" ")` dão `0`, não `NaN`, então um campo
de formulário vazio vira zero em silêncio. Confira se o texto está vazio antes de converter, ou use
`parseFloat`, que dá `NaN`.

Duas lições menores da tabela: `parseInt` deve sempre receber o segundo argumento, a base, e com
base 10 ele lê `"0x1A"` como `0`; e `Number(null)` é `0` enquanto `Number(undefined)` é `NaN`, mais
um lugar em que os dois valores de "sem valor" se comportam diferente.

## A vírgula decimal

**O separador decimal do JavaScript é o ponto, seja qual for a língua de quem lê.** `"1,5"` não é um
e meio para o `Number()`. Um texto digitado por uma pessoa no Brasil, em Portugal ou na maior parte
da Europa pode usar vírgula, e a conversão precisa trocá-la antes:

```javascript
const n = 42;
console.log(String(n), n.toString(), `${n}`);
console.log(n.toString(2), n.toString(16));
console.log((1234.5).toFixed(2), (1234.5).toLocaleString("pt-BR"));
console.log(Number("1,5".replace(",", ".")));
```

```
ana@dev:~/js$ node to-string.js
42 42 42
101010 2a
1234.50 1.234,5
1.5
```

O outro sentido é `String(n)`, `n.toString()` ou um template, e os três concordam. `toString`
também recebe uma base, então `42` em binário é `101010`. Para uma pessoa, `toLocaleString("pt-BR")`
escreve o número do jeito que um leitor brasileiro espera, com a vírgula e o ponto trocados.
**Guarde o locale para o que você mostra, e o ponto para o que você calcula.**
