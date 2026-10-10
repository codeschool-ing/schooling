---
title: Entrega: a etapa que todo mundo vê
version: 1
---

**A entrega é a etapa em que o dado finalmente chega a alguém de fora do time de dados, e é a única
etapa que o resto da empresa chega a ver.** Ninguém na Roda Livre agradece a Davi por um diretório
bruto. Marta repara no relatório da manhã, e repara mais ainda na manhã em que ele atrasa ou vem
errado.

É fácil achar que entrega quer dizer painel. Um painel é uma forma entre várias, e nem todos os
leitores são pessoas.

| forma | quem ou o que lê | na Roda Livre |
|---|---|---|
| **um relatório** | uma pessoa, num horário fixo | o relatório da manhã: as viagens de ontem, as estações mais movimentadas |
| **um painel** | uma pessoa, quando ela olhar | uma tela na sala de operações, atualizada a cada hora |
| **uma tabela de atributos** | um modelo | para Caio: uma linha por estação por hora, com as viagens e o clima |
| **ETL reverso** | outro sistema operacional | as estações com chance de esvaziar amanhã, enviadas para o aplicativo que os motoristas da van usam para redistribuir bicicletas |
| **uma API** | um programa, quando pede | o aplicativo pergunta "quão movimentada esta estação costuma ficar a esta hora?" e mostra a resposta |

O **ETL reverso** (reverse ETL) é a menos óbvia das cinco, e o nome diz o que ela é: o resultado
curado volta para uma ferramenta operacional, na direção oposta à da ingestão. Os motoristas da van
nunca abrem um painel; a lista aparece no aplicativo que eles já usam. O desenho de painéis é
`analytics-bi`, e construir uma API é `apis`.

## A entrega lê o curado, e mais nada

**Toda forma de entrega lê a zona curada, não a bruta e nunca o banco do aplicativo.** Se o painel
contasse as viagens a partir do bruto enquanto o relatório as conta a partir do curado, o painel
incluiria as partidas falsas e o relatório não, e Marta receberia dois números para uma pergunta. Uma
tabela curada, lida por todas as formas, é o que faz as cinco concordarem entre si.

## Uma entrega é uma promessa

**No momento em que alguém depende de uma entrega, ela carrega uma promessa, tenha alguém escrito ou
não.** O relatório da manhã promete duas coisas: que está lá às oito, e que "viagens" quer dizer o
que queria dizer na semana passada. Quebre a primeira e Marta espera. Quebre a segunda — mude a regra
da partida falsa sem avisar ninguém — e ela compara esta semana com a anterior e tira uma conclusão de
uma diferença que o pipeline inventou. A aula 2 põe números em promessas assim, como uma meta de
atualidade que um time consegue medir.

É por isso que a entrega fica no fim do ciclo de vida e é desenhada primeiro. **Quem lê, em que
forma, até quando, e com que definição** decide o que as etapas anteriores têm de guardar, com que
frequência rodam e que regras a transformação aplica.
