---
title: Uma tabela dinâmica que lê o modelo inteiro
version: 1
---

**Uma tabela dinâmica criada sobre o modelo lista todas as tabelas do modelo na lista de campos, e
tira cada campo de onde ele mora.** É toda a recompensa das últimas quatro seções: a pergunta
"receita por origem e ano" precisa de `Origin` de `Products`, `Year` de `Calendar` e `Revenue` de
`Sales`, e a tabela dinâmica pega os três sem nenhuma coluna de busca.

Crie uma numa planilha nova com **Inserir › Tabela Dinâmica › Do Modelo de Dados**, ou a partir da
janela do Power Pivot com **Página Inicial › Tabela Dinâmica**. A lista de campos mostra quatro
tabelas, cada uma com uma setinha para abri-la. Então:

1. de `Products`, arraste `Origin` para **Linhas**;
2. de `Calendar`, arraste `Year` para **Colunas**;
3. de `Sales`, arraste `Revenue` para **Valores**, onde vira **Soma de Revenue**.

O modelo responde com a tabela abaixo. Ela foi calculada, como todo número desta aula, seguindo as
três relações sobre as linhas que você colou, e não pelo Excel:

| `Origin` | 2025 | 2026 | Total Geral |
|---|---|---|---|
| `Cerrado` | 14.110 | 8.083 | 22.193 |
| `Mogiana` | 2.969 | 385 | 3.354 |
| `Sul de Minas` | 18.472 | 7.475 | 25.947 |
| **Total Geral** | **35.551** | **15.943** | **51.494** |

Duas conferências levam um segundo cada, e o hábito vale mais do que os segundos. O total geral,
R$ 51.494, precisa ser igual à soma da coluna `Revenue` na planilha:

```localised
=SOMA(Sales!H2:H109)
```

responde **51.494**, numa planilha. Os totais por ano podem ser conferidos do mesmo jeito com o
`SOMASES` (`SUMIFS` no Excel em inglês) da aula 5, e a aula 16 seção 06 faz exatamente isso. Compare
esta tabela com a da seção 05, em que toda linha dizia 51.494: a única diferença é a linha entre
`Sales` e `Products`.

## Trocar um campo é arrastar

Troque `Origin` por `Type` de `Customers` e a mesma tabela dinâmica divide a receita por tipo de
cliente: `Café` 13.532, `Individual` 12.763, `Office` 7.031 e `Retail` 18.168. Com colunas de busca,
isso era um segundo `PROCX` em cada venda; aqui é uma segunda relação desenhada uma vez, na seção
05.

Troque por `State` e uma linha aparece com o rótulo `(blank)`, com R$ 12.763. É o `C00`, o cliente
de balcão e web, cujo estado está vazio em `Customers`: as 70 vendas dele caem na linha em branco. É
a célula vazia da aula 4 de novo, e aqui ela é honesta em vez de armadilha. O dinheiro é contado, e
o rótulo diz que o estado é desconhecido.

Ponha `Quarter` de `Calendar` nas linhas, com `Year` ainda nas colunas, e a coluna de 2026 fica
vazia em `Q3` e `Q4`. O calendário tem esses dias, e nenhuma venda caiu neles, então as células não
guardam nada, nem mesmo um zero. A aula 16 seção 05 reencontra esses trimestres vazios numa
comparação em que eles importam.

## A regra que mantém tudo certo

A regra prática da seção 03 é a que vale guardar aqui. **Ponha colunas de dimensão em Linhas,
Colunas, Filtros e segmentações; ponha colunas de fatos em Valores.** Agrupar por `Products[Code]` e
por `Sales[Product]` dá as mesmas seis linhas, porque cada venda traz um código de produto; agrupar
por `Origin` só funciona a partir de `Products`, porque `Sales` não tem essa coluna. E a seção 05
mostrou o que faz um valor tirado de uma dimensão quando as linhas vêm dos fatos: seis em toda
linha.

Duas ferramentas das aulas 10 e 11 cedem lugar ao modelo aqui. Agrupar datas à mão é a ferramenta
errada: as colunas `Year`, `Quarter` e `Month` do calendário já são os grupos, e são as mesmas em
toda tabela dinâmica criada sobre o modelo. E o **Campo Calculado** nem é oferecido: um cálculo sobre
um modelo é uma **medida**, escrita em DAX, e arrastar `Revenue` para **Valores** acabou de criar
uma sem avisar. A aula 16 começa aí.
