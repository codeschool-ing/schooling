---
title: fixed e sticky
---

`fixed` prende o elemento à janela: ele não sai do lugar quando a página rola. É o que segura a barra do topo deste portal.

`sticky` é o híbrido: o elemento rola normalmente até atingir o limite declarado, e ali gruda.

```css
.cabecalho-tabela {
  position: sticky;
  top: 0;
}
```

Duas pegadinhas do `sticky` explicam quase todo caso de "não funciona": ele **exige** um deslocamento declarado (`top`, `bottom`…), sem o qual não faz nada; e ele gruda dentro do **pai**, não da janela — se o pai tem `overflow: hidden` ou acaba logo, o efeito termina junto.
