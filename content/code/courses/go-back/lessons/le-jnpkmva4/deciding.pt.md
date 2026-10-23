---
title: Decidindo, em quatro perguntas
version: 1
---

As seções anteriores deram a evidência. Esta a transforma nas perguntas a fazer, na ordem em que
resolvem as coisas, para um serviço HTTP novo em Go. **Faça-as nesta ordem, porque cada uma,
respondida com sim, torna irrelevantes as que vêm depois.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Quatro perguntas descendo pela esquerda, feitas em ordem. Um sim na primeira leva a: use o framework da equipe. Um sim na segunda: considere o Fiber. Um sim na terceira: Echo ou Gin. Um sim na quarta: acrescente um roteador como o chi. Quatro nãos levam ao fim: a biblioteca padrão mais bibliotecas pequenas.\"><defs><marker id=\"gb-l5-decide-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"300\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. a equipe já tem um?</text><path d=\"M 315 35 L 408 35\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"410\" y=\"15\" width=\"270\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">use o framework da equipe</text><path d=\"M 165 55 L 165 71\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><rect x=\"15\" y=\"73\" width=\"300\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. HTTP medido como gargalo?</text><path d=\"M 315 93 L 408 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"410\" y=\"73\" width=\"270\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">considere o Fiber</text><path d=\"M 165 113 L 165 129\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><rect x=\"15\" y=\"131\" width=\"300\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. muita gente, muitas rotas, um jeito só?</text><path d=\"M 315 151 L 408 151\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"410\" y=\"131\" width=\"270\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Echo ou Gin</text><path d=\"M 165 171 L 165 187\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><rect x=\"15\" y=\"189\" width=\"300\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4. um recurso de rota que o ServeMux não tem?</text><path d=\"M 315 209 L 408 209\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"410\" y=\"189\" width=\"270\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">acrescente um roteador como o chi</text><path d=\"M 165 229 L 165 245\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"178\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"15\" y=\"248\" width=\"665\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"347\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quatro nãos: a biblioteca padrão, mais bibliotecas pequenas no formato padrão</text></svg>", "caption": "As quatro perguntas desta seção. O primeiro sim encerra a busca."}
```

**1. A equipe já tem um framework?** Se os serviços ao lado dos quais você vai trabalhar usam um,
use-o. A seção 06 terminou com este motivo, e ele passa por cima de tudo o que vem abaixo: uma base
de código num estilo só ganha de uma base de código com escolhas melhores em cinco estilos.

**2. Uma medição mostrou que é na camada HTTP que o tempo vai?** Não um benchmark de "hello world",
mas um profile deste serviço sob a carga real dele. Se sim, o Fiber, ou o `fasthttp` por baixo de
alguma coisa, é candidato, e os custos dele da seção 05 da aula 4 valem ser pagos. Para um serviço
que espera um banco de dados, a resposta quase nunca é sim.

**3. Muita gente vai escrever muitas rotas que precisam ter todas a mesma cara?** Uma API grande, uma
equipe grande, um contrato público com documentação gerada. Se sim, o jeito único de um framework
vale as dependências, e o Echo ou o Gin, os dois `net/http` por baixo, deixam a saída aberta.

**4. Falta ao `ServeMux` um recurso de roteamento de que você precisa?** Expressões regulares num
caminho, grupos de rotas com os próprios middlewares. Se sim, acrescente um roteador que mantém seus
handlers padrão, como o `chi`.

**Se as quatro são não, use a biblioteca padrão**, e acrescente bibliotecas pequenas no formato
padrão para as lacunas que a seção 02 listou, uma de cada vez, quando cada uma for necessária. É o
que o boxoffice faz, e é o padrão que este curso recomenda.

## Como saber que você escolheu errado

Toda escolha dessas pode se revelar errada, e os sinais são específicos. **A biblioteca padrão foi a
escolha errada** se as mesmas vinte linhas de decodificação e tratamento de erro estão sendo coladas
em cada handler e se afastando umas das outras; esse é o momento de escrever o helper, ou de adotar o
framework que o tem. **Um framework foi a escolha errada** se metade do tempo da equipe com ele vai em
achar e sobrescrever os padrões dele, ou se uma atualização de versão maior fica adiada por um ano
porque mexe em cada handler. Nos dois casos o conserto é mais barato cedo, e por isso vale conhecer os
sinais antes de escrever a primeira linha.

## Por que esta aula valeu uma aula

A aula 4 podia ter terminado com "escolha um". Não terminou porque **a escolha de framework é uma das
poucas decisões num serviço Go que custa caro desfazer**: ela está na assinatura de cada handler. As
aulas 6 a 17 constroem o boxoffice sobre a biblioteca padrão, e a cada passo em que um framework
teria ajudado, a aula diz. Na aula 17 você terá visto por inteiro o que o padrão custa, e poderá
fazer a escolha oposta de olhos abertos.
