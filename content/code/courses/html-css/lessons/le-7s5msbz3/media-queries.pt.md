---
title: Media queries
version: 1
---

Uma **media query** é uma condição sobre o dispositivo ou a janela, e um bloco de regras que só vale enquanto a condição é verdadeira. A parte entre parênteses é uma **media feature**:

```css
@media (width >= 40rem) { … }
```

`width` é a largura do viewport, a janela onde a página é desenhada. Aqui ela é consultada em três momentos; o passo `width` redimensiona a janela com a página aberta:

```
ana@laptop:~/site$ probe --width 600 first.html media "(width >= 40rem)" width 640 media "(width >= 40rem)" media "(min-width: 40rem)"
(width >= 40rem)  does not match
(width >= 40rem)  matches
(min-width: 40rem)  matches
```

Em 600 a query não casa. Em 640 casa, porque aqui 40rem são 640 pixels. As regras de dentro começam a valer no instante em que a janela cruza essa largura e param quando ela volta, sem recarregar. A terceira linha é a mesma pergunta na sintaxe antiga, **`(min-width: 40rem)`**, que quer dizer "a largura é de pelo menos 40rem". Você vai ler as duas em todo lugar. A **sintaxe de intervalo**, `width >= 40rem`, diz o mesmo com um operador, e consegue dizer coisas que `min-` e `max-` não dizem diretamente, como `(40rem <= width < 64rem)`, um intervalo entre duas larguras. Funciona em todo navegador atual.

## Combinando, e outras features

Condições se combinam com **`and`**, como em `(width >= 40rem) and (orientation: landscape)`; uma vírgula entre duas queries quer dizer **ou**; `not` nega uma query inteira. Uma query pode começar com um **tipo de mídia**, `screen` ou `print`: `@media print { nav { display: none; } }` tira o menu de uma página impressa, e é o único tipo de mídia que você ainda vai escrever. A seção 08 trata das features que descrevem quem lê, e não a janela.

Uma folha de estilos inteira também pode ser condicional: `<link rel="stylesheet" href="print.css" media="print">` só vale na impressão.

## O rem de uma query não é o seu rem

`rem` dentro de uma media query não usa o tamanho de fonte que você definiu em `html`. Usa o tamanho de fonte **inicial** do navegador, em geral 16 pixels, porque a query precisa ser respondida antes de a sua folha de estilos ser aplicada. Esta página define `html { font-size: 20px; }`:

```
ana@laptop:~/site$ probe --width 700 rem.html box .box media "(width >= 40rem)" media "(width >= 45rem)"
div.box  x 8      y 8      width 800    height 23
(width >= 40rem)  matches
(width >= 45rem)  does not match
```

Uma caixa de `40rem` tem **800** de largura, porque na página um rem são 20 pixels. E a janela tem 700, mas `(width >= 40rem)` **casa**: na query, 40rem são 640. `45rem`, 720, não casa. Então escreva breakpoints em `rem` ou `em` e pense neles como múltiplos de 16; e não espere que mudar o tamanho de fonte da raiz os mova.

Por que rem e não pixels? Quem define um tamanho de fonte padrão maior no navegador deixa todo rem maior, **inclusive os das queries**. Um layout com breakpoints em rem passa antes para o layout estreito para essa pessoa, que é exatamente o que o texto maior dela precisa. Breakpoints em pixels ignoram essa configuração.
