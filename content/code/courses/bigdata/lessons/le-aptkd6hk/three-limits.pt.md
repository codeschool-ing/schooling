---
title: Os três jeitos de uma máquina se esgotar
version: 1
---

**"Big data" não é um tamanho. É o ponto em que uma máquina fica sem alguma coisa**, e há três
coisas de que ficar sem: memória, disco e tempo. Elas chegam em tamanhos diferentes, e qual você
atinge primeiro decide que tipo de solução você precisa.

**A memória acaba primeiro, e de forma mais súbita.** Um programa que guarda na memória o que já viu
funciona perfeitamente até o dia em que os dados ficam um pouco maiores, e então é morto. Não há
lentidão para avisar. A seção 08 leva um programa até essa parede de propósito.

**O disco acaba com mais educação.** Ele é de dez a cem vezes maior que a memória e enche aos
poucos, então você vê chegando. O preço é velocidade: um SSD rápido lê talvez 2 GB por segundo
quando lê em trechos longos, e bem menos quando o programa pula de um lugar para outro.

**O tempo acaba por último, e é o que decide a maioria dos casos reais.** Um job que termina
corretamente às quatro da manhã é inútil se o relatório que ele alimenta era para as oito. A conta
é curta e vale fazer antes de construir qualquer coisa:

| dados para ler | a 2 GB/s, um disco | a 200 MB/s, um disco em nuvem | o mesmo, em 100 máquinas |
|---|---|---|---|
| 250 MB, os cliques deste curso | 0,1 s | 1,3 s | não compensa |
| 1 TB, um ano de uma loja grande | 8 min | 1 h 23 min | 50 s |
| 100 TB, um ano de um site grande | 14 h | 6 dias | 1 h 23 min |

A última coluna é o argumento a favor de um cluster numa linha: **cem máquinas leem cem vezes mais
rápido, porque cada uma lê a sua parte do próprio disco.** Nenhum disco sozinho, por mais caro que
seja, faz isso. Mas leia a primeira linha também. No tamanho dos dados deste curso, um cluster não
compra nada, e o resto desta aula é honesto sobre isso.

**Os três limites são o motivo do curso, e também o seu aviso.** A maioria dos dados que as pessoas
chamam de grandes cabe numa máquina com folga: 250 MB não é nada, e 25 GB num notebook com 32 GB de
memória também não. Um cluster é a resposta a uma pergunta que precisa ser feita antes, que é *o
que exatamente está acabando?*
