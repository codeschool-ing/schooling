---
title: Roxo: os dois na mesma sala
version: 1
---

O arranjo clássico mantém vermelho e azul separados. O time vermelho trabalha semanas, escreve um
relatório, e o time azul o lê depois: "no terceiro dia chegamos ao banco e ninguém percebeu". A essa
altura os logs do terceiro dia muitas vezes já foram descartados, as pessoas que poderiam ter percebido
não lembram o que viram, e a lição chega tarde demais para ser testada.

O **time roxo** (*purple teaming*) põe as duas cores na mesma sala, ou na mesma chamada, e muda o ritmo.
O lado vermelho executa uma técnica. O lado azul pergunta na hora se ela foi vista: em qual log, por
qual regra e em quanto tempo. Se não foi, os dois descobrem por quê, mudam algo e executam a técnica de
novo. O ciclo se repete até a técnica ser detectada, ou até todos concordarem por que não dá.

```schooling-figure
{"svg": "<svg id=\"sf-purple-loop\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O ciclo roxo. O vermelho executa uma técnica. O azul pergunta se ela foi vista: em qual log, por qual regra, com que rapidez. Se não foi vista, os dois mudam algo: um log, uma regra, uma configuração. Então o vermelho executa a mesma técnica de novo. O ciclo termina com uma detecção que provou funcionar.\"><defs><marker id=\"sf-purple-loop-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sf-purple-loop-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sf-purple-loop-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">vermelho executa uma técnica</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">azul: foi visto?</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">uma detecção que funciona</text><rect x=\"270\" y=\"140\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mudar um log, uma regra</text><path d=\"M200 55 L270 55\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-purple-loop-ah-wire)\"></path><path d=\"M450 55 L520 55\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#sf-purple-loop-ah-phosphor)\"></path><text x=\"485\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sim</text><path d=\"M360 80 L360 140\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#sf-purple-loop-ah-amber)\"></path><text x=\"370\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não</text><path d=\"M270 165 L110 165 L110 80\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-purple-loop-ah-wire)\"></path><text x=\"190\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">executar de novo</text></svg>", "caption": "Uma técnica de cada vez, até a defesa provar que a enxerga."}
```

O resultado não é uma lista de furos, e sim uma **detecção que provou funcionar**, que é um produto
diferente e mais durável. Uma regra de firewall testada por quem a escreveu diz o que essa pessoa
pensou; uma detecção testada por alguém tentando ativamente passar por ela diz o que um atacante
encontraria.

### O que roxo não é

Roxo é um jeito de trabalhar, não um terceiro time. A maioria das organizações que "têm um time roxo"
tem gente de vermelho e de azul que combinou cooperar, às vezes com um facilitador no meio. Esse papel
de facilitador às vezes se chama **time branco**: os árbitros que escrevem as regras, mantêm o
exercício dentro delas e decidem o que conta.

### Por que importa numa escala pequena

Uma loja de nove pessoas não tem time vermelho nem SOC. Ela ainda tem a ideia do roxo, e é a prática de
segurança mais barata deste curso: **sempre que acrescentar um controle, tente passar por ele, e veja o
que os seus logs registraram quando você tentou.** A ana faz exatamente isso na próxima seção, com seis
senhas erradas e o log do portal.
