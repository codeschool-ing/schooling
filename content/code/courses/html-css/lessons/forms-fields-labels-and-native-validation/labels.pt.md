---
title: Campo sem rótulo é campo quebrado
---

Todo campo precisa de um `<label>` ligado a ele. A ligação é pelo `for` que aponta para o `id`:

```html
<label for="email">E-mail</label>
<input type="email" id="email" name="email" required />
```

A ligação faz três coisas de uma vez: o leitor de tela anuncia o rótulo quando o campo recebe foco, clicar no texto foca o campo, e a área de toque no celular cresce — o que importa mais do que parece em caixas de seleção.

`placeholder` **não** substitui rótulo. Ele some quando a pessoa começa a digitar, e aí ninguém mais sabe o que aquele campo era. É complemento, não substituto.
