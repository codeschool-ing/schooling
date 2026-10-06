---
title: Um escopo global, e o problema dele
version: 1
---

Um `<script>` clássico roda no escopo global da página. A aula 3 mostrou o que isso significa para
um `var` de nível de cima; aqui está com dois arquivos escritos por duas pessoas:

```javascript
function format(title) {
  return `A: ${title}`;
}
```

```javascript
function format(title) {
  return `B: ${title}`;
}
```

```html
<!doctype html>
<script src="a.js"></script>
<script src="b.js"></script>
<script>
  console.log(format("Iracema"));
</script>
```

```
ana@dev:~/js$ cd classic && page page.html
B: Iracema
```

**Os dois arquivos declararam `format` no mesmo escopo, e o carregado por último substituiu o
outro**, sem erro. Quem escreveu `a.js` acharia a sua função respondendo `B:` e nada para dizer por
quê. A ordem das tags `<script>` também era, em silêncio, uma lista de dependências: um script que
usava uma função de outro precisava vir depois dele, e nada conferia isso.

## O que um sistema de módulos te dá

Um **módulo** é um arquivo com escopo próprio. Nada que ele declara vaza para fora a menos que ele
diga, e nada de outro arquivo entra a menos que ele peça. Isso dá três coisas que o escopo global
não dava:

- **nomes que não colidem**, porque os nomes de cada arquivo são dele;
- **dependências escritas no arquivo que as tem**, então a ordem de carregamento é resolvida pelo
  sistema e não por quem edita a página;
- **uma superfície pública explícita**: o que um arquivo exporta é aquilo de que outros arquivos
  podem depender, e todo o resto pode mudar à vontade.

O JavaScript tem dois sistemas de módulos porque a linguagem levou vinte anos para ganhar um. O
**CommonJS** foi inventado para o Node em 2009 e ainda é o formato da maior parte do código Node mais
antigo. Os **ES modules**, ou ESM, entraram na linguagem em 2015 e funcionam igual no navegador e no
Node. As próximas seções tratam primeiro dos ES modules, já que são os da própria linguagem, depois
do CommonJS, depois do que acontece onde os dois se encontram.
