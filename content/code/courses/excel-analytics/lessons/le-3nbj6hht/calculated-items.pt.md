---
title: Itens calculados, e por que evitá-los
version: 1
---

**Um item calculado é uma linha nova dentro de um campo, feita de outras linhas do mesmo campo, e o
total geral a soma como qualquer outra linha.** Esse é o problema inteiro. Sempre que a linha nova
repete dinheiro que já está no campo, o total conta esse dinheiro duas vezes, e a tabela dinâmica não
dá sinal nenhum disso.

## Montando um, para vê-lo falhar

A Café Serra chama a loja virtual e o balcão, juntos, de canais *diretos*, em oposição ao atacado.
Monte uma segunda tabela dinâmica a partir da tabela `Sales` numa **Nova Planilha**, renomeie a
planilha para `Channels` e ponha `Channel` em **Linhas** e `Revenue` em **Valores**. Depois:

1. Clique num dos nomes de canal da tabela dinâmica, como `Online`. O comando fica cinza enquanto a
   célula ativa não for um item do campo que vai receber o item novo.
2. Escolha **Análise da Tabela Dinâmica › Campos, Itens e Conjuntos › Item Calculado**
   (*Calculated Item*).
3. Em **Nome**, digite `Direct`. Em **Fórmula**, digite a fórmula abaixo; um clique duplo num item
   da lista **Itens** digita o nome dele.
4. Clique em **Adicionar** e depois em **OK**.

```localised
=Online+Shop
```

`Direct` chega como um quarto canal, e o total geral cresceu:

| `Channel` | `Soma de Revenue` |
|---|---|
| `Online` | 11.143 |
| `Shop` | 1.620 |
| `Wholesale` | 38.731 |
| `Direct` | 12.763 |
| Total Geral | **64.257** |

A receita da Café Serra é 51.494. O total geral está 12.763 acima, 24,8% a mais, porque toda venda
online e de balcão agora é contada uma vez no próprio canal e outra vez em `Direct`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 250\" role=\"img\" data-fig=\"l11-item\" aria-label=\"Duas tabelas dinâmicas de receita por canal. À esquerda, um item calculado Direct, igual a Online mais Shop, fica no campo Channel ao lado deles, e o total geral soma as quatro linhas: 64257 em vez de 51494. À direita, Online e Shop estão agrupados em Direct e o total geral continua 51494.\"><text x=\"40.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um item calculado: Direct = Online + Shop</text><rect x=\"40.0\" y=\"34.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"47.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Rótulos de Linha</text><rect x=\"190.0\" y=\"34.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"47.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Soma de Revenue</text><rect x=\"40.0\" y=\"60.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"73.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Online</text><rect x=\"190.0\" y=\"60.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"73.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">11.143</text><rect x=\"40.0\" y=\"86.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"99.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop</text><rect x=\"190.0\" y=\"86.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"99.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.620</text><rect x=\"40.0\" y=\"112.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"125.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Wholesale</text><rect x=\"190.0\" y=\"112.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"125.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">38.731</text><rect x=\"40.0\" y=\"138.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"151.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Direct</text><rect x=\"190.0\" y=\"138.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"151.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">12.763</text><rect x=\"40.0\" y=\"164.0\" width=\"150.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"177.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Total Geral</text><rect x=\"190.0\" y=\"164.0\" width=\"140.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"177.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">64.257</text><path d=\"M332 73 L340 73 L340 99 L332 99\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M332 151 L340 151\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M340.0 99.0 L340.0 151.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"348.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">12.763 contados duas vezes</text><text x=\"40.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o total real é 51.494</text><text x=\"505.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um grupo: Online e Shop sob Direct</text><rect x=\"505.0\" y=\"34.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"47.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Rótulos de Linha</text><rect x=\"625.0\" y=\"34.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"47.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Soma de Revenue</text><rect x=\"505.0\" y=\"60.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"73.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Direct</text><rect x=\"625.0\" y=\"60.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"73.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">12.763</text><rect x=\"505.0\" y=\"86.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"99.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">   Online</text><rect x=\"625.0\" y=\"86.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"99.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">11.143</text><rect x=\"505.0\" y=\"112.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"125.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">   Shop</text><rect x=\"625.0\" y=\"112.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"125.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.620</text><rect x=\"505.0\" y=\"138.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"151.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Wholesale</text><rect x=\"625.0\" y=\"138.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"151.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">38.731</text><rect x=\"505.0\" y=\"164.0\" width=\"120.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"177.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Total Geral</text><rect x=\"625.0\" y=\"164.0\" width=\"115.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"734.0\" y=\"177.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">51.494</text><text x=\"505.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cada venda está em exatamente uma linha</text><text x=\"505.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">então o total continua sendo o total</text></svg>", "caption": "Um item calculado é uma linha nova no campo, e o total geral soma todas as linhas que encontra. Um grupo põe as mesmas vendas sob um título novo sem contá-las de novo."}
```

## O que mais ele custa

O total geral é a falha visível. Três outras são mais quietas:

- **Ele aparece em toda parte.** Arraste `Product` para **Linhas** acima de `Channel` e cada produto
  ganha uma linha `Direct` própria, calculada faça sentido ali ou não.
- **Ele não combina com agrupamento.** O Excel se recusa a acrescentar um item calculado a um campo
  enquanto esse campo está agrupado, então o agrupamento da aula 10 e um item calculado não dividem
  um campo.
- **A fórmula dele fica escondida.** Quem lê a tabela vê uma linha chamada `Direct` e não tem como
  saber que ela não é um canal dos dados. A fórmula mora numa caixa de diálogo que ninguém abre.

Uma tabela dinâmica montada sobre o modelo de dados da aula 15 nem oferece item calculado.

Apague-o antes de seguir: **Campos, Itens e Conjuntos › Item Calculado**, escolha `Direct` na lista
**Nome** e clique em **Excluir**. O total geral volta a 51.494.

## Dois jeitos de ter `Direct` sem ele

**Agrupe os itens.** Na tabela dinâmica, clique em `Online`, segure Ctrl e clique em `Shop`; depois
clique com o botão direito e escolha **Agrupar**. O Excel cria um campo novo chamado `Channel2` com
dois itens: `Agrupar1` (`Group1` no Excel em inglês), com `Online` e `Shop`, e `Wholesale`, com ele
mesmo. Clique na célula do grupo e digite `Direct` para renomeá-lo. As linhas passam a mostrar
`Direct` 12.763 e `Wholesale` 38.731, e o total geral continua 51.494, porque um grupo é um título
sobre as vendas e não uma cópia delas. Clique com o botão direito num grupo e escolha **Desagrupar**
para desfazê-lo.

**Ponha nos dados.** Se `Direct` é uma palavra que a empresa usa em mais de um relatório, ela é um
fato sobre cada venda, e um fato sobre uma linha mora numa coluna. Digite `Route` em I1 da planilha
`Sales`, ao lado da tabela, e a tabela incorpora a coluna, como a aula 7 mostrou. Depois, em I2:

```localised
=SE([@Channel]="Wholesale"; "Wholesale"; "Direct")
```

A tabela preenche a coluna até o fim. Atualize a tabela dinâmica e `Route` vira um campo como
qualquer outro, pronto para toda tabela dinâmica, toda fórmula e todo gráfico:

```localised
=SOMASES(Sales[Revenue]; Sales[Route]; "Direct")
=CONT.SES(Sales[Route]; "Direct")
```

A primeira dá **12.763** e a segunda, com `CONT.SES` (`COUNTIFS` no Excel em inglês), **70** vendas.
O grupo é mais rápido para uma tabela dinâmica; a coluna é a que dura.

O resto do curso trabalha com as oito colunas da aula 7, então apague `Route` agora: clique com o
botão direito numa célula dela e escolha **Excluir › Colunas da Tabela**, depois atualize a tabela
dinâmica.
