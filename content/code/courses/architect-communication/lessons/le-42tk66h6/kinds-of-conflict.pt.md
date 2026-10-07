---
title: Que tipo de conflito é este
version: 1
---

**Uma discordância técnica costuma ser três conflitos emaranhados: sobre o trabalho, sobre como a
decisão é tomada e sobre as pessoas.** Mediar começa por separá-los, porque cada um se resolve de um
jeito, e aquele de que se fala raramente é o que está causando o estrago.

Em 1º de maio, a RFC das conexões da aula 2 entrou em vigor: cada serviço ganhou uma cota fixa de
conexões ao banco de pedidos. Três semanas depois, Bruna, tech lead do checkout, escreveu no canal
da plataforma que a cota de 40 da logística era "absurda" e devia cair para 20. Paulo, engenheiro
sênior da logística, respondeu em menos de um minuto que o checkout "quebra tudo às sextas e depois
culpa todo mundo". Na hora do almoço a thread tinha sessenta mensagens, e os dois tech leads tinham
escrito para Lívia em particular.

## Três conflitos numa thread

A psicóloga organizacional Karen Jehn, estudando equipes de trabalho nos anos 1990, separou três
tipos de conflito, e a distinção continua sendo o primeiro passo mais útil:

| tipo | sobre | na thread |
|---|---|---|
| **tarefa** | qual é a resposta certa | 40 conexões são demais para a logística? |
| **processo** | como a decisão é tomada, e quem a toma | quem decide as cotas, e elas podem mudar depois de uma RFC? |
| **relacionamento** | as pessoas | "o checkout quebra tudo e culpa todo mundo" |

As primeiras pesquisas sugeriam que o conflito de tarefa era saudável, sinal de gente que se importa
com o trabalho, enquanto o conflito de relacionamento fazia mal. Trabalhos posteriores, entre eles
uma revisão muito citada de Carsten De Dreu e Laurie Weingart, de 2003, encontraram um quadro menos
confortável: o conflito de tarefa também tende a prejudicar o desempenho do time, principalmente
quando começa a parecer pessoal, o que na prática quase sempre acontece. **A leitura prática é que
uma discordância de tarefa precisa ser resolvida rápido e pelo mérito, antes de virar as outras
duas.**

## Como as pessoas reagem a um conflito

Kenneth Thomas e Ralph Kilmann descreveram cinco formas de reagir a um conflito, dispostas em dois
eixos: o quanto a pessoa busca os próprios interesses e o quanto busca os do outro lado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Cinco modos de lidar com conflito em dois eixos: buscar os próprios interesses, na vertical, e buscar os do outro lado, na horizontal. Alto nos próprios e baixo nos do outro: competir, eu ganho, você perde. Alto nos dois: colaborar, achar o que serve aos dois. No meio: ceder em parte, dividir a diferença. Baixo nos dois: evitar, deixar para depois. Baixo nos próprios e alto nos do outro: acomodar, deixar com o outro.\"><defs><marker id=\"tkmodes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M120 270 L680 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#tkmodes-ah)\"></path><path d=\"M120 270 L120 20\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#tkmodes-ah)\"></path><text x=\"400.0\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">buscar os interesses do outro lado →</text><text x=\"14\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">buscar os</text><text x=\"14\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">próprios</text><text x=\"14\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">interesses ↑</text><rect x=\"140\" y=\"30\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">competir</text><text x=\"230\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">eu ganho, você perde</text><rect x=\"480\" y=\"30\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">colaborar</text><text x=\"570\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">achar o que serve aos dois</text><rect x=\"310.0\" y=\"115\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">ceder em parte</text><text x=\"400.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dividir a diferença</text><rect x=\"140\" y=\"200\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">evitar</text><text x=\"230\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deixar para depois</text><rect x=\"480\" y=\"200\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">acomodar</text><text x=\"570\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">deixar com o outro</text></svg>", "caption": "Os cinco modos de Thomas e Kilmann. Cada um serve em algum lugar; o problema é o hábito de um só. Bruna e Paulo estavam os dois no canto de cima à esquerda."}
```

Nenhuma das cinco é errada em si. Evitar é o certo para uma discordância que não importa; acomodar
é o certo quando o outro lado se importa muito mais do que você. **O problema é usar um modo só para
tudo**, e em times de engenharia os dois hábitos mais comuns são competir (discutir até o outro lado
desistir) e evitar (deixar a thread morrer e fazer do seu jeito). Bruna e Paulo estavam os dois
competindo. A thread terminaria com quem tivesse mais fôlego, e a cota seria decidida por isso.

## O primeiro movimento de quem media

Lívia não respondeu no canal. Pediu aos dois tech leads, Bruna e Henrique, trinta minutos juntos na
manhã seguinte e escreveu uma linha na thread: "Vou levar isto para uma call com os dois leads
amanhã às 10:00; publico o resultado aqui." **Uma thread pública é o pior lugar para resolver um
conflito**: todo mundo está atuando para a plateia, e ninguém consegue mudar de posição sem perder a
pose na frente dela.

::: track tech-lead
A aula 22 de `people-leadership`, mais cedo na sua trilha, trata do conflito como um gestor o
encontra: entre pessoas que você lidera, e com produto. Esta aula é a versão do arquiteto: uma
discordância sobre uma decisão técnica, entre times que nenhum dos lados gerencia.
:::

::: track *
As mesmas habilidades valem para conflitos dentro de um time que você lidera; esta aula trata do
caso do arquiteto, uma discordância sobre uma decisão técnica entre times que nenhum dos lados
gerencia.
:::
