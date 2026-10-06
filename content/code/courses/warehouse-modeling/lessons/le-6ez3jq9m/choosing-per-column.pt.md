---
title: Escolhendo, uma coluna de cada vez
version: 1
---

O tipo é uma decisão sobre **cada atributo**, e não sobre a tabela. A dimensão de clientes da Ana
mistura três deles, e cada escolha tem um motivo que pode ser escrito:

| atributo | tipo | por quê |
|---|---|---|
| nível | 2 | o programa de fidelidade é analisado por nível ao longo do tempo |
| cidade, estado | 2 | vendas por região precisam contar a venda onde o comprador morava ao comprar |
| nome | 1 | toda mudança no registro é a correção de um erro de digitação |
| data de entrada, estado ao entrar | 0 | descrevem um momento, e a análise de coortes precisa deles congelados |
| e-mail | não guardado | nenhum relatório agrupa por ele, e é dado pessoal sem uso analítico |

As perguntas que decidem, em ordem:

1. **O valor antigo já foi verdade?** Se não, é uma correção: tipo 1.
2. **Alguém analisa fatos por este atributo ao longo do tempo?** Se não, o tipo 1 basta, e é mais
   barato.
3. **Um fato precisa do valor que valia quando aconteceu?** Então tipo 2.
4. **Há uma transição da qual as pessoas vão querer ver os dois lados?** Tipo 3, ou tipo 2 e uma view.
5. **Muda com tanta frequência que o tipo 2 multiplicaria as linhas?** Uma minidimensão, tipo 4.

**O mesmo atributo pode receber respostas diferentes em negócios diferentes.** A cidade de um cliente é
tipo 2 para uma loja que analisa vendas por região, e tipo 1 para uma companhia de energia que só
precisa saber para onde mandar a conta. O tipo segue as perguntas, e por isso os quatro passos da lição
2 começam por elas.

Livros mudam também. O departamento de um livro pode ser reclassificado, *Comics* passando um título
para *Young adult*. Se a rede quer que "vendas por departamento" mostre o arranjo que valia na época, o
departamento é tipo 2 na `dim_book`. Se quer cada ano mostrado no arranjo de hoje, que é o desejo mais
comum para uma hierarquia de produtos, é tipo 1. A `dim_book` da Ana é reconstruída a partir do catálogo
atual, então é tipo 1 em tudo, e essa é uma escolha que deveria estar escrita no dicionário da lição 12,
e não ser descoberta.
