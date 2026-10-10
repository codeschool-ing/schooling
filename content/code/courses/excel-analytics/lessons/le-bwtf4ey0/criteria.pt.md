---
title: Escrevendo uma condição, com operadores, curingas e datas
version: 1
---

**Uma condição é um pedaço de texto que o Excel lê como uma pequena comparação.** `"Wholesale"`
quer dizer *igual a Wholesale*. Ponha um operador na frente e ela passa a dizer outra coisa, e essa
é toda a linguagem de condições de `SOMASES` (`SUMIFS`), `CONT.SES` (`COUNTIFS`) e `MÉDIASES`
(`AVERAGEIFS`):

| condição | uma célula passa quando… |
|---|---|
| `"Online"` | é igual a `Online`, com qualquer mistura de maiúsculas |
| `"<>Wholesale"` | é qualquer coisa menos `Wholesale`, inclusive uma célula vazia |
| `">=10"`, `"<10"`, `">0"` | guarda um número que se compara desse jeito |
| `"*250"` | é texto que termina em `250`; `*` vale qualquer sequência de caracteres, inclusive nenhuma |
| `"SUL*"` | é texto que começa com `SUL` |
| `"?"` | é texto de exatamente um caractere; cada `?` vale um |
| `""` | está vazia |
| `"<>"` | não está vazia |

O operador vai **dentro** das aspas, porque a condição inteira é um pedaço de texto. Um caractere
curinga que você quer mesmo encontrar é escrito com um til na frente, então `"~*"` casa com uma
célula que guarda um asterisco.

## Operadores e curingas nas vendas

O *ou* que falta ao `SOMASES` muitas vezes pode ser escrito como um *não*:

```localised
=SOMASES(H2:H109; G2:G109; "<>Wholesale")
```

responde **12763**, os 11.143 de `Online` mais os 1.620 de `Shop`, porque esses são os únicos outros
canais. Se um quarto canal surgir, ele entra calado, então um *não* é um atalho que só vale enquanto
você conhece todo valor que a coluna pode ter.

Os códigos de produto trazem o tamanho no fim, então um curinga os separa por tamanho:

```localised
=SOMASES(E2:E109; D2:D109; "*250")
=SOMASES(E2:E109; D2:D109; "*1K")
```

**213** sacos de 250 g e **378** de 1 kg, que somam os 591. Funciona porque alguém desenhou os
códigos com o tamanho num lugar fixo. Uma regra que depende da grafia de um código é frágil, e a
coluna `Grams` de `Products` é o jeito confiável de perguntar por tamanho; as buscas da aula 4 a
trazem para o lado de cada venda.

## Datas são números, então uma condição de data é uma comparação

A aula 1 mostrou que uma data é guardada como uma contagem de dias. Uma condição sobre datas é,
portanto, um operador e um número, e o jeito seguro de escrever o número é a função `DATA` (`DATE`),
colada ao operador com `&`:

```localised
=SOMASES(H2:H109; B2:B109; ">="&DATA(2026;1;1))
```

`DATA(2026;1;1)` é o número do dia 1º de janeiro de 2026, e `">="&` cola o operador nele, então a
condição vira `">=46023"`. A resposta é **15943**, a receita de 2026 até agora. Um ano de 2025
precisa de começo e fim, duas condições sobre a mesma coluna:

```localised
=SOMASES(H2:H109; B2:B109; ">="&DATA(2025;1;1); B2:B109; "<"&DATA(2026;1;1))
```

**35551**. O fim é escrito como *antes do primeiro dia do período seguinte*, `"<"` 1º de janeiro de
2026, e não como *até o último dia*, `"<="` 31 de dezembro de 2025. As duas formas concordam nestes
dados, cujas datas não têm hora. Discordam assim que um valor tiver: 31 de dezembro às três da
tarde é um número maior que 31 de dezembro, e `"<="` o deixa de fora. Terminar um período no começo
do seguinte serve para os dois casos, e poupa você de saber quantos dias tem fevereiro.

## Uma condição que aponta para uma célula

O número de 2026 cobre só de janeiro a junho, então compará-lo com 2025 inteiro é injusto. A
comparação justa é com os mesmos meses um ano antes, e fica mais fácil de pedir se as datas
morarem em células. Digite `2026-01-01` em **J1** e `2026-07-01` em **K1**, e então:

```localised
=SOMASES(H2:H109; B2:B109; ">="&J1; B2:B109; "<"&K1)
```

responde **15943**. Mude J1 para `2025-01-01` e K1 para `2025-07-01`, e a mesma fórmula responde
**17789**. O primeiro semestre de 2026 rendeu R$ 1.846 a menos que o primeiro semestre de 2025,
cerca de **10,4%** a menos. Nada na fórmula mudou; a pergunta passou para as células.

O erro que custa uma hora aqui é pôr a célula dentro das aspas:

```localised
=SOMASES(H2:H109; B2:B109; ">=J1")
```

responde **0**. Dentro das aspas, `J1` são dois caracteres de texto, não uma referência, e nenhuma
data é maior ou igual ao texto `J1`. O operador vai entre aspas e a referência vai fora, ligada
com `&`.
