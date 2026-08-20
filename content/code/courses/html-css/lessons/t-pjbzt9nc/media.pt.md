---
title: Vídeo e áudio
---

Os elementos nativos dispensam biblioteca para o caso comum:

```html
<video controls preload="metadata" poster="capa.jpg" width="640">
  <source src="aula.webm" type="video/webm" />
  <source src="aula.mp4" type="video/mp4" />
  <track kind="captions" src="aula.vtt" srclang="pt" label="Português" default />
</video>
```

Vários `<source>` deixam o navegador pegar o formato que ele reproduz. `preload="metadata"` baixa só o suficiente para saber a duração — `auto` baixaria o vídeo inteiro de quem talvez não o assista.

A faixa de legenda não é opcional na prática: ela serve a quem não ouve, a quem está em lugar barulhento e a quem prefere ler. E, ao contrário do resto, ela não se acrescenta depois sem voltar a produzir o conteúdo.
