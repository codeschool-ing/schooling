---
title: Mobile first: o layout estreito é o padrão
version: 2
---

**Mobile first** é uma ordem para escrever CSS: as regras fora de qualquer media query são o layout da tela **mais estreita**, e cada media query acrescenta algo a ele para telas que têm mais espaço. Aqui está o menu da livraria escrito assim:

```css
*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; font-family: system-ui, sans-serif; }

/* The phone's layout is the default: one link per line, each easy to tap. */
.menu { list-style: none; margin: 0; padding: 0; }
.menu a { display: block; padding: 0.75rem 1rem; }

/* Only a window wide enough for a row gets one. */
@media (width >= 40rem) {
  .menu { display: flex; gap: 0.5rem; }
}
```

Fora da query, cada link é um bloco com padding: um por linha, na largura inteira da tela, fácil de acertar com o polegar. A media query, que a seção 03 desmonta, diz "de 40rem de largura para cima", e só ali a lista vira uma fileira flex:

```
ana@laptop:~/site$ probe --width 390 first.html box ".menu a"
a  x 0      y 0      width 390    height 44
a  x 0      y 44     width 390    height 44
a  x 0      y 88     width 390    height 44
ana@laptop:~/site$ probe --width 800 first.html box ".menu a"
a  x 0      y 0      width 82.61  height 44
a  x 90.61  y 0      width 130.89 height 44
a  x 229.5  y 0      width 143.44 height 44
```

Num celular de 390 de largura, os três links estão empilhados, cada um com **390 de largura e 44 de altura**. Numa janela de 800, ficam numa fileira em y 0, cada um da largura do próprio texto. É o `<meta name="viewport">` da seção 10 da aula 1 que permite ao celular informar 390 aqui; sem ele, o celular monta a página com 980 de largura e nenhuma query para tela estreita casaria.

## Por que começar pela ponta estreita

**O layout estreito é o mais simples.** Num celular, quase tudo é uma coluna só, na ordem do HTML, que é o que o layout de bloco faz sem CSS nenhum. Os layouts largos são onde entram as fileiras, as colunas e as barras laterais. Escrever primeiro o caso simples e acrescentar complexidade em queries faz cada query dizer só o que é **novo** naquela largura.

A outra ordem, **desktop first**, escreve primeiro o layout largo e depois o desfaz em queries que valem abaixo de uma largura:

```css
.menu { display: flex; gap: 0.5rem; }
.menu a { padding: 0.5rem; }

@media (width < 40rem) {
  .menu { display: block; }
  .menu a { display: block; padding: 0.75rem 1rem; }
}
```

Funciona, e cada regra da query está ali para cancelar uma de fora. Conforme a folha cresce, a tela estreita vira a soma de tudo o que o desktop fez com tudo o que foi desfeito depois, e a versão que mais gente usa é a última a ser construída.

Acrescentar é mais fácil que subtrair, e mobile first é isso, posto por escrito.
