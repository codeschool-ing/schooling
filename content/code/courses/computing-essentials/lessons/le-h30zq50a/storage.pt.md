---
title: Armazenamento, e a única troca que faz uma máquina velha parecer nova
version: 1
---

Armazenamento é o que sobrevive à queda de energia: os seus arquivos, os seus programas
instalados, o próprio sistema operacional. Duas tecnologias fazem esse trabalho, elas não são
dois níveis da mesma coisa, e a diferença entre elas é a maior mudança isolada que você pode
fazer na sensação de usar um computador.

## Um disco rígido é uma vitrola

Um **HDD** são pratos de metal girando a 5 400 ou 7 200 rotações por minuto, com um braço que
varre por cima deles para alcançar uma trilha. Para ler alguma coisa, o braço se move e depois o
prato tem de trazer o ponto certo para debaixo dele.

Essa espera tem nome — **tempo de busca** — e é de uns 10 milissegundos. Não é um atraso
eletrônico. É o tempo que um objeto físico leva para se mover, e nenhuma engenharia fez a
mecânica acompanhar a eletrônica.

## Um SSD não tem nada que se mexe

Um **SSD** são chips de memória. Sem braço, sem prato, nada a esperar. Chegar a qualquer
endereço leva uns 0,1 milissegundo, seja lá o que tenha sido lido antes.

Isso é mais ou menos **cem vezes mais rápido para alcançar uma coisa**, e a distância aumenta
ainda mais para o trabalho que os computadores de fato fazem, que é alcançar milhares de coisas
pequenas espalhadas por toda parte.

| | disco rígido | SSD |
|---|---|---|
| alcançar uma coisa | ~10 ms | ~0,1 ms |
| ler em linha reta | ~150 MB/s | 500 MB/s, ou 3 000+ no NVMe |
| peças móveis | sim | nenhuma |
| custo por gigabyte | o mais baixo que existe | várias vezes mais |
| para que serve | arquivo morto, backup, volume | qualquer coisa que você espera |

## A melhoria que funciona de verdade

Um notebook de oito anos com disco rígido, ao ganhar um SSD, liga em quinze segundos em vez de
noventa e abre programas na hora. O processador é o mesmo processador. Nada nele ficou mais
rápido.

Vale parar nessa frase, porque ela é o argumento inteiro da aula dentro de uma compra: **a
máquina nunca esteve lenta. Ela estava esperando**, e a espera estava toda num lugar só.

## SATA e NVMe, rapidamente

Você vai ver as duas palavras em SSDs, e a diferença é em *como* o disco se conecta, não do que
ele é feito:

- **SATA** é a conexão mais antiga, dividida com os discos rígidos, e para por volta de 550 MB/s.
- **NVMe** entra direto nas pistas rápidas da placa-mãe e chega a 3 000 ou 7 000 MB/s.

Sendo honesto: sair de um disco rígido para qualquer SSD é transformador, e sair de um SSD SATA
para um NVMe é um número que se mede e raramente se sente. O primeiro passo é o que importa.

## E uma palavra sobre capacidade, que não é velocidade

`512 GB` diz quanto cabe, e nada sobre quão rápido é. Um disco cheio fica mais lento — abaixo de
uns 10% livres, um SSD tem menos blocos sobrando para escrever e precisa remanejar — então
**deixe algum espaço**. É o único lugar em que os dois números se tocam.
