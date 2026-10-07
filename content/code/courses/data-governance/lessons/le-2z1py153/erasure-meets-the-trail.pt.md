---
title: Quando a eliminação encontra uma trilha só de inserção
version: 1
---

Duas obrigações deste curso parecem colidir. Aula 7: uma pessoa pode pedir que os seus dados sejam
apagados. Esta aula: a trilha de auditoria nunca pode ser mudada. Se a trilha guarda dado pessoal sobre
o cliente 112, e o cliente 112 pede eliminação, uma das duas promessas tem de quebrar.

Não quebra, se a trilha for desenhada para isso — e a do laboratório já é.

## Identificadores, e não valores

O `gov.audit_log` registra `row_key = 112` e `columns = {cep,city}`. Ele não registra o endereço antigo
nem o novo. Sozinho, `112` não significa nada; ele só é dado pessoal porque `sales.customers` diz quem
é o 112. Quando essa linha perde o nome e os contatos — a eliminação da aula 7 —, a trilha continua
dizendo que alguém conectado como ana mudou duas colunas do cliente 112, e ninguém consegue mais dizer
quem era o cliente 112.

A plataforma em que você estuda é construída exatamente sobre isso. O fluxo de eventos e o log de
prática dela guardam identificadores, nunca nomes. Eliminar uma pessoa apaga as linhas que dão
significado a esses identificadores, o que deixa o histórico apontando para ninguém: **as estatísticas
sobrevivem e a pessoa não está nelas**. É também por isso que essas tabelas não têm chave estrangeira
para a tabela de contas — uma chave com `ON DELETE SET NULL` tentaria atualizar uma linha só de
inserção, e aí as duas obrigações colidiriam de verdade.

## A regra que faz funcionar

**Uma tabela só de inserção pode guardar identificadores e não pode guardar o que eles identificam.**
Toda coluna que carregasse um nome, um e-mail, um valor de texto livre ou a cópia de um campo mudado
transformaria uma tabela imutável numa que nunca consegue atender uma eliminação. A verificação é a
mesma da classificação da aula 6: as colunas da trilha são classificadas, e qualquer coisa acima de
`personal` numa tabela só de inserção é um erro de desenho a corrigir antes de ir ao ar.

## E a trilha também tem prazo

O log de auditoria é dado pessoal — quem fez o quê — e vive sob a mesma regra de todo o resto: guardado
enquanto necessário, e não mais. Cinco anos é uma escolha comum para registros administrativos. Ele
pertence ao `gov.retention`, e expurgá-lo é o único caso em que linhas saem de uma tabela só de
inserção: por um job nomeado e revisado, que desliga a guarda para aquele comando e registra que o
fez — o mesmo padrão da ferramenta de reset da plataforma.
