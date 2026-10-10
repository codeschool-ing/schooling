---
title: SE, e escolher entre mais de duas opções
version: 1
---

**`SE` (`IF` no Excel em inglês) transforma uma comparação numa escolha: um valor quando ela é
`VERDADEIRO`, outro quando é `FALSO`.** Recebe três argumentos, sempre nesta ordem: o teste, o valor
se verdadeiro, o valor se falso. Todo o resto sobre ela é o que você põe nesses três lugares.

## Um teste, duas respostas

A Café Serra chama os clientes de atacado de *trade* e todos os outros de *retail*. Em J2 de
`Sales`:

```localised
=SE(G2="Wholesale";"Trade";"Retail")
```

J2 mostra `Trade`. Preencha para baixo e 38 linhas dizem `Trade`, as 38 vendas de atacado.

Os dois valores não precisam ser texto. Esta dá a receita de uma venda de atacado e 0 para qualquer
outra, então a soma da coluna é a receita do atacado:

```localised
=SE(G2="Wholesale";H2;0)
```

Preenchida e somada com `=SOMA(J2:J109)`, dá **38731**: R$ 38.731 dos R$ 51.494 vieram do atacado.
A aula 5 chega ao mesmo número com um `SOMASES` (`SUMIFS`) e nenhuma coluna auxiliar, e os dois
precisam bater.

Deixe de fora o terceiro argumento e o `SE` não devolve uma célula vazia. `=SE(E2>=10;"Large")`
mostra `FALSO` em toda linha com menos de dez sacos, o que quase nunca é o que alguém queria ver.
Escreva o texto vazio, `""`, como terceiro argumento quando quiser dizer nada.

## Mais de duas respostas: SE aninhado

Separe as vendas em três tamanhos: **Large** a partir de 10 sacos, **Medium** a partir de 4,
**Small** abaixo disso. O `SE` escolhe entre duas coisas, então a segunda escolha vai dentro da
primeira:

```localised
=SE(E2>=10;"Large";SE(E2>=4;"Medium";"Small"))
```

Leia como o Excel lê, da esquerda. Dez sacos ou mais: `Large`, e o resto da fórmula nem é olhado.
Senão, o `SE` de dentro roda: quatro ou mais, `Medium`; senão, `Small`. Preenchida para baixo, a
coluna tem 22 `Large`, 41 `Medium` e 45 `Small`, que somam as 108 vendas. Essa última conferência,
as partes somando o todo, vale ser feita toda vez que uma coluna separa linhas em grupos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l03-bands\" aria-label=\"Uma reta de quantidades de sacos de 1 a 20, cortada em 4 e em 10 em três faixas: Small de 1 a 3 sacos, 45 vendas; Medium de 4 a 9, 41 vendas; Large de 10 a 20, 22 vendas. Abaixo, o SE aninhado como um caminho: primeiro o teste E2&gt;=10, que leva a Large se for verdadeiro; senão o teste E2&gt;=4, que leva a Medium se for verdadeiro e a Small se for falso.\"><rect x=\"60.0\" y=\"56.0\" width=\"88.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"68.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Small</text><text x=\"105.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">45 vendas</text><rect x=\"150.0\" y=\"56.0\" width=\"178.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"158.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Medium</text><text x=\"240.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">41 vendas</text><rect x=\"330.0\" y=\"56.0\" width=\"328.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"338.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">Large</text><text x=\"495.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">22 vendas</text><path d=\"M60.0 84.0 L60.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><path d=\"M90.0 84.0 L90.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M120.0 84.0 L120.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 84.0 L150.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"150.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text><path d=\"M180.0 84.0 L180.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M210.0 84.0 L210.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M240.0 84.0 L240.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M270.0 84.0 L270.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M300.0 84.0 L300.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M330.0 84.0 L330.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10</text><path d=\"M360.0 84.0 L360.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M390.0 84.0 L390.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420.0 84.0 L420.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M450.0 84.0 L450.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M480.0 84.0 L480.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M510.0 84.0 L510.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M540.0 84.0 L540.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M570.0 84.0 L570.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M600.0 84.0 L600.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M630.0 84.0 L630.0 90.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"630.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">20</text><text x=\"664.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sacos</text><rect x=\"60.0\" y=\"150.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">E2&gt;=10</text><path d=\"M180.0 165.0 L268.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M268.0 165.0 L260.0 161.0 L260.0 169.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"224.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">verdadeiro</text><rect x=\"270.0\" y=\"150.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"320.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">\"Large\"</text><path d=\"M120.0 180.0 L120.0 218.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M120.0 218.0 L124.0 210.0 L116.0 210.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><text x=\"128.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falso</text><rect x=\"60.0\" y=\"220.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">E2&gt;=4</text><path d=\"M180.0 235.0 L268.0 235.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M268.0 235.0 L260.0 231.0 L260.0 239.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"224.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">verdadeiro</text><rect x=\"270.0\" y=\"220.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"320.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">\"Medium\"</text><path d=\"M120.0 250.0 L120.0 288.0\" stroke=\"var(--wire)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M120.0 288.0 L124.0 280.0 L116.0 280.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><text x=\"128.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falso</text><rect x=\"60.0\" y=\"290.0\" width=\"120.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120.0\" y=\"305.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">\"Small\"</text><text x=\"420.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o primeiro teste que passa decide,</text><text x=\"420.0\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">e os testes depois dele nem são lidos</text><text x=\"420.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">testado na outra ordem, E2&gt;=4 antes,</text><text x=\"420.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pega 14 sacos como Medium: 0 Large</text></svg>", "caption": "Três tamanhos a partir de dois testes. O SE aninhado pergunta primeiro pelo limite mais alto; 45, 41 e 22 vendas somam as 108."}
```

**A ordem dos testes é a lógica.** Ponha na ordem inversa:

```localised
=SE(E2>=4;"Medium";SE(E2>=10;"Large";"Small"))
```

Uma venda de 14 sacos passa no primeiro teste, `E2>=4`, e é chamada de `Medium` antes que o teste de
`Large` seja alcançado. A coluna agora tem 0 `Large` e 63 `Medium`, e toda célula parece uma
resposta perfeitamente boa. Com limites que sobem, teste o mais alto primeiro.

## SES, a mesma coisa sem aninhar

O Excel 2019 e posteriores, e o Microsoft 365, têm `SES` (`IFS`), que recebe pares de teste e valor
e devolve o valor do primeiro teste que der `VERDADEIRO`:

```localised
=SES(E2>=10;"Large";E2>=4;"Medium";VERDADEIRO;"Small")
```

O resultado é o mesmo: 22, 41 e 45. O último par merece uma palavra: `VERDADEIRO` é um teste que
sempre passa, então pega toda linha que falhou nos outros. Deixe-o de fora e uma venda de 3 sacos
não passa em teste nenhum, e o `SES` responde `#N/D`. Cópias mais antigas do Excel não têm `SES` e
respondem `#NOME?`, então uma pasta de trabalho que outras pessoas vão abrir fica mais segura com
`SE` aninhado.

Dois ou três níveis de `SE` se leem bem. Passando disso, a fórmula fica difícil de conferir e fácil
de quebrar, e uma tabelinha de limites é melhor: a aula 4 seção 06 faz esses mesmos três tamanhos
com uma busca, e aí os limites ficam em células onde qualquer pessoa vê e muda.
