---
title: O que uma conta feita de traces deixa de fora
version: 2
---

O `bill.py` soma o que os spans registraram. A fatura do fornecedor soma o que o fornecedor cobrou. As
duas deveriam bater, e vale conhecer os jeitos como não batem antes do dia em que alguém perguntar por
que o painel diz uma coisa e a fatura outra.

**Chamadas que ninguém rastreou.** Um job em lote, um script que alguém rodou do notebook, um segundo
serviço com a mesma chave de API e sem instrumentação. Cada um está na fatura e nenhum está nos spans.
A correção não é mais cuidado; é **uma chave por serviço**, para que a página de uso do próprio
fornecedor divida a conta do mesmo jeito que os traces, e uma chave com gasto e sem spans salte aos
olhos.

**Tentativas que falharam depois de o trabalho ter sido feito.** Um fornecedor que recusa um pedido
antes de fazer qualquer coisa em geral não cobra nada por isso. Uma resposta cortada no meio é outra
história: os tokens já gerados foram produzidos, e um fornecedor pode cobrá-los. O assistente
registra uma tentativa cortada como um span de erro com o número de pedaços recebidos
(`app.partial_pieces`), mas o uso dela nunca chega, porque o último pedaço, que o carrega, foi
justamente o que se perdeu. A aula 4 faz isso acontecer.

**Avaliação.** As aulas 9 a 12 mandam respostas para um modelo juiz, e cada uma dessas chamadas é
cobrada. Elas pertencem à mesma contabilidade, com o próprio nome de funcionalidade, para que "quanto
nos custa a qualidade" tenha resposta. A aula 9 mede isso.

**Cache e descontos.** Um fornecedor que guarda em cache um prefixo do prompt cobra menos pela parte em
cache, e uma interface em lote cobra menos pela espera. Os dois aparecem no uso que o fornecedor
devolve, como contagens separadas, e os dois precisam de preço próprio. A aula 17 do `rag` e a aula 17
do `prompt-reliability` medem o cache; uma tabela de custo que ignore essas contagens vai superestimar
a conta de qualquer sistema que o use.

**Impostos, mínimos, câmbio.** Uma fatura em dólar paga de uma conta brasileira tem câmbio e impostos
por cima que nenhum span conhece. Os traces medem o custo do trabalho; o financeiro mede o custo da
fatura. Os dois estão certos, e são números diferentes.

## Conciliando

Uma vez por mês, compare os dois: o relatório de uso do fornecedor, por chave e por modelo, contra a
soma dos spans no mesmo período e para os mesmos modelos. Uma diferença de um ou dois por cento são
novas tentativas, streams cortados e relógios na virada do mês. **Uma diferença de dez por cento é
trabalho não rastreado**, e achá-lo vale uma tarde, porque é a parte da conta que ninguém está olhando.
