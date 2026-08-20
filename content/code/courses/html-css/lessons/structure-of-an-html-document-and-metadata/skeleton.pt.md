---
title: O esqueleto de toda página
---

Todo documento HTML tem a mesma moldura, e vale digitá-la à mão algumas vezes antes de deixar o editor gerá-la:

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <title>Minha página</title>
</head>
<body>
  <h1>Olá</h1>
</body>
</html>
```

O `<!DOCTYPE html>` não é uma tag: é uma declaração que diz ao navegador para usar o modo padrão. Sem ela, ele entra em *quirks mode* e passa a imitar bugs de navegadores dos anos 90 — o mais famoso deles muda o modelo de caixa inteiro, e o layout desanda sem erro nenhum aparecer.

O `lang` no `<html>` também não é enfeite: é o que faz o leitor de tela escolher a pronúncia certa e o corretor ortográfico escolher o dicionário certo.
