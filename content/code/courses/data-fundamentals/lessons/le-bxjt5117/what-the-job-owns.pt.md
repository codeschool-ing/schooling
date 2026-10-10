---
title: Pelo que o trabalho responde
version: 1
---

**Um engenheiro de dados responde por resultados, e as ferramentas são o caminho até eles.** Anúncios
de vaga parecem inventários de software, então a imagem comum do trabalho é uma lista de produtos
para aprender. Os produtos mudam a cada poucos anos. O que faz alguém ser chamado às três da manhã
não mudou, e é a melhor descrição do trabalho.

A aula 1 deixou Davi conferindo toda manhã se o dia anterior tinha chegado. Aqui está tudo aquilo por
que ele e Ana respondem na Roda Livre:

| o que o trabalho tem sob sua responsabilidade | na Roda Livre | como fica quando ninguém é dono |
|---|---|---|
| **pipelines** | as cópias noturnas de viagens, leituras das docas e pagamentos | um script no notebook de alguém, que para quando a pessoa sai de férias |
| **contratos de dados** | um acordo com o time do aplicativo sobre a exportação de viagens | uma coluna renomeada numa terça, descoberta por um relatório na quarta |
| **atualidade** | viagens com menos de duas horas quando Marta olha às 09:00 | os números de sexta lidos na segunda, por alguém que acha que são de domingo |
| **privacidade** | nome, telefone e a estação perto de casa de cada cliente | um telefone numa tabela que qualquer analista lê |
| **custo** | a conta mensal de armazenamento, consultas e servidores | um painel relendo um ano de dados a cada cinco minutos |
| **plantão** | alguém que fica sabendo quando a exportação horária de viagens falha | a falha descoberta às onze pela pessoa que precisava do número |
| **documentação** | o que cada tabela quer dizer, de onde vem, a quem perguntar | uma pessoa que sabe, e todo mundo perguntando para ela |

Quatro delas merecem mais do que uma linha de tabela.

## Um contrato é um acordo sobre mudança

**Um contrato de dados é um acordo escrito entre o time que produz o dado e o time que o lê**: quais
campos existem, o que cada um quer dizer, qual é o tipo, e como uma mudança vai ser avisada. A coluna
renomeada da aula 1 quebrou porque o time do aplicativo não tinha motivo para saber que um pipeline
lia `start_station`. Com um contrato, renomeá-la vira uma mudança que alguém avisa com duas semanas de
antecedência, e o pipeline está pronto no dia.

O contrato não impede a mudança; o aplicativo precisa evoluir. Ele transforma uma surpresa numa data.
A aula 4 volta a ele, com as perguntas a fazer ao dono de uma fonte.

## Privacidade é um dever legal

A Roda Livre guarda dados pessoais: um nome, um telefone e um rastro de viagens que diz onde alguém
mora e trabalha. No Brasil isso é regido pela **LGPD**, a Lei Geral de Proteção de Dados (Lei 13.709,
de 2018), e fiscalizado por uma autoridade nacional, a ANPD. Três ideias dela bastam para reconhecer
aqui. Dado pessoal só pode ser tratado para uma finalidade declarada, com uma base legal. A pessoa a
quem ele se refere tem direitos sobre ele, entre eles o de saber o que se guarda sobre ela. E quem
trata o dado precisa mantê-lo seguro.

Para o engenheiro isso vira trabalho concreto: quem pode ler a tabela de clientes, por quanto tempo o
histórico de viagens fica guardado, como um pedido de exclusão chega a todas as cópias. A aula 7 mostra
como coletar só o que uma pergunta precisa; `data-governance` trata da lei e da sua maquinaria a fundo.

## Plantão faz parte do trabalho

Um pipeline que roda toda hora pode falhar a qualquer hora, inclusive às cinco da manhã. **Alguém
precisa ficar sabendo antes das pessoas que precisavam do dado**, o que quer dizer um alerta que chega
a um celular e uma pessoa cuja vez é atender. Num time de dois, é um rodízio de dois, e esse é um dos
argumentos para escolher ferramentas que falham pouco e se explicam quando falham. `observability` é o
ofício dos alertas e dos incidentes.

## Documentação é como o trabalho sobrevive à pessoa

Davi sabe que `rides.minutes` é arredondado para cima e que a estação `ST05` ficou fechada duas semanas
em agosto. Se isso mora só na cabeça dele, toda pergunta sobre o assunto espera por ele. **Uma tabela
que ninguém descreveu é descrita de novo por cada pessoa que a lê**, cada uma de um jeito um pouco
diferente. Um parágrafo por tabela, uma linha por coluna e um nome a quem perguntar bastam para
começar, e o registro de decisão, mais adiante nesta aula, é a mesma ideia aplicada a escolhas em vez
de tabelas.
