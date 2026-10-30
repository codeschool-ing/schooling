---
title: Projete para uma faixa de janelas, não para um celular
version: 1
---

**Um app não sabe em que formato vai ser desenhado, então um layout é projetado para uma faixa de
tamanhos e não para um aparelho.** A imagem comum são dois layouts, um para celular e outro para
tablet, escolhidos quando o app começa perguntando que tipo de aparelho ele é. Essa imagem falha no
primeiro dobrável, e a documentação do Android sobre classes de tamanho de janela diz isso com
todas as letras: as classes não são determinadas pelo tamanho da tela do aparelho, e não servem
para uma lógica do tipo "isto é um tablet".

## A janela, não a tela

O espaço que um app recebe é a **janela** dele, e num celular moderno a janela e a tela muitas
vezes têm tamanhos diferentes. Estas são as formas comuns de elas se separarem:

| o que acontece | o que o app vê |
|---|---|
| o usuário vira o celular | largura e altura trocam; uma janela alta vira uma baixa e larga |
| um dobrável abre ou fecha | a janela salta de tamanho de celular para quase tamanho de tablet, ou volta |
| tela dividida, no Android ou no iPad | o app fica com metade da tela, ou um terço, e o usuário pode arrastar a divisa |
| uma janela num desktop, num Chromebook ou num iPad em modo janela | qualquer tamanho até onde o usuário arrastar |
| uma segunda tela é conectada | a janela vai para uma tela com outro tamanho e outra densidade |

A documentação do Android sobre o modo de várias janelas lista as formas que ele assume: dois apps
lado a lado ou um sobre o outro na tela dividida, um app numa janela pequena de picture-in-picture,
e apps em janelas separadas que se movem e mudam de tamanho. As Human Interface Guidelines da Apple
listam a mesma família para iOS e iPadOS: tamanhos de tela diferentes, orientações, janelas
redimensionáveis no iPad e no Mac, e telas externas, tudo como coisas que um layout precisa
aguentar.

**Então "a tela tem 360 dp de largura" nunca é um fato que o app possa guardar.** É o tamanho
agora. A pergunta certa é feita de novo sempre que a janela muda, e no Android cada mudança da
tabela é uma mudança de configuração, o evento que a aula 4 descreveu como o sistema reconstruindo
a tela.

## Uma faixa tem duas pontas e um meio

Projetar para uma faixa quer dizer decidir três coisas, e vale separá-las porque elas falham de
jeitos diferentes:

- O que estica. Uma lista ocupa a largura que recebe; um campo de texto cresce; uma imagem escala.
  A seção depois da próxima trata disso.
- O que fica fixo. Um alvo de toque tem 48 dp em qualquer janela, e as classes de tamanho não
  mudam isso. A aula 7 explica por quê.
- Onde o layout muda de forma. Em alguma largura, uma coluna de conteúdo vira duas, ou uma barra
  de abas vira um trilho na lateral. Esses pontos são as classes de tamanho da próxima seção.

As duas primeiras tratam de um layout que se dobra. A terceira trata de trocar para outro layout, e
é a que precisa de uma regra, porque sem ela cada tela do app acaba escolhendo os próprios pontos de
quebra e o app muda de forma em cinco larguras diferentes.

**Travar a orientação não é uma saída.** Um app pode pedir para ficar só em retrato, e as diretrizes
da Apple lembram que mesmo um app travado numa orientação ainda precisa se redimensionar bem, porque
as janelas mudam por motivos que não têm nada a ver com virar o celular. A tela dividida dá a um app
travado em retrato uma janela mais larga do que alta, ou pouco mais larga que um botão.
