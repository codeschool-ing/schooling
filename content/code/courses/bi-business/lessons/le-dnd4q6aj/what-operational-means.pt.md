---
title: O que quer dizer operacional
version: 1
---

Uma empresa decide em três velocidades, e cada velocidade pede uma tela diferente. **O BI operacional
serve às decisões tomadas hoje, em minutos ou horas, por quem está fazendo o trabalho.** O BI tático
serve às decisões do mês, tomadas por gestores que mexem em verba, gente e estoque; o estratégico, às
do ano, tomadas pelos donos e pelo conselho. Esta aula é a primeira das três, e as aulas 15 e 16 tratam
das outras duas.

| nível | horizonte | quem decide na Varanda | a pergunta | o que a tela mostra | quão recente |
|---|---|---|---|---|---|
| operacional | minutos a horas | Marcos no CD, os gerentes de loja, o atendimento | o que precisa da minha atenção agora? | as exceções, uma linha cada | minutos |
| tático | semanas e meses | Renata, Caio, Otávio | estamos no plano, e para onde movemos recursos? | o mês contra a meta e contra o ano passado | o mês fechado |
| estratégico | anos | Helena e o conselho | estamos indo para o lado certo? | poucos números ao longo de cinco anos | o ano fechado |

## A imagem errada: o painel do mês, atualizado mais vezes

O erro comum é tratar os três níveis como um painel só, com três frequências de atualização: pegar os
gráficos que os diretores olham, fazer com que se atualizem a cada dez minutos e pendurá-los numa tela
no centro de distribuição. **Os níveis diferem na pergunta, não no relógio**, e um gráfico do mês
responde à pergunta de um diretor por mais vezes que seja redesenhado.

Marcos é o coordenador de entregas da Varanda, no centro de distribuição (CD) de Contagem. Numa
quarta-feira às 11:00 ele tem catorze caminhões na rua e uma pergunta: qual deles precisa de mim agora?
Um gráfico de linha da taxa de entrega no prazo do mês não responde. Uma pizza das entregas por região
também não. Os dois são verdadeiros e os dois falam de outra coisa.

## Decisões em minutos, por quem está no chão

As decisões operacionais têm uma forma em comum. **São muitas, pequenas e reversíveis, e quem as toma
não é analista.** Marcos passa seis paradas de um caminhão atrasado para outro que está adiantado. Uma
gerente de loja vê que as mangueiras de jardim sumiram da prateleira às três da tarde e liga para o CD.
Alguém do atendimento vê que a janela de entrega de um cliente fechou e telefona antes que ele telefone
para a loja.

Cada uma dessas pessoas lê a tela em poucos segundos, muitas vezes no celular ou numa televisão na
parede, enquanto faz outra coisa. Nenhuma quer analisar nada. Querem que a tela já tenha olhado por
elas e aponte a linha que está errada.

## Exceções, não médias

Por isso uma tela operacional abre com as exceções. Naquela quarta às 11:00, as catorze rotas estavam
em média **19,3 minutos** atrás do plano, com mediana de 13,5. Lido como número único, isso diz "um
pouco atrasado em todo lugar" e não sugere nada a fazer. As rotas, uma a uma, dizem outra coisa: seis
estavam a menos de dez minutos do plano, e uma, a rota 11 para Ribeirão das Neves, estava **74 minutos
atrasada**, com três clientes cuja janela já tinha fechado.

A média é a ferramenta certa para comparar este janeiro com o janeiro passado, que é uma pergunta
tática. Para quem está no chão, ela esconde a única linha que precisa dele no meio de treze que não
precisam. **Uma tela operacional é uma lista do que está errado, ordenada por quão errado está**, com
tudo o que está bem reduzido a uma linha dizendo isso.

## Resposta que chega tarde não é resposta

A outra propriedade é estar em dia. Onde os caminhões estavam às 08:00 já é história às 11:00, e uma
decisão tomada com base nisso põe paradas num caminhão que não está mais adiantado. Dado operacional
precisa ter minutos de idade, e a tela precisa dizer quantos. A última seção desta aula trata do que
acontece quando não diz.

## O que o BI operacional não é

Ele não explica. O painel mostra que a rota 11 está 74 minutos atrasada; não sabe que o caminhão
furou um pneu às 09:40. Marcos descobre isso ligando para o motorista, e por que as entregas atrasam ao
longo de um mês inteiro é a pergunta diagnóstica da aula 7, feita na reunião mensal da aula 15.

Também não decide, pelo menos não aqui. A aula 9 entregou uma regra de reposição ao sistema porque a
decisão era frequente, barata de errar e fácil de desfazer. Mudar uma entrega também é frequente, mas
depende de coisas que os dados não têm — se o cliente pode receber mais tarde, se o segundo motorista
conhece a região —, então uma pessoa decide e a tela sugere.

**A parte da Lívia é tudo o que fica em volta da tela.** Ela não fica olhando o painel; quem olha é o
Marcos. Ela define o que querem dizer "atraso" e "atrasado", combina com ele o limiar dos alertas,
monta o painel e garante que ele falhe de forma visível. A aula 13 disse que o Marcos precisa dos
números por pedido, e agora; esta aula é o que custa entregar essa frase.
