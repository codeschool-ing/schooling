---
title: Visões e pontos de vista: nenhum desenho mostra tudo
version: 1
---

**Uma arquitetura não cabe num diagrama só, porque pessoas diferentes fazem perguntas diferentes a
ela, e cada pergunta precisa do seu próprio desenho.** O vocabulário para isso vem da norma que
descreve descrições de arquitetura, a ISO/IEC/IEEE 42010, e vale conhecê-lo porque os frameworks
das aulas 8 a 10 usam todos esse vocabulário.

## Quatro palavras

- Um **stakeholder**, ou parte interessada, é qualquer pessoa com interesse no sistema: Celeste,
  Otávio, um passageiro, o engenheiro de plantão às três da manhã, o auditor conferindo como os CPFs
  são guardados.
- Uma **preocupação** (*concern*) é algo com que um stakeholder se importa: *um ônibus consegue
  embarcar quando a rede cai?*, *quanto tempo leva o checkout no pico?*, *quem pode ler o número do
  documento de um passageiro?*
- Um **ponto de vista** (*viewpoint*) é uma receita para um tipo de desenho: que preocupações ele
  trata, para quais stakeholders, e com qual notação. *Um ponto de vista de implantação, para
  operações, em diagramas de implantação UML* é um.
- Uma **visão** (*view*) é uma aplicação de um ponto de vista a um sistema: *a visão de implantação
  da Carcará*, desenhada neste mês.

**O ponto de vista é reutilizável e a visão não.** Uma empresa que escreve seus pontos de vista uma
vez recebe desenhos coerentes de todos os times, que é a mesma ideia da página *Como desenhamos* da
seção anterior, um nível acima.

## O 4+1 de Kruchten

O conjunto de pontos de vista mais conhecido para software é o **modelo de visões 4+1** de Philippe
Kruchten, de 1995. Ele nomeia quatro visões e uma quinta que amarra as outras:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l01-four-plus-one\" aria-label=\"O modelo 4+1 de Kruchten. Quatro visões nos cantos: lógica, para quem projeta; de desenvolvimento, para quem programa; de processo, para desempenho e confiabilidade; física, para operações. No meio, os cenários, os casos de uso que ligam as quatro e servem para conferir que elas concordam.\"><rect x=\"45.0\" y=\"27.0\" width=\"210.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"45.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Visão lógica</text><text x=\"150.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">abstrações e relações</text><text x=\"150.0\" y=\"74.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para quem projeta</text><rect x=\"465.0\" y=\"27.0\" width=\"210.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"45.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Visão de desenvolvimento</text><text x=\"570.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">módulos e donos</text><text x=\"570.0\" y=\"74.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para quem programa</text><rect x=\"45.0\" y=\"187.0\" width=\"210.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"205.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Visão de processo</text><text x=\"150.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que roda ao mesmo tempo</text><text x=\"150.0\" y=\"234.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para desempenho</text><rect x=\"465.0\" y=\"187.0\" width=\"210.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"205.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Visão física</text><text x=\"570.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">máquinas e redes</text><text x=\"570.0\" y=\"234.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para operações</text><ellipse cx=\"360.0\" cy=\"140.0\" rx=\"110\" ry=\"44\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></ellipse><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Cenários (+1)</text><text x=\"360.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">casos de uso percorridos</text><text x=\"360.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pelas quatro</text><path d=\"M255.0 80.0 L300.0 112.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M465.0 80.0 L420.0 112.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M255.0 200.0 L300.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M465.0 200.0 L420.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "As quatro visões respondem a quatro perguntas diferentes. Os cenários são a conferência: um caso de uso percorrido por todas as visões encontra os pontos em que elas discordam."}
```

| visão | a pergunta que responde | quem pergunta | diagrama típico |
| --- | --- | --- | --- |
| **lógica** | quais são as principais abstrações, e como se relacionam? | analistas, projetistas | diagrama de classes, aula 2 |
| **de desenvolvimento** | como o código se organiza em módulos, e quem é dono de cada um? | desenvolvedores, líderes de time | diagrama de componentes ou de pacotes, aula 2 |
| **de processo** | o que roda ao mesmo tempo, e como as partes em execução se comunicam? | engenheiros de desempenho e confiabilidade | diagramas de sequência e de atividade, aulas 2 e 4 |
| **física** | o que roda em qual máquina, e como as máquinas se ligam? | operações, plataforma | diagrama de implantação, aula 2 |
| **cenários** (o +1) | as quatro visões juntas dão conta do que os usuários fazem de fato? | todo mundo | casos de uso, aula 2 |

O +1 é a parte importante. **Os cenários são o jeito de conferir que as quatro visões concordam entre
si**: percorra um caso de uso, como *um passageiro compra uma passagem*, pela visão lógica, depois
pela de processo, depois pela física, e cada lugar em que o percurso emperra é uma lacuna numa visão.

## O que isso muda na segunda-feira

Você não vai desenhar as cinco visões para todo sistema, e Kruchten não sugeriu isso. O que o modelo
dá é **um jeito de perceber que um diagrama está tentando ser duas visões ao mesmo tempo**: um
desenho de caixas com servidores, classes e uma linha do tempo é a visão lógica, a física e a de
processo brigando por uma página. Separe, e cada desenho fica mais claro.

**Desenhe você também.** Para um sistema que você conhece, escreva o stakeholder que mais
precisaria de cada uma das quatro visões, e a pergunta que ele faria. Se você não consegue nomear um
stakeholder para uma visão, ela provavelmente ainda não precisa ser desenhada.
