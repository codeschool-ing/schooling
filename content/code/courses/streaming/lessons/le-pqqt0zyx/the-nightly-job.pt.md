---
title: O job noturno, e a pergunta que ele não responde
version: 1
---

**Um pipeline batch responde perguntas sobre um período que já terminou.** Toda noite às duas, um
job recolhe as vendas de ontem das cinco lojas da Ponto Final, limpa, carrega no warehouse e
termina. Às oito da manhã a gerente vê o que vendeu ontem, e os números estão completos, conferidos
e fechados. A maior parte dos dados da maior parte das empresas anda assim, e para a maioria das
perguntas esse é o jeito certo.

O batch tem um relógio, e o relógio é o projeto inteiro. O período está fechado antes de o job
começar: às duas da manhã ninguém está mais vendendo o dia de ontem, então o job pode ler
**tudo**, em qualquer ordem, quantas vezes quiser. Se falhar, roda de novo sobre a mesma entrada e
produz a mesma saída. Se o arquivo de uma loja chega atrasado, o job espera por ele. Completude sai
barato porque o job roda depois do fato.

## A pergunta que o batch não responde

Às dez e meia de um sábado, a loja do Recife vende o último exemplar de um livro de que todo mundo
está falando no rádio. As outras quatro lojas ainda têm, e o site ainda diz *em estoque*. Às onze,
uma cliente do Recife compra o livro pelo site, para retirar na loja do Recife à tarde. Ninguém vai
perceber até o job noturno rodar — e até lá a cliente já fez a viagem.

Nada no batch está quebrado. Ele responde a pergunta para a qual foi construído, *o que vendeu
ontem*, perfeitamente. A pergunta que ficou sem resposta era **o que está acontecendo agora**, e um
pipeline que roda uma vez por dia não consegue respondê-la a preço nenhum: rode a cada hora e o
buraco é de uma hora, a cada minuto e o buraco é de um minuto, e cada passo deixa o pipeline mais
caro sem mudar a forma dele.

## Quão pequeno um batch fica

A primeira resposta de costume é encolher o batch. Funciona mais do que parece, e vale saber onde
para:

| período | quanto custa | onde para |
|---|---|---|
| um dia | um job, uma janela de trabalho, fácil de reexecutar | a pergunta é sobre hoje |
| uma hora | 24 jobs por dia, cada um relendo as fontes | um arquivo atrasado agora segura a próxima execução |
| cinco minutos | 288 jobs; iniciar cada um é boa parte do custo | jobs se sobrepõem quando um demora |
| um evento | — | já não é um batch |

Em algum ponto dessa tabela o batch deixa de ser um agendamento e vira um programa que nunca
termina: lê o que chega, trata, e espera mais. **Esse programa é um processador de stream**, e o
resto deste curso é sobre o que ele precisa fazer diferente porque nunca chega a dizer *isso era
tudo*.

A imagem errada mais comum de streaming é a que essa tabela sugere: que um stream é um batch
rodado muitas vezes, e que a parte difícil é a velocidade. Velocidade é a parte fácil. A difícil é
que o período nunca fecha, então as perguntas que um batch responde de graça — *já vi tudo?*, *e se
eu rodar de novo?*, *em que ordem as coisas aconteceram?* — precisam cada uma de uma resposta
própria. A próxima seção dá nome a elas.
