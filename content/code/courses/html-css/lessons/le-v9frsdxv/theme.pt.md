---
title: Os seus design tokens em @theme
version: 1
---

A aula 10 prometeu que o Tailwind poderia usar os seus tokens em vez dos dele. É o bloco **`@theme`** na folha de entrada:

```css
@import "tailwindcss";

@theme {
  --color-andorinha-50: #fbf8f2;
  --color-andorinha-700: #2f6f4e;
  --color-andorinha-900: #1d1d1b;
  --color-cancelled: #8a1c1c;
  --font-display: Georgia, "Times New Roman", serif;
}
```

Cada variável em `@theme` é um token e **também cria utilitários**. O nome dela diz quais: `--color-andorinha-700` cria `bg-andorinha-700`, `text-andorinha-700`, `border-andorinha-700` e todo outro utilitário de cor para essa cor; `--font-display` cria `font-display`. A página os usa como os embutidos:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd theme -i input.css -o out.css --silent
ana@laptop:~/site$ grep -E -- "--(color-andorinha|color-cancelled|font-display)[a-z0-9-]*:" theme/out.css
    --color-andorinha-50: #fbf8f2;
    --color-andorinha-700: #2f6f4e;
    --color-andorinha-900: #1d1d1b;
    --color-cancelled: #8a1c1c;
    --font-display: Georgia, "Times New Roman", serif;
ana@laptop:~/site$ probe theme/index.html style body background-color style "#title" font-family,font-size style "#poetry,#swap" color
body.bg-andorinha-50.text-andorinha-900  background-color: rgb(251, 248, 242)
h1#title  font-family: Georgia, "Times New Roman", serif
h1#title  font-size: 30px
h2#poetry  color: rgb(29, 29, 27)
h2#swap  color: rgb(138, 28, 28)
```

Os tokens são declarados em `:root` com os valores que você deu, e a página tem as cores da livraria: o fundo da página **`rgb(251, 248, 242)`**, o título do evento cancelado **`rgb(138, 28, 28)`** e a fonte de destaque no `<h1>`.

## Até onde levar isso

A paleta e a escala do próprio Tailwind continuam disponíveis ao lado das suas. Para usar **só** as suas cores, comece o bloco com **`--color-*: initial;`**, que remove toda cor embutida, de modo que `bg-red-500` deixa de existir e ninguém consegue recorrer a ela. O mesmo vale para qualquer espaço de nomes: `--font-*`, `--text-*`, `--spacing`.

**Dê nome aos tokens pelo papel**, seção 06 da aula 10. `--color-cancelled` sobrevive a um redesenho em que `--color-red` não sobreviveria. E como todo token é uma propriedade personalizada CSS em `:root`, o seu próprio CSS pode usar os mesmos valores: `border-color: var(--color-andorinha-700)` numa folha de estilos acompanha o `border-andorinha-700` do HTML.
