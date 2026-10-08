---
title: O elemento picture: recortes e formatos diferentes
version: 2
---

`srcset` oferece **a mesma imagem** em tamanhos diferentes. Às vezes uma tela estreita precisa de **outra imagem**: a foto larga das estantes vira uma faixa de nada no celular, e um recorte quadrado de uma estante se lê melhor. Isso se chama **direção de arte** (*art direction*), e `<picture>` faz isso.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>The shop · Andorinha Books</title>
    <style>
      body { margin: 0; }
      img { width: 100%; height: auto; }
    </style>
  </head>
  <body>
    <picture>
      <source media="(max-width: 600px)" srcset="shelves-crop-600.png">
      <img src="shelves-960.png" width="960" height="640"
           alt="The shelves of the shop, floor to ceiling">
    </picture>
  </body>
</html>
```

`<picture>` envolve um `<img>` comum e acrescenta elementos `<source>` antes dele. O navegador pega o **primeiro** `<source>` cuja condição `media` bate e usa o `srcset` dele; se nenhum bate, usa o `<img>`. O `<img>` nunca é opcional: é ele que é desenhado, ele carrega o `alt`, o `width` e o `height`, e é ele que um navegador antigo demais para `<picture>` mostra.

```
ana@laptop:~/site$ probe --width 390 picture.html img img
img  chose shelves-crop-600.png (600×600 pixels), drawn 390 wide
ana@laptop:~/site$ probe --width 1024 picture.html img img
img  chose shelves-960.png (960×640 pixels), drawn 1024 wide
```

Numa janela de 390 de largura, `(max-width: 600px)` bate e o recorte quadrado é usado. Em 1024 não bate, e o arquivo do próprio `<img>` é usado.

## Formatos mais novos, com um antigo para recorrer

O outro uso do `<source>` é o formato do arquivo. WebP e AVIF comprimem fotos melhor que JPEG e PNG, e todo navegador atual lê WebP, mas uma página pode ainda querer guardar uma alternativa. `type` num `<source>` nomeia o formato, e um navegador que não o lê pula para o próximo:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>The shop · Andorinha Books</title>
  </head>
  <body>
    <picture>
      <source type="image/webp" srcset="shelves-960.webp">
      <img src="shelves-960.png" width="960" height="640"
           alt="The shelves of the shop, floor to ceiling">
    </picture>
  </body>
</html>
```

```
ana@laptop:~/site$ probe formats.html img img
img  chose shelves-960.webp (960×640 pixels), drawn 960 wide
ana@laptop:~/site$ wc -c shelves-960.png shelves-960.webp
26134 shelves-960.png
 5078 shelves-960.webp
31212 total
```

O Chromium lê WebP, então pegou o primeiro source. A diferença de tamanho é real, mas estas imagens são cor chapada com um rótulo, então a proporção, 5078 bytes contra 26134, diz pouco sobre fotos; em fotos de verdade a economia é a razão de o formato existir. Os seus dois números não serão estes, porque o seu sistema desenha o rótulo com a fonte dele, e o WebP continuará sendo o menor. Um navegador que não conhecesse `image/webp` teria pulado esse `<source>` e desenhado o PNG.

**Use `<picture>` quando o navegador precisa ser informado de algo que não consegue descobrir sozinho**: um recorte diferente, ou um formato que talvez não suporte. Para a mesma imagem em tamanhos diferentes, `srcset` e `sizes` num `<img>` simples bastam e são mais simples.
