---
title: Áreas nomeadas: o layout desenhado
---

A forma mais legível de grid é dar nome às regiões e desenhá-las:

```css
.app {
  display: grid;
  grid-template-columns: 240px 1fr;
  grid-template-areas:
    "barra  barra"
    "trilho conteudo"
    "rodape rodape";
}
.barra    { grid-area: barra; }
.trilho   { grid-area: trilho; }
.conteudo { grid-area: conteudo; }
.rodape   { grid-area: rodape; }
```

O CSS passa a **parecer** o layout, e reorganizar tudo no celular é reescrever as três linhas de aspas dentro de uma media query — sem tocar em nenhum filho.
