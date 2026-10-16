---
title: A mesma contagem em Flink SQL
version: 1
---

O Flink tem uma API em Java, uma em Python e uma em SQL, e **o SQL é o caminho mais curto para a
mesma contagem**: uma tabela sobre o tópico, uma tabela sobre a saída, e um `INSERT` que roda
enquanto o cluster rodar. O watermark, que a lição 12 declarou com `withWatermark`, aqui faz parte
da definição da tabela, ao lado das colunas.

Salve isto como `~/work/sales.sql`:

@@fence@@

Leia de baixo para cima. O `INSERT` é a consulta: uma **janela fixa** de cinco minutos sobre `ts`,
que a lição 10 desenhou, agrupada e contada. Os dois `CREATE TABLE` não criam nada no Kafka; eles
dizem ao Flink como ler um tópico como tabela e como escrever em outro. O `at` é lido como texto, e
`ts` é uma **coluna calculada** a partir dos primeiros dezenove caracteres dele, a hora do relógio da
loja; o `-03:00` do fim é descartado, o que é seguro porque as cinco lojas estão no mesmo fuso. A
linha `WATERMARK` diz que `ts` é o tempo do evento e que uma venda pode chegar até dois minutos
atrasada, o mesmo limite da lição 12. As duas linhas `SET` do topo são assunto da seção 07.

Submeta. O cliente SQL repete cada comando enquanto o executa, e a única linha que vale guardar é o
id do job, então o `grep` fica com ela:

@@fence@@

O cliente foi embora, e o job não: ele roda no cluster agora, e vai rodar até alguém pará-lo. Os
resultados vão para `flink-sales-per-window`, então leia esse tópico:

@@fence@@

## Nada, e por quê

**Dez segundos, e nenhuma janela**, embora o Spark tenha impresso seis a partir das mesmas vendas
com o mesmo watermark. O job está rodando:

@@fence@@

O motivo é a fonte ociosa da lição 11. O Flink mantém **um watermark por partição** e move o
watermark do job para o menor deles, para que as vendas atrasadas de nenhuma partição sejam
atropeladas. O tópico `sales` tem três partições e a partição 2 está vazia: a chave de nenhuma loja
cai nela. Uma partição sem registros não tem watermark nenhum, então o menor é nada, e nenhuma
janela fecha nunca. O Spark, com um watermark só para a consulta inteira, não esperou; o Flink
espera, o que é correto quando a partição quieta está só lenta e errado quando ela está vazia.

A correção é declarar quanto tempo uma partição pode ficar quieta antes de deixar de contar.
Cancele o job, com o id que o `flink list` imprimiu:

@@fence@@

Depois acrescente uma linha no topo do `sales.sql`, dizendo que uma partição calada por cinco
segundos está ociosa, e submeta de novo:

@@fence@@

@@fence@@

@@fence@@

**Seis janelas, as mesmas seis do modo append da lição 12**, com as mesmas contagens: 30 vendas a
partir de 09:00, 28 a partir de 09:05, até 25 a partir de 09:25. As janelas de 09:30 e 09:35 ficam
retidas pelo mesmo motivo de lá: o watermark está dois minutos atrás da última venda, 09:36:41, e a
janela de 09:30 termina às 09:35. O Flink escreve uma janela uma vez só, quando ela fecha, como o
modo append do Spark, então este tópico de saída pode ser lido por qualquer coisa que some
registros.

Os dois motores concordam porque a definição é a mesma: tempo do evento a partir de `at`, janelas
de cinco minutos, um limite de dois minutos. O que mudou foi uma regra sobre partições, e esse tipo
de regra vem junto com a escolha do motor.
