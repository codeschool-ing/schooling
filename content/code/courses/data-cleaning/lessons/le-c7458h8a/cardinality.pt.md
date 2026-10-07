---
title: Um, muitos, e a junção que você queria
version: 1
---

**Cardinalidade** é quantas linhas de cada lado podem compartilhar um valor da chave. Três casos
cobrem quase toda junção na prática:

- **um para um**: cada cliente tem uma linha no CRM e uma linha numa tabela de fidelidade;
- **muitos para um**: muitos itens apontam para um produto, muitos pedidos para um cliente;
- **muitos para muitos**: produtos e promoções, em que um produto está em várias promoções e uma
  promoção cobre vários produtos.

Os dois primeiros são para o que junções servem. **O terceiro quase nunca é o que você queria**:
ele devolve toda combinação de linhas que casam, então um valor de chave com três linhas de um lado
e quatro do outro produz doze. Quando é de propósito, existe uma tabela no meio dizendo quais
pares existem, e duas junções muitos para um passando por ela.

Juntar itens ao catálogo deveria ser muitos para um: muitos itens, um produto. Os três códigos
repetidos do catálogo tornam a junção, em silêncio, muitos para muitos nesses produtos. Dá para
dizer ao pandas o que você queria, e ele confere:

```
ana@lab:~/clean$ python -c "import pandas as pd; from lines import lines as l; p = pd.read_csv('raw/products.csv', dtype=str); l.merge(p, left_on='code', right_on='product_code', how='left', validate='many_to_one')" 2>&1 | grep ^pandas.errors
pandas.errors.MergeError: Merge keys are not unique in right dataset; not a many-to-one merge
```

`validate="many_to_one"` faz o `merge` testar a chave do lado direito antes de juntar, e recusar
se ela se repete. **O custo é um argumento, e ele transforma uma cópia silenciosa num erro com uma
frase.** Os outros valores são `"one_to_one"`, `"one_to_many"` e `"many_to_many"`; o último não
confere nada e só diz em voz alta que você espera cópias.

O SQL não tem esse argumento. O equivalente é o `GROUP BY … HAVING count(*) > 1` da seção
anterior, rodado no lado que deveria ser único, antes da junção e como passo próprio. Uma restrição
de unicidade nessa coluna, como a chave primária que a aula 10 pôs em `clean.customers`, faz o
banco manter a promessa de vez.
