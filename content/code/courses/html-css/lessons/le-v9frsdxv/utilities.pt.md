---
title: A ideia: uma classe, uma propriedade
---

Tailwind inverte a organização do CSS. Em vez de nomear componentes e descrevê-los num arquivo à parte, você compõe o estilo no próprio HTML com classes de uma propriedade cada:

```html
<button class="px-4 py-2 rounded bg-blue-500 text-white hover:bg-blue-600">
  Enviar
</button>
```

O ganho real não é digitar menos — é que **o CSS para de crescer**. Não há nome a inventar, não há arquivo a caçar, e apagar o HTML apaga o estilo junto. Some a classe órfã que ninguém tem coragem de remover.

O custo é igualmente real: o HTML fica poluído, e a leitura de um trecho longo piora. É uma troca, não uma vitória.
