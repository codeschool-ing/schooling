---
title: O problema do arco-íris
version: 1
---

Por décadas o colormap padrão da maioria dos programas científicos foi um **arco-íris**: do azul escuro,
passando por ciano, verde e amarelo, ao vermelho. A versão do matplotlib se chama `jet`, e foi o padrão
até 2017. Ele parece vivo e engana de três jeitos de uma vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 270\" role=\"img\" data-fig=\"l12-rainbow\" aria-label=\"Duas escalas de cor, cada uma com a luminosidade percebida desenhada embaixo. O arco-íris, o jet do matplotlib, vai do azul escuro ao ciano vivo, verde, amarelo, vermelho e vermelho escuro; a luminosidade dele sobe até um pico no meio, em 0,92, e cai de novo, então os menores e os maiores valores parecem os dois escuros. O viridis vai do roxo escuro ao amarelo vivo, e a luminosidade dele sobe constante de 0,29 a 0,92.\"><text x=\"40.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">jet (um arco-íris)</text><rect x=\"40.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#000080\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"78.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#0028ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"116.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#00d4ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"154.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#7dff7a\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#ffe600\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"230.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#ff4700\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"268.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#800000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M40.0 230.0 L302.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40.0 96.0 L40.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M58.7 218.3 L96.1 184.8 L133.6 127.8 L171.0 112.8 L208.4 109.4 L245.9 152.9 L283.3 199.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"58.7\" cy=\"218.3\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"96.1\" cy=\"184.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"133.6\" cy=\"127.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"171.0\" cy=\"112.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"208.4\" cy=\"109.4\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"245.9\" cy=\"152.9\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"283.3\" cy=\"199.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"340.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">viridis</text><rect x=\"340.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#440154\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"378.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#443983\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"416.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#31688e\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"454.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#21918c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"492.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#35b779\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"530.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#90d743\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"568.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#fde725\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M340.0 230.0 L602.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M340.0 96.0 L340.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M358.7 214.9 L396.1 196.5 L433.6 179.8 L471.0 163.0 L508.4 147.9 L545.9 129.5 L583.3 109.4\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"358.7\" cy=\"214.9\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"396.1\" cy=\"196.5\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"433.6\" cy=\"179.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"471.0\" cy=\"163.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"508.4\" cy=\"147.9\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"545.9\" cy=\"129.5\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"583.3\" cy=\"109.4\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"40.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">luminosidade percebida</text></svg>", "caption": "Um arco-íris é mais claro no meio, então valores perto do meio parecem importantes e as duas pontas parecem iguais. O viridis clareia a cada passo, então mais claro quer dizer mais, sempre.", "same": ["viridis"]}
```

```
ana@vm:~/viz$ .venv/bin/python palettes.py viridis cividis jet RdBu
viridis  #440154 #443983 #31688e #21918c #35b779 #90d743 #fde725
            0.29    0.40    0.50    0.60    0.69    0.80    0.92
cividis  #00224e #2a3f6d #575d6d #7d7c78 #a59c74 #d2c060 #fee838
            0.26    0.38    0.48    0.59    0.69    0.80    0.92
jet      #000080 #0028ff #00d4ff #7dff7a #ffe600 #ff4700 #800000
            0.27    0.47    0.81    0.90    0.92    0.66    0.38
RdBu     #67001f #c94741 #f7b799 #f6f7f7 #a7d0e4 #3783bb #053061
            0.33    0.58    0.83    0.97    0.83    0.59    0.31
```

A segunda linha embaixo de cada nome é a luminosidade OKLab de cada uma das sete amostras, do menor
valor ao maior. Leia a do jet:

1. **A luminosidade dele sobe e depois desce**: 0,27 na ponta de baixo, um pico de 0,92 no meio, 0,38
   na ponta de cima. As cores mais claras ficam em valores medianos, então **o meio do dado chama o
   olho**, e os menores e os maiores valores parecem os dois escuros.
2. **As fronteiras de matiz inventam bordas.** O olho vê "a região amarela" e "a região ciano" como
   faixas separadas com bordas nítidas, embora os valores mudem suavemente entre elas. Um mapa de
   tempos de entrega em arco-íris mostraria contornos que não estão no dado.
3. **Ele falha no daltonismo.** O meio dele depende de distinguir o verde do amarelo e do vermelho, as
   distinções que mais se perdem.

A linha do viridis sobe constante de 0,29 a 0,92, e a do cividis quase igual. O RdBu, um mapa
divergente, tem pico de 0,97 no meio de propósito, que é para isso que serve uma paleta divergente:
**o meio dela foi feito para ser o ponto mais claro.** No jet, a mesma forma é um acidente.

## A versão da planilha

As planilhas oferecem primeiro uma escala de **vermelho, amarelo e verde** na formatação condicional.
É um arco-íris curto com os mesmos problemas, e ele acrescenta um julgamento: verde se lê como bom e
vermelho como ruim, o que é errado para a maioria das quantidades. Use uma escala de duas cores, do
branco a uma cor, para quantidades, e uma de três cores com o meio branco, posto no valor que
significa algo, para diferenças.
