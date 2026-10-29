---
title: Regenerando uma página de cada vez
version: 1
---

**A regeneração incremental mantém cada página como arquivo, e dá a cada arquivo uma idade depois da
qual ele pode ser substituído.** Uma requisição para uma página mais nova que essa idade recebe o
arquivo. Uma requisição para uma página mais velha também recebe o arquivo, na hora, e o servidor
renderiza um novo em segundo plano; a próxima requisição recebe o novo. Nenhuma requisição espera
uma renderização, a não ser que a página esteja tão velha que servi-la seja pior que esperar.

O nome desse padrão é mais antigo que qualquer um dos frameworks. É **stale-while-revalidate**: uma
cópia que passou do frescor ainda pode ser servida enquanto uma fresca é buscada. O HTTP tem um
cabeçalho para isso, que é assunto da aula 9, e os frameworks aplicam a mesma regra ao seu próprio
estoque de páginas renderizadas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo de uma página sob regeneração incremental com idade de dez segundos. O build faz a cópia 1. As requisições nos primeiros dez segundos recebem a cópia 1. Os dados mudam. A primeira requisição depois de dez segundos ainda recebe a cópia 1 e inicia uma renderização em segundo plano, que produz a cópia 2. A requisição seguinte recebe a cópia 2.\"><line x1=\"60\" y1=\"150\" x2=\"690\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,150.0 682.6,153.1 682.6,146.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"690\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"60\" y=\"120\" width=\"330\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"225\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cópia 1, fresca por 10 s</text><rect x=\"390\" y=\"120\" width=\"120\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cópia 1, velha</text><rect x=\"510\" y=\"120\" width=\"180\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cópia 2, fresca</text><line x1=\"260\" y1=\"40\" x2=\"260\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"260\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">os dados mudam</text><line x1=\"120\" y1=\"196\" x2=\"120\" y2=\"152\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><polygon points=\"120.0,152.0 123.1,159.4 116.9,159.4\" fill=\"var(--paper)\"></polygon><line x1=\"320\" y1=\"196\" x2=\"320\" y2=\"152\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><polygon points=\"320.0,152.0 323.1,159.4 316.9,159.4\" fill=\"var(--paper)\"></polygon><line x1=\"420\" y1=\"196\" x2=\"420\" y2=\"152\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"420.0,152.0 423.1,159.4 416.9,159.4\" fill=\"var(--amber)\"></polygon><line x1=\"620\" y1=\"196\" x2=\"620\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"620.0,152.0 623.1,159.4 616.9,159.4\" fill=\"var(--phosphor)\"></polygon><text x=\"120\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">requisição: cópia 1</text><text x=\"305\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">requisição: cópia 1</text><text x=\"435\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">requisição: cópia 1, inicia render</text><text x=\"620\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">requisição: cópia 2</text><path d=\"M 430 118 C 460 80, 490 80, 510 118\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></path><text x=\"470\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">render em segundo plano</text></svg>", "caption": "Ninguém espera uma renderização, e a requisição que inicia uma é a última a ver a página velha."}
```

## Os dois números

Toda implementação pede as mesmas duas durações, com nomes diferentes:

| | o que decide | `cacheLife` do Next.js | `routeRules` do Nuxt |
|---|---|---|---|
| **fresca por** | por quanto tempo uma cópia é servida sem pensar em substituí-la | `revalidate` | `swr: <segundos>`, ou `isr: <segundos>` |
| **utilizável por** | por quanto tempo uma cópia velha ainda pode ser servida enquanto uma nova é feita | `expire` | sem limite no `swr`; definido pela hospedagem no `isr` |

**O primeiro número é quanto uma página pode estar errada, medido em tempo.** Um catálogo que pode
atrasar uma hora define uma hora, e ninguém precisa se lembrar de refazer o build. O segundo número é
o limite a partir do qual a correção vence a velocidade: depois dele, a próxima requisição espera uma
renderização nova em vez de receber algo muito velho.

## O que ela não dá

**A primeira requisição depois da idade ainda recebe a página velha.** Quem pede logo depois de os
dados mudarem, e logo depois de a cópia envelhecer, vê o conteúdo antigo; a regeneração que aquela
requisição iniciou é para a pessoa seguinte. Se os dados mudaram há um minuto e a idade é uma hora, a
página pode ficar até uma hora errada. Esse é o acordo, e a seção "Sob demanda: quando os dados dizem"
é a saída dele.

**Cada página se regenera sozinha.** Um curso renomeado nos dados mostra o nome novo na página do
curso quando essa página se regenera, e na página inicial quando *essa* se regenera. Por um tempo,
duas páginas do mesmo site discordam. Páginas que precisam concordar têm de ser regeneradas juntas,
o que a idade sozinha não consegue fazer.

**E uma página só se regenera onde a sua cópia mora.** O Next.js e o Nuxt guardam as cópias no
servidor que as renderizou, na memória ou no disco dele. Dois servidores atrás de um balanceador de
carga guardam dois conjuntos de cópias, que envelhecem em momentos diferentes; uma hospedagem feita
para esses frameworks guarda um estoque compartilhado no lugar, e isso é parte do que uma hospedagem
assim vende.
