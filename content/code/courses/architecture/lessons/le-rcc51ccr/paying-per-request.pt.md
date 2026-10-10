---
title: Pagar por requisição
version: 1
---

Uma plataforma de funções cobra pelo que o seu código usou, em geral em duas partes: **um preço por
requisição**, e **um preço por unidade de tempo de computação**, medido como memória multiplicada pela
duração, em gigabyte-segundos. Uma função com 512 MB que roda por 200 ms usa 0,5 × 0,2 = 0,1 GB-s.

Quando esta aula foi escrita, a AWS publicava estes preços para o Lambda em x86 na região
`us-east-1`, com uma cota mensal grátis de um milhão de requisições e 400.000 GB-s por conta:

| item | preço |
| --- | --- |
| requisições | US$ 0,20 por milhão |
| computação | US$ 0,0000166667 por GB-s |

**Preços mudam, e variam por região e por provedor**; confira a página do próprio provedor antes de
usar estes números para qualquer coisa real. A conta abaixo não depende dos valores exatos.

## Um mês calculado

As cotações de entrega da Quitanda: 3 milhões de requisições por mês, cada uma rodando 200 ms com
512 MB, ignorando a cota grátis.

| | cálculo | por mês |
| --- | --- | --- |
| computação | 3.000.000 × 0,1 GB-s = 300.000 GB-s, × 0,0000166667 | US$ 5,00 |
| requisições | 3 milhões × US$ 0,20 | US$ 0,60 |
| total | | US$ 5,60 |

## Onde um servidor sempre ligado ganha

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Um gráfico de custo mensal contra requisições por mês. A linha de pagar por requisição começa em zero e sobe em linha reta. O servidor sempre ligado é uma linha reta horizontal. As duas se cruzam num volume de equilíbrio; abaixo dele pagar por requisição é mais barato, acima dele o servidor é.\"><defs><marker id=\"l3-cost-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"260\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M70 230 L690 230\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-cost-ah-wire)\"></path><path d=\"M70 230 L70 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-cost-ah-wire)\"></path><text x=\"380\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">requisições por mês</text><text x=\"76\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">custo por mês</text><path d=\"M70 230 L660 50\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70 140 L660 140\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"540\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">pagar por requisição</text><text x=\"640\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">servidor sempre ligado</text><circle cx=\"365\" cy=\"140\" r=\"5\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></circle><path d=\"M365 146 L365 228\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"365\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">equilíbrio</text><text x=\"200\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">funções mais baratas</text><text x=\"520\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">servidor mais barato</text></svg>", "caption": "Pagar por requisição é uma reta que sai do zero; um servidor é uma linha horizontal. Onde as duas se cruzam é o volume de equilíbrio que os próximos parágrafos calculam."}
```

Pagar por requisição é uma reta que começa no zero: o dobro de requisições, o dobro da conta. Um
servidor alugado por mês é uma linha horizontal: o mesmo preço com uma requisição ou com cem por
segundo, até o que ele aguenta. **As duas linhas se cruzam**, e o cruzamento é fácil de calcular.

Uma requisição custa o preço da requisição mais a computação dela: US$ 0,20 / 1.000.000 + 0,1 ×
US$ 0,0000166667 = cerca de US$ 0,00000187. Suponha que um servidor capaz de levar a mesma carga custe
US$ 30 por mês; esse valor é uma suposição para o exemplo, não uma cotação. O equilíbrio é US$ 30
dividido pelo custo de uma requisição: cerca de **16 milhões de requisições por mês**, o que dá um
pouco mais de seis requisições por segundo, em média.

Abaixo desse volume a função é mais barata, e muito mais barata quando o tráfego vem em rajadas. Acima
dele, e principalmente com tráfego constante o dia todo, o servidor é. **Carga constante é aquilo em
que um servidor sempre ligado é bom, e carga em rajadas ou rara é aquilo em que funções são boas**; a
conta só diz a mesma coisa em dinheiro.

## O que a conta deixa de fora

A comparação acima conta máquinas e não pessoas. Uma função não precisa de sistema operacional com
patch, de capacidade planejada nem de processo reiniciado às três da manhã, e esse trabalho também tem
custo. Do outro lado, cada cópia de uma função mantém a sua própria conexão com o banco, e uma plataforma que
inicia mil cópias numa rajada abre mil conexões de uma vez, o que pode esgotar o banco. **Funções
mudam o custo operacional de lugar; não o apagam.**
