---
title: É outra coisa? Conferindo a região
version: 1
---

A objeção que o Paulo levantou na primeira reunião da Marina era boa: **isso inclui o interior?** Por trás
dela há uma explicação alternativa real, com duas metades, as duas verdadeiras:

- **O interior recebe mais primeiras caixas atrasadas**: 23,6% dos assinantes novos dele, contra 13,3% na
  capital.
- **O interior cancela mais de qualquer jeito**: 20,0% dos clientes do interior cuja primeira caixa chegou no
  prazo cancelaram em noventa dias, contra 16,0% na capital.

Então alguns clientes atrasados poderiam cancelar mais simplesmente por morarem no interior. Se essa fosse
a história inteira, a distância entre clientes atrasados e no prazo sumiria ao compará-los **dentro de
cada região**, onde todo mundo compartilha as mesmas distâncias e os mesmos hábitos.

## A conferência

Divida a tabela por região e calcule a taxa de cancelamento de cada combinação. Na planilha, é a fórmula
da aula 1 com mais uma condição:

```localised
=SOMASES(E2:E25;B2:B25;"capital";C2:C25;"late")/SOMASES(D2:D25;B2:B25;"capital";C2:C25;"late")
```

Troque `"capital"` por `"interior"`, e `"late"` por `"on time"`, para as outras três. O LibreOffice Calc dá:

| região | 1ª caixa atrasada | 1ª caixa no prazo | distância |
|---|---|---|---|
| capital | 38,8% | 16,0% | 22,8 pontos |
| interior | 43,9% | 20,0% | 23,9 pontos |
| as duas juntas | 41,5% | 17,4% | 24,1 pontos |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l10-strata\" aria-label=\"Três pares de barras: cancelamento em 90 dias para primeira entrega atrasada e no prazo. Capital: 38,8% contra 16,0%, distância de 22,8 pontos. Interior: 43,9% contra 20,0%, distância de 23,9 pontos. As duas juntas: 41,5% contra 17,4%, distância de 24,1 pontos. A distância sobrevive dentro de cada região.\"><path d=\"M60.0 40.0 L60.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M60.0 184.0 L640.0 184.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10%</text><path d=\"M60.0 148.0 L640.0 148.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"148.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20%</text><path d=\"M60.0 112.0 L640.0 112.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"112.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30%</text><path d=\"M60.0 76.0 L640.0 76.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"76.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">40%</text><path d=\"M60.0 40.0 L640.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><path d=\"M98.7 80.5 L152.8 80.5 L152.8 220.0 L98.7 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"125.7\" y=\"71.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">38,8%</text><path d=\"M160.5 162.5 L214.7 162.5 L214.7 220.0 L160.5 220.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><text x=\"187.6\" y=\"153.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">16,0%</text><text x=\"156.7\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">capital</text><text x=\"156.7\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">distância 22,8 pontos</text><path d=\"M292.0 61.9 L346.1 61.9 L346.1 220.0 L292.0 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"319.1\" y=\"52.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">43,9%</text><path d=\"M353.9 147.8 L408.0 147.8 L408.0 220.0 L353.9 220.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><text x=\"380.9\" y=\"138.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">20,0%</text><text x=\"350.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">interior</text><text x=\"350.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">distância 23,9 pontos</text><path d=\"M485.3 70.6 L539.5 70.6 L539.5 220.0 L485.3 220.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"512.4\" y=\"61.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">41,5%</text><path d=\"M547.2 157.3 L601.3 157.3 L601.3 220.0 L547.2 220.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--panel)\"></path><text x=\"574.3\" y=\"148.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">17,4%</text><text x=\"543.3\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as duas juntas</text><text x=\"543.3\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">distância 24,1 pontos</text><path d=\"M60.0 220.0 L640.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M446.7 40.0 L446.7 228.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"60.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cancelaram em 90 dias</text><text x=\"640.0\" y=\"20.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">1ª caixa atrasada</text></svg>", "caption": "Os clientes atrasados cancelam mais que o dobro dentro de cada região. A região explica um pouco da distância conjunta, e nada do resto.", "same": ["capital", "interior"]}
```

## O que ela mostra

**A distância sobrevive dentro de cada região.** Na capital, clientes atrasados cancelam 2,4 vezes mais que
os do prazo; no interior, 2,2 vezes. A distância conjunta, de 24,1 pontos, é um pouco maior que qualquer
uma das regionais, e essa diferença é exatamente a parte em que a objeção acertou: o cancelamento maior do
interior e a fatia maior de caixas atrasadas lá inflam um pouco o número conjunto. **A maior parte da
distância não é região.**

Comparar dentro de grupos assim se chama **estratificar**, e o curso `statistics` explica isso na aula 18,
sobre variáveis de confusão. O ponto aqui é mais estreito: a Marina agora pode responder à pergunta do Paulo com
um slide, numa frase, *a distância se mantém nas duas regiões*, e essa frase está em toda versão da
apresentação dela e no achado do sumário de uma página.

## O que ela não mostra

A região era a alternativa óbvia e está descartada. Outras não estão: clientes atrasados podem diferir de
jeitos que a tabela não registra, como morar em ruas recém-abertas que a conferência de endereço tem
dificuldade em achar, ou ter escolhido a opção de entrega mais barata. **Uma conferência estratificada tira
uma explicação de cada vez**, e dizer quais ela ainda não tirou faz parte de responder com honestidade. A
aula 12 volta às que sobram, e o piloto da aula 9 foi desenhado para testar a causa diretamente.
