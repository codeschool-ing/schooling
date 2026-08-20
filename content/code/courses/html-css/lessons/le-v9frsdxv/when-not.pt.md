---
title: Quando não usar
---

Repetir a mesma sequência de dez classes em quinze lugares é sinal de que ali havia um componente. A saída certa é o componente do framework que você já usa — um `<Botao>` em React, um parcial no template —, não uma classe nova que reagrupa utilitários.

E Tailwind **não** dispensa saber CSS. Cada classe é uma propriedade: quem não entende especificidade, modelo de caixa e flexbox não entende `flex-1`, `min-w-0` nem por que a sombra sumiu. As doze aulas anteriores continuam sendo o pré-requisito.

A régua honesta: Tailwind rende em produto com muitos componentes e um time que compartilha a escala. Numa página institucional de cinco telas, o CSS escrito à mão é menor, mais legível e não traz ferramenta nenhuma junto.
