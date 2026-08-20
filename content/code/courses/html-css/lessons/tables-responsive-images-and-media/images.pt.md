---
title: Imagens que não desperdiçam banda
---

Servir a mesma imagem de 2000px para um celular é jogar fora banda e bateria de quem tem menos dos dois. `srcset` deixa o navegador escolher:

```html
<img
  src="foto-800.jpg"
  srcset="foto-400.jpg 400w, foto-800.jpg 800w, foto-1600.jpg 1600w"
  sizes="(max-width: 700px) 100vw, 700px"
  alt="Fachada da escola vista da calçada"
  width="800" height="600"
  loading="lazy" />
```

`width` e `height` não fixam o tamanho quando há CSS — eles informam a **proporção**, e é isso que impede a página de pular quando a imagem termina de carregar. `loading="lazy"` adia o que está fora da tela.

```schooling-figure
{
  "image": "data:image/svg+xml,<svg%20xmlns=%22http://www.w3.org/2000/svg%22%20viewBox=%220%200%20640%20200%22><g%20fill=%22none%22%20stroke=%22%238a8f98%22%20stroke-width=%221.3%22><rect%20x=%2212%22%20y=%22118%22%20width=%2270%22%20height=%2252%22%20rx=%223%22/><rect%20x=%22106%22%20y=%2284%22%20width=%22120%22%20height=%2286%22%20rx=%223%22/><rect%20x=%22250%22%20y=%2226%22%20width=%22230%22%20height=%22144%22%20rx=%223%22/></g><g%20fill=%22%238a8f98%22%20font-family=%22monospace%22%20font-size=%2211%22%20text-anchor=%22middle%22><text%20x=%2247%22%20y=%22148%22>400w</text><text%20x=%22166%22%20y=%22130%22>800w</text><text%20x=%22365%22%20y=%22102%22>1600w</text><text%20x=%2247%22%20y=%22188%22>celular</text><text%20x=%22166%22%20y=%22188%22>tablet</text><text%20x=%22365%22%20y=%22188%22>desktop</text></g><g%20fill=%22none%22%20stroke=%22%238a8f98%22%20stroke-width=%221%22%20stroke-dasharray=%223%203%22%20opacity=%22.7%22><path%20d=%22M520%2026v144%22/></g><g%20fill=%22%238a8f98%22%20font-family=%22monospace%22%20font-size=%2210%22><text%20x=%22534%22%20y=%2290%22>o%20navegador</text><text%20x=%22534%22%20y=%22106%22>escolhe%20uma,</text><text%20x=%22534%22%20y=%22122%22>n%C3%A3o%20as%20tr%C3%AAs</text></g></svg>",
  "alt": "Três retângulos de tamanhos diferentes rotulados 400w, 800w e 1600w, sob os rótulos celular, tablet e desktop",
  "caption": "O `srcset` oferece as três; quem escolhe é o navegador, que sabe a largura da tela e a densidade dela — coisas que o servidor não sabe."
}
```

O `alt` descreve a imagem para quem não a vê. Imagem puramente decorativa leva `alt=""` — vazio, não ausente: assim o leitor de tela a ignora em vez de anunciar o nome do arquivo.
