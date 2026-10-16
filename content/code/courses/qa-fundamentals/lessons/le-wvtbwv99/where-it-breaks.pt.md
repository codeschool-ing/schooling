---
title: Onde a sequência quebra
version: 1
---

**A cascata e o modelo V compartilham uma suposição, e a maior parte dos problemas deles vem dela: que os
requisitos podem ser conhecidos por completo no começo e não vão mudar.** Quando isso vale, a sequência é
eficiente. Quando não vale, o que para a maior parte do software é a maior parte do tempo, a sequência
transforma cada mudança numa viagem de volta ao topo do desenho.

## Três jeitos de quebrar

**Os requisitos mudam.** A Joana escreve a regra de preço em janeiro. Em março, o cinema decide oferecer um
desconto de fidelidade. Num projeto sequencial, essa mudança volta à fase de requisitos, passa pelo projeto,
entra num código já escrito, e depois atravessa todos os níveis de teste de novo. O custo de uma mudança
depende de quanto o projeto já desceu pelo V, que é a curva da aula 3 de outro jeito.

**O retorno chega tarde.** A primeira vez que alguém de fora do time usa a loja é no teste de aceitação, no
fim. Se a reação da Célia à primeira tela é *"ninguém no balcão entenderia isto"*, o time descobre depois de
a tela, e tudo atrás dela, ter sido construído. O próprio alerta de Royce era exatamente sobre isso.

**O teste é espremido.** O teste é a última fase antes de uma data fixa. Todo atraso nas fases acima sai do
tempo do teste, e a fase mais cortada é aquela cujo trabalho é dizer se o resto funcionou. Quem testa em
projetos em cascata aprende a planejar uma fase de teste com metade da duração da que está no cronograma.

## Respostas parciais dentro do modelo

Times que precisam trabalhar em sequência acharam jeitos de amenizar isso:

- **projetar testes na descida**, como a seção anterior descreveu, para que o lado direito do V esteja
  pronto no dia em que o código chega e as ambiguidades sejam achadas ao escrevê-los;
- **o modelo W**, proposto por Andreas Spillner por volta de 2000, que desenha um segundo V de atividades de
  teste correndo em paralelo ao desenvolvimento: revisar cada documento enquanto é escrito já é um teste, no
  mesmo momento em que o documento é produzido;
- **revisões e inspeções em cada fase**, que são o teste estático da aula 1, pegando defeitos em requisitos e
  projetos sem esperar pelo código.

As três são prevenção parafusada num processo desenhado em torno da detecção. Ajudam, e mantêm a sequência.

## A outra resposta

A resposta mais radical é parar de supor que os requisitos podem ser conhecidos no começo: construir uma
parte pequena, mostrar a alguém, aprender, e construir a parte seguinte com o que se aprendeu. O próprio
Royce sugeriu fazer tudo duas vezes. Os modelos das próximas aulas, a espiral e depois a família ágil, pegam
essa ideia e fazem dela o processo inteiro. Para quem testa, a mudança é menos de técnica que de ritmo: em
vez de uma longa fase de teste no fim, uma curta em cada ciclo, o tempo todo.
