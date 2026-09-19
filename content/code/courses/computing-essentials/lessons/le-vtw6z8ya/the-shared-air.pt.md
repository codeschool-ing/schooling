---
title: Alcance, velocidade e energia, que puxam uns contra os outros
version: 1
---

Tudo nesta aula é um rádio menos um, e todo rádio faz a mesma troca de três lados. Não dá para
ter tudo, e saber em que canto uma tecnologia se senta explica quase todo o resto sobre ela.

| | alcance | velocidade | energia |
|---|---|---|---|
| **Wi-Fi** | uma casa | `100 Mb/s` a `1 Gb/s` na prática | uma tomada |
| **Bluetooth** | um cômodo | `1` a `3 Mb/s` | uma pilha-moeda por meses |
| **Bluetooth LE** | um cômodo | `0,3 Mb/s` | uma pilha-moeda por anos |
| **NFC** | 4 centímetros | `0,4 Mb/s` | nenhuma na etiqueta |
| **infravermelho** | linha de visada | lento, e sem uso para dados | duas pilhas AAA por anos |

Leia como uma diagonal: **quanto mais longe vai, mais custa manter.** Um aparelho que precisa
durar um ano com uma pilha não consegue também atravessar uma casa, e é por isso que um sensor de
porta usa Bluetooth LE e um notebook não.

## O ar é compartilhado, e é essa a parte que as pessoas não veem

Um cabo pertence às duas máquinas das pontas dele. **Um canal de rádio pertence a todo mundo ao
alcance dele**, o que num prédio são várias dezenas de residências.

Dois rádios no mesmo canal não colidem nem se embaralham; eles se revezam. Isso é educado e
significa que **o tempo disponível é dividido entre todos que o usam**. Um canal ocupado não é
barulhento — é uma fila.

Então a descrição honesta de uma conexão lenta à noite normalmente não é *o roteador é fraco*. É
que o canal está cheio de vizinhos, e por isso mudar para um menos disputado costuma render mais
que qualquer compra.

## Três coisas que enfraquecem um sinal de rádio, em ordem

1. **A distância.** A força do sinal cai com o quadrado dela: o dobro da distância é um quarto da
   força. Isso é aritmética e equipamento nenhum muda.
2. **O que está no caminho.** Uma parede de gesso custa pouco. Tijolo custa muito. **Concreto com
   ferro dentro, banheiros azulejados e espelhos são quase paredes de metal**, e uma cozinha cheia
   de eletrodomésticos é o pior cômodo da maioria das casas.
3. **Água.** O que inclui pessoas. Uma sala que mede bem vazia mede pior com quarenta pessoas
   dentro, e é por isso que um centro de eventos planeja para corpos.

## O que os números da caixa significam

Um roteador anunciando `3000` está somando cada rádio que ele tem — digamos `600` numa banda e
`2400` na outra. **Nenhum aparelho sozinho jamais alcança esse número.** É a soma de velocidades
que um cliente não consegue usar ao mesmo tempo.

A figura que você de fato recebe é perto da metade da velocidade negociada do enlace, porque o
rádio gasta tempo escutando, confirmando e esperando a vez. Isso não é defeito; é o que
compartilhar custa.
