---
title: Calor, poeira, e o que a ventoinha está te dizendo
version: 1
---

Calor é o problema de hardware mais comum do mundo e quase ninguém o reconhece, porque o que ele
produz é *a máquina ficou lenta* — que todo mundo arquiva como software.

## O que um processador faz quando está quente demais

Ele se desacelera. De propósito, por projeto, para se proteger: o clock cai, o trabalho leva mais
tempo, e nada em lugar nenhum diz isso. Isso é **throttling térmico**, e uma máquina fazendo isso
pode estar rodando a um terço da velocidade sem mensagem e sem erro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 312\" role=\"img\" aria-label=\"Um gráfico de barras da velocidade de uma máquina em cinco momentos. Aos zero e aos cinco minutos ela roda a cem por cento, a quarenta e um e cinquenta e oito graus. Aos dez minutos está a oitenta e cinco por cento e setenta e quatro graus. Aos vinte minutos, cinquenta e cinco por cento e oitenta e oito graus. Aos quarenta minutos, trinta e cinco por cento e noventa e cinco graus.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">A mesma máquina, a cada dez minutos</text><text x=\"24\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dentro de cada barra está a velocidade em porcentagem; acima dela, a temperatura em graus</text><path d=\"M70 220 L690 220\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><rect x=\"80\" y=\"70\" width=\"70\" height=\"150\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.22\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"115.0\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">100</text><text x=\"115.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">41</text><text x=\"115.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"200\" y=\"70\" width=\"70\" height=\"150\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.22\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"235.0\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">100</text><text x=\"235.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">58</text><text x=\"235.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><rect x=\"320\" y=\"92\" width=\"70\" height=\"128\" rx=\"4\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"355.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">85</text><text x=\"355.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">74</text><text x=\"355.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><rect x=\"440\" y=\"138\" width=\"70\" height=\"82\" rx=\"4\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"475.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">55</text><text x=\"475.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">88</text><text x=\"475.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><rect x=\"560\" y=\"168\" width=\"70\" height=\"52\" rx=\"4\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"595.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">35</text><text x=\"595.0\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">95</text><text x=\"595.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><text x=\"24\" y=\"236\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minutos</text><text x=\"80\" y=\"264\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">velocidade cheia</text><text x=\"320\" y=\"264\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">se desacelerando para sobreviver</text><text x=\"24\" y=\"294\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nada na tela diz que isso está acontecendo. O único sintoma é que tudo demora mais.</text></svg>", "caption": "Aos quarenta minutos, esta máquina faz um terço do trabalho que fazia no começo, e não relatou absolutamente nada."}
```

Se esquentar mais ainda, ela desliga. Não um desligamento com aviso — uma perda instantânea de
energia, como se alguém tivesse puxado o fio, porque essa é a última proteção que existe.

## A assinatura

**Bem quando fria, lenta depois de vinte minutos.** Essa frase é a que vale decorar. Uma máquina
que é rápida de manhã e inutilizável no meio da tarde, ou rápida por dez minutos depois de cada
reinício, é uma máquina superaquecendo, e nada que você desinstale vai mudar isso.

Mais duas que acompanham:

- **a ventoinha está sempre alta**, em especial parada, o que quer dizer que a máquina vem
  tentando e falhando em se resfriar há um tempo;
- **ela desliga sob carga** — um jogo, uma chamada de vídeo, exportar alguma coisa — e volta ao
  normal depois de esfriar.

## A poeira é a causa, e é mecânica

Um dissipador funciona fazendo o ar passar por uma pilha densa de aletas finas. A poeira entope os
vãos entre elas formando um feltro, e uma vez que isso acontece, a ventoinha pode girar a toda
mexendo um ar que não vai a lugar nenhum.

Num desktop isso é uma lata de ar comprimido e dez minutos, uma vez por ano. Num notebook é mais
difícil — a entrada é uma fresta embaixo, a pilha está dentro, e uma limpeza completa significa
abrir. **Soprar nas frestas de fora vale a pena e não é o mesmo serviço**; isso move a poeira
solta e deixa o feltro.

Duas coisas que ajudam sem abrir nada: **levante a traseira do notebook** para que o ar consiga
chegar embaixo, e **não o use sobre uma cama ou um sofá**, onde a entrada fica prensada no tecido.

## Pasta térmica, em resumo, e com honestidade

Entre o processador e o dissipador há uma camada de pasta, e depois de cinco a dez anos ela seca e
conduz mal. Trocá-la é um reparo de verdade que funciona de verdade.

É também o ponto em que um serviço caseiro vira um serviço profissional: o dissipador tem de sair,
a pasta velha tem de ser limpa das duas superfícies, e a camada nova tem de ter a quantidade
certa. Vale conhecer o termo para reconhecer um orçamento justo. Não é a primeira coisa a tentar.

## Os barulhos, e qual deles é urgente

- **Uma ventoinha que chacoalha ou zumbe** é um rolamento indo embora. Chato, barato, e não é
  urgente.
- **Uma ventoinha que muda de tom com a carga** é uma ventoinha fazendo o serviço dela.
- **Um clique, ou um tique ritmado, vindo de um disco rígido** não é ventoinha alguma, e é a
  próxima seção, e é o urgente.
