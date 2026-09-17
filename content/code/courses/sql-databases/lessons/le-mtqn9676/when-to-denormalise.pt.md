---
title: Quando quebrar de propósito
version: 1
---

Desnormalizar é devolver uma redundância que as formas removeram, deliberadamente, em troca de algo.
É uma técnica real e é a ideia mais mal usada desta aula, porque também é o que alguém diz quando
não quis criar outra tabela.

A diferença é uma palavra: **medida**.

## A troca sendo feita

Toda divisão que esta aula fez tornou a escrita mais segura e a leitura mais longa. Uma pergunta que
era uma tabela agora é uma junção, e em alguma escala, em alguma consulta, esse custo deixa de ser
de graça.

Desnormalizar compra a leitura de volta guardando algo que poderia ser calculado ou seguido:

| o que você guarda | em vez de | o que custa |
|---|---|---|
| um `comment_count` no post | contar os comentários | toda inserção e exclusão tem que mantê-lo |
| o nome do autor no post | juntar com o autor | renomear um autor toca todo post |
| um total no pedido | somar as linhas | uma linha mudando tem que atualizar o pedido |
| uma tabela de relatório pronta | a consulta que a construiu | está velha desde o momento em que é escrita |

Cada linha dessa tabela é uma cópia de um fato em dois lugares, que é a falha que o modelo
relacional inteiro existe para remover. Você está trocando uma propriedade de correção
**garantida** por uma de desempenho **medida**, e a troca só é honesta se a medida for real.

## O teste

Antes de desnormalizar, as quatro:

**1. A consulta é de fato lenta?** Lenta em produção, com dados do tamanho de produção, com um
plano de execução real — não lenta na intuição de alguém. As aulas 9 e 10 tratam de como saber. Uma
junção sobre uma chave estrangeira indexada em dez mil linhas não é lenta, e uma fatia enorme das
desnormalizações propostas mira junções que custam menos de um milissegundo.

**2. Você tentou um índice?** Quase todo "a junção está lenta" acaba sendo um índice faltando na
chave estrangeira. Um índice é uma mudança que ninguém precisa lembrar depois; uma coluna duplicada
é uma mudança que todo mundo precisa lembrar para sempre. Aula 9.

**3. Você tentou a consulta?** `EXISTS` em vez de contar, um `SELECT` mais estreito, fazer em um
comando em vez de em laço. O problema N+1 da aula 11 é a causa mais comum de "o banco está lento" e
não se resolve desnormalizando nada.

**4. Você sabe o que vai mantê-lo correto?** Esta é a que as pessoas pulam. Se `comment_count` é
guardado, *o que* o incrementa — código de aplicação, um gatilho, um job de reparo agendado? O que
acontece quando um comentário é apagado por um caminho que ninguém lembrou? **Um valor
desnormalizado sem mecanismo que o mantenha verdadeiro não é otimização de desempenho, é um bug com
agenda.**

Só depois das quatro é decisão em vez de reflexo.

## E quando a resposta é sim

Às vezes é, genuinamente. Os formatos que justificam:

**Uma contagem num caminho de leitura muito quente.** A contagem de comentários de um post,
renderizada a cada visita, onde contar significa varrer uma tabela grande. Mantida por um gatilho,
porque um gatilho não pode ser esquecido pelo próximo programa que escrever um comentário.

**Um total que é parte de um documento.** O total de uma fatura, guardado na fatura. Essa
normalmente não é desnormalização de verdade — veja a próxima seção — mas é onde o argumento começa.

**Uma tabela de relatório reconstruída periodicamente.** Análise sobre um esquema transacional
normalizado costuma ser genuinamente lenta demais, e a resposta é uma tabela separada, ou um banco
separado, reconstruído de madrugada. **A propriedade-chave é que nada escreve nela à mão**: ela é
derivada, inteira, por um job que pode ser rodado de novo. Ser reconstruída é o que torna seguro
ser redundante.

**Uma visão materializada**, que é o nome do próprio banco para essa ideia e vale saber que existe:
uma consulta cujo resultado é guardado e atualizado sob comando. Aula 7.

## O que a torna defensável

Seja o que for que você desnormalizar, três coisas:

**Escreva que é derivado.** Num comentário na coluna, na migração, em algum lugar que uma pessoa
veja. Uma coluna que parece autorada e é na verdade derivada é uma armadilha para a próxima pessoa,
que vai atualizá-la à mão e vai ter razão em achar que podia.

**Tenha um mecanismo que a mantenha, e só um.** Um gatilho, ou um caminho de código por onde tudo
passa. Dois mecanismos é o estado em que eles discordam.

**Consiga reconstruí-la a partir da verdade.** Se `comment_count` pode ser recalculado contando,
você pode conferir, reparar e provar o desvio. Se não pode ser recalculado, não é derivado — é uma
segunda fonte de verdade, e você já não tem um banco de dados, tem dois.

## A ordem, uma última vez

> **Normalize primeiro. Meça. Depois, se a medida disser, desnormalize a coisa específica que a
> medida apontou, e escreva como ela permanece verdadeira.**

Desnormalizar antes de medir não é decisão de desempenho nenhuma. São as anomalias do começo desta
aula, escolhidas de propósito, em troca de nada.
