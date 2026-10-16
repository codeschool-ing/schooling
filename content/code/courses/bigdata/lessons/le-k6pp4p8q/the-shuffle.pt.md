---
title: O que um shuffle custa
version: 1
---

**Um shuffle se paga em três moedas: disco, rede e memória.** Cada tarefa do estágio anterior ordena
ou faz hash das suas linhas pela partição de destino e as escreve no disco local do seu executor, num
arquivo. Cada tarefa do estágio seguinte busca a sua parte em cada um desses arquivos, pela rede num
cluster de verdade, e mescla o que buscou na memória, despejando em disco se não couber.

O custo cresce com os bytes que atravessam, e eles dependem menos da entrada do que da chave. Os dois
agrupamentos da seção 02 leram as mesmas 24 milhões de linhas:

| | chaves distintas | shuffle escrito |
|---|---|---|
| por tipo | 4 | 0,0 MiB |
| por visitante | 1.729.141 | 34,6 MiB |

**A agregação parcial é o motivo.** Cada uma das 15 tarefas de leitura conta as suas linhas por chave
antes de escrever, o `partial_count` da aula 6. Com quatro tipos, cada tarefa escreve quatro linhas.
Com 1,7 milhão de visitantes, espalhados pelo ano inteiro, cada tarefa encontra uma boa parte deles e
escreve uma linha para cada: a contagem parcial quase não encolhe nada. **Um agrupamento por uma chave
com poucos valores sai quase de graça no shuffle; um agrupamento por uma chave com muitos valores paga
por quase toda linha.**

Nesta máquina 34,6 MiB atravessam em menos de um segundo, porque "a rede" é memória. Num cluster de
máquinas separadas com uma rede de 10 gigabits, cerca de 1,2 GB por segundo no melhor caso, o mesmo
shuffle com mil vezes os dados, 35 GB, leva meio minuto só para atravessar, se nada mais usar a rede.
Essa é a lentidão que a aula 1 disse que o laboratório não consegue mostrar, e o motivo de o resto
desta aula e a próxima tratarem de encolher shuffles ou evitá-los.
