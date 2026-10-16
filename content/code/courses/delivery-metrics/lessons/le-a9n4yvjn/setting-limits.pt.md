---
title: Definindo o limite
version: 1
---

Não existe um número correto para começar, e procurar um atrasa a única coisa que o produz: testar um número e observar o que acontece. O que existe é um pequeno conjunto de escolhas sobre **o que** limitar, e cada escolha tem uma falha conhecida.

## Por pessoa, por coluna ou pelo quadro

| limite sobre | exemplo | o que ele pega | como ele falha |
|---|---|---|---|
| **cada pessoa** | um item por dev | a multitarefa que custa tempo de troca | não diz nada sobre filas entre pessoas; a revisão ainda pode se acumular |
| **cada coluna** | a revisão comporta no máximo dois | uma fila se formando diante de uma etapa | um time pode respeitar todas as colunas e ainda ter coisa demais aberta no total |
| **o quadro inteiro** | no máximo seis itens entre *started* e *merged* | tudo de uma vez, de forma simples | não dá pista de onde o trabalho está parado |

O time de Billing escolheu o primeiro, mais uma regra que tornou o segundo desnecessário: **revisar antes de começar qualquer coisa**. Um limite por pessoa sozinho teria deixado a fila da Bia exatamente onde estava, porque cada dev, com um item e nada mais para fazer, simplesmente teria esperado. A regra de revisar primeiro é o que transformou tempo ocioso em tempo de revisão.

Um limite sobre o quadro inteiro às vezes é chamado de CONWIP, de *constant work in progress* (trabalho em andamento constante), um nome vindo da manufatura. É o mais fácil de explicar para pessoas de fora do time, e combina bem com o gráfico de envelhecimento, que então diz onde está o trabalho parado.

## Por onde começar

- **Comece perto do número de pessoas**, ou um pouco abaixo, para um limite por pessoa ou pelo quadro inteiro. Um limite de seis no quadro para cinco devs deixa espaço para um item esperando revisão.
- **Defina colunas de fila com limites baixos.** Uma coluna cuja função é esperar, *pronto para revisão* ou *pronto para deploy*, deveria comportar um ou dois itens, porque qualquer coisa acima disso é tempo em que alguém está esperando.
- **Mude uma coisa de cada vez, e deixe por algumas semanas.** A aula 1 mostrou que uma mudança leva a maior parte de um mês para atravessar o quadro; julgar um limite novo depois de uma semana é julgar as sobras do sistema antigo.

## Duas regras que mantêm um limite honesto

**Um item bloqueado conta.** O limite do time de Billing tinha uma porta: um item bloqueado deixava de contar, então o dev dele podia começar algo novo. Nada nisso está errado no momento. Ao longo de semanas, produziu o `BIL-189`, com quarenta dias e invisível. Se itens bloqueados contam, um item bloqueado vira problema de todo mundo, porque está ocupando um lugar de que o time precisa, e **essa pressão para desbloqueá-lo é o objetivo do limite**.

**Trabalho urgente tem sua própria raia, com limite de um.** Todo time recebe trabalho que não pode esperar: um incidente em produção, uma correção de segurança, um cliente que não consegue emitir nota. Uma raia de *expedite* deixa esse trabalho furar a fila sem fingir que o limite não existe. O limite próprio de um impede que "urgente" vire o jeito normal de conseguir qualquer coisa; se duas coisas são urgentes ao mesmo tempo, decidir qual vai primeiro é trabalho da tech lead, e deveria ser uma decisão visível.

## Como saber se o limite está certo

Um limite **nunca atingido** não está limitando nada; abaixe-o. Um limite **sempre cheio com itens velhos atrás**, como um gráfico de envelhecimento mostra, está preso por algo parado, e a coisa parada importa mais que o número. Um limite **sempre cheio com itens novos** é o caso saudável: o setembro do time de Billing, em que o trabalho em andamento ficou no limite todos os dias e nada além do `BIL-189` era velho. Aquela linha reta no gráfico da aula 1 é a cara de um limite que funciona.
