---
title: Onde o TDD sofre
version: 1
---

**O TDD supõe que você consegue dizer o que o código deve fazer antes de ele existir, num exemplo
que uma máquina confere, em poucos segundos.** Onde essa suposição vale, o método é difícil de
superar. Onde ela falha, forçar o laço custa tempo e produz testes que dizem pouco. Saber qual é o
caso faz parte de usá-lo bem, e a lista honesta é mais longa do que os entusiastas admitem.

## Quando você ainda não sabe o que quer

Uma primeira tentativa com uma biblioteca desconhecida, um protótipo de tela, uma pergunta como "o
SQLite faz isso rápido o bastante?": a resposta a *o que o teste deve afirmar?* é justamente o que
você está tentando descobrir. O conselho do próprio Beck é um **spike**: escreva código descartável
para aprender, sem testes, depois apague e recomece guiado por testes com o que aprendeu. Apagar é a
parte que todo mundo pula, e um spike que vai para produção vira código sem teste que ninguém
projetou.

## Quando a saída certa não pode ser escrita antes

Alguns resultados são reconhecidos em vez de previstos. Um layout de página parece certo ou não. Uma
lista de recomendações é boa ou fraca. Uma simulação numérica produz uma curva cujos valores exatos
ninguém sabia antes de rodar. Você não consegue escrever `assertEqual(result, ...)` primeiro quando
não sabe o lado direito. Essas áreas usam outras verificações: uma propriedade que sempre tem de
valer (uma multa total nunca é negativa), uma saída gravada que uma pessoa aprovou uma vez e que é
comparada em toda execução seguinte, ou uma tolerância em torno de um resultado conhecido.

## Quando o código não tem costuras

TDD em código novo é agradável porque os testes moldam o código. Numa base antiga o código já está
moldado, muitas vezes em torno de globais, relógios escondidos e chamadas ao banco dentro de laços,
exatamente as coisas que a seção anterior sobre projeto mostra um teste empurrando para fora. Você
não consegue escrever um teste pequeno que falha para uma função que não consegue chamar sozinha. O
caminho de entrada é fixar primeiro o comportamento atual, com testes de caracterização, e abrir
costuras uma de cada vez sob a proteção deles. A lição 14 faz exatamente isso com um relatório
legado.

## Quando a falha não se repete

Uma corrida entre duas threads aparece uma vez em mil execuções, numa máquina carregada, e nunca
quando você está olhando. Um teste que falha uma vez em mil não é um passo vermelho sobre o qual dá
para agir, e uma execução verde quase não prova nada. Concorrência precisa de um projeto que torne a
corrida impossível, que é o assunto da lição 18, mais do que de um teste mais esperto.

## Quando os testes estão soldados à implementação

A seção anterior mostrou um jeito de isso acontecer: mocks que copiam as suposições do código. A
forma mais ampla é uma suíte que afirma *como* em vez de *o quê*, métodos privados testados
diretamente, contagem de chamadas conferida, estruturas de dados internas inspecionadas. **Uma suíte
assim deixa a refatoração mais lenta, não mais segura**, porque toda mudança estrutural deixa testes
vermelhos sem que comportamento algum tenha mudado. É o contrário do que o terceiro passo precisa.

## O que as medições dizem

O TDD foi mais estudado do que a maioria das práticas, e os resultados são mistos de um jeito que
vale conhecer com precisão. Em 2008, Nachiappan Nagappan e colegas acompanharam quatro equipes da
Microsoft e da IBM que o adotaram. A densidade de defeitos antes do lançamento caiu de 40 a 90 por
cento em comparação com projetos parecidos, e os gerentes estimaram que o desenvolvimento levou de 15
a 35 por cento mais tempo. Outros estudos, muitos com estudantes em tarefas pequenas, acharam efeitos
menores ou nenhum.

Um resultado posterior explica parte da discordância. Davide Fucci e colegas, estudando
profissionais em 2017, viram que a ordem de escrever teste e código não explicava as diferenças de
qualidade nem de produtividade. O que explicava era trabalhar em passos curtos e constantes. Lido
assim, a parte mais valiosa do método pode ser o ritmo de passos pequenos e verificados, e a regra
do teste primeiro é o jeito mais confiável que alguém achou de mantê-lo.

| onde o TDD cabe | onde outra coisa vai na frente |
|---|---|
| regras de domínio com exemplos claros: multas, prazos, limites | explorar uma biblioteca ou ideia desconhecida: spike primeiro |
| um relato de bug, escrito como teste que falha antes da correção | layout, saída visual: aprovação e revisão |
| código novo com colaboradores que você controla | código legado sem costuras: testes de caracterização primeiro |
| código que vai ser mudado com frequência por várias pessoas | corridas e temporização: elimine pelo projeto (lição 18) |

A coluna da esquerda é a maior parte do que um desenvolvedor back-end escreve num dia comum, e é por
isso que o método durou.
