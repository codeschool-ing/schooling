---
title: Uma classe que o build não enxerga
version: 1
---

O build acha os nomes de classe **lendo os arquivos como texto**. Ele não roda JavaScript. Então um nome de classe montado juntando strings não existe para o build:

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
    <p id="status" class="text-red-700">Sold out</p>
    <script>
      const colour = "green";
      document.querySelector("#status").className = "text-" + colour + "-700";
    </script>
  </body>
</html>
```

O script troca a classe do parágrafo para `text-green-700`, montada a partir de `"text-"`, uma variável e `"-700"`:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd dynamic -i input.css -o out.css --silent
ana@laptop:~/site$ grep -c "text-red-700" dynamic/out.css
1
ana@laptop:~/site$ grep -c "text-green-700" dynamic/out.css
0
ana@laptop:~/site$ probe dynamic/index.html style "#status" color
p#status  color: rgb(0, 0, 0)
```

`text-red-700`, escrita inteira no HTML, tem regra: **1**. `text-green-700` não tem nenhuma: **0**. No navegador o script fez o trabalho dele, a classe está no elemento, e a cor é **preta**, porque nenhuma folha de estilos diz nada sobre essa classe. Nada relatou erro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"O build do Tailwind como desenho. À esquerda, um arquivo HTML com atributos class: mt-4 p-4, text-2xl font-bold, border-emerald-700, e um script que monta uma classe a partir de text-, uma variável e -700. O scanner lê o arquivo como texto. À direita, out.css tem uma regra para cada classe escrita inteira, e nenhuma para a montada.\"><defs><marker id=\"ah13\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"220\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">index.html</text><text x=\"32\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">class=&quot;mt-4 p-4&quot;</text><text x=\"32\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">class=&quot;text-2xl font-bold&quot;</text><text x=\"32\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">class=&quot;border-emerald-700&quot;</text><text x=\"32\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&quot;text-&quot; + colour + &quot;-700&quot;</text><line x1=\"250\" y1=\"95\" x2=\"300\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13)\"></line><rect x=\"310\" y=\"66\" width=\"120\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">scanner</text><text x=\"370\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lê texto</text><line x1=\"440\" y1=\"95\" x2=\"490\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13)\"></line><rect x=\"500\" y=\"20\" width=\"200\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">out.css</text><text x=\"512\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.mt-4 { … }</text><text x=\"512\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.p-4 { … }</text><text x=\"512\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.text-2xl { … }</text><text x=\"512\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.font-bold { … }</text><text x=\"512\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">.border-emerald-700 { … }</text><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">O scanner procura qualquer coisa com forma de nome de classe e escreve uma regra para cada uma que conhece.</text><text x=\"20\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Um nome montado por um script nunca é escrito inteiro, então não há regra para ele.</text></svg>", "caption": "O build lê os seus arquivos; não os executa.", "same": ["scanner"]}
```

**Escreva os nomes de classe inteiros**, todos, em algum lugar que o build lê. Em vez de montar um, escolha entre nomes completos:

```js
const colours = { available: "text-green-700", soldOut: "text-red-700" };
```

É um bug comum de Tailwind, e é invisível até alguém ver a cor errada. Quando uma classe está no elemento no painel Elements e não faz nada, confira se a folha tem regra para ela.
