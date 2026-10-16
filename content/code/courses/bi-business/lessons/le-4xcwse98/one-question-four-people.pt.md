---
title: Uma pergunta, quatro pessoas
version: 1
---

A tabela da seção anterior faz os papéis parecerem departamentos separados. Na prática, **uma
pergunta de negócio passa por vários deles, e cada um faz uma parte diferente.** Seguir uma pergunta
desde quem a fez até a decisão a que serviu mostra onde cada papel começa e termina — e, na Varanda,
quão pouca gente há para ocupá-los.

## A pergunta de Renata

Em fevereiro de 2026, Renata Sá, diretora de marketing, perguntou a Lívia: "Quais clientes vão
voltar?". Ela estava planejando uma campanha da loja online para maio e queria gastar a verba nas
pessoas com mais chance de comprar uma segunda vez, em vez de em todo mundo que já tinha comprado uma.

Parece uma pergunta. São pelo menos quatro.

## A parte do engenheiro: dá para acompanhar um cliente?

Para saber se alguém voltou, os dados precisam reconhecer essa pessoa na segunda vez. A loja online
reconhece: todo pedido pertence a uma conta. As lojas físicas, em geral, não, porque quem paga no
caixa é anônimo, a não ser que informe um e-mail para o programa de fidelidade. **Antes de alguém
analisar clientes que voltam, Tiago teve de montar uma tabela de clientes a partir das contas da loja
online e copiá-la para o banco toda noite**, com cada pedido ligado à sua conta. Ele também decidiu,
e deixou escrito, que a primeira versão cobriria só a loja online.

Isso é engenharia: nenhuma pergunta de negócio respondida, e nada mais possível sem ela.

## A parte do analista de dados: o que os dados dizem, uma vez?

Lívia então fez um trabalho de analista de dados. Pegou todos os clientes cujo primeiro pedido online foi feito no primeiro semestre de 2025, para
que cada um tivesse tido pelo menos 180 dias para voltar até o fim do ano: **13.200 clientes.**
Desses, **3.820 fizeram outro pedido em até 180 dias depois do primeiro, ou 28,9%.** Depois procurou diferenças: pela categoria da primeira compra, pelo
mês e por ter chegado atrasado ou não o primeiro pedido. No começo ela não sabia que comparação ia
importar, e a maioria não importou.

O que ela achou foi modesto e útil. Dos 840 clientes cujo primeiro pedido chegou atrasado, 21,9%
voltaram; dos 12.360 cujo primeiro pedido chegou no prazo, 29,4%. Isso foi para Caio, além de Renata.

## A parte do analista de BI: a mesma resposta, todo mês

Renata gostou do número e pediu para vê-lo todo mês. Nesse momento o trabalho mudou de natureza. **Um
número que vai ser mostrado todo mês precisa de uma definição escrita que não se mexe**: quem conta
como cliente novo, o que quer dizer "de novo" (outro pedido pago, não um cancelado), por que 180 dias
e não 90. Lívia escreveu isso, deu nome à medida — taxa de recompra — e a pôs no relatório mensal da
loja online. A conta era a mesma da exploração; o que a tornou BI foi a definição e a repetição.

## A parte do cientista de dados: qual cliente, exatamente?

A pergunta original de Renata era sobre clientes individuais: quais vão voltar. Uma taxa de recompra
de 28,9% responde "quantos", não "quais". **Dar a cada cliente uma nota pela chance de voltar é um
modelo, e é trabalho de cientista de dados.** A Varanda não tem quem faça isso. Lívia disse isso, e
ofereceu a versão simples que ela conseguia defender: mandar a campanha para os clientes novos de
2025 cujo primeiro pedido chegou no prazo, já que esse grupo voltou mais. Se a campanha funcionar e a
Varanda quiser ir além, o próximo passo é um modelo, e ele só vale o que custa se superar essa regra.

## O que levar daqui

Quatro tipos de trabalho, duas pessoas, uma pergunta. Tiago fez o primeiro e Lívia os dois seguintes;
o quarto foi nomeado e não foi feito. **A habilidade útil não é fazer os quatro. É reconhecer qual
deles um pedido precisa**, dizer quais ninguém na empresa consegue fazer ainda, e oferecer a versão
honesta que cabe nas pessoas que existem.
