---
title: Três pontos: spread e rest
version: 1
---

`...` significa duas coisas opostas conforme onde fica. **Onde se esperam valores, ele espalha**:
desmonta um array ou um objeto e põe as peças no lugar. **Onde se declaram nomes, ele junta o
resto** num único array ou objeto.

```javascript
const fiction = ["Iracema", "Dom Casmurro"];
const poetry = ["Lira dos Vinte Anos"];
const all = [...fiction, ...poetry, "Macunaíma"];
console.log(all);

const years = [1899, 1865, 1928];
console.log(Math.max(...years));

const defaults = { theme: "light", perPage: 20, language: "en" };
const chosen = { perPage: 50, language: "pt" };
console.log({ ...defaults, ...chosen });
console.log({ ...chosen, ...defaults });

function total(label, ...amounts) {
  return `${label}: ${amounts.reduce((a, b) => a + b, 0)}`;
}
console.log(total("pages", 112, 256, 208));
```

```
ana@dev:~/js$ node spread.js
[ 'Iracema', 'Dom Casmurro', 'Lira dos Vinte Anos', 'Macunaíma' ]
1928
{ theme: 'light', perPage: 50, language: 'pt' }
{ perPage: 20, language: 'en', theme: 'light' }
pages: 576
```

## Spread

- **`[...fiction, ...poetry, "Macunaíma"]`** constrói um array novo com os itens de outros dois e
  mais um. `[...shelf]` sozinho é o jeito comum de copiar um array, e é raso do mesmo jeito que o
  spread de objeto;
- `Math.max` recebe números separados, não um array, então **`Math.max(...years)` espalha o array
  em argumentos**. Antes do spread existir isso se escrevia com `apply`, que a aula 7 cobre;
- com objetos, o spread copia as propriedades para um objeto novo, e **quando duas têm o mesmo
  nome, a que vem depois ganha**. `{ ...defaults, ...chosen }` é o jeito padrão de aplicar as
  escolhas de um usuário por cima dos padrões. Trocar a ordem jogou as escolhas fora, como mostra a
  quarta linha.

## Rest

Numa lista de parâmetros, `...amounts` junta todo argumento depois dos nomeados num array de
verdade. `total` recebeu um rótulo e **qualquer quantidade de valores**, e os somou com `reduce`. Um
parâmetro rest tem de ser o último, já que leva tudo o que sobrar.

O rest também funciona na desestruturação, que é o assunto da próxima seção:
`const [first, ...others] = list` fica com o primeiro item e junta o resto.

**O spread faz uma cópia, e só de um nível.** Isso basta para manter uma mudança no nível de cima da
cópia longe do original, e não basta para nada aninhado, como a figura da cópia rasa desta aula
mostrou.
