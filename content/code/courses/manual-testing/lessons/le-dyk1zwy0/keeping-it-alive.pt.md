---
title: Mantendo a suíte viva
version: 1
---

Uma suíte de regressão costuma ser tratada como algo escrito uma vez, no fim da primeira versão, e
rodado sem mudança dali em diante. **Uma suíte largada se deteriora em duas direções ao mesmo
tempo**: deixa de fora as partes do produto que cresceram depois que ela foi escrita, e continua
rodando casos de partes que mudaram ou sumiram, que falham por motivos que não interessam a ninguém.
Depois de algumas versões as pessoas param de acreditar nela, e uma suíte em que ninguém acredita é
pulada. Mantê-la útil é um pouco de trabalho depois de cada versão, e quatro hábitos cobrem quase
tudo.

## Acrescente o que a versão ensinou

**Todo defeito corrigido acrescenta seu reteste à suíte.** A aula 9 verificou duas correções na
1.1: seis ingressos aceitos, e 15% para um sócio que reserva cinco. Os dois retestes entram agora na
suíte de regressão, com seus vizinhos, porque a seção 02 citou o jeito como uma correção vai embora:
a edição posterior de alguém a tira de novo, e a única coisa que percebe é um caso que continua
perguntando.

**Todo defeito que chegou a uma versão acrescenta o caso que o teria pegado.** O desconto de
estudante é o exemplo instrutivo. A suíte o pegou, porque as oito regras da tabela de desconto
estavam nela, o que é o argumento para manter tabelas inteiras em vez de uma amostra conveniente.
Mas a regressão agora é um jeito conhecido de esta função falhar, então a regra 7, um sócio
estudante reservando dois, ganha uma nota ao lado: *regrediu na 1.1*. Um caso com histórico é um
caso que ninguém corta por acidente.

## Tire o que não diz mais nada

Um caso pertence à suíte enquanto ainda pode falhar por um motivo que importa. Três tipos deixam de
se qualificar:

- um caso de uma funcionalidade que foi removida, que agora falha em toda rodada e ensina todo mundo
  a ler vermelho como normal;
- dois casos que conferem a mesma coisa pelo mesmo caminho, dos quais um fica e o outro sai;
- um caso cujo resultado esperado era uma decisão que mudou desde então. Se o teatro decidisse que
  estudantes ganham 40%, as oito regras recebem um novo resultado esperado no dia em que a decisão é
  tomada, e não no dia em que alguém roda a suíte e relata um defeito contra a regra nova.

O último é o mais comum e o mais caro de deixar passar. **Uma suíte com resultados esperados
desatualizados relata um comportamento correto como defeito**, e cada relatório falso gasta o
tempo de um desenvolvedor e um pouco da credibilidade da suíte.

## Mantenha em camadas

Nem todo caso roda em toda versão. Um arranjo comum tem três camadas:

| camada | o que tem nela | quando roda |
|---|---|---|
| núcleo | a lista de fumaça, e um caso por risco alto | toda versão |
| pela mudança | os casos que a análise de impacto escolhe, como a seção 03 fez para a 1.1 | toda versão que promete uma mudança |
| completa | todo caso da suíte | antes de uma entrega, ou num calendário |

Cada caso carrega o que decide a camada dele: o risco que cobre, de A a E no boxoffice, e a área que
testa, para que "tudo sobre preço" ou "tudo do risco C" seja um filtro, e não uma tarde de leitura.
A aula 18 mostra as ferramentas que guardam suítes assim; uma planilha com uma coluna para cada um é
como a maioria das equipes começa.

## Registre os resultados por versão

Um resultado sem número de versão é um resultado que ninguém consegue comparar. **Guarde os
resultados como uma grade de casos contra versões**, e uma regressão vira algo que se vê:

| caso | 1.0 | 1.1 |
|---|---|---|
| sócio, estudante, 2 ingressos: 50% | passou | **falhou** |
| sócio, 5 ingressos: 15% | falhou (25%) | passou |
| sócio, 6 ingressos: um pedido | falhou (recusado) | passou |
| quantidade que não é número: uma frase, R7 | falhou (500) | falhou (500) |

Lida ao longo de uma linha, cada caso tem uma história: corrigido, regrediu, continua aberto. Um
passou que vira falhou entre duas colunas é uma regressão sem mais discussão, e um falhou que nunca
muda é um defeito conhecido esperando a correção. Essa grade é também a primeira coisa que alguém
pede quando uma entrega está sendo decidida, e a aula 19 a transforma num relatório de uma página.

Quando a camada completa deixa de caber no tempo antes de uma entrega, e com uma versão por semana
ela deixa, os casos que rodam em toda versão e nunca precisam do julgamento de uma pessoa são os
primeiros candidatos a automação. A aula 13 mostra como é um teste automatizado na menor escala, e o
curso `web-automation` automatiza verificações como estas pelo navegador. Até lá, a suíte é rodada à
mão, e fica curta pelas decisões acima, e não por pular o fim dela.
