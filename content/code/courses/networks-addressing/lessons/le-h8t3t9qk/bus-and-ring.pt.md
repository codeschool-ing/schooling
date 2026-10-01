---
title: Barramento e anel, as formas de um cabo compartilhado
version: 1
---

Antes de os switches ficarem baratos, uma rede local era **um meio compartilhado**: um único cabo, ou
uma única volta, que todas as máquinas usavam por turnos. Duas formas saíram daí, o barramento e o
anel. Nenhuma das duas é montada num escritório hoje, e nenhuma rodou no laboratório deste curso,
mas as duas explicam palavras que você ainda encontra — *colisão*, *terminador*, *token* — e as duas
mostram a falha que a estrela foi adotada para evitar.

## O barramento

Num **barramento**, cada máquina se liga a um único cabo que passa por todas elas. A Ethernet antiga
era exatamente isso: o **10BASE5**, um cabo coaxial grosso de até 500 metros, e depois o **10BASE2**,
um mais fino de até 185 metros, com um conector em T em cada máquina. Cada ponta do cabo levava um
**terminador**, um resistor que absorve o sinal; sem ele, o sinal batia na ponta aberta, voltava e
corrompia tudo o que estava no fio.

Um barramento é um broadcast por construção. Um quadro que uma máquina envia percorre o cabo
inteiro, e toda máquina o lê e guarda só o que é endereçado a ela. Só uma máquina pode transmitir por
vez, então duas que começam juntas **colidem**, os dois sinais se embaralham, e as duas tentam de novo
depois de uma espera aleatória. Essa regra se chama CSMA/CD, e a aula 18 mostra o que é um domínio de
colisão e por que os switches o fizeram desaparecer.

**O barramento falha inteiro.** Uma quebra em qualquer ponto do cabo deixa duas pontas abertas sem
terminador, as reflexões estragam as duas metades, e toda máquina ligada a ele perde a rede — não só
as que ficaram depois da quebra. Um conector em T frouxo atrás da mesa de alguém bastava, e achá-lo
queria dizer percorrer o cabo a pé.

## O anel

Num **anel**, cada máquina é ligada a exatamente dois vizinhos e as ligações se fecham numa volta.
Nos anéis compartilhados dos anos 1980 e 1990, um quadro dava a volta de máquina em máquina até
chegar de novo a quem o enviou.

O **Token Ring** (IEEE 802.5) resolveu o problema da colisão com uma regra: um quadro pequeno chamado
**token** circula, e só a máquina que está com ele pode transmitir. Nenhuma colisão, e a vez de cada
um garantida. O **FDDI** usava dois anéis de fibra girando em sentidos opostos, de modo que uma
quebra podia ser contornada mandando o tráfego de volta pelo segundo anel.

Um anel simples tem a fraqueza do barramento em outra forma: **uma quebra abre a volta**, e num anel
único nada mais dá a volta. Por isso o Token Ring era cabeado fisicamente em estrela, com cada estação
ligada a uma caixa central que fechava a volta por dentro e a fechava de novo quando uma estação era
desconectada — o anel lógico e a estrela física da seção anterior.

## O que sobrou deles

Dentro dos prédios, os dois perderam para a Ethernet sobre uma estrela de switches, por motivos que a
próxima seção põe no laboratório. As ideias sobrevivem em outros lugares:

- **Os anéis** estão vivos na fibra metropolitana, onde uma operadora passa fibra em volta de uma
  cidade para que um cabo cortado possa ser contornado pelo outro lado. A aula 4 os encontra com o
  nome de MAN, e o anel do laboratório desta aula é uma versão moderna: um anel de roteadores, cada
  cabo um link próprio, que não é um meio compartilhado.
- **Os barramentos** estão vivos em máquinas que não são redes de computadores no sentido deste
  curso: o barramento CAN, que liga as centrais eletrônicas de um carro, é um único par de fios
  compartilhado com um terminador em cada ponta.

Se você encontrar Ethernet coaxial num escritório em funcionamento hoje, a frase útil é que ela é um
ponto único de falha do comprimento do prédio.
