---
title: O doctype, e o modo sem ele
version: 2
---

A primeira linha de toda página, `<!doctype html>`, parece formalidade. Não é uma tag, e não cria nenhum elemento. **É uma chave**, e deixá-la de fora muda a forma como o navegador monta a página inteira.

## Dois modos

No começo dos anos 2000, quando os navegadores passaram a seguir direito os padrões do CSS, já havia milhões de páginas escritas para o comportamento antigo, fora do padrão. Corrigir os navegadores teria quebrado essas páginas. Então os navegadores mantiveram os dois comportamentos e escolhem entre eles página a página: uma página que começa com um doctype moderno ganha o **modo padrão** (*standards mode*), e uma sem doctype ganha o **modo de compatibilidade** (*quirks mode*), que imita os navegadores de por volta de 2000.

`<!doctype html>` é o doctype mais curto que seleciona o modo padrão, e por isso é o que o HTML usa hoje. Ele não diferencia maiúsculas, então `<!DOCTYPE html>` é a mesma chave.

## O que a chave muda

As diferenças são pequenas e espalhadas, e é exatamente por isso que machucam: uma página em modo de compatibilidade parece quase certa. Aqui está uma que dá para medir. Os dois arquivos são idênticos, menos a primeira linha: uma `<div>` com uma única imagem de 80 pixels de altura.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Cover, with a doctype</title>
  </head>
  <body>
    <div class="frame"><img src="cover.png" alt="" width="120" height="80"></div>
  </body>
</html>
```

Salve-o como `standards.html`, com qualquer imagem pequena ao lado chamada `cover.png`: os atributos `width` e `height` fixam o tamanho dela em 120 por 80, seja qual for a imagem. Depois salve uma cópia como `quirks.html`, apague a primeira linha e mude o título para *Cover, without a doctype*.

Com o doctype:

```
ana@laptop:~/site$ probe standards.html mode box div.frame
compatMode: CSS1Compat
div.frame  x 8      y 8      width 1008   height 84
```

Sem ele:

```
ana@laptop:~/site$ probe quirks.html mode box div.frame
compatMode: BackCompat
div.frame  x 8      y 8      width 1008   height 80
```

`compatMode` é o nome que o próprio navegador dá ao modo: `CSS1Compat` é o padrão e `BackCompat` é o de compatibilidade. No modo padrão a `<div>` tem **84** pixels de altura para uma imagem de 80, porque a imagem fica sobre a linha de texto como uma letra, e a linha reserva espaço embaixo para as partes das letras que descem, como o rabo do *g*. No modo de compatibilidade esse espaço não é reservado e a `<div>` tem exatamente 80.

Quatro pixels não parece muito. Mas o resto do curso explica o layout no modo padrão, e toda regra sobre caixas e espaço das aulas 6 a 9 o pressupõe. No modo de compatibilidade algumas dessas regras saem diferentes, sem aviso, e você estaria depurando um layout com o livro de regras errado. O espaço embaixo das imagens é algo que a aula 6 mostra como remover de propósito.

**Uma página sem doctype não tem mensagem de erro.** Nada diz em que modo você está, a não ser o DevTools, se você souber onde olhar, e um validador, que o aponta como erro, seção 13. A cura é uma linha, e ela vem primeiro, antes de qualquer outra coisa.
