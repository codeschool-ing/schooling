---
title: A aritmética da disponibilidade
version: 1
---

**Um número de disponibilidade é uma quantidade de tempo fora do ar escrita como percentual, e o
percentual esconde quanto tempo é.** "Três noves" soa quase perfeito. Convertido de volta em horas,
é um dia inteiro de trabalho perdido por ano, e o hábito que vale criar é fazer essa conversão antes
de concordar com qualquer número.

Joana deu de cara com isso no segundo mês. Regina perguntou o que o Portal B2B deveria prometer às
4.000 padarias que fazem pedidos por ele, e Joana deu a resposta que dava na fintech: 99,9%. Depois
ela fez a conta dos sistemas de que o portal depende e descobriu que o portal não conseguiria
cumprir essa promessa. O código dele estava bem. **O problema era aquilo que ele chamava.**

## Os noves, em tempo

Um ano tem 8.760 horas (365 × 24) e um mês de 30 dias tem 43.200 minutos. Um serviço com
disponibilidade *A* pode ficar fora do ar durante a fração (1 − *A*) desse tempo. A tabela abaixo
não faz nada além disso:

| disponibilidade | fora do ar por ano | fora do ar por mês de 30 dias |
|---|---|---|
| 99% | 87,6 h, ou 3,65 dias | 432 min, ou 7,2 h |
| 99,5% | 43,8 h | 216 min, ou 3,6 h |
| 99,9% | 8,76 h | 43,2 min |
| 99,95% | 4,38 h | 21,6 min |
| 99,99% | 52,56 min | 4,32 min |

Cada nove a mais divide o tempo fora do ar por dez. O preço não se divide junto. Passar de 99,9% para 99,99% significa sobreviver à perda de um servidor inteiro ou de um site inteiro sem acordar
ninguém, e isso é outra arquitetura, não uma versão melhor da mesma.

Dois detalhes pegam as pessoas toda vez que elas leem um desses números.

*Qual mês.* 43,2 minutos é um décimo de por cento de um mês de 30 dias. Um mês médio, um doze avos
do ano, permite 43,8 minutos; um mês de 31 dias permite 44,64; fevereiro permite 40,32. As
diferenças são pequenas e são exatamente o tipo de coisa sobre a qual duas partes discutem depois de
uma queda, então uma meta diz qual é o seu período.

*Qual janela de medição.* 99,9% medido ao longo de um ano permite 8,76 horas, e nada impede que
todas cheguem numa única noite. 99,9% medido por mês permite no máximo 43,2 minutos em qualquer mês.
**O mesmo percentual sobre uma janela diferente é uma promessa diferente**, e uma padaria que não
consegue fazer o pedido na única noite ruim não quer saber se o ano fechou na média.

## Uma cadeia multiplica

Quando uma requisição precisa passar por vários sistemas e cada um deles precisa estar no ar para
ela dar certo, a disponibilidade do todo é o produto das partes. O raciocínio é o da probabilidade
de eventos independentes: a requisição só funciona se o primeiro sistema estiver no ar, e o segundo,
e o terceiro.

O caso de Joana era a consulta de estoque. Quando uma padaria abre o carrinho, o portal pergunta ao
serviço de disponível para promessa (ATP) do SAP quanto de cada produto ainda pode ser vendido (a
aula 1 conta como esse serviço passou a existir), e a chamada atravessa o barramento de Rui no
caminho. Três sistemas em fila, com a disponibilidade dos últimos doze meses tirada do monitoramento
de cada equipe:

| sistema | disponibilidade medida |
|---|---|
| Portal B2B | 99,9% |
| o barramento de serviços (IBM Integration Bus) | 99,5% |
| SAP ECC, fora da janela planejada | 99,0% |

A cadeia é 0,999 × 0,995 × 0,99 = 0,98406, cerca de **98,41%**. Sobra 1,594% do ano, que são 139,6
horas, ou 5,8 dias. Num mês de 30 dias são cerca de 688 minutos, onze horas e meia. Cada sistema
sozinho parece respeitável. Juntos, deixam o carrinho da padaria fora de alcance por quase uma semana
por ano.

Quando todos os fatores estão perto de 100%, existe um atalho que vale conhecer: **as
indisponibilidades praticamente se somam.** 0,1% + 0,5% + 1,0% = 1,6%, contra o 1,594% exato. É
assim que se confere a promessa de um fornecedor numa reunião sem calculadora, e isso deixa o próximo
ponto óbvio. Uma cadeia é sempre menos disponível do que o seu membro mais fraco. A equipe do portal
poderia deixar o próprio código perfeito e a consulta de estoque continuaria em 0,995 × 0,99 =
98,505%.

O diagrama também subestima a cadeia. A chamada precisa da rede entre o data center e a hospedagem
do portal, da resolução de nomes, do certificado em cada salto e do serviço de identidade que assina
o token do portal. **Cada dependência síncrona é mais um fator**, e a cadeia honesta é mais longa do
que a do quadro branco. A figura abaixo fica nas três que as medições cobrem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l12-chain\" aria-label=\"Duas linhas. A de cima é a consulta de estoque como ela é: o Portal B2B com 99,9%, o barramento com 99,5% e o SAP ECC com 99,0%, em série, então a cadeia é 0,999 vezes 0,995 vezes 0,99, que dá 98,41%, cerca de 139,6 horas fora do ar por ano. A de baixo põe dois nós do barramento em paralelo entre o portal e o SAP. No papel o par é 1 menos 0,005 ao quadrado, 99,9975%, e a cadeia passa a 98,90%. Com o histórico de falhas do ano passado, 18 das 43,8 horas do barramento vieram de causas que os dois nós compartilham, então o par chega a cerca de 99,79%, e não a 99,9975%.\"><defs><marker id=\"l12-chain-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">em série: todos precisam estar no ar</text><rect x=\"25.0\" y=\"47.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Portal B2B</text><text x=\"95.0\" y=\"79.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99,9%</text><rect x=\"220.0\" y=\"47.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">barramento</text><text x=\"290.0\" y=\"79.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99,5%</text><rect x=\"415.0\" y=\"47.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP ECC</text><text x=\"485.0\" y=\"79.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99,0%</text><path d=\"M166.0 72.0 L218.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M361.0 72.0 L413.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M556.0 72.0 L586.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><text x=\"650.0\" y=\"64.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">= 98,41%</text><text x=\"650.0\" y=\"79.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">139,6 h por ano</text><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,999 × 0,995 × 0,99 = 0,98406</text><path d=\"M20.0 140.0 L700.0 140.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"20.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um segundo nó do barramento em paralelo</text><rect x=\"25.0\" y=\"215.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"232.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Portal B2B</text><text x=\"95.0\" y=\"247.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99,9%</text><rect x=\"220.0\" y=\"184.0\" width=\"140.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nó A  99,5%</text><rect x=\"220.0\" y=\"254.0\" width=\"140.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nó B  99,5%</text><rect x=\"415.0\" y=\"215.0\" width=\"140.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"232.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP ECC</text><text x=\"485.0\" y=\"247.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">99,0%</text><path d=\"M166.0 240.0 L190.0 240.0 L190.0 205.0 L218.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M190.0 240.0 L190.0 275.0 L218.0 275.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M361.0 205.0 L390.0 205.0 L390.0 240.0 L413.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-chain-es-ah-paper-dim)\"></path><path d=\"M361 275 L390 275 L390 240\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"650.0\" y=\"232.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">= 98,90%</text><text x=\"650.0\" y=\"247.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">no papel</text><text x=\"360.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">par no papel: 1 − 0,005² = 99,9975%   ·   com as 18 h que os dois nós compartilham: cerca de 99,79%</text></svg>", "caption": "A consulta de estoque como uma cadeia. Em série as disponibilidades se multiplicam; um segundo nó acrescenta um nove no papel, e as falhas que os dois nós compartilham levam de volta a maior parte dele.", "same": ["Portal B2B", "SAP ECC"]}
```

## Redundância compra um nove, no papel

Duas cópias de um componente, qualquer uma das quais faz o trabalho, só falham juntas quando as duas
estão fora. Se cada uma está disponível com probabilidade *a*, o par está disponível com
probabilidade 1 − (1 − *a*)².

Para o barramento com 99,5%, um segundo nó daria 1 − 0,005² = 0,999975, que é **99,9975%**. O tempo
fora do ar cai de 43,8 horas por ano para cerca de 13 minutos (0,000025 × 525.600 minutos). Ponha
esse par na cadeia e a consulta de estoque passa a 0,999 × 0,999975 × 0,99 = 98,90%. Agora o SAP é
quase tudo o que sobra.

Essa fórmula se apoia numa palavra: independentes. Ela supõe que aquilo que derruba uma cópia deixa
a outra em paz, e é essa suposição que os sistemas reais quebram. Rui guarda o registro de cada queda
do barramento, e Joana repassou com ele as 43,8 horas do ano passado:

| causa | horas | um segundo nó teria ajudado? |
|---|---|---|
| um certificado vencido nos endpoints do barramento | 11 | não: os dois nós usariam o mesmo certificado |
| um fluxo implantado com um erro de mapeamento | 7 | não: uma implantação vai para os dois nós |
| falhas de nó: disco cheio, reinício do host, processo travado | 25,8 | sim |

As 18 horas de causas compartilhadas continuam lá, seja qual for o número de nós. As 25,8 horas de
falhas de nó quase desaparecem: cada nó fica fora 25,8 de 8.760 horas, então os dois ficam fora ao
mesmo tempo cerca de 0,076 hora, menos de cinco minutos. O par fica em cerca de 18,1 horas por ano,
o que dá 99,79%.

**A redundância elimina as falhas independentes e mantém todas as falhas que as cópias
compartilham.** O segundo nó continua valendo a pena: ele tira mais da metade do tempo fora do ar.
Não vale 99,9975%, e uma proposta que cita a fórmula sem o histórico de quedas prometeu algo que o
sistema não vai entregar. A fórmula também supõe que a troca de uma cópia para a outra é instantânea.
Um failover que leva quatro minutos para perceber e dois para concluir devolve esses minutos a cada
falha.

## O que a aritmética manda fazer

A conclusão de Joana não foi comprar primeiro um segundo nó para o barramento. A cadeia mostrou onde
estavam as horas: o SAP, com 1,0%, é o maior fator, e o SAP é o sistema que a Serra Alta tem menos
como mudar. Acrescentar noves ao barramento ou ao portal mexe no total em décimos. **Tirar o SAP do
caminho enquanto a padaria espera** mexe em pontos percentuais inteiros, e o cache curto da aula 1 é
o primeiro passo disso: um carrinho aberto enquanto o SAP está lento é atendido com um número de
poucos minutos atrás em vez de falhar. A seção sobre modos degradados, duas adiante, transforma isso
num projeto em vez de um acidente.

Há uma segunda coisa que a tabela acima não mostra. Os 99,0% do SAP são medidos fora da janela
planejada, e todo domingo, da 01:00 às 05:00, ele fica fora do ar de propósito. Se isso conta ou não
depende de quem pergunta, que é o que a próxima seção resolve: o que exatamente está sendo medido, de
onde, e o que acontece quando o número não é cumprido.
