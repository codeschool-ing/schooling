---
title: Estimativa paramétrica
version: 1
---

A estimativa paramétrica leva a analogia um passo adiante. Em vez de comparar trabalhos inteiros, ela acha uma **quantidade mensurável** que move o esforço — telas, interfaces, relatórios, tabelas de dados —, calcula pelo trabalho passado quanto esforço uma unidade levou, e multiplica.

## Um exemplo resolvido

No último ano o time Agenda construiu **40 telas** em várias funcionalidades, e o tempo gasto em trabalho de tela foi de **128 dias úteis**. Isso dá **3,2 dias por tela**, uma taxa que já contém o desenho, a revisão, os testes e o retrabalho que o time de fato fez.

A funcionalidade de agendamento online precisa de **7 telas**. A 3,2 dias cada, o trabalho de telas chega a **22,4 dias úteis**.

A estimativa é tão boa quanto duas coisas: se as telas de fato movem o esforço nesse tipo de trabalho, e se as telas novas se parecem com as antigas. Uma tela de agendamento com lógica de calendário complexa não é uma página de configurações, e uma taxa única para as duas esconde a diferença. Times que usam estimativa paramétrica a sério mantêm taxas separadas para tipos de unidade que se comportam de forma diferente.

## Os modelos formais

A estimativa paramétrica tem uma história longa e formal. O **COCOMO** de Barry Boehm, publicado em 1981 no mesmo livro do cone da incerteza, estimava o esforço a partir do tamanho esperado do código em linhas, ajustado por fatores do time, do produto e do ambiente. Os **pontos de função**, introduzidos por Allan Albrecht na IBM em 1979, medem o tamanho do lado do usuário — entradas, saídas, consultas, arquivos e interfaces —, de modo que dá para contá-los antes de qualquer código ser escrito. Os dois ainda são usados em contratos, sobretudo em compras públicas, onde um preço por ponto de função é um jeito comum de contratar software.

## A força e a armadilha

A força de uma estimativa paramétrica é ser **reproduzível**: duas pessoas com as mesmas contagens e a mesma taxa chegam ao mesmo número, o que é útil quando uma estimativa precisa ser defendida. A armadilha é uma taxa de aparência precisa fazer a resposta parecer mais certa do que é. 22,4 dias tem uma casa decimal; a incerteza sobre se esta funcionalidade precisa mesmo de sete telas é muito maior que a casa decimal. A aula 10 chama isso de falácia da precisão.
