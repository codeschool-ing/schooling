---
title: Soma, contagem, média, e uma fração do total
version: 1
---

**Um campo em Valores é resumido por uma função, e a função é uma escolha, não um fato sobre o
campo.** O Excel escolhe **Soma** para uma coluna que só tem números, e **Contagem** para uma coluna
que tenha qualquer texto ou qualquer célula vazia. Os dois padrões são palpites, e a tabela dinâmica
não dá sinal de qual escolheu além das palavras no alto da coluna.

## Mudando o resumo

Na tabela dinâmica `By channel` da seção 02, clique em qualquer número, depois clique com o botão
direito e escolha **Configurações do Campo de Valor** (**Value Field Settings**). A guia **Resumir
Valores por** lista **Soma**, **Contagem**, **Média**, **Máx**, **Mín** e mais algumas. Cada uma
responde a uma pergunta diferente sobre as mesmas linhas:

| resumo de `Revenue` | Online | Shop | Wholesale | Total Geral |
|---|---|---|---|---|
| **Soma**: quanto dinheiro | 11.143 | 1.620 | 38.731 | 51.494 |
| **Contagem**: quantas vendas | 47 | 23 | 38 | 108 |
| **Média**: uma venda típica | 237,09 | 70,43 | 1.019,24 | 476,80 |

As médias aparecem aqui com duas casas; a tabela dinâmica mostra tantas quantas o formato de número
da célula deixar. A contagem e a média também têm fórmulas:

```localised
=CONT.SES(Sales[Channel]; "Online")
=MÉDIASES(Sales[Revenue]; Sales[Channel]; "Wholesale")
```

**47** e **1.019,24**. As três linhas da tabela contam uma história juntas: o atacado são menos
vendas que o online, cada uma umas quatro vezes maior, e três quartos do dinheiro.

Aproveite a janela para renomear a coluna: **Nome Personalizado** transforma `Soma de Revenue` no que
o leitor deve ver, como `Revenue (R$)`. Um nome não pode ser exatamente o nome de um campo, então
`Revenue` sozinho é recusado; acrescente um espaço ou uma palavra.

## O resumo que não quer dizer nada

Arraste `Price` para **Valores**. Ele chega como **Soma de Price**: 3.576 para Online, 943 para Shop,
3.589 para Wholesale. São somas reais de células reais, e não querem dizer nada: somar o preço de um
saco de 250 g com o preço de um saco de 1 kg não responde a nenhuma pergunta de ninguém. Uma tabela
dinâmica soma qualquer coluna numérica, então **o teste é se você consegue dizer em palavras o que o
número é**. "A receita total das vendas online" passa. "O total dos preços das vendas online" não
passa. Tire `Price` da caixa.

Um preço médio por saco é uma pergunta real, e também não é a **Média de Price**: a aula 11 mostra
por quê, e como um campo calculado responde a ela.

## Mostrar Valores como: uma fração em vez de um valor

A segunda guia de **Configurações do Campo de Valor**, **Mostrar Valores como** (**Show Values As**),
mantém o resumo e muda a forma de mostrá-lo. Escolha **% do Total Geral**:

| Rótulos de Linha | Soma de Revenue |
|---|---|
| Online | 21,64% |
| Shop | 3,15% |
| Wholesale | 75,21% |
| **Total Geral** | **100,00%** |

Na tabela dinâmica `Grid`, com produtos na lateral e canais no alto, **% do Total da Coluna** diz que
fração da receita de cada canal cada produto traz, e **% do Total da Linha** diz como a receita de
cada produto se divide entre os canais. A mesma grade, três perguntas, conforme o total pelo qual uma
célula é dividida. Volte para **Sem Cálculo** para ver valores de novo.

Uma fração esconde o tamanho de que ela é fração. Os 75,21% do atacado não dizem que são R$ 38.731, e
os 3,15% da loja não dizem que são 23 vendas. Quando uma fração importa, ponha o valor ao lado:
arraste `Revenue` para **Valores** uma segunda vez e mostre uma cópia como valor e a outra como
percentual.
