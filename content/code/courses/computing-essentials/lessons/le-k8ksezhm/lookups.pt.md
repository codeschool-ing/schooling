---
title: Consultas, que é como duas tabelas viram uma resposta
version: 2
---

A coisa mais útil que uma planilha faz: **pegar um valor de uma tabela e achar a linha a que ele
pertence em outra.** Um código de produto e uma lista de preços. Uma matrícula e um departamento.
Um pedido e um cliente.

## O `PROCX`, e por que ele substituiu os outros dois

```localised
=PROCX(o que achar; onde procurar; o que trazer de volta; o que fazer se não achar)
```

Quatro argumentos na ordem em que uma pessoa os diria. Ele procura para a esquerda com a mesma
facilidade que para a direita, não quebra quando alguém insere uma coluna, e o quarto argumento é
o que transforma um `#N/D` numa frase.

O `PROCV` fazia o mesmo serviço com um **número de coluna** — `=PROCV(A2; D:H; 3; FALSO)` — e esse
`3` é o problema inteiro: ele conta colunas a partir da esquerda do intervalo, então inserir uma
coluna em qualquer lugar de `D:H` muda em silêncio qual coluna volta. A fórmula continua
funcionando. Ela devolve a coisa errada.

Se o `PROCX` não estiver disponível — um Excel mais antigo, alguns modos de compatibilidade — a
alternativa robusta é `ÍNDICE` com `CORRESP`:

```localised
=ÍNDICE(a coluna a trazer; CORRESP(o que achar; a coluna a procurar; 0))
```

Mais digitação, a mesma imunidade a colunas inseridas, e disponível em todo lugar.

## O argumento que estraga mais trabalho que qualquer outro

**Correspondência exata ou aproximada.**

O quarto argumento do `PROCV` assume *aproximada* por padrão, o que supõe a coluna de busca
ordenada e devolve **o valor mais próximo abaixo** do que você pediu. Numa lista não ordenada de
códigos de produto, isso é uma linha aleatória, devolvida com confiança, sem erro algum.

- **Exata** é o que você quer para códigos, nomes, identificadores — qualquer coisa em que *perto*
  não significa nada. `FALSO` ou `0` no `PROCV`, e o padrão no `PROCX`.
- **Aproximada** é o que você quer para faixas: uma tabela de imposto, uma tabela de frete, uma
  faixa de nota. Ordenada de forma crescente, e é genuinamente a ferramenta certa.

**Escrever `FALSO` toda vez é o hábito**, e o `PROCX` fazer disso o padrão é a razão de trocar.

## O que o `#N/D` está te dizendo

Ele significa *este valor não está naquela lista*, o que quase sempre é um achado real:

- **um espaço sobrando** — `"SP "` e `"SP"` são cadeias diferentes. O `ARRUMAR` conserta a coluna;
- **um número guardado como texto** — o problema da aula nove, com o alinhamento denunciando;
- **uma linha genuinamente faltando**, que é o caso mais importante e o que o `SEERRO` esconde.

Então: **conte.** `=CONT.SE(os resultados; "#N/D")` ao lado da tabela, ou um filtro na coluna. Três
linhas sem correspondência em novecentas é uma nota na aba `notas`; trezentas são um problema de
dados completamente diferente, e o total não significa nada até ser entendido.
