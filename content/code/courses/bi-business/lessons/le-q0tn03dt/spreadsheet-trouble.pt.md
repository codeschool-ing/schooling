---
title: Quando a planilha discorda de você
version: 1
---

A maior parte dos problemas que uma planilha como a anterior dá vem de cinco erros. Dois se anunciam
com uma mensagem de erro e um acontece antes de qualquer fórmula rodar. **Os outros dois dão um
número com cara de certo e errado**, e são esses que chegam a uma reunião. Cada valor abaixo é o que o
LibreOffice Calc devolveu quando o erro foi cometido de propósito, numa cópia de três linhas da
planilha:

| | A | B |
|---|---|---|
| 1 | Loja | Vendas |
| 2 | Savassi | 11880 |
| 3 | Pampulha | 10560 |
| 4 | Contagem | 12480 |

Digitado direito, o total é:

```localised
=SOMA(B2:B4)      34920
```

## Um número que na verdade é texto

Copie um número de um e-mail ou de uma página web e ele pode chegar como texto que por acaso tem
dígitos. Transforme B3 em texto e o total não reclama:

```localised
=SOMA(B2:B4)      24360
```

**`SOMA` pula texto sem dizer nada**, e os R$ 10,56 milhões de Pampulha simplesmente sumiram do total.
Somando as células uma a uma, o LibreOffice não tem como pular, e recusa:

```localised
=B2+B3+B4      #VALUE!
```

Outras planilhas tratam essa segunda fórmula de outro jeito, então não conte com o erro para avisar.
O sinal que funciona em todas é o alinhamento: número fica à direita da célula, texto à esquerda. Para
ter certeza, pergunte à planilha:

```localised
=SE(ÉTEXTO(B3);"texto";"número")      texto
```

A cura é redigitar o número, e depois olhar de onde ele veio: uma coluna colada de um lugar costuma
trazer mais de um.

## Um separador de milhar que a planilha lê como vírgula decimal

No Brasil, doze mil quatrocentos e oitenta se escreve `12.480`. Digite isso numa planilha configurada
em inglês e ela lê o ponto como separador decimal:

```localised
B4      12.48
=SUM(B2:B4)      22452.48
```

Nenhum erro, um total plausível, e as vendas de Contagem ficaram mil vezes menores. **É por isso que
os números da seção anterior foram digitados puros.** O contrário também acontece, e é o caso mais
comum para quem trabalha em português: um `12,480` vindo de um arquivo em inglês, colado numa planilha
em português, vira doze vírgula quatro oito.

## Uma função do outro idioma

A planilha responde com um erro de nome quando não conhece o nome de uma função. A causa mais comum é
uma fórmula copiada de algum lugar escrito para outro idioma:

```localised
=SOMA(B2:B4)      #NAME?
```

É `SOMA`, o nome em português de `SUM`, digitada num LibreOffice que roda em inglês. O contrário dá o
mesmo erro, com o nome do erro no idioma da planilha: `SUM` digitada numa planilha em português. O
Excel e o LibreOffice instalado usam os nomes do próprio idioma; o Google Planilhas tem uma opção para
usar sempre os nomes em inglês. Este curso mostra cada fórmula na grafia do idioma em que você está
lendo.

## Uma divisão por célula vazia

Uma parcela, uma taxa e uma média são todas divisões, e uma divisão por célula vazia ou por zero
responde:

```localised
=B2/0      #DIV/0!
```

Neste curso quase sempre quer dizer uma referência apontando para a célula errada — o `$` que faltou
na seção anterior é o culpado de sempre. Conserte a referência em vez de esconder o erro.

## Uma tabela colada que cai numa coluna só

O último erro não tem valor para mostrar, porque é sobre a colagem. Copie uma tabela de um arquivo de
texto ou de um e-mail e a linha inteira pode cair na coluna A, vírgulas e tudo. Selecione a coluna e
divida: **Dados → Texto para colunas** no LibreOffice e no Excel, **Dados → Dividir texto em colunas**
no Google Planilhas. Depois confira uma linha à mão contra o original antes de confiar no resto, que é
o hábito que pega os cinco erros.
