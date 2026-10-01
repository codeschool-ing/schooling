---
title: A MAN, uma rede do tamanho de uma cidade
version: 1
---

Uma **MAN** (*metropolitan area network*, rede metropolitana) fica entre as outras duas: maior que uma
sede, menor que um país, e em geral do tamanho de uma cidade ou de uma região metropolitana. É a menos
precisa das cinco palavras, e você vai encontrá-la mais na tabela de preços de uma operadora do que
nos diagramas da própria empresa.

Três coisas são chamadas de MAN, e vale distingui-las:

- **A rede metropolitana de uma operadora.** Uma operadora passa fibra em volta de uma cidade — muitas
  vezes como um **anel**, a forma que a aula 3 cortou e viu se recuperar — e vende conexões aos prédios
  ao longo dela. Para a operadora, é parte da própria rede. Para o cliente, é um link de WAN com
  distância curta e velocidade alta.
- **Metro Ethernet.** Um serviço montado sobre essa fibra que entrega Ethernet comum entre dois ou mais
  prédios do cliente na mesma cidade. Do lado do cliente, o prédio distante parece estar na ponta de um
  cabo muito comprido, e as duas sedes podem até dividir uma LAN.
- **A rede de uma organização espalhada por uma cidade.** Uma prefeitura ligando suas escolas e seus
  hospitais, ou uma universidade ligando campi em bairros diferentes, às vezes em fibra própria e às
  vezes em fibra alugada.

**A posse decide qual das palavras anteriores se aplica**, como na seção de WAN. Uma universidade dona
da fibra entre os campi opera algo que se comporta como uma LAN muito grande; uma empresa que aluga
metro Ethernet de uma operadora está comprando um link de WAN que por acaso é curto e rápido. A palavra
MAN descreve mais a distância do que o arranjo.

O termo também vive no nome do órgão de padronização por trás da Ethernet e do Wi-Fi: o **IEEE 802
LAN/MAN Standards Committee**. É por isso que "LAN/MAN" aparece mais em documentos de padrões do que em
qualquer outro lugar.

## O que o laboratório não mostra

Nada no laboratório deste curso é uma MAN. Uma cidade inteira de fibra não tem imitação útil num só
computador, e nenhuma foi tentada. O que o laboratório consegue mostrar é a propriedade que faz a fibra
metropolitana valer a pena como anel — duas saídas de cada prédio — e a aula 3 mediu isso: o anel perdeu
19 de 30 pings quando um cabo foi cortado, e depois seguiu pelo outro lado.

Quando um chamado diz "o link para o outro prédio caiu", a primeira pergunta útil é a que esta aula
continua fazendo: **de quem é o link?** Se é fibra da própria empresa, o defeito é seu para achar. Se é
um serviço metropolitano de uma operadora, o próximo passo é o número do chamado na operadora, e as
evidências que você junta — um traceroute que para no seu próprio roteador, uma luz de link que apagou
num minuto conhecido — são o que faz esse chamado andar.
