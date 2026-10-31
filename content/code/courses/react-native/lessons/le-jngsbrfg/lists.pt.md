---
title: Listas que continuam suaves
version: 1
---

A aula 7 mostrou por que a `FlatList` existe: ela cria as linhas perto da tela e não as mil atrás delas. A
última seção viu o mesmo pelo outro lado, cinco linhas de cinquenta. **Uma lista engasga quando um quadro
precisa de linhas que ela ainda não fez**, e as props que decidem quantas ela faz, e quando, são as
ferramentas:

- **O `initialNumToRender`**, 10 por padrão, é quantas vagas a primeira renderização faz. O bastante para
  encher a tela uma vez é o certo; mais atrasa o primeiro quadro.
- **O `windowSize`**, 21 por padrão, medido em telas: quanto da lista fica renderizado em volta da parte
  visível, dez telas acima e dez abaixo. Uma janela menor poupa memória e trabalho e mostra linhas em branco
  mais cedo num arraste rápido.
- **O `maxToRenderPerBatch`** e o **`updateCellsBatchingPeriod`** decidem quantas linhas são feitas por
  passada durante a rolagem, e com que frequência.
- **O `getItemLayout`**, quando toda linha tem a mesma altura, diz à lista onde está a linha 500 sem medir
  as 499 anteriores, então rolar até ela, ou pular com a barra de rolagem, não precisa do layout das linhas
  no meio.
- **O `keyExtractor`**, da aula 7, impede o React de reconstruir linhas que só mudaram de lugar.

**E a própria linha é a maior parte.** Uma lista renderiza linhas o tempo todo enquanto rola; uma linha que
renderiza rápido e raramente, o `memo` e os callbacks estáveis das duas últimas seções, vale mais que
qualquer um desses números.

**A FlashList**, da Shopify, segue outro caminho: ela recicla as views nativas das linhas que saíram da tela
para as linhas que entram, como o `RecyclerView` do Android e o `UICollectionView` do iOS fazem nativamente,
em vez de criar novas. Para listas longas de linhas parecidas, ela costuma ser o ganho maior. *As listas do
planner são curtas, então este curso não a instalou.*
