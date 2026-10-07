---
title: A mesma cor quer dizer a mesma coisa
version: 1
---

Quando um leitor aprende que laranja é o Nordeste, ele para de ler a legenda. Esse é o objetivo de uma
legenda, e quer dizer que **uma cor tem de manter o significado em todo gráfico que o leitor vê
junto**: um relatório, um painel, uma apresentação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 300\" role=\"img\" data-fig=\"l13-consistency\" aria-label=\"Dois pares de pequenos gráficos de barras de três regiões, 2024 à esquerda de cada par e 2025 à direita. No par de cima as cores mudam entre os dois gráficos: o Sudeste é azul no primeiro e laranja no segundo. No par de baixo cada região mantém uma cor nos dois gráficos.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cores trocadas</text><path d=\"M40.0 130.0 L240.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M54.0 53.9 h40.0 v76.1 h-40.0 Z\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1.2\"></path><path d=\"M120.7 99.0 h40.0 v31.0 h-40.0 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><path d=\"M187.3 98.2 h40.0 v31.8 h-40.0 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><text x=\"140.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><path d=\"M270.0 130.0 L470.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M284.0 42.7 h40.0 v87.3 h-40.0 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><path d=\"M350.7 85.1 h40.0 v44.9 h-40.0 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><path d=\"M417.3 90.7 h40.0 v39.3 h-40.0 Z\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1.2\"></path><text x=\"370.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><text x=\"20.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cores mantidas</text><path d=\"M40.0 270.0 L240.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M54.0 193.9 h40.0 v76.1 h-40.0 Z\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1.2\"></path><path d=\"M120.7 239.0 h40.0 v31.0 h-40.0 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><path d=\"M187.3 238.2 h40.0 v31.8 h-40.0 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><text x=\"140.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><path d=\"M270.0 270.0 L470.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M284.0 182.7 h40.0 v87.3 h-40.0 Z\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1.2\"></path><path d=\"M350.7 225.1 h40.0 v44.9 h-40.0 Z\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1.2\"></path><path d=\"M417.3 230.7 h40.0 v39.3 h-40.0 Z\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1.2\"></path><text x=\"370.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><rect x=\"500.0\" y=\"120.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"#0072B2\" stroke=\"#0072B2\" stroke-width=\"1\"></rect><text x=\"518.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Sudeste</text><rect x=\"500.0\" y=\"142.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"#E69F00\" stroke=\"#E69F00\" stroke-width=\"1\"></rect><text x=\"518.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Nordeste</text><rect x=\"500.0\" y=\"164.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"#009E73\" stroke=\"#009E73\" stroke-width=\"1\"></rect><text x=\"518.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Sul</text></svg>", "caption": "O leitor aprende uma cor no primeiro gráfico e lê o segundo com ela. Troque as cores e o segundo gráfico é lido errado, com confiança."}
```

No par de cima o programa atribuiu as cores em cada gráfico pela ordem das séries, então quando a
ordem mudou entre 2024 e 2025, as cores se mexeram. Um leitor que aprendeu "azul é o Sudeste" no
primeiro gráfico lê a barra azul do segundo como Sudeste, e ela é o Sul. **Nada na página avisa.** No
par de baixo cada região mantém a cor, e o segundo gráfico se lê num relance.

## Como manter as cores fixas

- **Ligue as cores a nomes, não a posições.** No código, mantenha um dicionário de categoria para cor e
  consulte cada uma, em vez de depender da ordem em que a biblioteca distribui as cores.
- **Anote o mapeamento** para a equipe: "Sudeste `#0072B2`, Nordeste `#E69F00`…", nas notas de estilo do
  projeto, para o próximo gráfico que alguém fizer usá-lo.
- **Em planilhas e ferramentas de BI**, defina à mão as cores das séries, e confira de novo quando um
  filtro tirar uma categoria, porque algumas ferramentas redistribuem as cores para preencher o vão.

## Consistência de significado, também

O mesmo vale para o que uma cor sinaliza. Se o vermelho marca uma queda na página um, não pode marcar o
maior valor na página três. **Uma cor usada para ênfase é usada para ênfase em todo lugar**, e o cinza
que quer dizer "contexto" quer dizer contexto em todo gráfico.
