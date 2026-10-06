---
title: Animando algo que aparece
version: 1
---

A seção 05 disse que `display` não pode ter transição: não há valor entre `none` e `block`. Isso tornava impossível fazer surgir aos poucos algo que aparece mudando o `display`, um aviso, um dropdown, um diálogo, e é o caso que mais importa. Dois recursos recentes resolvem:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <style>
      body { margin: 16px; font-family: system-ui, sans-serif; }
      .toast {
        display: none;
        opacity: 0;
        transition: opacity 400ms linear, display 400ms allow-discrete;
      }
      .toast.open { display: block; opacity: 1; }
      @starting-style {
        .toast.open { opacity: 0; }
      }
    </style>
  </head>
  <body>
    <button type="button" onclick="document.querySelector('.toast').classList.toggle('open')">Save</button>
    <p class="toast" role="status">Saved to your list.</p>
  </body>
</html>
```

**`@starting-style`** diz quais eram os estilos de um elemento **antes de ele ser exibido**. Sem isso, um elemento que vai de `display: none` para `block` não tem estilo anterior de onde partir a transição, então aparece direto na opacidade final. Com isso, o navegador faz a transição de `opacity: 0` para 1. **`transition-behavior: allow-discrete`**, escrito aqui como `display 400ms allow-discrete` dentro do atalho, deixa o `display` participar da transição: na saída ele espera a opacidade terminar antes de virar `none`, então o esmaecimento de saída também é visto.

O botão alterna a classe `open` com uma linha de JavaScript, que o curso `javascript` explica. 200 ms depois de um clique, com e sem o bloco `@starting-style`:

```
ana@laptop:~/site$ probe starting.html click button at 200 style .toast display,opacity
p.toast.open  display: block
p.toast.open  opacity: 0.5
ana@laptop:~/site$ probe nostart.html click button at 200 style .toast display,opacity
p.toast.open  display: block
p.toast.open  opacity: 1
```

Com ele, o aviso está **na metade**, opacidade **0.5**, o meio de um esmaecimento linear de 400 ms. Sem ele, já está em **1**, 200 ms antes: apareceu de uma vez, sem transição, embora a transição estivesse declarada.

Os dois são recentes, então confira o suporte nos navegadores de quem lê antes de contar com o esmaecimento. Um navegador sem eles ainda mostra e esconde o aviso, só não esmaece, que é o jeito certo de um efeito se degradar. O elemento `<dialog>` e o atributo `popover` são animados exatamente assim.
