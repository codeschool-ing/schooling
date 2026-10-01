---
title: A nuvem cobra por unidade, não por servidor
version: 1
---

A imagem com que quase todo mundo chega é a de um plano de hospedagem: você aluga um servidor, e ele
custa tanto por mês. **A nuvem não cobra por servidor. Ela cobra por unidade de uso**, e o servidor é
só uma das coisas medidas. A máquina é contada em horas, o disco dela em gigabytes mantidos por um mês,
o tráfego que sai dela em gigabytes, as requisições a um bucket em milhares, e uma função numa unidade
chamada GB-segundo. A conta de um mês tem centenas de linhas, e cada linha é uma quantidade
multiplicada por um preço.

Todas as unidades da tabela abaixo já apareceram neste curso, presas ao serviço de que cada aula
tratava. Os preços são linhas da tabela do curso, `python3 prices.py`, na coluna `sa-east-1`: a lista
pública de São Paulo, em dólares americanos e sem impostos.

| unidade | um exemplo da tabela | de onde veio |
| --- | --- | --- |
| hora de instância | `t3.medium`, 0.06720 por hora | aula 4 |
| GB-mês provisionado | volume gp3, 0.1520 por GB-mês | aula 5 |
| GB-mês armazenado | S3 Standard, 0.04050 por GB-mês | aula 5 |
| requisição | GET no S3, 0.00056 por 1.000; Lambda, 0.20 por milhão | aulas 5 e 8 |
| hora de um equipamento de rede | NAT gateway, 0.0930 por hora; load balancer, 0.0340 por hora | aula 6 |
| GB processado | NAT gateway, 0.0930 por GB | aula 6 |
| hora de endereço | endereço IPv4 público, 0.0050 por hora | aula 6 |
| GB transferido | saída para a internet, 0.1500 por GB; entre zonas, 0.0100 em cada sentido | aulas 6 e 9 |
| GB-segundo | Lambda, 0.0000166667 por GB-segundo | aula 8 |

Duas palavras dessa tabela fazem mais trabalho do que parece. Um volume gp3 é cobrado pelo tamanho que
você **provisionou**: um volume de 100 GB com 3 GB de arquivos custa os mesmos 15,20 dólares por mês que
um cheio. Um bucket do S3 é cobrado pelo que **guarda**: 3 GB nele custam 0,12 dólar. A aula 5
desenhou a diferença entre um dispositivo de blocos e um armazenamento de objetos; a conta a desenha de
novo.

## Cobrado por existir, cobrado por uso

As unidades se dividem em duas famílias, e separar uma da outra é boa parte de ler uma conta de nuvem.

**Algumas unidades são cobradas por existir.** Uma hora de instância, um gigabyte de disco
provisionado, uma hora de NAT gateway, uma hora de endereço público: cada uma acumula aconteça algo ou
não. Uma `m7i.large` que não atende nenhuma requisição a noite toda custa os mesmos 0,16065 por hora que
uma ocupada. Uma instância parada deixa de somar horas de instância, mas o volume ligado a ela continua
somando GB-mês, porque o disco ainda existe.

**Outras unidades são cobradas por uso.** Uma requisição, um gigabyte enviado, um GB-segundo de uma
função: com atividade zero custam zero, e crescem com o tráfego. Uma função Lambda que ninguém chama não
custa nada, que foi o argumento da aula 8 a favor das funções.

As duas famílias respondem a perguntas diferentes. A primeira diz quanto o desenho custa parado, o piso
que você paga num domingo tranquilo. A segunda diz como o custo se move quando o produto é usado, e essa
é a metade que ninguém sabe com exatidão de antemão.

## Por que se vende assim

O preço por unidade é o motivo de a nuvem poder ser alugada por uma hora e devolvida. O grupo de
autoscaling da aula 4 acrescenta duas máquinas ao meio-dia e as tira às seis, e a conta traz doze horas
de instância pela tarde, em vez de mais dois servidores por um ano. A mesma propriedade é o motivo de
uma conta não poder ser lida num contrato: **o custo é o que foi usado**, e ninguém aprovou o uso.

Mesmo um provedor que anuncia uma máquina por um preço mensal, como fazem alguns dos menores da aula 3,
mede alguma coisa ao lado dela: tráfego acima de uma franquia, um snapshot, um endereço a mais. As
unidades mudam de nome entre provedores. A forma de uma quantidade vezes um preço, somada em muitas
linhas, não muda.
