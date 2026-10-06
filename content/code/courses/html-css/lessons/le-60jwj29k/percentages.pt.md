---
title: Porcentagens: uma fração de quê?
version: 1
---

Uma porcentagem é sempre uma fração de alguma coisa, e essa coisa depende da propriedade. Errar isso é como um layout acaba com o dobro da altura que alguém esperava. As regras que valem saber:

- **`width`**: uma fração da **largura do bloco de contenção**. Para a maioria dos elementos o bloco de contenção é o pai; a aula 7 trata das exceções.
- **`height`**: uma fração da **altura** do bloco de contenção, mas só se essa altura estiver definida; senão, é ignorada.
- **`padding` e `margin`, em todos os lados, inclusive em cima e embaixo**: uma fração da **largura** do bloco de contenção.
- **`font-size`**: uma fração do tamanho de fonte do pai, como `em`.

A terceira regra é a que surpreende. Aqui está uma coluna de 600 por 200 com um filho em `width: 50%; padding-top: 10%; height: 50%`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Percentages · Andorinha Books</title>
    <style>
      body { margin: 0; }
      .column { width: 600px; height: 200px; }
      .half { width: 50%; padding-top: 10%; height: 50%; }
    </style>
  </head>
  <body>
    <div class="column">
      <div class="half"></div>
    </div>
  </body>
</html>
```

```
ana@laptop:~/site$ probe percent.html box .half
div.half  x 0      y 0      width 300    height 160
```

O filho tem **300 de largura**, metade de 600. Tem **160 de altura**: 100 do `height: 50%`, metade dos 200 da coluna, mais **60** do `padding-top: 10%`. Dez por cento da **largura** da coluna, não da altura. A regra existe para que o padding nos quatro lados tenha o mesmo tamanho quando escrito com a mesma porcentagem, e antes de existir o `aspect-ratio` era o truque usado para uma caixa manter a proporção: `padding-top: 56.25%` numa caixa vazia a deixava 16:9 em qualquer largura. A seção 11 mostra o jeito moderno.

## Porcentagens e a página

`width: 100%` num bloco costuma ser desnecessário: um bloco já ocupa a largura inteira do contêiner. E com `content-box`, `width: 100%` mais padding fica mais largo que o contêiner, o que é mais um motivo para a regra da seção 04. Onde porcentagens se justificam é em layouts em que algo deve ser uma fração do contêiner, e as aulas 8 e 9 dão ferramentas melhores para a maioria desses casos: a unidade `fr` e o `flex` dividem espaço com mais precisão que porcentagens, e sem nenhuma conta com bordas.
