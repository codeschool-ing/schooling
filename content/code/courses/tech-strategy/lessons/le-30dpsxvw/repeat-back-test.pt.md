---
title: O teste de repetir de volta
version: 1
---

Uma estratégia faz seu trabalho quando alguém toma uma decisão sem a página na frente: um líder
técnico planejando uma sprint, um engenheiro escolhendo se faz deploy numa quinta antes de uma
abertura. Então o teste da página é se as pessoas a carregam na cabeça. **Peça a cinco pessoas que a
digam de volta, com as próprias palavras, e escute o que sai.** Uma página que elas não conseguem
repetir não está fazendo seu trabalho, por mais bem escrita que seja.

## O que não diz nada

A evidência comum de que uma estratégia pegou é que ela foi publicada. Foi para todos os engenheiros
numa mensagem, a Helena a apresentou na reunião geral, o documento mostra que a maior parte da
empresa o abriu. **Nada disso mede se alguém consegue usá-la.** Abrir um documento não é lê-lo, e
lê-lo não é lembrar o que ele exclui.

Perguntar "a estratégia está clara?" não é melhor. Quase todo mundo diz que sim, em parte por
educação e em parte porque a pergunta pede que a pessoa admita, na frente do autor, que não
acompanhou. A resposta mede a relação, não a página.

## Como fazer

Espere uma ou duas semanas depois que a página sai, tempo para a primeira leitura se apagar. Escolha
cinco pessoas que não ajudaram a escrevê-la, de times e níveis diferentes: um engenheiro, um líder
técnico, alguém de produto, alguém que entrou há pouco. Faça a cada uma, separadamente e sem a
página, três perguntas:

1. Numa frase, qual é a nossa estratégia técnica?
2. Cite uma coisa que não vamos fazer este ano por causa dela.
3. Uma situação que a página não menciona, e o que a estratégia diz sobre ela.

A terceira pergunta é a que mais importa. Uma pessoa consegue decorar uma frase; **só quem entendeu a
política consegue aplicá-la a um caso que ela não lista.** Para a Coreto, Davi usou: "O Mobile quer
mudar o tempo limite da reserva de assento no app na semana antes de uma grande abertura. O que a
estratégia diz?" A resposta que ele esperava ouvir: isso toca o caminho da reserva de assentos,
então precisa da revisão do time de Reservas e de um resultado do teste de carga, e não pode sair nas
24 horas antes da abertura.

Anote o que cada pessoa diz, com as palavras dela. A paráfrase é o dado; um tique numa caixa perde
justamente a parte que diz o que consertar.

## A primeira rodada na Coreto

A primeira versão da página do Davi tinha o título *Estratégia técnica da Coreto*, a política no
segundo parágrafo e a lista do que não fazer no fim, abaixo das medidas. Duas semanas depois da
publicação, ele perguntou a cinco pessoas:

| quem | pergunta 1, com as palavras da pessoa | pergunta 2 | pergunta 3 |
|---|---|---|---|
| engenheira da Bilheteria | "Confiabilidade, acho. E pagar dívida técnica." | não soube citar | "Perguntar ao time de Reservas?" |
| líder técnico do Mobile | "Proteger as aberturas: nada no caminho de reservas sem teste de carga." | nada de microsserviços | revisão, teste de carga, e não nas 24 horas antes |
| engenheiro de Dados | "As reservas de assento ganham um time próprio." | não soube citar | não tinha certeza se valia para o Mobile |
| gerente de produto do Catálogo | "Arrumar o checkout das grandes aberturas antes de tudo." | o piloto do framework caiu | precisa do teste de carga antes |
| engenheira de Pagamentos | "Estamos saindo do monólito, devagar." | não soube citar | "Se for pequeno, deve estar tudo bem." |

Duas das cinco pessoas disseram de volta a política, duas citaram algo da lista do que não fazer, e
duas aplicaram a estratégia corretamente ao tempo limite. **As duas que passaram eram as duas cujo
trabalho a estratégia tinha mudado.** O líder técnico do Mobile tinha ouvido que seu gateway estava
fora; a gerente de produto tinha perdido seu piloto. As outras três tinham lido a página uma vez e
guardado o que combinava com o que já achavam.

O engenheiro de Dados lembrou uma ação e a tomou pela estratégia. A engenheira da Bilheteria lembrou
as palavras da primeira versão, que tinha circulado por semanas antes da segunda. **A engenheira de
Pagamentos disse o contrário da página**: nenhuma migração este ano tinha virado uma migração lenta.
Essa resposta é a mais útil da tabela. Ela quer dizer que circula uma versão da estratégia que
ninguém escreveu, e essa versão vai tomar decisões até ser corrigida.

## O que o Davi mudou

As falhas apontavam para a página e para o modo como ela foi entregue, não para as cinco pessoas.

- A política foi para o título: *Estratégia técnica da Coreto: proteger a abertura de vendas
  primeiro.* Quem abre a página, ou vê um link para ela, lê a política antes de qualquer outra coisa.
- A lista do que não fazer subiu para cima das medidas, ao lado das ações, para que o que a empresa
  está fazendo e o que não está fazendo sejam lidos juntos.
- Ele leu a página em voz alta na reunião de planejamento seguinte de cada time e respondeu
  perguntas, em vez de confiar na mensagem e na reunião geral. Isso tomou uma manhã do tempo dele,
  passando pelos times.

Um mês depois, ele fez as mesmas três perguntas a cinco outras pessoas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 324\" role=\"img\" aria-label=\"Duas grades de cinco pessoas por três perguntas: a política com as próprias palavras, uma coisa da lista do que não fazer, e o caso novo do tempo limite da reserva. Primeira rodada, com a primeira página: duas de cinco passam em cada pergunta, sempre as mesmas duas. Segunda rodada, cinco outras pessoas depois das mudanças: quatro de cinco na política, quatro de cinco na lista, três de cinco no caso novo.\"><rect x=\"20\" y=\"14\" width=\"330\" height=\"262\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"185\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Primeira rodada: a primeira página</text><text x=\"160\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">política</text><text x=\"230\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">lista do não</text><text x=\"300\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">caso novo</text><text x=\"36\" y=\"96\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 1</text><rect x=\"151\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 2</text><rect x=\"151\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 3</text><rect x=\"151\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"192\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 4</text><rect x=\"151\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"224\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 5</text><rect x=\"151\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"221\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"291\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><path d=\"M32 242 L338 242\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"160\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2 de 5</text><text x=\"230\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2 de 5</text><text x=\"300\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">2 de 5</text><text x=\"36\" y=\"264\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">total</text><rect x=\"370\" y=\"14\" width=\"330\" height=\"262\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"535\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Segunda rodada: depois das mudanças</text><text x=\"510\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">política</text><text x=\"580\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">lista do não</text><text x=\"650\" y=\"64\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">caso novo</text><text x=\"386\" y=\"96\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 1</text><rect x=\"501\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"82\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"128\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 2</text><rect x=\"501\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"114\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 3</text><rect x=\"501\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"146\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"192\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 4</text><rect x=\"501\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"178\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"224\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pessoa 5</text><rect x=\"501\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"571\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641\" y=\"210\" width=\"18\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M382 242 L688 242\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"510\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">4 de 5</text><text x=\"580\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">4 de 5</text><text x=\"650\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">3 de 5</text><text x=\"386\" y=\"264\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">total</text><rect x=\"150\" y=\"296\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"172\" y=\"308\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">disse de volta, ou aplicou</text><rect x=\"420\" y=\"296\" width=\"14\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"442\" y=\"308\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não</text></svg>", "caption": "Cinco pessoas, três perguntas, duas vezes. Na primeira rodada, só conseguiram dizer a estratégia de volta as duas pessoas cujo trabalho ela tinha mudado; depois que a página e a entrega mudaram, a maioria de cinco pessoas novas conseguiu.", "same": ["total"]}
```

Quatro disseram de volta a política, quatro citaram algo da lista, e três aplicaram a estratégia ao
tempo limite. A quinta pessoa, na pergunta 1, descreveu o teste de carga como a estratégia, o que
chega perto e ainda é uma ação; Davi deixou assim, porque uma página que quatro pessoas em cinco
conseguem repetir com as próprias palavras está fazendo seu trabalho.

## Fazendo de novo

**Pessoas entram, e uma estratégia que estava na cabeça de todos em janeiro pode se perder até
junho.** A cada trimestre, na revisão que o cabeçalho da página promete, pergunte a cinco pessoas
novas — incluindo alguém que entrou desde a última rodada. Uma queda é um sinal precoce de que a
página envelheceu ou de que as razões por trás dela pararam de ser repetidas, e chega muito antes de
alguém entregar algo que a política exclui.

E quando as respostas vierem certas, mas exatamente com as palavras da página, faça a terceira
pergunta de novo com outra situação. Recitar passa nas duas primeiras perguntas. Só entender passa
na terceira.
