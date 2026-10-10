---
title: Por que mais de uma máquina
version: 1
---

**Um sistema distribuído não é um computador mais rápido. São vários computadores que precisam
concordar entre si, através de uma rede que nem sempre entrega.** A imagem com que quase todo mundo
começa é a primeira: ponha mais máquinas no problema e ele anda mais rápido, na mesma proporção. Às
vezes anda. O que acontece sempre é que a segunda máquina traz problemas que a primeira nunca teve,
e esta aula é sobretudo sobre eles.

## Para cima ou para os lados

Há dois jeitos de ter mais capacidade do que se tem.

**Escalar para cima**, ou escalar verticalmente, troca a máquina por uma maior: mais núcleos, mais
memória, discos mais rápidos. Nada no software muda, e essa é a grande virtude, e ela para na maior
máquina que alguém vende. **Escalar para os lados**, ou horizontalmente, acrescenta mais máquinas do
mesmo tamanho. O teto é bem mais alto, e o preço é que todo programa envolvido precisa saber que
existe mais de uma delas.

Quatro motivos empurram um time para os lados em vez de para cima:

- os dados não cabem mais nos discos de uma máquina;
- o trabalho não cabe mais no tempo de uma máquina, e um relatório que precisa estar pronto às seis
  da manhã exige dez máquinas trabalhando ao mesmo tempo para ficar pronto a tempo;
- uma máquina é uma falha, e quando ela para, tudo o que depende dela para;
- as pessoas estão longe umas das outras, e uma cópia dos dados perto delas responde mais rápido do
  que uma do outro lado do oceano.

A Roda Livre não tem nenhum desses problemas. As doze estações e as noventa bicicletas produzem dados
que um notebook guarda com folga, e a regra de Davi é uma máquina até doer. Mesmo assim você precisa
desta aula, porque os serviços que um time de dados aluga são distribuídos por baixo: o data
warehouse de `warehouse-modeling`, o armazenamento de objetos de `cloud`, um log de mensagens como o
da aula 8. Quando eles se comportam de um jeito estranho, a estranheza costuma ser o assunto desta
aula aparecendo por baixo.

## Três coisas que uma máquina sozinha nunca teve

**Uma rede que perde mensagens.** Dentro de um programa, uma chamada de função retorna ou lança uma
exceção. Através de uma rede, um pedido pode se perder na ida, a resposta pode se perder na volta, e
qualquer um dos dois pode chegar atrasado. Para a máquina que fez o pedido, tudo isso parece a mesma
coisa: nenhuma resposta ainda. Quando o aplicativo pede ao provedor de pagamentos que cobre uma viagem
e não ouve nada, ele não sabe se o cliente foi cobrado. A seção 09 desta aula trata do que fazer
em seguida.

**Relógios que discordam.** Cada máquina tem o próprio relógio, e sincronizá-los pela rede os mantém
perto da hora certa, não nela. Digamos que o sensor da doca do Largo da Ordem esteja meio segundo
adiantado em relação ao servidor do aplicativo. Uma bicicleta é devolvida ali e retirada de novo um
instante depois, e o sensor carimba a devolução às 08:00:00.400 enquanto o servidor carimba a nova
retirada às 08:00:00.100: nos dados, a bicicleta saiu antes de chegar. A aula 8 encontra um primo
disso num fluxo, onde os eventos chegam numa ordem diferente daquela em que aconteceram.

**Falha parcial.** Uma máquina sozinha funciona ou não funciona. Cinco máquinas podem ter uma morta,
uma lenta e três bem, tudo ao mesmo tempo, e as três não têm como saber qual das outras duas é qual.
Um sistema feito delas precisa continuar funcionando no meio disso, e a seção 08 mostra por que isso
é mais difícil do que parece.

O resto da aula pega um de cada vez. O **particionamento** divide os dados para que cada máquina
guarde uma parte. A **replicação** copia cada parte para mais de uma máquina, para que perder uma
máquina não seja perder os dados. A **tolerância a falhas** é tudo o que mantém o sistema respondendo
enquanto uma parte dele está quebrada. A aula 10 faz a pergunta a que as três levam: quando a rede
separa as máquinas em dois grupos, do que o sistema abre mão?
