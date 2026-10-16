---
title: Três palavras que se usam como uma
version: 1
---

**A maioria das pessoas chega achando que garantia de qualidade quer dizer testar, e testar quer dizer
procurar defeito no fim.** Essa imagem não está errada sobre o que é teste. Está errada sobre quanto da
garantia de qualidade o teste cobre, e sobre quando qualquer parte dela acontece.

Três palavras se usam como uma, e separá-las é a primeira coisa útil que este curso pode te dar:

| | para o que olha | para que serve | quando |
|---|---|---|---|
| **garantia de qualidade** | o **processo**: como o trabalho é feito | **prevenir** que defeitos sejam feitos | desde a primeira conversa |
| **controle de qualidade** | o **produto**: o que o trabalho produziu | **detectar** defeitos que foram feitos | quando existe algo para examinar |
| **teste** | o produto, examinando-o ou rodando-o | achar defeitos, e informação sobre risco | onde houver algo para examinar |

O teste é a maior parte do controle de qualidade, e o controle de qualidade é metade da garantia de
qualidade. O glossário do ISTQB, o vocabulário em que a maioria das certificações de teste é escrita,
traça a mesma linha: garantia é **orientada a processo**, controle é **orientado a produto**. Num
anúncio de vaga as três palavras se misturam, e um "engenheiro de QA" passa a maior parte da semana
testando. A distinção importa mesmo assim, porque diz qual metade do trabalho está faltando quando um
time só faz uma.

## Prevenir

A prevenção age **antes de o defeito existir**. Trabalha no requisito, no projeto, nos hábitos do time,
para que menos erros sejam cometidos:

- um requisito lido em voz alta por alguém caçando o segundo sentido, como a seção anterior fez com
  *maiores de 60*;
- uma lista que o time combina que todo trabalho precisa cumprir antes de alguém chamá-lo de pronto, que
  a aula 12 chama de definição de pronto;
- uma revisão de código, em que uma segunda pessoa lê uma mudança antes de ela se juntar ao resto;
- uma regra que o time adota depois de um defeito, para que o mesmo tipo não aconteça duas vezes, que é
  o assunto da aula 18.

Nada disso roda o software, e várias dessas coisas acontecem antes de existir software para rodar.
Examinar um documento ou um projeto sem executar nada tem nome próprio, **teste estático**, e é a única
forma de teste que também previne.

## Detectar

A detecção age **depois de o defeito existir**, antes ou depois de um cliente topar com ele. Rodar o
programa com entradas escolhidas e comparar o que ele faz com o que deveria fazer é **teste dinâmico**,
e é o que a maior parte da prática deste curso é. Monitorar um sistema em produção também é detecção, a
mais tardia que existe.

A detecção tem um limite que nenhum esforço remove, e Edsger Dijkstra o pôs numa frase numa conferência
da OTAN em 1969: **o teste pode mostrar a presença de defeitos, nunca a ausência deles.** Quatro
respostas certas do `tickets.py` não provaram nada sobre a quinta entrada. Todo resultado de teste é uma
afirmação sobre as entradas que foram tentadas e nada mais, e é por isso que escolhê-las é uma
habilidade, e que as aulas 6, 19 e 20 tratam de escolher.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l01-two-halves\" aria-label=\"Uma fila de seis etapas da esquerda para a direita: ideia, requisito, projeto, código, entrega, em uso. Acima das etapas requisito, projeto e código fica uma faixa chamada prevenir, com três atividades: ler o requisito buscando um segundo sentido, revisar o projeto, revisar a mudança; nada roda. Abaixo das etapas código, entrega e em uso fica uma faixa chamada detectar, com três atividades: rodar com entradas escolhidas, verificar a entrega, observar em produção; o programa roda. As duas faixas se sobrepõem na etapa código.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ideia</text><rect x=\"128.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">requisito</text><path d=\"M121.0 148.0 L127.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"236.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"286.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">projeto</text><path d=\"M229.0 148.0 L235.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"344.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"394.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">código</text><path d=\"M337.0 148.0 L343.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"452.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"502.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">entrega</text><path d=\"M445.0 148.0 L451.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"128.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">em uso</text><path d=\"M553.0 148.0 L559.0 148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"128.0\" y=\"22.0\" width=\"316.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"136.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">prevenir</text><text x=\"436.0\" y=\"36.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estático: nada roda</text><text x=\"178.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ler buscando um</text><text x=\"178.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">segundo sentido</text><path d=\"M178.0 92.0 L178.0 126.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"286.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">revisar o</text><text x=\"286.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">projeto</text><path d=\"M286.0 92.0 L286.0 126.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"394.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">revisar a</text><text x=\"394.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">mudança</text><path d=\"M394.0 92.0 L394.0 126.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"344.0\" y=\"182.0\" width=\"316.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"352.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">detectar</text><text x=\"652.0\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dinâmico: o programa roda</text><text x=\"394.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rodar com entradas</text><text x=\"394.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">escolhidas</text><path d=\"M394.0 170.0 L394.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"502.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">verificar a</text><text x=\"502.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">entrega</text><path d=\"M502.0 170.0 L502.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"610.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">observar em</text><text x=\"610.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">produção</text><path d=\"M610.0 170.0 L610.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "A prevenção trabalha no que está sendo planejado e escrito, antes de haver algo para rodar. A detecção precisa de algo que rode, então começa no código e nunca termina."}
```

## Por que um time precisa das duas

Um time que só detecta paga cada erro duas vezes: uma para cometê-lo, e outra para achá-lo e consertá-lo,
e a segunda cresce quanto mais tarde é paga. Um time que só previne não tem como saber se a prevenção
funciona; uma revisão que nunca foi comparada com o que escapou dela é um ritual.

As duas se alimentam. Todo defeito que a detecção acha é uma pergunta para a prevenção: **por que isso
foi possível?** O ingresso da pessoa de sessenta anos é um defeito no `tickets.py`, e também é evidência
de que o time escreve requisitos com palavras que permitem duas leituras e ninguém os lê caçando a
segunda. Consertar o código conserta um defeito. Mudar como os requisitos são lidos conserta uma classe
deles.

Esse é o formato do trabalho que este curso descreve: achar defeitos, sim, e depois usar cada um para
tornar o próximo menos provável. Quem só os acha é útil. Quem também muda por que eles acontecem é a
pessoa que um time quer manter.
