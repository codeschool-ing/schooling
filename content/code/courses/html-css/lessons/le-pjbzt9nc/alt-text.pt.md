---
title: Texto no lugar de uma imagem
version: 2
---

Todo `<img>` precisa de um **atributo `alt`**, e a pergunta que ele responde não é "o que tem na imagem?", e sim **"o que eu escreveria aqui se não pudesse usar uma imagem?"**. O texto dele substitui a imagem para quem não consegue vê-la: quem usa leitor de tela, um leitor cuja conexão não carregou o arquivo, um buscador. Toda imagem cai num de três casos, e uma página logo abaixo mostra os três.

As imagens desta aula não são fotos. São um verde liso com o tamanho escrito em cima, para que, quando uma página puder escolher entre vários arquivos, você veja qual ela escolheu. Uma página faz todas, e também o vídeo da seção 11. Salve-a como `pictures.html` em `site` e abra:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Pictures for lesson 4</title>
  </head>
  <body>
    <h1>Pictures for lesson 4</h1>
    <p>Save each file into your site folder: click it, or right-click and choose to save the link.</p>
    <ul id="files"></ul>
    <script>
      function offer(blob, name) {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = name;
        link.textContent = name;
        const item = document.createElement('li');
        item.append(link);
        document.getElementById('files').append(item);
      }
      // Flat green with the size written on it, so you can see which file a page chose.
      function draw(width, height) {
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const pen = canvas.getContext('2d');
        pen.fillStyle = '#2f6f4e';
        pen.fillRect(0, 0, width, height);
        if (height >= 40) {
          pen.fillStyle = 'white';
          pen.font = Math.round(height / 8) + 'px sans-serif';
          pen.textAlign = 'center';
          pen.textBaseline = 'middle';
          pen.fillText(width + '×' + height, width / 2, height / 2);
        }
        return canvas;
      }
      function picture(width, height, name, type = 'image/png', quality) {
        draw(width, height).toBlob(blob => offer(blob, name), type, quality);
      }
      picture(200, 300, 'cover.png');
      picture(400, 8, 'divider.png');
      picture(480, 320, 'shelves-480.png');
      picture(960, 640, 'shelves-960.png');
      picture(1600, 1067, 'shelves-1600.png');
      picture(600, 600, 'shelves-crop-600.png');
      picture(960, 640, 'shelves-960.webp', 'image/webp', 0.8);
      // Two seconds of video: the same green, recorded from a canvas.
      const screen = draw(320, 180);
      const recorder = new MediaRecorder(screen.captureStream(25), { mimeType: 'video/webm' });
      const chunks = [];
      recorder.ondataavailable = event => chunks.push(event.data);
      recorder.onstop = () => offer(new Blob(chunks, { type: 'video/webm' }), 'reading.webm');
      const tick = setInterval(() => screen.getContext('2d').fillRect(0, 0, 1, 1), 40);
      recorder.start();
      setTimeout(() => { recorder.stop(); clearInterval(tick); }, 2000);
    </script>
  </body>
</html>
```

Ela lista oito arquivos. Clique em cada um: o navegador o salva na pasta de downloads, e de lá ele vai para `site`. A página usa um pouco de JavaScript, um canvas para desenhar e um gravador para o vídeo. O curso de `javascript` é onde isso se ensina; aqui ela só precisa rodar. Com as imagens no lugar, esta é a página com os três casos, `alt.html`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>This week's find · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>This week's find</h1>
      <img src="cover.png" width="200" height="300"
           alt="First edition of Grande Sertão: Veredas, green cloth cover, spine faded">
      <img src="divider.png" width="400" height="8" alt="">
      <img src="cover.png" width="200" height="300">
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe alt.html tree axe
- main:
  - heading "This week's find" [level=1]
  - 'img "First edition of Grande Sertão: Veredas, green cloth cover, spine faded"'
  - img
image-alt (critical, 1 element): Images must have alternative text
```

**A primeira imagem traz informação**, então o `alt` dela diz o que o leitor precisa saber por ela: que livro, que edição, em que estado. A árvore a lista como **img** nomeada por esse texto.

**A segunda é decoração**, uma linha divisória, e o `alt` dela é vazio: `alt=""`. Isso não é um alt faltando; é uma declaração de que a imagem não diz nada. O navegador a deixa inteiramente fora da árvore, então um leitor de tela a pula, que é exatamente o certo: ouvir *imagem, divisória* entre cada seção é ruído.

**A terceira não tem `alt` nenhum**, e é a pior das três. A árvore mostra um **img** sem nada, e muitos leitores de tela recorrem então a ler o nome do arquivo, *cover ponto png*, que é como as pessoas acabam ouvindo `IMG_4031.jpg` em voz alta. O axe a apontou como **image-alt**, crítico.

## Como escrever um bom texto alternativo

- **Diga para que a imagem serve, no contexto.** A mesma foto da loja é *a fachada da Andorinha Books, Rua dos Pinheiros* na página de contato e pode ser decoração na página inicial.
- **Não comece com "imagem de" ou "foto de".** O leitor de tela já diz *imagem*.
- **Fique numa frase.** Se a imagem precisa de mais, um gráfico por exemplo, a explicação pertence ao texto da página, onde todo mundo pode lê-la.
- **Texto dentro da imagem vai no alt.** A foto de um cartaz que diz *Book swap, Saturday 10 am* tem isso como alt.
- **Dentro de um link, descreva para onde o link vai**, como a seção 09 da aula 2 mostrou.

A decisão entre os dois primeiros casos é a que importa: **se tirar a imagem perderia informação, descreva-a; se não perderia nada, `alt=""`.**
