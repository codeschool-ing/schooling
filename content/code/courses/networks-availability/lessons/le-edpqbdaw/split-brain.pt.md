---
title: Split brain, e por que dois não conseguem votar
version: 1
---

A pior falha de um par redundante não é as duas máquinas morrerem. É **as duas vivas, cada uma achando
que a outra morreu**. Acontece quando o enlace que leva os heartbeats quebra enquanto as máquinas em si
estão bem. Cada uma para de ouvir a outra, cada uma conclui que está sozinha, e cada uma assume. Isso se
chama **split brain**.

Para dois roteadores que dividem um endereço virtual, split brain quer dizer duas máquinas respondendo
por um endereço. As entradas ARP dos hosts oscilam entre dois endereços de hardware e o tráfego vai para
quem respondeu por último. É feio, e acaba no instante em que o enlace volta. O VRRP, o protocolo da aula
15, é em parte protegido pelo lugar por onde manda os heartbeats: a própria LAN que ele atende. Uma quebra que separa os dois roteadores costuma separar os hosts também, e cada metade fica com um gateway
que funciona para ela.

Para qualquer coisa que guarda dados, um par de servidores de banco de dados ou de arquivos, split brain é
muito pior. **Os dois lados aceitam gravações, e as duas cópias se afastam.** Quando o enlace volta há
duas versões da verdade, e nada consegue juntar um pedido gravado de um lado com um estorno gravado do
outro sem uma pessoa decidir qual vale.

## Uma maioria, ou nada

Um par não resolve isso sozinho, porque de dentro de cada metade as duas situações são idênticas: "meu
parceiro morreu" e "a linha até meu parceiro morreu" chegam as duas como silêncio. A saída é um
**quórum**. Uma máquina só pode agir enquanto enxerga a maioria dos votantes. Com três votantes, o lado
que enxerga dois continua e o lado que só enxerga a si mesmo para. As duas metades de uma divisão nunca
têm maioria ao mesmo tempo, então no máximo uma delas age.

| votantes | a maioria é | falhas que aguenta |
|---|---|---|
| 2 | 2 | 0 |
| 3 | 2 | 1 |
| 4 | 3 | 1 |
| 5 | 3 | 2 |

A tabela explica um hábito que parece superstição: **clusters têm número ímpar de membros**. Um quarto
votante não aguenta mais falhas do que três; só acrescenta uma máquina que pode quebrar. Dois votantes não aguentam nenhuma. Por isso um cluster de dois nós que se importa com os dados acrescenta um terceiro voto que não faz trabalho nenhum: uma **testemunha** (witness), muitas vezes uma máquina pequena
ou um serviço de nuvem num terceiro lugar.

A outra ferramenta é o **fencing**, o isolamento. Antes de assumir, o sobrevivente se certifica de que o
outro está mesmo desligado, cortando a energia dele por uma régua gerenciável ou cortando o acesso dele ao
storage compartilhado. O mundo dos clusters dá a isso um nome bruto, STONITH, "shoot the other node in the
head", atire na cabeça do outro nó. Parece drástico, e é o único jeito de ter certeza, e não esperança, de
que só um lado está gravando.

Os pares de VRRP e keepalived das aulas 15 e 16 não têm nem quórum nem fencing, de propósito. Para
roteadores e balanceadores que não guardam dados, o preço de um split brain curto são alguns segundos de
confusão, e essa é uma troca aceita. Para dados não é, e a aula 17 volta ao assunto com replicação.
