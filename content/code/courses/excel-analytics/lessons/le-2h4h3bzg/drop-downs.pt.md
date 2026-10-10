---
title: Listas suspensas que crescem com uma tabela
version: 1
---

**Uma regra de lista transforma a célula numa lista suspensa, e um valor escolhido numa lista não
tem como sair com erro de digitação.** É a regra mais forte que existe para uma coluna cujos valores
vêm de um conjunto curto e conhecido: `Customer`, `Product` e `Channel` em `New sales`. De onde a
lista vem decide se ela continua certa quando o negócio muda.

## Uma lista digitada na regra

`Channel` tem três valores, e eles não vão mudar com frequência. Selecione a célula de `Channel` de
`NewSales` (G2), vá em **Dados › Validação de Dados** (**Data › Data Validation**), **Permitir:
Lista**, e digite em **Fonte**: `Wholesale;Online;Shop`. Deixe **Menu suspenso na célula** marcado.
A célula agora mostra uma seta quando está selecionada, e digitar qualquer coisa que não seja um dos
três é recusado.

O ponto e vírgula separa os itens num Excel em português, o mesmo que separa os argumentos de uma
fórmula. Num Excel em inglês, que separa argumentos com vírgula, os itens também vão separados por
vírgula.

## Uma lista lida de uma tabela

Produtos e clientes mudam. Uma lista digitada na regra teria de ser redigitada a cada café novo do
Café Serra, e no dia em que alguém esquecer, o produto novo não pode ser vendido pela planilha. Então
a lista deve ser lida das tabelas `Products` e `Customers` da aula 7, que já guardam todos os
códigos.

**A caixa Fonte da maioria das versões do Excel recusa uma referência estruturada como
`=Products[Code]`, e aceita um nome.** Um nome pode apontar para uma coluna de tabela, então a coluna
ganha um nome primeiro:

1. **Fórmulas › Gerenciador de Nomes › Novo** (**Formulas › Name Manager › New**).
2. **Nome**: `ProductCodes`. **Refere-se a**: `=Products[Code]`. **OK**.
3. De novo, com **Nome** `CustomerCodes` e **Refere-se a** `=Customers[Customer]`.

A aula 2 criou nomes para intervalos e constantes; estes dois são a mesma coisa, apontando para uma
coluna que pode crescer. Para conferir, digite numa célula vazia:

```localised
=LINS(ProductCodes)
=LINS(CustomerCodes)
```

As fórmulas respondem **6** e **11**: seis produtos e onze clientes, de `C00` a `C10`. Agora
selecione a célula de `Product` de `NewSales` (D2), escolha **Lista** e digite `=ProductCodes` em
**Fonte**. Faça o mesmo na célula de `Customer` (C2) com `=CustomerCodes`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 300\" role=\"img\" data-fig=\"l08-list\" aria-label=\"Uma cadeia de três passos. À esquerda, a coluna Code da tabela Products, com seis códigos e uma sétima linha tracejada para um produto incluído depois. No meio, um nome, ProductCodes, que se refere a Products[Code]. À direita, a célula Product da tabela NewSales com a lista suspensa aberta, mostrando os mesmos seis códigos e, tracejado, o sétimo.\"><text x=\"40.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">tabela Products, coluna Code</text><text x=\"32.0\" y=\"51.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"40.0\" y=\"40.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"51.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Code</text><text x=\"32.0\" y=\"73.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"40.0\" y=\"62.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"73.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SUL250</text><text x=\"32.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"40.0\" y=\"84.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"95.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SUL1K</text><text x=\"32.0\" y=\"117.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"40.0\" y=\"106.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"117.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER250</text><text x=\"32.0\" y=\"139.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"40.0\" y=\"128.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"139.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER1K</text><text x=\"32.0\" y=\"161.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><rect x=\"40.0\" y=\"150.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"161.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">MOG250</text><text x=\"32.0\" y=\"183.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><rect x=\"40.0\" y=\"172.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"183.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DEC250</text><rect x=\"40.0\" y=\"194.0\" width=\"96.0\" height=\"22.0\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"40.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um produto novo: a tabela</text><text x=\"40.0\" y=\"247.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cresce uma linha</text><text x=\"270.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um nome</text><rect x=\"270.0\" y=\"100.0\" width=\"170.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"355.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">ProductCodes</text><text x=\"355.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">=Products[Code]</text><text x=\"270.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aponta para a coluna,</text><text x=\"270.0\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">do tamanho que ela for</text><path d=\"M146.0 129.0 L264.0 129.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M264.0 129.0 L256.0 125.0 L256.0 133.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"540.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a regra em NewSales[Product]</text><text x=\"540.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Source: =ProductCodes</text><rect x=\"540.0\" y=\"64.0\" width=\"150.0\" height=\"22.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"75.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER1K</text><rect x=\"690.0\" y=\"64.0\" width=\"22.0\" height=\"22.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M695 72 L707 72 L701 79 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--paper)\"></path><rect x=\"540.0\" y=\"90.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"100.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SUL250</text><rect x=\"540.0\" y=\"110.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"120.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SUL1K</text><rect x=\"540.0\" y=\"130.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"140.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER250</text><rect x=\"540.0\" y=\"150.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"160.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CER1K</text><rect x=\"540.0\" y=\"170.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"180.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">MOG250</text><rect x=\"540.0\" y=\"190.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"546.0\" y=\"200.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DEC250</text><rect x=\"540.0\" y=\"210.0\" width=\"172.0\" height=\"20.0\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">e a lista acompanha</text><path d=\"M446.0 129.0 L534.0 129.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M534.0 129.0 L526.0 125.0 L526.0 133.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path></svg>", "caption": "A regra de lista lê um nome, e o nome lê a coluna da tabela. Um produto incluído na tabela Products aparece em toda lista suspensa feita sobre o nome, sem ninguém editar uma regra."}
```

## Por que não `=Products!$A$2:$A$7`

Esse endereço funciona hoje e dá os mesmos seis códigos. Ele para de funcionar no dia em que a tabela
`Products` ganha uma sétima linha, porque `$A$2:$A$7` são seis células e continuam sendo seis
células. O nome aponta para `Products[Code]`, que é a coluna da tabela, do tamanho que a tabela for.
A lista suspensa então oferece o sétimo produto sem ninguém mexer na regra.

O mesmo raciocínio explica por que a regra fica numa coluna de `NewSales`: a tabela leva a regra a
cada linha nova, e o nome leva cada produto novo à regra.

## O que uma lista não faz

Uma lista suspensa mostra os códigos, não o que eles significam: `C07` está na lista e `Escritório
Faro` não está. Uma coluna ao lado do código que busque o nome, com o `PROCX` (`XLOOKUP` no Excel em
inglês) da aula 4, mostra a quem digita quem foi escolhido. A lista também oferece os valores na
ordem em que a tabela os guarda, então uma lista longa fica mais fácil de usar quando a tabela está
classificada.
