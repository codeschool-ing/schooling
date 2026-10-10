---
title: O que é explorar
version: 1
---

O teste exploratório tem uma fama que não merece: clicar por aí sem plano, o que uma equipe faz
quando ninguém escreveu casos de teste, impossível de repetir e impossível de relatar. Muito clique
sem plano anda com esse nome, e é assim que a fama foi conquistada. **O que o nome quer dizer é mais
estreito e mais disciplinado: aprender sobre o produto, desenhar testes e executá-los, tudo ao mesmo
tempo, com cada resultado decidindo o próximo teste.**

## Roteirizado e exploratório

No teste roteirizado as três atividades acontecem em ordem, e em geral por pessoas diferentes em
momentos diferentes. Alguém desenha os casos a partir dos requisitos, como as aulas 2 a 5 fizeram,
escreve cada um com o resultado esperado, e depois alguém os executa. O desenho termina antes da
primeira execução. Essa é a força dele: um caso pode ser executado por um estranho, executado de novo
na próxima versão, e contado.

No teste exploratório o desenho nunca termina antes. A Ana tenta alguma coisa, lê o que a aplicação
responde, e essa resposta decide o passo seguinte. Uma mensagem estranha a faz tentar a mesma ação a
partir de outro estado; um estado que aceita demais a faz procurar os vizinhos dele. O termo foi
cunhado por Cem Kaner nos anos 1980, e a definição curta de James Bach é a que a maioria das equipes
cita: **aprendizado, desenho de teste e execução de teste simultâneos**.

Os dois são pontas de uma mesma linha, e não dois times. Um caso roteirizado com "tente alguns outros
valores aqui" escrito nele andou um pouco na direção da exploração; uma sessão exploratória que
começa com uma lista de perguntas andou um pouco na direção do roteiro. Quase todo teste real fica em
algum lugar no meio, e a decisão útil é onde nessa linha cada parte de um produto deve ficar nesta
semana.

## Por que uma equipe faz os dois

Um roteiro confere o que alguém pensou em escrever. **Os defeitos que os roteiros deixam passar são
os que ninguém pensou em perguntar**, e eles são boa parte do que chega aos clientes. As aulas 4 e 5
encontraram os defeitos do boxoffice trabalhando de forma sistemática a partir do R4, do R5 e do R6.
Nada nesses requisitos diz como deve ser a mensagem de uma ação recusada, além do "uma frase dizendo
o que está errado" do R7, nem como um reembolso deve se comportar à medida que a noite avança. Um
roteiro escrito a partir do R6 faz exatamente o que o R6 diz e para aí. Quem explora continua.

A exploração rende mais em quatro lugares:

- uma funcionalidade nova, em que ninguém sabe ainda quais devem ser os casos;
- uma área em que todos os casos roteirizados passam, mas que continua gerando reclamações;
- onde os requisitos são ralos, e um roteiro só os repetiria;
- em volta de um defeito recém-encontrado, porque defeitos andam em grupo, e o código que produziu um
  foi escrito pela mesma pessoa, na mesma semana, sob a mesma pressão.

Ela não substitui os roteiros. O que uma sessão encontra não é uma verificação de regressão: na
semana que vem ninguém consegue rodar de novo "o que a Ana por acaso tentou". **O que uma sessão
exploratória encontra vira casos**, relatórios de defeito e novas perguntas, e os casos entram nas
suítes da aula 10.

## Exploração com estrutura

A resposta para "impossível de planejar e relatar" é uma estrutura de 2000, a **gestão de teste
baseada em sessões**, descrita por Jonathan e James Bach. A exploração acontece em **sessões**: um
bloco de tempo sem interrupção com uma missão, escrita antes de começar, notas feitas durante, e uma
conversa curta no fim. Cada sessão deixa uma folha, então um gerente consegue contar sessões por área
como conta casos, e um testador consegue mostrar para onde foi o tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" data-fig=\"l11-session-loop\" aria-label=\"Um ciclo de três caixas, da esquerda para a direita: uma missão, escrita antes; uma sessão de 60 a 120 minutos com notas; uma conversa final usando PROOF. A conversa final aponta para três saídas: relatórios de defeito, casos de regressão e novas missões. Uma seta vai de novas missões de volta à caixa da missão, com o rótulo a próxima sessão.\"><defs><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"82.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"103.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">missão</text><text x=\"90.0\" y=\"118.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escrita antes</text><rect x=\"200.0\" y=\"82.0\" width=\"180.0\" height=\"58.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"103.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sessão</text><text x=\"290.0\" y=\"118.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">60 a 120 minutos, com notas</text><rect x=\"404.0\" y=\"82.0\" width=\"140.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"474.0\" y=\"103.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">conversa final</text><text x=\"474.0\" y=\"118.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">PROOF, 10 a 15 minutos</text><path d=\"M160.0 111.0 L198.0 111.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M380.0 111.0 L402.0 111.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"574.0\" y=\"22.0\" width=\"118.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"633.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">relatórios de defeito</text><path d=\"M544.0 111.0 L572.0 42.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"574.0\" y=\"86.0\" width=\"118.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"633.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">casos de regressão</text><path d=\"M544.0 111.0 L572.0 106.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"574.0\" y=\"150.0\" width=\"118.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"633.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">novas missões</text><path d=\"M544.0 111.0 L572.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M633 190 L633 218 L90 218 L90 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"365.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a próxima sessão</text></svg>", "caption": "Gestão de teste baseada em sessões. Cada sessão tem uma missão, e a conversa final transforma as notas em relatórios, casos e as missões das sessões seguintes."}
```

As quatro partes são as próximas quatro seções desta aula: a missão, chamada de **charter** em
inglês (seção 03); as **heurísticas** que sugerem o que tentar quando a missão sozinha não basta
(seção 04); uma **sessão** de verdade no boxoffice 1.1, com as notas dela (seção 05); e a **conversa
final**, o *debrief*, que transforma as notas em decisões (seção 06). O plano da aula 1 para o
boxoffice já pedia uma sessão exploratória por área; esta aula roda a primeira.
