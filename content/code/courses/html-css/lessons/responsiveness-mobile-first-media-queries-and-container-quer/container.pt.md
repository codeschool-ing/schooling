---
title: Container queries: o componente que se mede
---

Media query pergunta o tamanho da **janela**. Isso quebra para componentes reutilizáveis: o mesmo cartão pode estar numa barra estreita ou ocupando a tela inteira, e a janela não distingue os dois casos.

Container queries perguntam o tamanho do **contêiner**:

```css
.lista { container-type: inline-size; }

@container (min-width: 400px) {
  .cartao { display: grid; grid-template-columns: 80px 1fr; }
}
```

O cartão passa a se adaptar ao espaço que **ele** recebeu, não ao tamanho do monitor. É a resposta certa para biblioteca de componentes, e hoje tem suporte em todos os navegadores atuais.
