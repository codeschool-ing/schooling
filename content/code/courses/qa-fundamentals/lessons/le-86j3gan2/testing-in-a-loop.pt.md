---
title: Testando em laço, e o teste que não para de crescer
version: 1
---

**Quando um sistema é construído em voltas, toda volta muda algo que já funcionava.** A parte nova precisa
ser testada, e tudo o que ela pode ter mexido também. Esse segundo tipo de teste tem nome, **teste de
regressão**: conferir que o que funcionava antes ainda funciona depois de uma mudança. Numa única passagem
pela cascata ele acontece uma vez. Num projeto iterativo ele acontece a cada volta, e cresce.

## Por que ele cresce

No Cine Aurora, construído em voltas, os testes se acumulam assim:

| volta | o que é novo | o que precisa ser conferido |
|---|---|---|
| 1 | a regra de preço | a regra de preço |
| 2 | pedidos | pedidos, e a regra de preço de novo, já que os pedidos a chamam |
| 3 | o mapa de assentos | o mapa de assentos, os pedidos, a regra de preço |
| 4 | a quinta frase da Joana: meia é o máximo | a mudança, e todo caso de preço, já que a mudança mexe em todos |

Na quarta volta, o teste de uma mudança pequena inclui tudo o que foi construído nas três voltas anteriores.
As conferências da volta 1 rodam quatro vezes; as da volta 4 rodam uma. Feito à mão, o teste de regressão
cresce até ser a maior parte do tempo de teste, que é o argumento mais forte que existe para automatizá-lo.
O `cases.py` da aula 7 é uma pequena amostra exatamente disso: os seis casos de preço, rodados por um
programa, de novo sempre que alguém quiser, em um segundo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 280\" role=\"img\" data-fig=\"l10-regression\" aria-label=\"Quatro colunas, uma por volta. Cada coluna empilha as conferências rodadas naquela volta: volta 1, preços; volta 2, preços de novo e pedidos novo; volta 3, preços e pedidos de novo e assentos novo; volta 4, preços, pedidos e assentos de novo e a regra meia é o máximo nova. A pilha de conferências rodadas de novo cresce um bloco a cada volta.\"><rect x=\"40.0\" y=\"186.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">preços</text><text x=\"95.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">volta 1</text><rect x=\"170.0\" y=\"186.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"225.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">preços</text><rect x=\"170.0\" y=\"142.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"225.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pedidos</text><text x=\"225.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">volta 2</text><rect x=\"300.0\" y=\"186.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">preços</text><rect x=\"300.0\" y=\"142.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pedidos</text><rect x=\"300.0\" y=\"98.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">assentos</text><text x=\"355.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">volta 3</text><rect x=\"430.0\" y=\"186.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">preços</text><rect x=\"430.0\" y=\"142.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pedidos</text><rect x=\"430.0\" y=\"98.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assentos</text><rect x=\"430.0\" y=\"54.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">meia é o máximo</text><text x=\"485.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">volta 4</text><rect x=\"40.0\" y=\"258.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"58.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">conferências novas</text><rect x=\"220.0\" y=\"258.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"238.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conferências rodadas de novo</text></svg>", "caption": "As conferências da primeira volta rodam em toda volta depois dela. O teste de regressão cresce com o sistema, e é por isso que é o primeiro teste que os times automatizam."}
```

## Uma correção também é uma mudança

A correção do defeito dos sessenta anos é um caractere: `>` vira `>=`. Ainda é uma mudança, e um teste de
regressão é como alguém sabe que ela mudou só o que devia. Depois da correção, quem tem sessenta precisa pagar
meia, e quem tem sessenta e um também, e quem tem setenta também; quem tem cinquenta e nove ainda precisa
pagar inteira, e o estudante e a criança precisam ficar intocados. Uma correção que acerta os sessenta e por
acidente erra os cinquenta e nove é um defeito novo, e sem as conferências antigas iria para produção
parecendo um conserto.

É por isso que **todo defeito achado deveria deixar um teste para trás**: o caso que o expôs, guardado e
rodado de novo a cada mudança posterior. Com o tempo esses testes viram o registro de tudo o que o sistema já
errou, que é exatamente a lista dos lugares mais propensos a quebrar de novo.

## Escolhendo o que rodar de novo

Nem toda volta pode pagar para rodar tudo de novo, sobretudo à mão. A escolha do que rodar de novo é
priorização outra vez, e as perguntas são as que esta aula repete: em que esta mudança mexeu, o que depende
daquilo em que ela mexeu, e o que já quebrou antes? A aula 20 dá a isso um método, e a aula 10 de
`manual-testing` trata o teste de regressão como uma prática própria.

O que esta aula acrescenta é o ritmo. Na cascata, o teste era uma fase que vinha uma vez. Daqui em diante, em
todo modelo que o curso descreve, o teste é um **laço**: conferências novas para o que é novo, conferências
antigas para o que pode ter se mexido, toda vez.
