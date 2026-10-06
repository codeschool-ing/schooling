---
title: Emprestando uma função
version: 1
---

**Um método é uma função guardada num objeto, e nada impede você de rodá-la em outro objeto com
`call`.** Quando o outro objeto tem o formato que o método espera, funciona. Isso é empréstimo, e é o
uso do `call` que não ficou datado.

## Métodos de array em coisas que não são arrays

Alguns valores têm itens numerados e um `length` sem serem arrays. Eles se chamam **array-like**,
parecidos com array, e o clássico é o `arguments`, que toda função normal tem:

```javascript
function oldStyle() {
  console.log(Array.isArray(arguments), arguments.length);
  const list = Array.prototype.slice.call(arguments);
  console.log(list);
  console.log(Array.from(arguments));
}

function newStyle(...titles) {
  console.log(Array.isArray(titles), titles);
}

oldStyle("Iracema", "Dom Casmurro");
newStyle("Iracema", "Dom Casmurro");
```

```
ana@dev:~/js$ node arguments.js
false 2
[ 'Iracema', 'Dom Casmurro' ]
[ 'Iracema', 'Dom Casmurro' ]
true [ 'Iracema', 'Dom Casmurro' ]
```

`arguments` não é um array, então não tem `slice`. **`Array.prototype.slice.call(arguments)` empresta
o `slice` dos arrays** e o roda em `arguments`, que é parecido o bastante com um array para o `slice`
funcionar. Você vai ver exatamente essa linha em código antigo. `Array.from` é o jeito moderno de
obter um array de qualquer coisa array-like, e um parâmetro rest (aula 4) evita o `arguments` de vez.

Numa página, a mesma coisa aparece com listas de elementos:

```html
<!doctype html>
<ul>
  <li>Iracema</li>
  <li>Dom Casmurro</li>
  <li>Macunaíma</li>
</ul>
<script>
  const items = document.querySelectorAll("li");
  console.log(typeof items.forEach, typeof items.map);
  console.log(Array.prototype.map.call(items, (li) => li.textContent.length));
  console.log(Array.from(items, (li) => li.textContent.length));
  console.log(items.map((li) => li.textContent));
</script>
```

```
ana@dev:~/js$ page nodelist.html
function undefined
[7, 12, 9]
[7, 12, 9]
Uncaught TypeError: items.map is not a function
```

Uma `NodeList` tem `forEach` e não tem `map`. Emprestar o `map` funcionou, `Array.from` com uma
função de mapeamento funcionou, e **chamar `items.map` lançou erro**. A aula 11 trata de selecionar
elementos; esta é a coisa sobre o resultado que surpreende todo mundo.

## Métodos que podem ter sido substituídos

```javascript
const record = { title: "Iracema", hasOwnProperty: "yes, a field called that" };
const dictionary = Object.create(null);
dictionary.title = "Dom Casmurro";

console.log(Object.prototype.hasOwnProperty.call(record, "title"));
console.log(Object.prototype.hasOwnProperty.call(dictionary, "title"));
console.log(Object.hasOwn(record, "title"), Object.hasOwn(dictionary, "title"));
console.log(record.hasOwnProperty("title"));
```

```
ana@dev:~/js$ node hasown.js 2>&1 | head -n 8
true
true
true true
/home/ana/js/hasown.js:8
console.log(record.hasOwnProperty("title"));
                   ^

TypeError: record.hasOwnProperty is not a function
```

`record` tem uma propriedade própria chamada `hasOwnProperty`, uma string, que esconde o método que
todo objeto herda; `dictionary` foi feito sem método herdado nenhum. **Emprestar o método de
`Object.prototype` funciona nos dois**, porque não depende do que o objeto tem. A última linha mostra
o que acontece sem o empréstimo. `Object.hasOwn`, acrescentado em 2022, faz o mesmo que a versão
emprestada com menos caracteres, e é o que se escreve hoje.

## Perguntando o que algo é de verdade

```javascript
const tag = (v) => Object.prototype.toString.call(v);
console.log(tag([]), tag({}), tag(null), tag(new Date(0)), tag(new Map()));
console.log(String([]), String({}));
console.log(Array.prototype.map.call("abc", (c) => c.toUpperCase()));
```

```
ana@dev:~/js$ node tostring.js
[object Array] [object Object] [object Null] [object Date] [object Map]
 [object Object]
[ 'A', 'B', 'C' ]
```

Emprestar `Object.prototype.toString` dá uma etiqueta precisa para qualquer valor, `[object Array]`
ou `[object Null]`, onde o `String()` dá uma string vazia para um array. **É como as bibliotecas
distinguem os tipos embutidos**, e é por isso que você vai ver exatamente essa linha no código delas.
A última linha empresta o `map` para uma string, cujos caracteres são numerados como os itens de um
array.
