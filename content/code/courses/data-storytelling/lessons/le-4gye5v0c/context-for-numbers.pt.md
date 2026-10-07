---
title: Um número precisa de algo com que comparar
version: 1
---

"84,1%" num bloco diz quase nada ao leitor. É bom? Melhor que na semana passada? Perto da meta? **Um número
num painel só é legível contra alguma coisa**, e o bloco tem de carregar essa coisa, ou o leitor tem de
lembrar dela, o que em trinta segundos ele não vai fazer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 190\" role=\"img\" data-fig=\"l07-kpi-context\" aria-label=\"O mesmo número em três blocos. O primeiro mostra só 84,1%. O segundo acrescenta a meta, 95%, e diz que está abaixo. O terceiro acrescenta a semana anterior, igual, e uma sparkline de 26 semanas que fica entre 80% e 85%, bem abaixo da linha tracejada da meta.\"><text x=\"113.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um número</text><rect x=\"10.0\" y=\"26.0\" width=\"206.0\" height=\"152.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1ªs entregas no prazo</text><text x=\"24.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"26\" font-weight=\"600\" fill=\"var(--paper)\">84,1%</text><text x=\"339.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">contra uma meta</text><rect x=\"236.0\" y=\"26.0\" width=\"206.0\" height=\"152.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1ªs entregas no prazo</text><text x=\"250.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"26\" font-weight=\"600\" fill=\"var(--amber)\">84,1%</text><text x=\"250.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">abaixo da meta de 95%</text><text x=\"565.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">meta, semana anterior e tendência</text><rect x=\"462.0\" y=\"26.0\" width=\"206.0\" height=\"152.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"476.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1ªs entregas no prazo</text><text x=\"476.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"26\" font-weight=\"600\" fill=\"var(--amber)\">84,1%</text><text x=\"476.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">abaixo da meta de 95%</text><text x=\"476.0\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">igual à semana anterior</text><path d=\"M476.0 142.9 L652.0 142.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M476.0 158.4 L483.0 161.4 L490.1 160.5 L497.1 161.2 L504.2 162.1 L511.2 157.7 L518.2 160.2 L525.3 159.5 L532.3 159.0 L539.4 164.0 L546.4 164.5 L553.4 160.3 L560.5 159.7 L567.5 164.2 L574.6 163.3 L581.6 163.7 L588.6 160.3 L595.7 160.9 L602.7 158.7 L609.8 160.8 L616.8 159.3 L623.8 160.9 L630.9 160.3 L637.9 161.7 L645.0 159.0 L652.0 159.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><circle cx=\"652.0\" cy=\"159.0\" r=\"2.6\" fill=\"var(--amber)\"></circle></svg>", "caption": "Só o terceiro bloco responde “estamos bem?”, “está mudando?” e “esta semana é típica?” numa olhada."}
```

## Três comparações que um bloco pode carregar

- **Uma meta.** "84,1%, meta 95%" responde "estamos bem?" na hora: não, e por quanto. A meta da Faro para
  as primeiras entregas é o nível que as renovações já atingem, uma escolha defensável porque diz *trate o
  cliente novo tão bem quanto o antigo*.
- **O período anterior.** "Igual à semana anterior" diz se está se mexendo, e aqui não está. Escolha o
  período em que o leitor pensa; o Paulo revisa por semana, então a comparação é semanal.
- **A tendência.** Uma linha pequena dos últimos seis meses ao lado do número mostra numa olhada se esta
  semana é típica. Edward Tufte chamou esses gráficos do tamanho de uma palavra de **sparklines**: uma linha
  da altura de uma linha de texto, sem eixos, que carrega uma forma em vez de valores.

A taxa semanal de primeira entrega nos seis meses ficou entre 80,4% e 85,0%. Uma sparkline torna isso
visível na hora: **a taxa não está piorando; ela está mais ou menos ruim assim o ano todo**, o que é uma
mensagem diferente de uma queda súbita e pede uma resposta diferente.

## Cor pela comparação, não pelo valor

Painéis pintam números de verde ou vermelho. A questão é o que decide a cor. Uma regra como "verde acima de
90%" é um julgamento escrito uma vez e esquecido. **A cor deve vir da comparação que importa ao leitor**:
abaixo da meta é uma cor, na meta ou acima é neutro. O mostrador antigo da Faro estava verde em 94,5%
porque alguém um dia decidiu que 90% era bom; contra uma meta de 95% para as primeiras entregas, a cor
honesta de 84,1% é a de alerta.

E como na aula 5, nunca dependa só da cor: uma pequena seta ou a palavra *abaixo* ao lado do número mantém o
bloco legível para quem não vê a diferença entre as cores.
