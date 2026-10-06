---
title: Células que ocupam várias linhas e colunas
version: 1
---

Uma célula pode cobrir mais de uma linha ou coluna. **`colspan`** deixa uma célula da largura de várias colunas e **`rowspan`** a deixa da altura de várias linhas. A tabela de horários usou um: no domingo, *Closed* é uma única célula atravessando as duas colunas, *Opens* e *Closes*.

A programação de sábado usa os dois. A troca de livros ocupa a sala da frente das 10 às 11, então a célula dela ocupa duas linhas; ao meio-dia a loja inteira fecha, então essa célula ocupa as duas salas:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Saturday · Andorinha Books</title>
    <style>
      td, th { border: 1px solid; padding: 4px 8px; }
      table { border-collapse: collapse; }
    </style>
  </head>
  <body>
    <main>
      <h1>Saturday 10 October</h1>
      <table>
        <caption>What is on, room by room</caption>
        <thead>
          <tr>
            <th scope="col">Time</th>
            <th scope="col">Front room</th>
            <th scope="col">Back room</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <th scope="row">10 am</th>
            <td rowspan="2">Book swap</td>
            <td>Children's reading</td>
          </tr>
          <tr>
            <th scope="row">11 am</th>
            <td>Bookbinding class</td>
          </tr>
          <tr>
            <th scope="row">12 noon</th>
            <td colspan="2">Lunch: the shop is closed</td>
          </tr>
        </tbody>
      </table>
    </main>
  </body>
</html>
```

Medidas, as células saem assim:

```
ana@laptop:~/site$ probe spans.html box td box 'th[scope=row]'
td  x 79.3   y 125.38 width 95.95  height 54
td  x 175.25 y 125.38 width 135.67 height 27
td  x 175.25 y 152.38 width 135.67 height 27
td  x 79.3   y 179.38 width 231.63 height 27
th  x 8.5    y 125.38 width 70.8   height 27
th  x 8.5    y 152.38 width 70.8   height 27
th  x 8.5    y 179.38 width 70.8   height 27
```

*Book swap* é uma célula de **54 pixels de altura**, exatamente duas linhas de 27. *Lunch* é uma célula de **231,63 pixels de largura**, as duas colunas de sala juntas, 95,95 e 135,67, mais o pixel de borda entre elas. Desenhado a partir dessas caixas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A tabela de sábado desenhada a partir das caixas medidas. Linha de cabeçalho: Time, Front room, Back room. Cabeçalhos de linha: 10 am, 11 am, 12 noon. Book swap tem rowspan 2 e ocupa a sala da frente às 10 e às 11, uma célula de 54 pixels de altura. Lunch: the shop is closed tem colspan 2 e ocupa as duas salas ao meio-dia, uma célula de 231,63 pixels de largura.\"><rect x=\"20\" y=\"40\" width=\"99.12\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69.56\" y=\"58.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Time</text><rect x=\"119.12\" y=\"40\" width=\"134.33\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"186.28\" y=\"58.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Front room</text><rect x=\"253.45\" y=\"40\" width=\"189.94\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"348.42\" y=\"58.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Back room</text><rect x=\"20\" y=\"77.8\" width=\"99.12\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69.56\" y=\"96.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">10 am</text><rect x=\"20\" y=\"115.6\" width=\"99.12\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69.56\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">11 am</text><rect x=\"20\" y=\"153.4\" width=\"99.12\" height=\"37.8\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"69.56\" y=\"172.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12 noon</text><rect x=\"119.12\" y=\"77.8\" width=\"134.33\" height=\"75.6\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"186.28\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Book swap</text><rect x=\"253.45\" y=\"77.8\" width=\"189.94\" height=\"37.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"348.42\" y=\"96.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Children&#x27;s reading</text><rect x=\"253.45\" y=\"115.6\" width=\"189.94\" height=\"37.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"348.42\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Bookbinding class</text><rect x=\"119.12\" y=\"153.4\" width=\"324.28\" height=\"37.8\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"281.26\" y=\"172.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Lunch: the shop is closed</text><text x=\"467.39\" y=\"85.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">rowspan=&quot;2&quot;</text><text x=\"467.39\" y=\"103.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma célula, duas linhas de altura:</text><text x=\"467.39\" y=\"119.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">54 pixels</text><text x=\"467.39\" y=\"157.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">colspan=&quot;2&quot;</text><text x=\"467.39\" y=\"175.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma célula, duas colunas de largura:</text><text x=\"467.39\" y=\"191.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">231,63 pixels</text></svg>", "caption": "Uma célula expandida ocupa o lugar das células que cobre, e as linhas abaixo dela são escritas sem elas.", "same": ["54 pixels"]}
```

## A regra em que as pessoas tropeçam

**Uma linha é escrita sem as células que um span vindo de cima já cobre.** A linha das 11 tem um cabeçalho e uma célula, *Bookbinding class*, porque a sala da frente às 11 ainda está ocupada pelo *Book swap*. Escreva uma segunda célula ali e a linha fica com uma célula a mais: o navegador a empurra para uma quarta coluna sem cabeçalho, e a tabela ganha uma borda irregular. Conte cada linha como as células que você escreve mais as células que descem até ela vindas de cima, e toda linha deve dar o mesmo número.

**Spans deixam tabelas mais difíceis de ler para todo mundo.** Um leitor de tela lida com um span simples como estes, e uma tabela com spans dentro de spans fica difícil de acompanhar de ouvido e de olho. Se uma tabela precisa de muitos, muitas vezes ela é duas tabelas.
