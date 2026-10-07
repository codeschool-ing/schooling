---
title: Vídeo e áudio
version: 2
---

`<video>` e `<audio>` põem uma gravação na página, tocada pelo próprio navegador, sem plug-in. O sebo tem a gravação do sarau de poesia do mês passado:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Last month's reading · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Last month's reading</h1>
      <figure>
        <video controls preload="none" width="320" height="180" poster="cover.png">
          <source src="reading.webm" type="video/webm">
          <track kind="captions" src="reading.vtt" srclang="en" label="English" default>
          <a href="reading.webm">Download the video</a>.
        </video>
        <figcaption>Hilda Hilst's poems, read by three of our customers.</figcaption>
      </figure>
    </main>
  </body>
</html>
```

O que cada parte faz:

- **`controls`** mostra os botões do próprio navegador de tocar, pausar, volume e tela cheia. Sem ele não há nenhum, e um vídeo sem controles é um que quem usa teclado não consegue parar.
- **`<source>`**, com um `type`, lista os arquivos; o navegador toca o primeiro que consegue. Vários sources em formatos diferentes funcionam como o `<picture>` da seção 08.
- **`<track kind="captions">`** dá um arquivo de legendas em **WebVTT**, um formato de texto com um intervalo de tempo e uma linha para cada legenda. `default` as liga a menos que o leitor as desligue.
- **`poster`** é a imagem mostrada antes de o vídeo tocar.
- **O conteúdo dentro de `<video>`**, o link de download, só aparece num navegador que não consegue tocar vídeo nenhum.
- **`preload`** diz quanto buscar antes de alguém apertar o play.

O arquivo de legendas, `reading.vtt`, é texto puro, e este tem uma única legenda:

```
WEBVTT

00:00.000 --> 00:02.000
Good evening, and welcome to Andorinha Books.
```

## O que o `preload` muda

Com `preload="none"`, e depois com uma cópia salva como `video-metadata.html` que diz `preload="metadata"` no lugar:

```
ana@laptop:~/site$ probe video.html fetched
cover.png
ana@laptop:~/site$ probe video-metadata.html fetched
cover.png
reading.webm
```

Com `none`, o navegador buscou o poster e mais nada: o plano de dados do leitor fica intacto até ele apertar o play. Com `metadata`, ele também pediu o arquivo de vídeo, para saber a duração e as dimensões. Numa página com um vídeo perto do topo, `metadata` é a escolha comum; numa página que lista vinte gravações, `none` poupa o leitor de vinte requisições.

## Legendas não são opcionais

**Um vídeo com fala precisa de legendas**: são como pessoas surdas e com deficiência auditiva o acompanham, como qualquer um o acompanha sem som num ônibus, e a WCAG as exige para vídeo pré-gravado. Uma gravação de áudio precisa de uma **transcrição**, o texto inteiro na página ou atrás de um link. Gerar legendas automaticamente é um começo que precisa ser corrigido por uma pessoa, porque uma palavra errada numa legenda é uma palavra errada no que o leitor ouviu dizer.

**Não toque som automaticamente.** Uma página que começa a falar quando abre briga com o leitor de tela de quem usa um. Os navegadores já bloqueiam o autoplay com som; `autoplay` junto com `muted` é permitido e é como funcionam os vídeos de fundo, e mesmo esses precisam de um jeito visível de serem parados.
