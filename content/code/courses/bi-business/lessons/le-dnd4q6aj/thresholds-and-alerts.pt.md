---
title: Limiares e alertas
version: 1
---

Um painel espera ser olhado, e o Marcos passa a maior parte da manhã carregando caminhões. Então o
painel também manda uma mensagem para o celular dele quando uma rota passa de uma linha. **Tudo nessa
mensagem depende de onde fica a linha**, e o jeito de escolhê-la é contar o que cada escolha teria
feito num dia de verdade.

## A manhã, na sua planilha

Estas são as catorze rotas de quarta às 11:00, com os minutos de atraso de cada uma em relação ao
plano. Digite-as numa aba nova, começando em A1, e ponha os três limiares candidatos em D1, E1 e F1,
como números:

| | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| 1 | Rota | Região | Atraso | 15 | 30 | 60 |
| 2 | 1 | Contagem Centro | 0 | | | |
| 3 | 2 | Eldorado | 6 | | | |
| 4 | 3 | Betim | 12 | | | |
| 5 | 4 | Barreiro | 18 | | | |
| 6 | 5 | Pampulha | 3 | | | |
| 7 | 6 | Venda Nova | 35 | | | |
| 8 | 7 | Savassi | 9 | | | |
| 9 | 8 | Nova Lima | 22 | | | |
| 10 | 9 | Sabará | 0 | | | |
| 11 | 10 | Santa Luzia | 41 | | | |
| 12 | 11 | Ribeirão das Neves | 74 | | | |
| 13 | 12 | Ibirité | 15 | | | |
| 14 | 13 | Lagoa Santa | 27 | | | |
| 15 | 14 | Vespasiano | 8 | | | |

Em D2, um 1 se a rota já chegou ao limiar do topo da coluna, e um 0 se não chegou:

```localised
=SE($C2>=D$1;1;0)      0
```

Copie D2 para a direita até F2, depois as três células para baixo até a linha 15. Os dois cifrões
fazem trabalhos opostos: `$C` mantém todas as colunas lendo o atraso em C, e `D$1` mantém todas as
linhas lendo o limiar na linha 1. A rota 4, na linha 5, está 18 minutos atrasada, então D5 mostra
**1** e E5 mostra 0. Em A16 digite `Alertas`, e em D16:

```localised
=SOMA(D2:D15)      7
```

Copie para E16 e F16. **Sua linha 16 deve mostrar 7, 3 e 1**: sete alertas com 15 minutos, três com 30
e um com 60, todos no mesmo instante da mesma manhã.

## Alertas demais, e tarde demais

Com 15 minutos, metade da frota dispara alerta às 11:00. Marcos não consegue ajudar sete caminhões ao
mesmo tempo, e dois dos sete estão 15 e 18 minutos atrasados, uma diferença que um motorista consegue
tirar ao longo de uma tarde de paradas. Se o celular vibra para todos, ele aprende em uma semana que a
maioria das vibrações não pede nada, e passa a ignorá-las. **Os hospitais têm nome para isso, fadiga
de alarme**, por causa de monitores que tocam tanto que a equipe deixa de ouvir. Um alerta que dispara
demais não é um alerta cauteloso. É um alerta desligado, e o alerta que importa chega no meio de uma
pilha dos que não importam.

Com 60 minutos, só a rota 11 dispara, e a essa altura a tarde dela já está perdida: as janelas de três
clientes fecharam. Um alerta nessa linha comunica uma falha em vez de avisar dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Catorze barras verticais, uma por rota, da mais atrasada à menos: 74, 41, 35, 27, 22, 18, 15, 12, 9, 8, 6, 3, 0 e 0 minutos. Três linhas tracejadas as cruzam. Em 15 minutos, 7 barras alcançam a linha; em 30, 3; em 60, 1.\" data-fig=\"l14-thresholds\"><path d=\"M64.0 270.0 L70.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"274.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M64.0 212.5 L70.0 212.5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"216.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><path d=\"M64.0 155.0 L70.0 155.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"159.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">40</text><path d=\"M64.0 97.5 L70.0 97.5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"101.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">60</text><path d=\"M64.0 40.0 L70.0 40.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"60.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">80</text><path d=\"M70.0 34.0 L70.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M70.0 270.0 L540.0 270.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"24.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">minutos de atraso às 11:00</text><path d=\"M76.0 57.2 H97.6 V270.0 H76.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"86.8\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><path d=\"M109.6 152.1 H131.1 V270.0 H109.6 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"120.4\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M143.1 169.4 H164.7 V270.0 H143.1 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"153.9\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><path d=\"M176.7 192.4 H198.3 V270.0 H176.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"187.5\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">13</text><path d=\"M210.3 206.8 H231.9 V270.0 H210.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"221.1\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><path d=\"M243.9 218.2 H265.4 V270.0 H243.9 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"254.6\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M277.4 226.9 H299.0 V270.0 H277.4 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"288.2\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><path d=\"M311.0 235.5 H332.6 V270.0 H311.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"321.8\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><path d=\"M344.6 244.1 H366.1 V270.0 H344.6 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"355.4\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><path d=\"M378.1 247.0 H399.7 V270.0 H378.1 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"388.9\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">14</text><path d=\"M411.7 252.8 H433.3 V270.0 H411.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"422.5\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><path d=\"M445.3 261.4 H466.9 V270.0 H445.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"456.1\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M478.9 268.5 H500.4 V270.0 H478.9 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"489.6\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M512.4 268.5 H534.0 V270.0 H512.4 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"523.2\" y=\"286.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><text x=\"305.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">rota, da mais atrasada à menos</text><path d=\"M70.0 226.9 L548.0 226.9\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></path><text x=\"554.0\" y=\"230.9\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">15 min: 7 alertas</text><path d=\"M70.0 183.8 L548.0 183.8\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></path><text x=\"554.0\" y=\"187.8\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">30 min: 3 alertas</text><path d=\"M70.0 97.5 L548.0 97.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></path><text x=\"554.0\" y=\"101.5\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">60 min: 1 alerta</text></svg>", "caption": "As mesmas catorze rotas contra três limiares. Em 15 minutos, metade da frota dispara alerta; em 60, só a rota que já está perdida. As barras em vermelho são o que o painel mostra em 30."}
```

Com 30 minutos, três rotas disparam, e são exatamente as três em que mudar paradas ou ligar para um
cliente ainda muda o resultado. Por isso o painel usa 30. **O limiar é uma decisão de negócio, não um
resultado estatístico.** Ele troca o custo de um alerta de que ninguém precisava pelo custo de um
alerta tardio. Quem paga os dois custos é o Marcos, então ele escolhe com a Lívia em vez de receber a
escolha pronta. A aula 11 de `machine-learning` faz o mesmo argumento sobre o limiar de um modelo.

## Um alerta que nomeia uma ação

Compare duas mensagens sobre a mesma rota.

> A rota 11 está 74 minutos atrasada.

> Rota 11 (Ribeirão das Neves): 74 min de atraso, faltam 22 paradas, 3 janelas perdidas. A rota 14
> (Vespasiano) está 8 min atrasada e é vizinha: passar 6 paradas?

A primeira é uma notificação: entrega um fato ao Marcos e deixa que ele descubra o que significa. A
segunda é um alerta: **diz quem deve fazer o quê, agora**. A regra da Lívia para todo alerta do painel
é que ele nomeie uma pessoa, uma ação e os dados necessários para tomá-la, ou não é enviado.

Mais duas regras saíram da primeira semana:

- **Uma vez por travessia, não uma vez por atualização.** Os dados são copiados a cada dez minutos,
  então uma rota que fica acima da linha a manhã inteira vibraria 6 vezes por hora. Ela alerta quando
  cruza a linha, e de novo só se piorar mais 30 minutos.
- **Alerta na exceção, nunca na média.** As catorze rotas tinham em média 19,3 minutos de atraso às
  11:00, então um alerta para média acima de 15 teria disparado naquela manhã sem dizer onde. Num dia
  com a rota 11 a 74 minutos e as outras treze no horário, a média é 5,3 e ele ficaria calado.

## Medindo o próprio alerta

Um alerta é um pedaço pequeno de BI e é medido como um. O número a guardar não é quantos alertas
dispararam, mas **quantos levaram a uma ação**. Se a maioria dos alertas de 30 minutos termina com o
Marcos sem fazer nada, a linha está baixa demais para as rotas da Varanda, ou o próximo passo sugerido
está errado. A Lívia conta as duas coisas todo mês com o Marcos, o que transforma o limiar de palpite em
uma decisão que alguém revisa.
