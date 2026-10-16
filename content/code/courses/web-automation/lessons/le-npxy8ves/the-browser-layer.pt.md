---
title: O que merece um lugar na camada do navegador
version: 1
---

A ideia errada é que um teste de navegador é o teste mais realista, então o mais valioso, então uma
verificação é melhor quanto mais perto do usuário ela roda. Ele é realista. **O que um teste de
navegador compra é a costura**: a página, o servidor e o navegador rodando juntos, como nada mais
numa suíte os roda. Uma verificação que não precisa da costura paga por ela mesmo assim e não leva
nada pelo dinheiro.

Então a camada do navegador se decide por uma pergunta, feita a toda verificação antes de ela ser
escrita ali: **uma camada mais barata conseguiria ver isto?** Se sim, ela desce. Se não, ela ganhou
o seu lugar.

## O que pertence a ela

- Uma jornada, de ponta a ponta. Abrir a loja, pôr uma banana, ler o total. Um teste por caminho
  que um cliente de fato percorre, e primeiro os caminhos que pagam as contas. É o teste que falha
  quando qualquer coisa na corrente está quebrada, que é o que você quer dos poucos testes do topo.
- A costura entre a página e o servidor. O primeiro defeito desta aula morava ali: o servidor
  respondeu 590 e estava certo, e a página desenhou R$ 590,00. Nada abaixo do navegador lê o que a
  página desenha.
- O que só um navegador faz. O cache da aula 4, o service worker da aula 5, os botões da aula 6 que
  não faziam nada durante um segundo e meio e a cesta da aula 7 larga demais para um celular. Cada
  um é invisível para uma requisição e para uma função, porque cada um é algo que o navegador faz com
  a resposta depois que ela chega.
- O que uma pessoa percebe e opera. Foco, teclado, o que está visível e o que está coberto. As aulas
  12 a 15 de `non-functional-testing` tratam de acessibilidade a sério; aqui o ponto é só que ela
  mora nesta camada.

## O que não pertence

- Aritmética. `total()` é uma regra sobre números, e três casos de unidade cravaram o que o teste
  de navegador deixou passar. Um teste de navegador de aritmética é um teste de unidade lento com
  mais jeitos de falhar.
- Regras de validação. Se um nome já usado é recusado é uma resposta do servidor, `409`, e a aula
  15 a encontrou. Um teste de navegador mostra que a recusa chega à tela; todo outro caso do que o
  servidor aceita e recusa pertence à camada que decide.
- Toda combinação de entradas. É aqui que a aritmética da seção de custo deixa de ser teoria. A loja
  tem oito produtos, e uma cesta com de zero a três de cada um é uma de 4 multiplicado por si mesmo
  oito vezes, 65.536 cestas. Aos 281 ms que o teste de navegador levou para um clique, elas
  custariam 65.536 × 0,281 = 18.416 s, mais de cinco horas, antes de contar os cliques extras que
  uma quantidade pede. A no máximo 1 ms cada, a camada de unidade as roda em uns 66 segundos. Mesmo
  ali você não escreveria todas: escolheria os casos que têm algo a dizer (vazia, uma, várias de um,
  várias de muitos), e eles seriam casos de unidade.

## O teste que desceu, e o que ele perdeu

Descer uma verificação também não sai de graça, e a aula 6 tem o caso a lembrar. O HTML de `/ssr`
esteve certo o tempo todo, então o teste por requisição passou, durante o segundo e meio em que
todo botão da página não fazia nada. **Uma verificação descida para baixo do navegador mantém o
assunto e perde a costura.** Se a costura era o assunto, o teste mais barato é um teste de outra
coisa.

Então a regra tem duas metades, e a segunda é a que se esquece. Empurre cada verificação para a
camada mais barata que consegue vê-la, e mantenha ao menos um teste de navegador sobre cada costura,
porque esse teste é o único que a atravessa. Na quitanda isso é uma lista curta: a jornada que esta
aula mediu, a espera pela hidratação da aula 6, o transbordamento da aula 7 e os poucos outros que
as aulas anteriores defenderam cada uma. A aula 22 leva o mesmo julgamento um passo adiante, até o
teste que não deveria ser escrito.
