---
title: Por que conferir o que é digitado
version: 1
---

**Uma célula aceita qualquer coisa digitada nela, e um valor errado cobra o preço em outro lugar,
mais tarde, num total que ninguém liga à digitação.** O Excel não faz ideia de que `Channel` guarda
uma de três palavras, de que uma venda é de alguns sacos e não de algumas centenas, nem de que o
Café Serra não vendeu nada em 2205. Você sabe as três coisas. A validação de dados é como você conta
isso para a célula.

## Um espaço, e os totais param de fechar

Experimente na sua pasta de trabalho. Numa célula vazia à direita da tabela `Sales`, digite os três
totais por canal e o total geral:

```localised
=SOMASES(Sales[Revenue]; Sales[Channel]; "Online")
=SOMASES(Sales[Revenue]; Sales[Channel]; "Wholesale")+SOMASES(Sales[Revenue]; Sales[Channel]; "Online")+SOMASES(Sales[Revenue]; Sales[Channel]; "Shop")
=SOMA(Sales[Revenue])
```

O primeiro responde **11.143**, e os outros dois concordam em **51.494**, como deveriam: toda venda
pertence a exatamente um canal. Agora clique em G4, o canal da venda `S1003`, e digite `Online` com
um espaço depois. A célula parece igual. Mas `Online` com espaço é outra palavra, diferente de
`Online`, então `SOMASES` (`SUMIFS` no Excel em inglês) não encontra mais a venda. O total Online
cai para **11.028**, os três canais somam **51.379**, e o total geral continua dizendo **51.494**. A
diferença é **115**, a receita de `S1003`, e nada na planilha diz para onde ela foi.

Aperte **Ctrl+Z** para devolver a célula ao que era antes de seguir.

`SOMASES` não liga para maiúsculas, então `online` teria sido encontrado. Um espaço no fim, uma
letra trocada (`Onlnie`) ou outra palavra para a mesma coisa (`Web`) criam, cada um, um canal pelo
qual nenhuma fórmula pergunta.

## Os quatro jeitos de um valor digitado dar errado

| o que foi digitado | onde dói |
|---|---|
| uma categoria escrita de outro jeito: `Online ` | um total por essa categoria, que a deixa de fora em silêncio |
| um número fora da faixa: `140` sacos no lugar de `14` | toda soma e média que o inclui |
| uma data impossível: `2205-03-11` | um total por ano ou mês, e todo filtro de datas |
| um código que não existe: `CER1KG` | toda busca por ele, que responde `#N/D` (aula 4) |

Nenhum deles é um erro que o Excel consiga ver. Cada um é um valor válido do seu tipo, numa célula
que não tinha regra.

## Conferir no momento da digitação

**A validação leva a conferência para o único momento em que o valor certo é conhecido**: quando
alguém o está digitando, com o pedido ou o recibo na frente. Achado um mês depois num relatório, o
mesmo erro custa alguém caçando entre 108 linhas aquela que está errada. Achado na digitação, custa
um segundo.

É uma ferramenta para dados que pessoas digitam. Dados que chegam como arquivo de outro sistema são
outro trabalho, e as aulas 13 e 14 fazem isso com o Power Query. A próxima seção monta o lugar onde
o pessoal do Café Serra digitaria a próxima venda.
