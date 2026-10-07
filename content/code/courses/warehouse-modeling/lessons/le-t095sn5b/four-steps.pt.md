---
title: Quatro decisões, nesta ordem
version: 1
---

O jeito mais comum de começar um warehouse é copiar as tabelas operacionais e começar a escrever
relatórios. Parece progresso, e reconstrói o problema da lição 1 um banco adiante: os mesmos seis
joins, a mesma árvore de categorias irregular, o mesmo cliente no estado errado.

**A modelagem dimensional começa pelas perguntas, e não pelas tabelas.** Ralph Kimball, cujos livros
nos anos 1990 a tornaram o jeito padrão de projetar um warehouse, a reduziu a quatro decisões
tomadas numa ordem fixa:

1. **Escolha o processo de negócio.** Não um departamento e não um relatório: algo que o negócio
   *faz*, e que deixa um registro a cada vez. Vender um livro. Contar o estoque. Despachar um pacote.
2. **Declare a granularidade.** Diga, numa frase, o que uma linha da tabela vai ser. "Uma linha por
   item de um pedido que não foi cancelado."
3. **Identifique as dimensões.** Tudo aquilo por que uma pessoa vai querer filtrar ou agrupar uma
   linha: a data, a loja, o livro, a promoção.
4. **Identifique os fatos.** Os números medidos naquela granularidade: a quantidade, o valor bruto,
   o desconto, o valor líquido.

**A ordem é o método.** A granularidade vem antes das dimensões porque uma dimensão só cabe se tiver
um valor por linha. Um item de venda tem um livro, então o livro é dimensão da tabela de vendas; não
tem um autor único, porque alguns livros têm três, e a lição 4 trata do que fazer com isso. Os fatos
vêm por último porque um número só é fato *numa* granularidade: o frete é cobrado uma vez por pedido,
e na granularidade de um item ele não existe.

O primeiro processo de negócio da Ana é aquele sobre o qual o gerente perguntou na lição 1: **vender
livros**. O resto desta lição segue os quatro passos para ele, e depois para outros três processos
da rede, cada um dos quais acaba precisando de um tipo diferente de tabela.

A lição 4 dedica uma lição inteira ao passo 2, porque é o mais pulado e aquele cujos erros são os
mais difíceis de ver.
