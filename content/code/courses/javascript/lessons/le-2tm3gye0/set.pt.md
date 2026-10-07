---
title: Set: cada valor uma vez
version: 1
---

**Um `Set` é uma coleção em que cada valor aparece no máximo uma vez.** Acrescentar um valor que
ele já tem não faz nada. Isso o torna o jeito mais curto de tirar duplicatas, e um jeito rápido de
perguntar "já vi isto?":

```javascript
const tags = ["novel", "classic", "novel", "romance", "classic"];
const unique = new Set(tags);
console.log(unique, unique.size);
console.log([...unique]);

unique.add("novel");
unique.add("poetry");
console.log(unique.has("poetry"), unique.size);

console.log(new Set([NaN, NaN, 0, -0]).size);
console.log(new Set([{ id: 1 }, { id: 1 }]).size);
```

```
ana@dev:~/js$ node set.js
Set(3) { 'novel', 'classic', 'romance' } 3
[ 'novel', 'classic', 'romance' ]
true 4
2
2
```

- `new Set(tags)` ficou com três das cinco tags, **na ordem em que cada uma apareceu primeiro**.
  `[...unique]` o transforma de volta em array, que é a deduplicação de uma linha de costume;
- acrescentar `"novel"` de novo não mudou nada; acrescentar `"poetry"` fez quatro;
- um `Set` decide "o mesmo" quase como o `===`, com uma diferença: **ele trata `NaN` como igual a
  si mesmo**, então dois `NaN` viraram um, e `0` e `-0` também viraram um. Isso deu dois;
- dois objetos com o mesmo conteúdo continuam sendo **dois objetos**, então o último set tem dois
  itens. A seção de igualdade da aula 2 explica por quê.

O `has` de um `Set` continua rápido por maior que o set fique, enquanto o `includes` de um array
confere os itens um a um. **Para uma lista longa em que você pergunta "isto está nela?" muitas
vezes, construa um `Set` uma vez.**

## Operações de conjunto

```javascript
const ana = new Set(["Iracema", "Dom Casmurro", "Macunaíma"]);
const bia = new Set(["Dom Casmurro", "O Cortiço"]);

console.log(ana.union(bia));
console.log(ana.intersection(bia));
console.log(ana.difference(bia));
console.log(ana.isSupersetOf(new Set(["Iracema"])));
```

```
ana@dev:~/js$ node set-ops.js
Set(4) { 'Iracema', 'Dom Casmurro', 'Macunaíma', 'O Cortiço' }
Set(1) { 'Dom Casmurro' }
Set(2) { 'Iracema', 'Macunaíma' }
true
```

Desde 2024 um `Set` tem as operações da matemática: **união** é tudo o que está em qualquer um,
**interseção** é o que os dois têm em comum, **diferença** é o que o primeiro tem e o segundo não.
O Node 22 as tem, assim como os navegadores atuais; este é um dos recursos a que a aula 1 se
referia quando mandou instalar o 22 ou mais novo. Antes delas, o mesmo se escrevia com `filter` e
`has`: `[...ana].filter((t) => bia.has(t))` é a interseção.
