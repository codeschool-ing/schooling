---
title: Relações, e o sentido em que um filtro corre
version: 1
---

**Uma relação diz ao modelo que uma coluna de uma tabela guarda a chave de outra.** É o ponteiro da
aula 1 seção 06, escrito num lugar onde o Excel consegue segui-lo: `Sales[Product]` guarda códigos,
e cada código nomeia uma linha de `Products`. Quando o modelo sabe disso, uma tabela dinâmica pode
pôr `Products[Origin]` nas linhas e somar `Sales[Revenue]` embaixo, e nenhuma fórmula busca nada.

Duas das três relações podem ser desenhadas agora. A terceira liga `Sales[Date]` ao calendário da
próxima seção.

| de, o lado muitos | para, o lado um |
|---|---|
| `Sales[Product]` | `Products[Code]` |
| `Sales[Customer]` | `Customers[Customer]` |
| `Sales[Date]` | `Calendar[Date]`, na seção 06 |

## Desenhando uma

Na janela do Power Pivot, **Página Inicial › Exibição de Diagrama** (*Home › Diagram View*) mostra
cada tabela como uma caixa com as colunas listadas. Arraste `Product` da caixa `Sales` e solte sobre
`Code` na caixa `Products`. Aparece uma linha entre as duas caixas, com um `1` na ponta de
`Products` e um asterisco na ponta de `Sales`. Faça o mesmo de `Sales[Customer]` para
`Customers[Customer]`.

Há dois outros caminhos para o mesmo resultado, e eles fazem a mesma linha: **Design › Criar
Relação** (*Create Relationship*) na janela do Power Pivot, que pede as duas tabelas e as duas
colunas numa caixa de diálogo, e **Dados › Relações › Nova** no próprio Excel. Use o que você
encontrar; o diagrama é o que mostra o modelo inteiro de uma vez, e vale abri-lo depois de qualquer
mudança.

## As regras que uma relação precisa obedecer

**O lado um precisa ser único.** `Products[Code]` guarda seis códigos e nenhum código duas vezes,
então cada venda encontra exatamente um produto. Se `CER1K` aparecesse em duas linhas de `Products`,
uma venda de `CER1K` não saberia de qual se trata, e o Excel se recusa a criar a relação em vez de
adivinhar. É por isso que a aula 1 seção 06 insistiu que uma chave identifica uma linha: aqui o
modelo confere.

**As duas colunas precisam ser do mesmo tipo.** Texto liga com texto e data com data. Um código que
é texto de um lado e número do outro não casa com nada, e é por isso que a seção anterior conferiu
os tipos.

**Um valor do lado muitos que não acha linha não é erro, e também não é descartado.** Uma venda de
um código de produto ausente de `Products` ainda seria contada, numa linha com o rótulo `(blank)`.
Nos seus dados não há nenhuma: cada uma das 108 vendas nomeia um produto e um cliente que existem.
Vale ler uma linha `(blank)` numa tabela dinâmica criada sobre um modelo como uma pergunta: qual
chave não tem linha do outro lado?

## Um filtro corre do lado um para o lado muitos

As setas da figura da seção 03 apontam de cada dimensão para os fatos, e são a coisa mais
importante desta seção. **Um filtro numa dimensão chega à tabela de fatos; um filtro na tabela de
fatos não chega à dimensão.** Escolha `Cerrado` em `Products[Origin]` e o modelo fica com os dois
produtos do Cerrado, e depois com as vendas que apontam para eles. É um esquema em estrela
funcionando.

O outro sentido é onde um modelo surpreende. Ponha `Sales[Channel]` nas linhas de uma tabela
dinâmica e **Contagem de Code**, uma contagem de `Products[Code]`, nos valores. A tabela dinâmica
responde:

| `Channel` | Contagem de Code | vendas nesse canal |
|---|---|---|
| `Online` | 6 | 47 |
| `Shop` | 6 | 23 |
| `Wholesale` | 6 | 38 |

Seis em todas as linhas. O filtro em `Channel` mora em `Sales`, na ponta muitos, e não sobe a linha
de volta até `Products`, então cada linha conta os seis produtos, seja lá o que foi vendido. Nada
está quebrado: a pergunta foi feita ao contrário. **Para contar algo por canal, conte em `Sales`**,
onde o canal está, e a aula 16 faz exatamente isso com uma medida.

## Esquecendo uma relação

A outra surpresa parece igual e tem outra causa. Ponha `Products[Origin]` nas linhas e
`Sales[Revenue]` nos valores de uma tabela dinâmica do modelo **antes** de a relação existir, e todas
as linhas mostram o mesmo número:

| `Origin` | Soma de Revenue |
|---|---|
| `Cerrado` | 51.494 |
| `Mogiana` | 51.494 |
| `Sul de Minas` | 51.494 |

R$ 51.494 é toda a receita que existe. Sem linha entre as tabelas, escolher `Cerrado` filtra
`Products` e não chega a mais nada, então cada linha soma `Sales` inteira. O Excel percebe: a lista
de campos da tabela dinâmica mostra um aviso de que relações podem ser necessárias, com um botão
para criar uma. **O mesmo número repetido coluna abaixo é o sintoma, diga o aviso o que disser.** A
seção 07 mostra a mesma tabela dinâmica com a relação no lugar.
