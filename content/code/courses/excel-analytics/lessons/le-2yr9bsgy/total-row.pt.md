---
title: A linha de total, e totais que acompanham um filtro
version: 1
---

**A linha de total de uma tabela soma o que está visível, então muda quando você filtra e fica
parada quando você não filtra.** Isso a torna o jeito mais rápido de responder *quanto, nas linhas
que estou vendo*. Também a torna o lugar errado para guardar um número que alguém vai citar depois,
porque um filtro não fica escrito em lugar nenhum que o leitor vá olhar.

## Ligando

Clique dentro da tabela `Sales` e marque **Linha de Total** na guia **Design da Tabela**. Aparece uma
linha debaixo da última venda, com `Total` na coluna A e, sob `Revenue`, **51494**.

Clique na célula da linha de total sob `Bags`. Ela tem uma setinha que abre uma lista de funções:
**Soma**, **Contagem**, **Média**, **Máx.** e outras. Escolha **Soma**, e a célula mostra **591**.
Clique nela de novo e leia a barra de fórmulas:

```localised
=SUBTOTAL(109;[Bags])
```

É o que a linha de total escreve para toda função da lista: `SUBTOTAL`, com um número que diz qual
cálculo fazer. 109 quer dizer *soma*; 101 seria uma média e 103 uma contagem. Dentro da tabela a
coluna é escrita `[Bags]`, sem o nome da tabela.

## Filtrando

Abra o botão de filtro do cabeçalho `Channel`, deixe só **Wholesale** marcado e clique em **OK**. A
tabela passa a mostrar as 38 vendas do atacado, e a linha de total responde **403** sacos e
**38731** de receita: os mesmos números que o `SOMASES` deu na aula 5, sem condição nenhuma.

Agora digite, numa célula fora da tabela,

```localised
=SOMA(Sales[Bags])
=SUBTOTAL(109; Sales[Bags])
```

A primeira continua respondendo **591**: `SOMA` soma toda linha da coluna, visível ou não. A segunda
responde **403**, como a linha de total, porque `SUBTOTAL` deixa de fora as linhas que um filtro
esconde. Contar as vendas visíveis funciona do mesmo jeito:

```localised
=SUBTOTAL(103; Sales[Sale])
```

responde **38**.

## 9 ou 109

`SUBTOTAL` aceita duas famílias de números de função. As duas deixam de fora as linhas escondidas
por um **filtro**. Diferem nas linhas que alguém escondeu **à mão**, com o botão direito ›
**Ocultar**: de 1 a 11 ainda contam essas, e de 101 a 111 as deixam de fora. Então `SUBTOTAL(9; …)`
e `SUBTOTAL(109; …)` concordam nesta tabela filtrada, e discordam assim que alguém esconde uma linha
por conta própria. A linha de total usa os da casa dos 100, então sempre soma o que está na tela e
nada mais, que é a única regra que um leitor consegue conferir olhando.

## Onde um total filtrado deve ficar

Um total filtrado responde uma pergunta para quem está olhando a tela. Copie-o para um relatório e o
filtro que o produziu se perde: o próximo leitor vê 403 e não tem como saber que quer dizer *só o
atacado*. Um número que vai ser citado deve ficar numa fórmula que diz a própria condição, que é para
isso que o `SOMASES` existe. Use a linha de total para olhar, e o `SOMASES` para guardar.

Antes de seguir, limpe o filtro pelo botão do cabeçalho `Channel`, **Limpar Filtro de "Channel"**,
para que as 108 vendas apareçam. Depois desmarque **Linha de Total**: as aulas seguintes trabalham
com a tabela sem ela, e isso deixa livre a linha debaixo da última venda.
