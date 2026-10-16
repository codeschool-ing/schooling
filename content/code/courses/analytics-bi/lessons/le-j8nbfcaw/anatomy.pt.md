---
title: Do que uma métrica é feita
version: 1
---

Toda métrica de negócio, seja qual for o nome, é construída das mesmas cinco partes. Escritas para
a receita líquida do financeiro:

| parte | o que ela diz | receita líquida |
|---|---|---|
| **medida** | a coluna que é somada, contada ou tirada a média | `net_cents` |
| **agregação** | como as linhas viram um número | `sum` |
| **filtro** | quais linhas participam | `status = 'paid'`, sem o cliente 1 |
| **tempo** | que data põe uma linha num período, e em que fuso | a data do pedido, São Paulo |
| **dono** | quem decide quando a definição muda | financeiro |

O número do marketing difere do financeiro em duas das cinco: a medida dele é `gross_cents` e ele
não tem filtro. Essa é a discordância inteira, e ela cabe em duas células de uma tabela. **Quando
dois números com o mesmo nome discordam, compare as partes antes de comparar as consultas.** As
partes são curtas; as consultas são longas e escondem a diferença num `WHERE` na linha doze.

A quarta parte é a que ninguém escreve. Uma linha pode carregar várias datas — um pedido é feito,
pago, enviado, estornado — e "receita de março" significa uma coisa diferente para cada uma. As
tabelas da Lantern só têm a data em que o pedido foi feito, o que faz a escolha por você aqui; uma
loja real tem as quatro, e a escolha muda o número na borda de todo mês. O fuso é a segunda metade
dessa mesma parte, e ganha uma seção própria nesta aula.

A quinta parte não é aritmética, e é a que mantém as outras quatro estáveis. **Uma definição sem
dono muda sempre que alguém edita uma consulta**, e ninguém sabe dizer que versão um relatório
usou. Com dono, uma mudança é uma decisão com data.

## Medidas e dimensões

As duas primeiras partes formam uma **medida**: algo que você soma. Tudo aquilo por que você
poderia quebrar uma medida — o estado, o segmento, o canal, o mês — é uma **dimensão**. "Receita
líquida por região e mês" é uma medida e duas dimensões, e quase toda pergunta que um negócio faz
aos dados tem esse formato. As duas próximas seções são sobre dimensões; o resto da aula, sobre
medidas.
