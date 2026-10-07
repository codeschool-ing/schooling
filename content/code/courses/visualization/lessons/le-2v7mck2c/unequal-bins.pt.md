---
title: Intervalos desiguais e densidade
version: 1
---

Às vezes intervalos de larguras diferentes são a escolha natural: faixas de renda, grupos de idade,
as faixas de preço em que uma empresa já reporta. Eles são permitidos, com uma condição fácil de
perder.

**Num histograma o olho lê a área, não a altura.** Com intervalos iguais não faz diferença, porque a
área é a altura vezes a mesma largura. Com intervalos desiguais faz toda a diferença.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 240\" role=\"img\" data-fig=\"l05-density\" aria-label=\"Dois histogramas dos mesmos tempos de entrega com intervalos desiguais: de 10 a 20, depois quatro intervalos de 5 minutos, depois de 40 a 50 e por fim de 50 a 105. À esquerda a altura é a contagem, e o último intervalo largo, de 50 a 105, vira um bloco que cobre mais da figura que qualquer outra barra. À direita a altura é entregas por minuto, então a área de cada barra é a sua contagem, e o último intervalo vira a cauda baixa e longa que ele é de fato.\"><path d=\"M50.0 200.0 L300.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M50.0 40.0 L50.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M72.7 164.9 h22.7 v35.1 h-22.7 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M95.5 118.1 h11.4 v81.9 h-11.4 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M106.8 76.3 h11.4 v123.7 h-11.4 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M118.2 54.5 h11.4 v145.5 h-11.4 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M129.5 81.3 h11.4 v118.7 h-11.4 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M140.9 91.3 h22.7 v108.7 h-22.7 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><path d=\"M163.6 144.8 h125.0 v55.2 h-125.0 Z\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"72.7\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"118.2\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><text x=\"163.6\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"288.6\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">105</text><text x=\"175.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">altura = contagem (engana)</text><path d=\"M360.0 200.0 L610.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360.0 40.0 L360.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M382.7 182.4 h22.7 v17.6 h-22.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M405.5 118.1 h11.4 v81.9 h-11.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M416.8 76.3 h11.4 v123.7 h-11.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M428.2 54.5 h11.4 v145.5 h-11.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M439.5 81.3 h11.4 v118.7 h-11.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M450.9 145.7 h22.7 v54.3 h-22.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M473.6 195.0 h125.0 v5.0 h-125.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><text x=\"382.7\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"428.2\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><text x=\"473.6\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"598.6\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">105</text><text x=\"485.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">altura = contagem por minuto</text></svg>", "caption": "Com intervalos desiguais o olho lê a área, então a altura tem de ser a contagem dividida pela largura. Desenhado pela contagem, um intervalo largo parece uma multidão."}
```

Os dois gráficos usam os mesmos sete intervalos: de 10 a 20, depois quatro de 5 minutos, depois de 40
a 50 e de 50 a 105. À esquerda a altura de cada barra é a contagem. O último intervalo guarda só 33
entregas, mas tem 55 minutos de largura, então vira a maior forma da figura, e o leitor conclui que
entregas muito lentas são comuns.

À direita a altura é **a contagem dividida pela largura**: entregas por minuto do intervalo. Agora
**a área de cada barra é a sua contagem**, e o último intervalo encolhe para a cauda baixa e longa
que ele é de fato. Essa altura se chama **densidade**, e o eixo vertical deve dizer isso: "entregas
por minuto", e não "entregas".

## A regra

- **Intervalos iguais**: desenhe contagens. Nada a corrigir.
- **Intervalos desiguais**: desenhe a densidade, e rotule o eixo como uma taxa.
- **Nunca** desenhe intervalos desiguais pela contagem, e nunca deixe o programa fazer isso em
  silêncio. O `hist` do matplotlib desenha contagens a menos que receba `density=True`, que também
  reescala para que as áreas somem 1.

## Por que não usar só intervalos iguais?

Em geral você deve. Intervalos desiguais ganham seu lugar quando o dado é muito ralo numa região, e
intervalos iguais deixariam muitos vazios, ou quando o leitor já pensa naquelas faixas, como faixas de
imposto. Em todos os outros casos, intervalos iguais tiram o problema em vez de corrigi-lo.
