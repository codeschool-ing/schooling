---
title: Mob programming: o time inteiro num teclado
version: 1
---

**Mob programming, hoje muitas vezes chamado de *ensemble programming*, é um time inteiro trabalhando
numa tarefa, diante de uma tela, com uma pessoa digitando e todas as outras navegando, num rodízio a
cada poucos minutos.** Parece o arranjo menos eficiente possível, e para a tarefa certa não custa mais do que trabalhar
separado e deixa o time inteiro conhecendo o código.

## De onde veio

Woody Zuil descreveu a prática a partir do seu time na Hunter Industries, que por volta de 2011
começou a trabalhar assim o dia todo e viu sumirem quase por completo os problemas que costumavam
atrasá-lo (esperar respostas, esperar revisões, mal-entendidos entre pessoas trabalhando separadas). O
time continuou assim por anos e escreveu bastante sobre isso.

## Como uma sessão funciona

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Cinco pessoas em roda, Bruna, Diego, Paulo, Rafael e Lívia, com a Bruna destacada como piloto atual e setas tracejadas passando o papel para a próxima pessoa a cada 4 a 10 minutos. Ao lado: um piloto digita o que os outros decidem; um navegador fala pelo grupo de cada vez; uma retrospectiva curta no fim.\"><defs><marker id=\"mobrotatio-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"202.0\" y=\"27.0\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Bruna</text><rect x=\"301.8609342109911\" y=\"99.55321559063051\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"349.8609342109911\" y=\"117.55321559063051\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Diego</text><rect x=\"263.71745149070966\" y=\"216.94678440936949\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"311.71745149070966\" y=\"234.94678440936949\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Paulo</text><rect x=\"140.28254850929034\" y=\"216.94678440936949\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"188.28254850929034\" y=\"234.94678440936949\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Rafael</text><rect x=\"102.13906578900887\" y=\"99.55321559063054\" width=\"96\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"150.13906578900887\" y=\"117.55321559063054\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Lívia</text><path d=\"M288 73 L312 90\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><path d=\"M335 162 L326 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><path d=\"M265 235 L235 235\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><path d=\"M174 190 L165 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><path d=\"M188 90 L212 73\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#mobrotatio-ah)\"></path><text x=\"250\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o piloto troca</text><text x=\"250\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cada 4 a 10 minutos</text><text x=\"430\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um piloto digita</text><text x=\"430\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o que os outros decidem;</text><text x=\"430\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um navegador fala</text><text x=\"430\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pelo grupo de cada vez</text><text x=\"430\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">uma retrospectiva curta</text><text x=\"430\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">no fim</text></svg>", "caption": "Uma sessão de mob no leitor do outbox. A rotação segue um cronômetro para todo mundo digitar e ninguém se dispersar.", "same": ["Bruna", "Diego", "Lívia", "Paulo", "Rafael"]}
```

- **Um piloto**, no teclado, digita o que os navegadores decidem. No estilo forte, o piloto não
  acrescenta ideias próprias enquanto pilota.
- **Todos os outros navegam**, mas um fala pelo grupo de cada vez, em geral a pessoa à esquerda do
  piloto ou quem pilota em seguida.
- **O piloto troca por timer**, muitas vezes a cada quatro a dez minutos, para que todo mundo digite e
  ninguém se desligue.
- **Uma retrospectiva curta** no fim: o que funcionou, o que mudar na próxima vez.

## Quando a Marola usa

O time da Bruna faz mob por algumas horas num número pequeno de tarefas:

- **a primeira versão de algo novo**, que o time inteiro vai ter de manter e em que cada decisão de
  design vale ser tomada em conjunto: o leitor do outbox da aula 9 foi feito em mob por dois dias;
- **o acompanhamento de um incidente**, quando a correção mexe nas áreas de várias pessoas e todo
  mundo precisa entendê-la;
- **o onboarding**, na primeira semana de um engenheiro novo, para que ele veja de uma vez como o time
  inteiro trabalha.

O time não faz mob no trabalho de rotina, e nunca faz mob por uma semana inteira; descobriu que mais
de umas três horas por dia deixava as pessoas cansadas demais para qualquer outra coisa.

## O custo, com franqueza

Cinco engenheiros numa tarefa por dois dias são dez dias-engenheiro. A pergunta é o que isso
substituiu: uma discussão de design, um ciclo de revisão com três rodadas de comentários, duas pessoas
aprendendo o código depois sob pressão e um documento de passagem que ninguém lê. No caso do leitor do
outbox, a estimativa da Bruna foi que o mob substituiu mais ou menos os mesmos dez dias desse
trabalho, e **terminou com cinco pessoas que entendiam o código em vez de uma.** Numa mudança de
rotina, não teria substituído nada.
