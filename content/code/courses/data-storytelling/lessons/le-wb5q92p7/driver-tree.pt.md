---
title: Uma árvore de direcionadores: onde o achado fica
version: 1
---

Uma **árvore de direcionadores** (*driver tree*) quebra o número que importa à empresa nos números que o
produzem, e esses nos deles, até chegar a coisas que alguém pode mudar. **Ela é o mapa onde um achado é
posto**, e pô-lo ali mostra que galho ele mexe e até onde o efeito sobe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l11-driver-tree\" aria-label=\"Uma árvore lida do topo. A margem bruta é caixas vendidas vezes margem por caixa. A margem por caixa é preço vezes a taxa de margem. As caixas vendidas vêm dos assinantes e de quanto tempo eles ficam. Os assinantes vêm dos novos conquistados menos os cancelamentos precoces. Os cancelamentos precoces dependem da fatia de primeiras caixas atrasadas, a folha que esta análise achou, destacada.\"><defs><marker id=\"ds-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M340.0 42.0 L200.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M340.0 42.0 L500.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M200.0 112.0 L110.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M200.0 112.0 L290.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M500.0 112.0 L430.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M500.0 112.0 L590.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 182.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 182.0 L210.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M285.0 236.0 L305.0 236.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ds-ah-amber)\"></path><rect x=\"250.0\" y=\"10.0\" width=\"180.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">margem bruta</text><rect x=\"125.0\" y=\"80.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">caixas vendidas</text><rect x=\"425.0\" y=\"80.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">margem por caixa</text><rect x=\"45.0\" y=\"150.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">assinantes</text><rect x=\"220.0\" y=\"150.0\" width=\"140.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">meses que ficam</text><rect x=\"375.0\" y=\"150.0\" width=\"110.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">preço</text><rect x=\"515.0\" y=\"150.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">taxa de margem, 31%</text><rect x=\"10.0\" y=\"220.0\" width=\"100.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conquistados</text><rect x=\"135.0\" y=\"220.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cancelamentos precoces</text><rect x=\"305.0\" y=\"220.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"380.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">1ªs caixas atrasadas</text><text x=\"462.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">o achado</text><text x=\"340.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">leia para cima: cada ligação é uma multiplicação que o financeiro já faz</text></svg>", "caption": "A primeira caixa é uma folha pequena num galho curto e íngreme: decide se o cliente fica vinte e oito meses ou menos de dois."}
```

## A árvore da Faro

No topo, a **margem bruta**. Ela é o número de caixas vendidas vezes a margem por caixa. As caixas vendidas
dependem de quantos assinantes há e de quanto tempo eles ficam. Os assinantes dependem de quantos são
conquistados e de quantos saem cedo. E a fatia que sai cedo depende, entre outras coisas, de a primeira
caixa ter chegado no prazo, que é a folha que a análise da Marina achou.

Lida da folha para cima, a árvore diz o que o achado significa para a empresa: **uma mudança na fatia de
primeiras caixas atrasadas mexe nos cancelamentos precoces, que mexem no número de assinantes, que mexe nas
caixas vendidas, que mexem na margem**. Cada ligação é uma multiplicação que alguém do financeiro já sabe
fazer.

## Para que serve a árvore

- **Traduzir.** Ela transforma "17,3% de atraso" em "R$ 790 mil de margem" seguindo as ligações, o que a
  próxima seção faz.
- **Conferir o alcance.** Um achado que mexe numa folha pequena de um galho longo mexe pouco no topo. A
  primeira caixa da Faro é uma folha pequena (uma entrega em vinte e duas) num galho curto e íngreme: ela
  decide se o cliente fica vinte e oito meses ou menos de dois.
- **Achar o dono.** Toda folha tem alguém responsável por ela. A folha da primeira entrega é da logística; a
  da aquisição, do marketing; o preço, do diretor comercial. **Um achado que cruza galhos cruza
  departamentos**, que é o que a aula 1 achou na reunião da Marina.

## Desenhando a sua

Você não precisa do modelo do financeiro para desenhar uma árvore útil. Comece pelo número que a sua
empresa reporta aos donos, pergunte "do que isso é feito?" duas ou três vezes e pare quando chegar ao seu
achado. Desenhe no `my-analysis.txt` como linhas recuadas. **Se você não consegue ligar o seu achado ao topo
em quatro ou cinco passos**, ou o achado é pequeno demais para importar à empresa ou você ainda não entendeu
como ele importa, e vale saber as duas coisas antes da reunião.
