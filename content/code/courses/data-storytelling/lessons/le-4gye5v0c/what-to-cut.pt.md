---
title: O que tirar, e o que um painel não é
version: 1
---

Um painel cresce por adição. Cada pedido é razoável, cada bloco é barato, e depois de um ano ele tem
catorze. **Tirar coisas é a parte do design de painel que ninguém pede**, então precisa ser regra.

## Mostradores

O mostrador, um disco com ponteiro, é o elemento de painel mais reconhecível e um dos menos úteis. Ele gasta
um círculo grande de espaço com um número só, a escala curva é difícil de ler com precisão, e quase sempre
não traz comparação além de um arco verde e vermelho. Stephen Few desenhou o **gráfico de bala** (*bullet
graph*) para substituí-lo: uma única barra horizontal para o valor, uma linha curta atravessada para a meta e
faixas cinza ao fundo para os intervalos que contam como ruim, regular e bom. **Ele carrega mais que um
mostrador numa fração do espaço**, e se alinha bem com outros gráficos de bala para comparar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 200\" role=\"img\" data-fig=\"l07-bullet\" aria-label=\"O mesmo número duas vezes. À esquerda, um mostrador: um semicírculo com ponteiro em 84,1% e arcos coloridos, ocupando um quadrado grande. À direita, um gráfico de bala: uma barra fina até 84,1%, um traço vertical na meta de 95% e três faixas cinza ao fundo para ruim, regular e bom, numa única linha.\"><text x=\"130.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mostrador</text><text x=\"450.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gráfico de bala</text><rect x=\"10.0\" y=\"26.0\" width=\"240.0\" height=\"164.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M40.0 150.0 A90 90 0 0 1 157.8 64.4\" stroke=\"var(--amber)\" stroke-width=\"10\" fill=\"none\"></path><path d=\"M157.8 64.4 A90 90 0 0 1 210.2 109.1\" stroke=\"var(--paper-dim)\" stroke-width=\"10\" fill=\"none\"></path><path d=\"M210.2 109.1 A90 90 0 0 1 220.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"10\" fill=\"none\"></path><path d=\"M130.0 150.0 L191.4 116.5\" stroke=\"var(--paper)\" stroke-width=\"2.4\" fill=\"none\"></path><circle cx=\"130.0\" cy=\"150.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"130.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">84,1%</text><rect x=\"270.0\" y=\"26.0\" width=\"400.0\" height=\"164.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M300.0 84.0 L470.0 84.0 L470.0 118.0 L300.0 118.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--panel)\"></path><path d=\"M470.0 84.0 L549.3 84.0 L549.3 118.0 L470.0 118.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--scan)\"></path><path d=\"M549.3 84.0 L640.0 84.0 L640.0 118.0 L549.3 118.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--wire)\"></path><path d=\"M300.0 94.0 L459.8 94.0 L459.8 108.0 L300.0 108.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><path d=\"M583.3 80.0 L583.3 122.0\" stroke=\"var(--paper)\" stroke-width=\"2.4\" fill=\"none\"></path><text x=\"583.3\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">meta 95%</text><text x=\"459.8\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">84,1%</text><text x=\"300.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">70%</text><text x=\"413.3\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">80%</text><text x=\"526.7\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">90%</text><text x=\"640.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"300.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1ªs entregas no prazo</text><text x=\"300.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">faixas cinza: ruim, regular, bom</text></svg>", "caption": "O gráfico de bala carrega o valor, a meta e as faixas numa linha, e se alinha com o próximo. O mostrador gasta um quadrado num número só."}
```

## O resto da lista

- **Gráficos em três dimensões** distorcem os valores que mostram e não acrescentam nada.
- **Mapas** só valem o espaço quando a localização é a pergunta. O mapa da Faro colorido por pedidos
  mostrava onde mora a população de São Paulo.
- **Tabelas de registros brutos** na primeira tela são detalhes sem demanda; ponha atrás de um clique.
- **Mais de uns sete elementos** numa tela tornam impossível a leitura de trinta segundos. O número é uma
  regra prática, e o motivo por trás dele é real: cada elemento é um lugar que o olho precisa visitar.
- **Um bloco que ninguém abriu em três meses**, coisa que a maioria das ferramentas de painel conta para
  você, é um bloco de que ninguém sentiria falta.

## Um painel vigia; ele não argumenta

Quando a taxa de primeira entrega cai, o painel mostra, e é aí que o trabalho dele termina. **Ele não
consegue contar a história do porquê, e não deve tentar**: explicações, causas e recomendações são o
trabalho das aulas 2 a 5, numa apresentação ou num sumário de uma página.

O erro comum é o contrário: responder ao pedido de uma apresentação com o link de um painel. Um painel
entrega dados ao leitor e deixa a análise com ele, que é a falha da primeira reunião da Marina num formato
mais caro. **Use o painel para perceber, e a história para decidir.**
