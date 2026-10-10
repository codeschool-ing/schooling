---
title: O que faz quem é arquiteto
version: 1
---

Três retratos do arquiteto são comuns, e cada um guarda um pedaço da verdade embrulhado num engano.
**O arquiteto é o programador mais experiente**, promovido por ser bom de código. **O arquiteto é
quem desenha os diagramas.** **O arquiteto é quem aprova tudo.** O primeiro confunde uma recompensa
com um trabalho, o segundo confunde uma visão com a arquitetura (aula 2), e o terceiro descreve um
gargalo, não um papel.

Uma descrição melhor cabe numa frase, e é a frase em torno da qual este curso foi construído: **o
arquiteto é quem decide, registra e responde pelas escolhas estruturais.** Cada um dos três verbos
carrega uma parte do trabalho.

## Decide

*Decide* não quer dizer que o arquiteto toma pessoalmente cada decisão estrutural. Numa empresa do
tamanho da Carreto isso seria impossível, e a próxima seção argumenta que também seria indesejável.
Quer dizer que **o arquiteto garante que as decisões estruturais sejam tomadas — pelas pessoas
certas, no momento certo, com a informação certa** — e toma algumas delas diretamente.

A aula 1 deu o teste para saber quais decisões são estruturais: o custo de mudá-las e se elas
atravessam fronteiras de times. A aula 2 acrescentou o tempo: o último momento responsável. Juntos
eles descrevem a maior parte da atenção de um arquiteto. Uma decisão dentro de um time, barata de
desfazer, pertence a esse time. Uma decisão sobre a qual três times vão construir por anos precisa
de alguém cujo trabalho seja vê-la chegando.

## Registra

*Registra* quer dizer que a decisão sobrevive à reunião em que foi tomada. **Uma decisão que ninguém
escreveu vai ser tomada de novo**, por alguém que não sabe que ela já foi tomada, e talvez ao
contrário. Escrever também obriga o raciocínio a aparecer: uma decisão que não se explica numa
página quase sempre é uma decisão que ainda não foi entendida. A aula 5 apresenta o registro de
decisão de arquitetura e a aula 8 trata de manter a documentação viva. O hábito começa aqui.

## Responde

*Responde* quer dizer que, quando uma decisão estrutural dá errado, o arquiteto é uma das pessoas
que explicam o que aconteceu, por que a decisão parecia certa na época e o que muda agora. É o menos
visível dos três verbos e o que dá peso aos outros dois. A seção 04 desta aula é sobre ele.

## Por que a Carreto criou o papel

Durante anos a Carreto não teve arquiteto, e funcionou. Com um time, as decisões estruturais eram
tomadas por quem escrevia o código, na mesma sala. Com sete times há **21 pares de times**, e cada
par pode tomar uma decisão que afeta o outro sem que nenhum dos dois perceba. As costuras entre os
times não têm dono.

Tomás Viana, o CTO, criou o papel depois que três incidentes num trimestre tiveram a mesma forma. No
pior deles, o Matching e o Payments mudaram, na mesma semana, o jeito de guardar o status de uma
carga. Cada mudança foi revisada, testada e estava correta sozinha; juntas, fizeram o Payments ler
certas cargas canceladas como entregues, e quem encontrou o problema foi um embarcador, não a
Carreto. **Nenhum time tinha feito nada errado, e nenhuma pessoa era responsável pelo lugar em que
as duas mudanças se encontraram.** Essa lacuna é o que Tomás entregou a Renata.

## A primeira semana de Renata

Renata passa a primeira semana como arquiteta descobrindo qual é o trabalho na Carreto, não fazendo
o trabalho.

**Segunda-feira.** Ela se reúne com Tomás e pergunta o que ele espera. A resposta é curta: menos
incidentes nas costuras, decisões que as pessoas consigam encontrar depois, e times que não fiquem
mais lentos por causa dela. Ela anota as três; são a única definição de sucesso que tem.

**Terça-feira.** Ela pergunta a cada tech lead que perguntas em aberto envolvem outro time. Recebe
nove. Duas são sobre a tabela `loads`, uma é sobre o Matching ganhar banco próprio, uma é sobre
autenticação entre serviços, e cinco são menores. Nenhuma das nove tem dono.

**Quarta-feira.** Ela lê o sistema em vez dos documentos: manifestos de implantação, strings de
conexão, os consumidores do broker, um dia de traces. É aqui que o slide da integração da aula 2 se
desmancha.

**Quinta-feira.** Kátia Lemos, tech lead do Matching, pede que ela decida se o Matching deve ir para
um banco próprio. Renata fica tentada a responder — ela tem opinião, e responder mostraria que o
papel novo faz alguma coisa. Ela pede a Kátia uma semana e, antes, uma página descrevendo o
problema. A próxima seção explica por quê.

**Sexta-feira.** Ela escreve uma página e manda para os cinquenta engenheiros: para que serve o
papel, o que ele não é, e as nove perguntas em aberto com um dono proposto para cada uma. A página
diz com todas as letras que ela não vai aprovar pull requests, não vai gerenciar ninguém e não vai
decidir prioridades de produto.

## O que preenche as semanas de um arquiteto

A primeira semana de Renata é incomum, mas as atividades dela se repetem. Quase todo o resto deste
curso é uma delas:

| atividade | onde o curso trata dela |
|---|---|
| trabalhar em escopos diferentes, de um serviço à empresa inteira | aula 4 |
| tomar e registrar decisões de tecnologia e de estrutura | aulas 5 e 6 |
| descobrir do que o negócio de fato precisa | aula 7 |
| documentar, e manter verdadeiro | aula 8 |
| definir padrões e verificá-los automaticamente | aula 9 |
| trabalhar com times, produto e outras partes interessadas | aula 10 |
| aconselhar e desenvolver outros engenheiros | aula 11 |
| tirar complexidade em vez de acrescentar | aula 12 |
| equilibrar qualidade, prazo e custo; estimar | aulas 13 e 14 |
| continuar escrevendo código | aula 15 |

Duas coisas faltam na tabela de propósito. **O arquiteto não é o gestor dos engenheiros cujos
sistemas ele molda, e não é dono do que o produto faz.** Isso pertence a outras pessoas, e a aula 16
traça as fronteiras entre o arquiteto, o tech lead e o engenheiro sênior. A tabela é o que sobra
quando essas coisas saem, e é suficiente para um trabalho em tempo integral.

## O papel é definido pelas costuras

O que torna o papel necessário na Carreto não é falta de habilidade dos engenheiros. **É que as
decisões estruturais agora acontecem entre os times, e entre os times é onde ninguém estava
olhando.** Um arquiteto que passa todos os dias dentro do código de um time virou o engenheiro
sênior desse time. Um que nunca olha código nenhum virou o desenhista de diagramas do primeiro
parágrafo. O trabalho está nas costuras, e ele precisa tanto da visão de conjunto quanto de
profundidade suficiente em cada parte para merecer crédito. De onde vem esse crédito é o assunto da
próxima seção.
