---
title: Uma lista do sistema antigo
version: 1
---

**Dados de outro sistema chegam com todos os valores presentes e metade deles inutilizável.** Até
o fim de 2024 a Café Serra registrava os pedidos em outro programa, e os doze pedidos de dezembro de
2024 só existem na exportação dele. Eles não estão em `Sales`, que começa em janeiro de 2025, e o
trabalho desta aula é deixá-los como se estivessem: um valor limpo por célula, do tipo certo,
escrito do mesmo jeito todas as vezes.

## Colando

1. Crie uma planilha chamada `Old export`.
2. Clique em **A1**, copie o bloco abaixo com o botão do canto e cole.

```
Order	Date	Customer	Item	Qty	Channel	Price
00841	20241202	Café Aroma	SUL1K - Sul de Minas 1 kg	12	Wholesale	113
00842	20241203	  café aroma	DEC250 - Decaf 250 g	6 un	wholesale	35
00843	20241205	EMPÓRIO SERRA	cer1k - Cerrado 1 kg	10 un	WHOLESALE 	101
00844	20241209	Walk-in and web	MOG250 - Mogiana Reserve 250 g	2	 Online	49
00845	20241210	Padaria  Central	SUL250 - Sul de Minas 250 g	8	Wholesale	32
00846	20241212	CAFE DO LARGO	SUL1K - Sul de Minas 1 kg	15 un	Wholesale	113
00847	20241216	Walk-in and web	CER250 - Cerrado 250 g	3	Shop	31
00848	20241217	café do largo 	CER1K - Cerrado 1 kg	9	wholesale	101
00849	20241218	Walk-in and web	DEC250 - Decaf 250 g	1	online	39
00850	20241219	Empório Serra	MOG250 - Mogiana Reserve 250 g	7 un	Wholesale	44
00851	20241220	Walk-in and web	SUL1K - Sul de Minas 1 kg	2	Shop	126
00852	20241223	Café Aroma	CER1K - Cerrado 1 kg	11	Wholesale	101
```

Olhe antes de fazer qualquer coisa. Na tela, quase tudo parece certo, e esse é o problema: uma
pessoa lê `  café aroma` como Café Aroma e `6 un` como seis, e nenhuma fórmula faz nenhuma das duas
coisas.

## Contando o que está errado

O mesmo hábito da aula 1: antes de confiar numa coluna, conte-a. Numa célula vazia de `Old export`,
à direita dos dados, como **P1**:

```localised
=CONT.NÚM(E2:E13)
=SOMA(E2:E13)
=CONT.SES(F2:F13; "Wholesale")
```

`CONT.NÚM` (`COUNT` no Excel em inglês) responde **8**. Doze pedidos e oito números: quatro
quantidades são texto, as digitadas com `un` depois, então `SOMA` (`SUM`) soma as outras oito e
responde **48**. O total real, depois que a coluna for consertada na seção 04, é **86**. O
`CONT.SES` (`COUNTIFS`) responde **7**, e contando a olho há oito pedidos do atacado: `WHOLESALE `
tem um espaço depois, e para uma condição isso faz dela outra palavra. As maiúsculas não são o
problema, já que as condições ignoram maiúsculas; o espaço é.

Mais dois defeitos se escondem à vista. **A2** mostra `841`, porque o número do pedido chegou como
`00841` e o Excel o leu como número e jogou fora os zeros. **B2** mostra `20241202`, que é uma data
para uma pessoa e vinte milhões para o Excel, que guarda 2 de dezembro de 2024 como **45628**.

## O plano

Cada coluna tem seu defeito, e cada defeito tem uma função. O resto da aula passa por eles nesta
ordem:

| coluna | o que está errado | o que conserta | seção |
|---|---|---|---|
| `Customer` | espaços antes, depois e entre as palavras; maiúsculas por toda parte | `ARRUMAR`, e `PRI.MAIÚSCULA` para exibir | 03 |
| `Channel` | as mesmas três palavras com maiúsculas misturadas e espaços soltos | `ARRUMAR` e `PRI.MAIÚSCULA` | 03 |
| `Item` | um código e um nome na mesma célula, alguns códigos em minúsculas | `PROCURAR`, `ESQUERDA`, `MAIÚSCULA` | 04 |
| `Qty` | alguns números trazem `un` e são texto | `SUBSTITUIR` e `VALOR` | 05 |
| `Order` | os zeros à esquerda se perderam | `TEXTO` | 05 |
| `Date` | oito dígitos, não uma data | `ESQUERDA`, `EXT.TEXTO`, `DIREITA` e `DATA` | 06 |

**Todo conserto vai numa coluna nova, da I em diante, e o original fica intocado.** Uma coluna limpa
ao lado daquela de onde veio pode ser comparada linha a linha, e um erro na fórmula aparece como uma
linha em que as duas discordam de um jeito que não deviam. Redigitar os valores à mão não deixa nada
para comparar, e a próxima exportação do mesmo sistema chega com os mesmos defeitos.
