---
title: O que é o IAF
version: 1
---

**O IAF, o Integrated Architecture Framework, é o framework da Capgemini para arquitetura corporativa
e de soluções, desenvolvido a partir dos anos 1990 e usado desde então no trabalho de consultoria
dela.** É menos famoso que o TOGAF e aparece em menos vagas de emprego, mas está nos documentos de
qualquer empresa por onde os arquitetos da Capgemini passaram, e a ideia central dele é uma das mais
claras da área.

## Uma grade, não um ciclo

Onde o centro do TOGAF é um processo, o ciclo do ADM da aula 8, o centro do IAF é uma **grade**:

- **quatro níveis de abstração**, que são quatro perguntas feitas em ordem: *por quê?*, *o quê?*,
  *como?* e *com o quê?*;
- **quatro áreas de aspecto**, as partes da empresa que estão sendo descritas: negócio, informação,
  sistemas de informação e infraestrutura de tecnologia;
- duas preocupações **transversais**, que valem para todas as células: **segurança** e
  **governança**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l09-grid\" aria-label=\"A grade do IAF. Quatro linhas são os níveis de abstração, perguntados em ordem: contextual, por quê; conceitual, o quê; lógico, como; físico, com o quê. Quatro colunas são as áreas de aspecto: negócio, informação, sistemas de informação e tecnologia. A coluna de sistemas de informação aparece em destaque, a coluna que a aula percorre. Duas faixas verticais à direita, segurança e governança, atravessam todas as linhas.\"><text x=\"207.5\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Negócio</text><text x=\"322.5\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Informação</text><text x=\"437.5\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Sistemas de informação</text><text x=\"552.5\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Tecnologia</text><rect x=\"20.0\" y=\"54.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Contextual</text><text x=\"80.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">por quê?</text><rect x=\"154.0\" y=\"54.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"269.0\" y=\"54.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"384.0\" y=\"54.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"499.0\" y=\"54.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"20.0\" y=\"106.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Conceitual</text><text x=\"80.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">o quê?</text><rect x=\"154.0\" y=\"106.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"269.0\" y=\"106.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"384.0\" y=\"106.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"499.0\" y=\"106.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"20.0\" y=\"158.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Lógico</text><text x=\"80.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">como?</text><rect x=\"154.0\" y=\"158.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"269.0\" y=\"158.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"384.0\" y=\"158.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"499.0\" y=\"158.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"20.0\" y=\"210.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Físico</text><text x=\"80.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">com o quê?</text><rect x=\"154.0\" y=\"210.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"269.0\" y=\"210.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"384.0\" y=\"210.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"499.0\" y=\"210.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"614.0\" y=\"54.0\" width=\"50.0\" height=\"200.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"668.0\" y=\"54.0\" width=\"50.0\" height=\"200.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"639\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\" transform=\"rotate(-90 639 154)\">segurança</text><text x=\"693\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\" transform=\"rotate(-90 693 154)\">governança</text></svg>", "caption": "Cada célula se justifica pela de cima. Uma escolha de produto na última linha sem nada acima dela na coluna aparece flutuando.", "same": ["Contextual"]}
```

Todo trabalho de arquitetura tem um lugar na grade. *Por que estamos mudando o embarque?* é o nível
contextual da área de negócio. *Quais aplicações vão validar passagens, e como elas interagem?* é o
nível lógico de sistemas de informação. Pôr uma pergunta na sua célula diz do que ela depende (as
células acima) e o que depende dela (as de baixo).

## A ideia que faz valer a pena conhecê-lo

A regra central do IAF é que **os níveis são respondidos em ordem, e cada um se justifica pelo nível
acima dele**. Uma escolha de produto no nível físico precisa remeter a um desenho lógico, que precisa
remeter a um requisito conceitual, que precisa remeter a um motivo contextual. É a rastreabilidade da
aula 6, embutida no formato do framework.

A regra pega a falha mais comum do trabalho de arquitetura, que é **começar pelo *com o quê?***:
escolher um produto, um serviço de nuvem ou um fornecedor e depois escrever os motivos de trás para a
frente. Na grade do IAF, uma decisão sem nada acima dela na coluna aparece flutuando.

## O que ele não tem

O IAF não tem um padrão publicado comparável ao do TOGAF: o material detalhado sempre foi da própria
Capgemini, ensinado nos treinamentos dela e em *Integrated Architecture Framework Explained*, o livro
que os autores publicaram em 2010. Por isso não há um mercado público de certificação e a comunidade
é menor. É também por isso que vale aprendê-lo como um **jeito de pensar**, mais do que como um corpo
de regras. As duas próximas seções tratam de cada um dos seus dois eixos.
