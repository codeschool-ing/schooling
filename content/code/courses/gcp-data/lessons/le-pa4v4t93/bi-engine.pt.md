---
title: BI Engine, memória alugada por GiB
version: 1
---

**O BI Engine é memória em que o BigQuery mantém as suas tabelas, para que os painéis as leiam da memória
em vez do armazenamento.** Uma visão materializada deixa a resposta pequena; o BI Engine deixa a leitura
dela rápida e, sob demanda, gratuita. Ele é comprado como uma **reserva** de um número de GiB, num projeto
e numa localização, e o BigQuery mantém nessa memória as tabelas e colunas que as consultas do projeto
mais usam, ou as indicadas como preferidas. Uma consulta cujo estágio de leitura pode ser servido por ela é
**acelerada**. Tudo nesta seção vem da página de preços e da documentação do Google sobre o BI Engine, e
nada disso rodou.

## O que ele faz com a conta

**Sob demanda, o estágio que o BI Engine serve é cobrado por nada.** A página de preços diz isso em duas
frases: "When BI Engine accelerates a query, the query stage that reads table data is free", e "For
on-demand pricing, stages that use BI Engine are charged for 0 scanned bytes." Numa reserva, o mesmo
estágio "consumes no BigQuery reservation slots", e os estágios depois dele usam slots normalmente. Então
um painel cujas consultas o BI Engine acelera deixa de pagar o preço por TiB da aula 14 pela leitura da
tabela, e paga a memória no lugar.

## O preço da memória

**Em `southamerica-east1`, o BI Engine custa 0,0749 USD por GiB-hora**, que a página também imprime como
54,677 USD por GiB-mês, lida em 2026-10-30. A reserva é cobrada por toda hora em que existe, usada ou não,
como a baseline de uma reserva de slots. Dois GiB por um mês, pelos dois números da página:

```
ana@laptop:~/gcp$ python3 -c 'print(round(2 * 0.0749 * 730, 2), round(2 * 54.677, 2))'
109.35 109.35
```

**109,35 USD por mês por 2 GiB**, de qualquer jeito que se calcule, já que 54,677 é 0,0749 × 730. A tabela
inteira de pedidos da Quitanda tem 0,092 GiB de bytes lógicos e o agregado diário alguns kilobytes, então 2
GiB guardariam os dois muitas vezes. Se vale a pena depende inteiramente do que os painéis custavam sem
ele: o painel de hora em hora da aula 15, a mil vezes o tamanho da Quitanda e particionado por dia, custava
2,90 USD por mês, e nenhuma reserva de memória sai mais barata que isso. Sem partições custava 220,15, e
aí uma reserva que o servisse valeria a pena.

**Compromissos de edições incluem algum BI Engine de graça.** A tabela da página dá a um compromisso de 100
slots 5 GiB de BI Engine sem custo extra, a 500 slots 25 GiB, a 1.000 slots 50 GiB, e assim por diante até
um máximo de 100 GiB por organização, desde que a reserva fique num projeto da mesma organização com slots
atribuídos. Uma empresa que comprou slots por outros motivos pode já ter o BI Engine pago, o que vale
conferir antes de comprá-lo à parte.

## O que ele acelera

**O BI Engine é para a consulta pequena, repetida e interativa**, que é o que um painel manda: filtrar uma
tabela, agregar algumas colunas, devolver poucas linhas. A documentação do Google descreve o que ele
consegue acelerar e o que faz uma consulta voltar ao motor comum, entre eles tabelas grandes demais para a
reserva e SQL que ele não suporta. Uma consulta que volta roda normalmente e é cobrada normalmente, e as
estatísticas do job registram se o BI Engine foi usado e, se não, por quê: o mesmo hábito do smart tuning,
que é ler o que o job fez em vez de supor.

## Os três, em ordem

**Primeiro deixe a resposta pequena, depois deixe-a rápida.** Uma visão materializada, ou uma consulta
agendada onde uma view não serve, transforma um milhão de pedidos em algumas centenas de linhas;
particionamento e clustering, da aula 15, deixam até a tabela base barata de ler para um dia. **Depois, se
os painéis ainda leem o bastante para importar**, uma reserva pequena de BI Engine na frente das tabelas
pequenas as deixa rápidas e, sob demanda, faz o estágio de leitura delas deixar de ser cobrado. Comprada
primeiro, na frente de uma tabela grande sem partições, uma reserva é memória alugada para guardar um
problema que as aulas anteriores resolvem de graça.
