---
title: absolute e o contexto de posicionamento
---

`position: absolute` tira o elemento do fluxo: o espaço dele deixa de existir e os vizinhos se fecham como se ele não estivesse ali. Ele passa a se posicionar em relação ao **ancestral posicionado mais próximo** — qualquer um que não seja `static`.

```css
.cartao      { position: relative; }
.cartao .selo {
  position: absolute;
  top: 8px;
  right: 8px;
}
```

É o padrão mais usado do CSS inteiro: o pai vira `relative` só para servir de referência, e o filho se pendura no canto dele. **Esquecer o `relative` no pai** é o defeito clássico — o selo sobe até o canto da página, porque na falta de ancestral posicionado a referência vira a janela.
