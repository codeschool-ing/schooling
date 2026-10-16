---
title: Um número responde uma pergunta, ou é enfeite
version: 1
---

**Uma métrica vale ser coletada quando responde uma pergunta que alguém precisa responder para tomar uma decisão.**
Todo o resto num painel é enfeite, e enfeite não é inofensivo: toma tempo para coletar, atenção para ler, e tende a
virar a coisa pela qual as pessoas são julgadas.

## Da meta à pergunta ao número

Victor Basili e colegas descreveram uma disciplina simples para isso nos anos 1980, a abordagem **Meta, Pergunta,
Métrica** (*Goal, Question, Metric*): comece por uma meta, faça as perguntas que diriam se você está chegando lá, e só
então escolha os números que respondem essas perguntas. A ordem é o ponto. A maioria das métricas ruins vem de fazer
o caminho ao contrário: começar por um número fácil de coletar e inventar um motivo para ele depois.

O Cine Aurora fez o caminho para a frente no próprio teste:

| meta | pergunta | métrica |
|---|---|---|
| os clientes pagam o preço certo | quantos defeitos de preço chegam aos clientes? | defeitos achados depois da entrega, por área |
| o teste acha os defeitos que importam antes da entrega | de todos os defeitos que conhecemos, quantos achamos primeiro? | percentual de detecção |
| um defeito que chega a um cliente não fica muito tempo | quão rápido um defeito de preço é corrigido depois de conhecido? | dias do relato à correção |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" data-fig=\"l22-gqm\" aria-label=\"Meta, pergunta, métrica, como três colunas lidas da esquerda para a direita. Meta: preços certos para os clientes; pergunta: quantos defeitos de preço chegam aos clientes; métrica: defeitos que escaparam, por área. Meta: defeitos achados antes da entrega; pergunta: quantos achamos primeiro; métrica: percentual de detecção. Meta: defeitos que escapam não demoram; pergunta: quão rápido um defeito de preço é corrigido; métrica: dias do relato à correção. Abaixo das métricas: que decisão mudaria se este número mudasse?\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">meta</text><text x=\"345.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">pergunta</text><text x=\"585.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">métrica</text><rect x=\"10.0\" y=\"32.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">preços certos para os clientes</text><path d=\"M211.0 52.0 L229.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"32.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quantos defeitos de preço chegam aos clientes?</text><path d=\"M461.0 52.0 L479.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"480.0\" y=\"32.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">defeitos que escaparam, por área</text><rect x=\"10.0\" y=\"84.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">defeitos achados antes da entrega</text><path d=\"M211.0 104.0 L229.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"84.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quantos achamos primeiro?</text><path d=\"M461.0 104.0 L479.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"480.0\" y=\"84.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">percentual de detecção</text><rect x=\"10.0\" y=\"136.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">defeitos que escapam não demoram</text><path d=\"M211.0 156.0 L229.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"136.0\" width=\"230.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quão rápido um defeito de preço é corrigido?</text><path d=\"M461.0 156.0 L479.0 156.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"480.0\" y=\"136.0\" width=\"210.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">dias do relato à correção</text><text x=\"690.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">que decisão mudaria se este número mudasse?</text></svg>", "caption": "Feito para a frente, da meta ao número. A maioria das métricas ruins vem de fazê-lo ao contrário."}
```

Cada número tem uma pergunta acima dele e uma meta acima dela. Quando alguém propõe um número novo, a primeira
pergunta no Cine Aurora é a que esta aula repete: **que decisão mudaria se este número mudasse?**

## Números que soam úteis e não são

Algumas métricas de teste são populares em todo lugar e respondem quase nada:

- **casos de teste escritos** ou **casos de teste executados**: cem casos triviais e um cuidadoso contam como cento e
  um; o número recompensa escrever muitos testes pequenos, não achar defeitos;
- **defeitos achados por pessoa**: recompensa dividir um defeito em cinco relatos e pune quem passou um dia no único
  defeito sutil que importava;
- **porcentagem de testes automatizados**: automatizados *para quê*? Uma suíte pode estar noventa por cento
  automatizada e não conferir nada que um cliente perceberia;
- **taxa de aprovação**: a aula 21 mostrou o que uma porcentagem de testes que passam esconde.

Nenhuma delas é sempre inútil. Cada uma fica inútil, ou pior, quando é relatada sem uma pergunta, e cada uma fica
nociva quando alguém é recompensado por ela, que é a próxima seção.

## Medidas que olham para fora

Os números da tabela do Cine Aurora têm algo em comum: olham para o que chega ao cliente, não para quão ocupado o time
estava. Atividade é fácil de contar e diz pouco sobre qualidade. Quem rodou quatrocentos testes no mês passado contou
como o mês foi gasto. Um time cujo percentual de detecção foi de 60% para 80% contou algo sobre a experiência dos
clientes.
