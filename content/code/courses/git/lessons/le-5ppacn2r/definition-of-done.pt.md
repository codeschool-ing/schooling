---
title: A definição de pronto
version: 1
---

Pergunte a quatro pessoas de uma equipe quando um ticket está pronto e você pode receber quatro respostas:
quando funciona para mim, quando entrou, quando o Diego testou, quando os clientes têm. Cada uma é a ideia
honesta de pronto de alguém, e a equipe perde um dia toda vez que duas delas se encontram:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Sete degraus de uma escada, de baixo para cima: na minha máquina funciona, que só quem escreveu sabe; enviado; revisado e com merge; checks verdes numa máquina limpa, feito pela CI; testado por outra pessoa, feito pelo QA; lançado; conferido onde o cliente vê. Uma linha acima do degrau mais alto marca a definição de pronto da padaria.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"304\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"320\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">na minha máquina funciona</text><text x=\"352\" y=\"320\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">só quem escreveu sabe</text><rect x=\"80\" y=\"260\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"94\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">enviado</text><rect x=\"120\" y=\"216\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"134\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">revisado e com merge</text><rect x=\"160\" y=\"172\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"174\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">checks verdes numa máquina limpa</text><text x=\"472\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CI</text><rect x=\"200\" y=\"128\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">testado por outra pessoa</text><text x=\"512\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">QA</text><rect x=\"240\" y=\"84\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"254\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lançado</text><rect x=\"280\" y=\"40\" width=\"300\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"294\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conferido onde o cliente vê</text><path d=\"M260 34 L700 34\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"700\" y=\"22\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a definição de pronto da padaria</text></svg>", "caption": "Cada degrau é alguém dizendo pronto. A equipe combina uma vez qual degrau a palavra quer dizer, e esse acordo é a definição de pronto.", "same": ["CI", "QA"]}
```

Uma **definição de pronto** (*definition of done*) é a equipe escolhendo um degrau, uma vez, e escrevendo o
que é preciso para chegar nele. Ela vale para **todo** ticket, e é isso que a separa dos critérios de aceite:

| | critérios de aceite | definição de pronto |
|---|---|---|
| pertence a | um ticket | a equipe inteira |
| diz | o que *esta* mudança tem de fazer | por onde *toda* mudança tem de ter passado |
| exemplo | o cardápio mostra glúten, leite e ovos | revisado, checks verdes, testado pelo QA, lançado |

Um ticket está pronto quando **os dois** são atendidos.

## A da padaria, por escrito

1. Critérios de aceite atendidos.
2. Revisado e aprovado por alguém que não escreveu.
3. Checks verdes no pull request.
4. Testado pelo Diego na versão candidata, num celular e num computador.
5. Lançado, e visto no site no ar.
6. Ticket atualizado, com o que se aprendeu escrito nele.

Curta o bastante para lembrar, específica o bastante para ninguém discutir. Ela fica no mesmo
`CONTRIBUTING.md` do fluxo da aula 9, e a coluna *pronto* do quadro quer dizer exatamente esta lista.

## O que ela muda

Muda o que "terminei" quer dizer numa daily. **O #34 da Ana não estava pronto quando funcionou na máquina
dela, e também não está no merge**; a definição diz isso antes, então ninguém precisa dizer a ela depois.
Também deixa as estimativas honestas: um ticket de 3 pontos inclui o teste e a release, porque pronto
inclui os dois.

E devolve o custo para onde ele é mais barato. Cada degrau da escada é um lugar onde um problema pode ser
pego, e **quanto mais embaixo ele é pego, menos custa**. Um arquivo esquecido é um comando no notebook da
Ana, vinte minutos do Bruno na revisão, uma hora do Diego nos testes, e a confiança de um cliente em
produção.
