---
title: "Depois: o resumo e a carta"
version: 1
---

**Quando um incidente acaba, dois documentos ficam devendo: um resumo curto em até um dia, para todo
mundo que foi afetado ou avisado, e depois o postmortem completo, que é o assunto da aula 15.** O
resumo fecha o ciclo aberto pelas atualizações. Sem ele, a última coisa que as pessoas ouviram foi
"resolvido", e as perguntas que vêm em seguida ("o que aconteceu?", "vai acontecer de novo?") são
respondidas pelo boato.

## O resumo interno, em até 24 horas

Lívia mandou o resumo no sábado de manhã, para toda a engenharia, o suporte e a diretoria:

> **Incidente no checkout, sexta, 6 de março, das 19:09 às 19:41**
>
> **Impacto.** Durante 32 minutos, a maioria dos clientes não conseguiu concluir o checkout. Cerca de
> 1.350 checkouts falharam. Ninguém foi cobrado por um pagamento que falhou, e nenhum dado de pedido
> se perdeu.
>
> **Causa, até onde sabemos.** Uma tarefa de backfill de dados das zonas de entrega foi iniciada às
> 19:05. Ela abriu mais conexões com o banco de pedidos do que o banco permite, e o checkout não
> conseguiu nenhuma. Interromper a tarefa às 19:38 restabeleceu o checkout em três minutos.
>
> **Já feito.** O runbook do backfill agora diz para não rodá-lo entre 17:00 e 22:00.
>
> **Próximos passos.** Uma revisão sem culpados na terça, às 14:00, aberta a qualquer pessoa. O
> relato completo sai até sexta, 13 de março.

Cinco blocos curtos: o quê, quão grave, por quê (até onde se sabe), o que já foi feito, o que vem
depois. **"Até onde sabemos" não é rodeio; é precisão.** A revisão completa muitas vezes encontra mais
de uma causa, e um resumo que afirmasse certeza no sábado teria de ser corrigido na semana seguinte.

## A carta aos clientes

Os clientes que tiveram um checkout com falha receberam um e-mail na segunda-feira:

> Na sexta à noite, entre 19:10 e 19:41, muitos de vocês não conseguiram concluir o pedido. A culpa foi
> nossa, e pedimos desculpas. Vocês não foram cobrados por nenhum pagamento que falhou. Para compensar,
> a taxa da sua próxima entrega é por nossa conta. Já mudamos a forma como fazemos manutenção para que
> isso não aconteça nos horários de movimento, e vamos fazer mais nesta semana.

Quatro coisas que uma carta ao cliente precisa ter, e nada além delas: **o que aconteceu nos termos
dele, um pedido de desculpas que assume a responsabilidade, o que isso significa para ele (não foi
cobrado, ganhou um crédito) e que algo mudou.** Sem tecnologia, sem nomes internos e sem promessa de
que nunca mais vai acontecer.

## Por que "a culpa foi nossa" vale aqui

A aula 3 alertou contra pedidos de desculpas que admitem o que não foi estabelecido. Aqui a causa *foi*
estabelecida, e era o próprio sistema da Marola. Assumir com clareza a responsabilidade por algo que é
claramente seu é o que torna o resto da carta crível; enrolar faria a Marola parecer estar culpando o
celular do cliente.
