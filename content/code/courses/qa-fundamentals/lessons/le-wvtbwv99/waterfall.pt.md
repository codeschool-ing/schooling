---
title: A cascata, e o que o autor dela disse de fato
version: 1
---

**O modelo cascata é a sequência que a maioria das pessoas imagina quando pensa em construir software
direito:** levantar todos os requisitos, depois projetar o sistema inteiro, depois escrever todo o código,
depois testá-lo, depois entregá-lo. Cada fase termina antes de a próxima começar, e cada uma produz
documentos com que a seguinte trabalha. O trabalho desce, um degrau por vez, e é daí que vem o nome.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 270\" role=\"img\" data-fig=\"l09-waterfall\" aria-label=\"Cinco fases desenhadas como degraus descendo para a direita: requisitos, projeto, implementação, teste, operação. Cada fase entrega um documento à seguinte: especificação, documento de projeto, código, relatório de teste. Uma seta tracejada volta do teste aos requisitos, com o rótulo voltar custa mais quanto mais abaixo você está.\"><defs><marker id=\"qa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"79.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requisitos</text><path d=\"M138.0 37.0 L152.0 37.0 L152.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"158.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">especificação</text><rect x=\"142.0\" y=\"64.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"201.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">projeto</text><path d=\"M260.0 81.0 L274.0 81.0 L274.0 107.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"280.0\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">documento de projeto</text><rect x=\"264.0\" y=\"108.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"323.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">implementação</text><path d=\"M382.0 125.0 L396.0 125.0 L396.0 151.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"402.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">código</text><rect x=\"386.0\" y=\"152.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">teste</text><path d=\"M504.0 169.0 L518.0 169.0 L518.0 195.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"524.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">relatório de teste</text><rect x=\"508.0\" y=\"196.0\" width=\"118.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"567.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">operação</text><path d=\"M400 187 C 330 245, 110 240, 79 56\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#qa-ah-amber)\"></path><text x=\"250.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">voltar custa mais quanto mais abaixo você está</text></svg>", "caption": "A cascata como costuma ser desenhada. O teste é o quarto degrau, o primeiro momento em que o sistema encontra algo além dos próprios documentos."}
```

## Onde o teste fica

Na cascata, o teste é uma fase, e vem tarde: depois de toda linha ter sido escrita. Tudo o que as aulas 3 e
5 descreveram decorre dessa posição. Defeitos achados no teste foram cometidos meses antes, num requisito ou
num projeto sobre o qual o sistema inteiro foi construído depois. Quem testa recebe um produto pronto de uma
vez, sob um prazo que costuma já ter escorregado quando o código chega, e a fase de teste vira a que é
espremida.

## O que Royce escreveu

O modelo costuma ser atribuído a **Winston Royce**, cujo artigo de 1970, *Managing the Development of Large
Software Systems*, traz o famoso diagrama de fases descendo. O que se repete menos é a frase logo abaixo
dele, em que Royce chama essa abordagem de **arriscada e um convite ao fracasso**, justamente porque o teste
vem no fim e é o primeiro momento em que algo é conferido contra a realidade. O resto do artigo propõe
correções: voltar a fases anteriores, construir uma versão piloto primeiro, envolver o cliente o tempo todo.

Então o modelo que leva o nome dele é, em boa parte, aquele contra o qual ele alertou. Espalhou-se mesmo
assim, porque uma sequência de fases com um documento no fim de cada uma é fácil de planejar, fácil de pôr
num contrato e fácil de relatar.

## Por que ainda vale conhecê-lo

Chamar a cascata de obsoleta é comum e só meio certo. Ela ainda cabe em alguns lugares, e você vai
trabalhar neles:

- **domínios regulados**, como equipamentos médicos, aviação e bancos, em que um auditor precisa de
  evidência de que cada requisito foi projetado, construído e testado, em ordem, com registros;
- **contratos de preço fechado**, em que o cliente paga por um resultado especificado e a especificação
  precisa ser acordada antes de o trabalho começar;
- **hardware junto com software**, em que a parte física não pode mudar a cada duas semanas e o software
  precisa estar pronto numa data fixa.

E mesmo times que nunca a usam herdam o vocabulário dela: requisitos, projeto, implementação, teste,
entrega. As próximas aulas tratam sobretudo de rearranjar essas mesmas atividades, não de inventar novas.

## O que quem testa faz dentro de uma

Dentro de um projeto em cascata, o melhor movimento de quem testa é o da aula 1: envolver-se **antes** da
fase de teste. Ler os requisitos enquanto são escritos e fazer as quatro perguntas da aula 2. Escrever
planos e casos de teste enquanto o projeto é escrito, a partir do requisito, para que o teste possa começar
no dia em que o código chegar. Essa é a ideia que o modelo V transforma num desenho, na próxima seção.
