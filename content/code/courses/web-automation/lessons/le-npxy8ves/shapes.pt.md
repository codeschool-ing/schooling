---
title: Pirâmide, cone e troféu
version: 1
---

Três desenhos aparecem toda vez que uma equipe discute seus testes, e a aula 1 de `testing-cicd`
apresenta os três para um projeto em Python. **Cada um é uma afirmação sobre onde o dinheiro deve
ir**, e aqui a pergunta é mais estreita: o que cada um diz da camada do topo, a que tem o navegador
dentro.

## A pirâmide

Mike Cohn desenhou a pirâmide de automação de testes em *Succeeding with Agile* (2009): uma base
larga de testes de unidade, uma camada do meio que ele chamou de testes de serviço e um topo fino de
testes pela interface. **A afirmação dela é sobre custo por teste**, e é a afirmação que a seção
anterior mediu. Uma verificação que pode morar mais embaixo deve morar, porque embaixo é mais rápido,
falha por menos motivos e aponta mais perto da causa.

A leitura errada mais comum é que a pirâmide fixa uma proporção. Um post do Google Testing Blog de
2015 sugeriu uma divisão de 70, 20 e 10 por cento como ponto de partida, e os números viajaram mais
longe que as palavras em volta deles. **O desenho diz que o topo é estreito; não diz o quanto.**
Nada nele diz se a quitanda quer três testes de navegador ou trinta.

## O cone de sorvete

A pirâmide de cabeça para baixo: poucos testes de unidade, alguns de serviço, uma faixa larga de
testes de navegador e uma bola de teste manual por cima. Alister Scott deu o nome por volta de 2012,
como retrato do que evitar, e é no que uma suíte se transforma quando a automação começa depois de o
código estar escrito e a única porta para o produto é a tela.

**O cone é uma descrição, não uma estratégia**: ninguém o defende. O custo dele é o que esta aula
mediu, pago em cada teste. Uma suíte de testes de navegador roda o navegador para cada verificação,
inclusive as de aritmética, e o defeito em `total()` de duas seções atrás é justamente do tipo que
ela trata mal. O teste de navegador passou por cima dele porque comprou uma banana só.

Vale reconhecê-lo por um motivo que não tem nada a ver com culpa. **Este curso montou um.** Quase
todo teste que você salvou desde a aula 1 dirige uma página, porque o curso é sobre a camada do
navegador. Um punhado nas aulas 4, 6 e 15 fala só HTTP, e `unit/total.test.js` é o primeiro que não
sobe servidor nenhum. Isso é certo para um curso de automação de navegador e errado para a suíte de
um produto, e a diferença é o ponto desta aula.

## O troféu

Kent C. Dodds desenhou o troféu de testes em 2018 para front-ends em JavaScript: uma base de
verificações estáticas (tipos e lint), uma camada pequena de testes de unidade, uma **faixa larga de
testes de integração** e um copo pequeno de testes de ponta a ponta no alto. O argumento é que, num
front-end, a maioria dos defeitos mora no encaixe entre as peças, então a faixa que testa as peças
juntas compra mais confiança por segundo.

Lido com cuidado, o troféu concorda com a pirâmide sobre o topo. Os testes de integração dele
desenham componentes num DOM escrito em JavaScript, o jsdom, que a aula 11 apresentou: sem layout,
sem pintura, sem navegador de verdade. **O copo de ponta a ponta também é pequeno no troféu.** Onde
os dois discordam é no meio, e essa é uma discordância sobre onde os defeitos de um produto costumam
morar.

## O que a evidência daqui sustenta

Os dois defeitos desta aula não escolhem um vencedor, e seria desonesto fazê-los escolher. Um morava
numa regra (a aritmética), e a camada mais barata o pegou. O outro morava na costura entre a página e
o servidor (centavos mostrados como reais), e só a camada que atravessa essa costura o viu. Um
produto cujos defeitos são na maioria do primeiro tipo quer uma base larga. Um cujos defeitos são na
maioria do segundo quer um meio largo, e um front-end que é quase só cola é esse produto.

**Aquilo em que toda forma concorda é o topo**, e essa concordância vem da medição, não do desenho:
a camada do navegador custou mais por teste, e nada na quitanda vai mudar isso. Então a pergunta que
importa para quem testa navegador não é que forma pendurar na parede. É que verificações merecem um
lugar no topo, e esse é o assunto da próxima seção.
