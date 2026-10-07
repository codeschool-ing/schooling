---
title: O Preflight, e as camadas onde ele mora
version: 1
---

A folha começa com `@layer theme, base, components, utilities;`, a ordem de camadas da seção 11 da aula 10. **`theme`** guarda as propriedades personalizadas. **`base`** guarda o **Preflight**, o reset do Tailwind. **`components`** fica vazia até você acrescentar algo, seção 10. **`utilities`** guarda as classes, por último, então um utilitário vence qualquer coisa das camadas anteriores seja qual for a especificidade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"As quatro camadas de cascata de uma folha do Tailwind, a mais fraca embaixo: theme, com os tokens; base, com o Preflight; components, com as suas classes como .btn; e utilities, com as classes utilitárias. Um botão com btn e bg-stone-700 recebe o fundo stone, porque utilities vem depois de components.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais forte</text><rect x=\"20\" y=\"26\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer utilities</text><text x=\"190\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as classes: p-4, bg-stone-700, md:grid-cols-2</text><rect x=\"20\" y=\"70\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer components</text><text x=\"190\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as suas, como .btn com @apply</text><rect x=\"20\" y=\"114\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer base</text><text x=\"190\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o Preflight, o reset, e as suas regras de elemento</text><rect x=\"20\" y=\"158\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer theme</text><text x=\"190\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">os tokens, como propriedades personalizadas em :root</text><text x=\"20\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais fraca</text><text x=\"480\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">class=&quot;btn bg-stone-700&quot;:</text><text x=\"480\" y=\"59\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o fundo é stone, porque</text><text x=\"480\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">utilities vem depois</text><text x=\"480\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de components.</text><text x=\"480\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A camada decide antes</text><text x=\"480\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">de a especificidade ser</text><text x=\"480\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">comparada, aula 10, seção 11.</text></svg>", "caption": "A saída do Tailwind é a folha em camadas da aula 10, gerada.", "same": ["class=&quot;btn bg-stone-700&quot;:"]}
```

O Preflight vai além do reset da aula 10. Aqui está uma página sem classe nenhuma, com build do Tailwind:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="out.css">
  </head>
  <body>
    <main>
      <h1>This week</h1>
      <ul>
        <li><a href="events.html">Events</a></li>
        <li><a href="order.html">Order a book</a></li>
      </ul>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd bare -i input.css -o out.css --silent
ana@laptop:~/site$ probe bare/index.html style h1 font-size,font-weight style ul list-style-type,padding-left style a color,text-decoration-line
h1  font-size: 16px
h1  font-weight: 400
ul  list-style-type: none
ul  padding-left: 0px
a  color: rgb(0, 0, 0)
a  text-decoration-line: none
a  color: rgb(0, 0, 0)
a  text-decoration-line: none
```

O `<h1>` tem **16px** e peso **400**: o mesmo tamanho e peso do texto corrido. A lista não tem marcadores nem recuo. Os links são **pretos como o texto em volta, sem sublinhado**. O Preflight tira todo padrão que o navegador tinha, para que o que você vê seja só o que as suas classes dizem.

**Dois desses padrões estavam fazendo um trabalho.** O tamanho do título dizia a quem enxerga que era um título; devolva um tamanho a ele, `text-2xl`, e mantenha-o um `<h1>`, porque o papel dele, aula 2, continua sendo o que um leitor de tela anuncia. E **um link que parece texto não pode ser encontrado** sem passar o mouse sobre cada palavra. O critério de sucesso 1.4.1 das WCAG pede que a cor não seja o único jeito de distinguir um link num parágrafo do texto em volta, e o Preflight tirou até a cor. Devolva o sublinhado aos links dentro de texto, com `underline` ou com uma regra na sua folha de entrada:

```css
@layer base {
  main a { text-decoration-line: underline; }
}
```

Pô-la em `base` a mantém abaixo dos utilitários, então `no-underline` num link específico ainda funciona.
