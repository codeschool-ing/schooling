---
title: Nomes no topo de um script
version: 1
---

A última diferença aparece no nível de cima de um arquivo, fora de toda função. **No navegador, um
`var` ou uma função declarados no topo de um script clássico viram propriedade do objeto global**,
`window`, que todo script da página compartilha. Um `let` ou um `const` não:

```html
<!doctype html>
<script>
  var shelfCount = 12;
  let readerName = "ana";
  function openShelf() {}

  console.log(window.shelfCount, window.readerName, typeof window.openShelf);
</script>
<script>
  console.log(shelfCount, readerName);
</script>
```

```
ana@dev:~/js$ page globals.html
12 undefined function
12 ana
```

`window.shelfCount` é 12 e `window.openShelf` é a função, enquanto `window.readerName` é
`undefined`. Ainda assim a segunda linha mostra que o segundo `<script>` conseguiu ler
`readerName`. **`let` e `const` de nível de cima também são compartilhados entre os scripts da
página**, num escopo próprio ao lado do `window`, e não nele.

A diferença importa porque o `window` já guarda centenas de propriedades. **Um `var` de nível de
cima chamado `name`, `status` ou `top` colide com uma que o navegador pôs lá**:

```html
<!doctype html>
<script>
  var name = 42;
  var top = "the top shelf";
  console.log(typeof name, name);
  console.log(top === window);
</script>
```

```
ana@dev:~/js$ page collide.html
string 42
true
```

`window.name` só guarda strings, então o número 42 voltou como o texto `"42"`. `window.top` não pode
ser substituído de jeito nenhum, então a atribuição não fez nada e `top` continua sendo a janela.
Nenhum dos dois acusou erro. Com `let` não há colisão possível.

## O Node é diferente

```javascript
var shelfCount = 12;
console.log(globalThis.shelfCount);
```

```
ana@dev:~/js$ node globals.js
undefined
```

**Cada arquivo do Node tem um escopo próprio**, então o `var` de nível de cima fica no arquivo e o
`globalThis`, o nome do objeto global em todo hospedeiro, não o recebe. A aula 9 explica de onde
vem esse escopo. Um `<script type="module">` no navegador se comporta do mesmo jeito, e esse é um
dos motivos de os módulos terem substituído os scripts clássicos.

## O global que você nunca declarou

```javascript
function countBooks() {
  total = 7;
}

countBooks();
console.log(total, globalThis.total);
```

```
ana@dev:~/js$ node implicit.js
7 7
```

`total` nunca foi declarado em lugar nenhum. **Atribuir a um nome não declarado cria uma
propriedade no objeto global**, então a função criou em silêncio um global que todo outro arquivo
do programa agora vê e pode sobrescrever. Um erro de digitação no nome de uma variável faz a mesma
coisa. Isso não é um recurso que alguém queira, e a aula 20 mostra o modo, o modo estrito, em que
esta linha é um `ReferenceError`.
