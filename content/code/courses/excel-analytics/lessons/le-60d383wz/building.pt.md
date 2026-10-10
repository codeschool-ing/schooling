---
title: Montando um gráfico a partir de um resumo ou de uma tabela dinâmica
version: 1
---

**Faça o gráfico do resumo, nunca dos registros.** Selecione a tabela `Sales` e insira um gráfico de
colunas, e o Excel desenha um grupo de colunas para cada uma das 108 vendas: uma cerca de estacas que
não responde nada. Um gráfico desenha um punhado de números que alguém já somou, e há dois lugares
para somá-los: um pequeno intervalo de fórmulas que você mesmo monta, ou uma tabela dinâmica.

## Um gráfico a partir de um intervalo de fórmulas

Crie uma planilha chamada `Monthly`. Digite os cabeçalhos `Month`, `Revenue` e `Bags` em A1, B1 e
C1, e a data `2025-01-01` em A2. Depois, em A3:

```localised
=DATAM(A2;1)
```

`DATAM` (`EDATE` no Excel em inglês) move uma data em meses inteiros, então A3 mostra o primeiro dia
de fevereiro. Arraste até A19, o primeiro de junho de 2026. Em B2 e C2:

```localised
=SOMASES(Sales[Revenue]; Sales[Date]; ">="&A2; Sales[Date]; "<"&DATAM(A2;1))
=SOMASES(Sales[Bags]; Sales[Date]; ">="&A2; Sales[Date]; "<"&DATAM(A2;1))
```

Cada uma, com `SOMASES` (`SUMIFS`), soma as vendas do primeiro dia do mês até o primeiro do mês
seguinte, sem incluí-lo: os critérios de data da aula 5. Arraste as duas até a linha 19 e confira as
colunas contra a tabela inteira:

```localised
=SOMA(B2:B19)
=SOMA(C2:C19)
```

Elas respondem 51.494 e 591, os totais das aulas 1 e 2. Dê à coluna A o formato de número
personalizado `mmm/aaaa` (`mmm yyyy` no Excel em inglês) para ela mostrar `jan/2025`.

Agora selecione A1:B19 e escolha **Inserir › Inserir Gráfico de Linhas ou de Áreas › Linhas**. O
Excel vê datas na primeira coluna e faz dela um eixo de datas, um ponto por mês na ordem do
calendário. A linha chega ao pico de R$ 5.004 em janeiro de 2026 e cai a R$ 971 em abril de 2026.
Essa queda é a coisa mais importante que o gráfico mostra, e uma fórmula a explica:

```localised
=CONT.SES(Sales[Channel]; "Wholesale"; Sales[Date]; ">="&DATA(2026;4;1); Sales[Date]; "<"&DATA(2026;6;1))
```

Ela, com `CONT.SES` (`COUNTIFS`), responde 0. Não houve venda de atacado em abril nem em maio de
2026, e o atacado é três quartos da receita. O gráfico achou a pergunta; a fórmula a respondeu.

**Um gráfico feito sobre um intervalo simples desenha exatamente aquele intervalo.** Quando chegarem
as vendas de julho, a linha 20 terá de ser acrescentada à mão e o intervalo do gráfico alargado para
incluí-la. Transforme o resumo numa tabela com **Ctrl+T**, como na aula 7, e uma linha acrescentada
à tabela entra no gráfico sozinha.

## Um gráfico dinâmico

A planilha `Report` da aula 11 já tem `ByProduct`, a receita de cada produto. Ordene-a primeiro:
clique com o botão direito numa célula de receita e escolha **Classificar › Classificar do Maior
para o Menor**. Depois clique na tabela dinâmica, escolha **Análise da Tabela Dinâmica › Gráfico
Dinâmico** (*PivotChart*) e escolha **Barras › Barras Agrupadas**.

As barras saem de cabeça para baixo. Um gráfico de barras desenha a primeira categoria embaixo,
junto do eixo, então o maior produto, `CER1K` com 21.356, fica no pé do gráfico. Dê um clique duplo
no eixo dos produtos e, em **Formatar Eixo**, marque **Categorias em ordem inversa** (*Categories in
reverse order*); a maior barra sobe para o topo, onde o leitor começa.

Um gráfico dinâmico é desenhado a partir da tabela dinâmica e a acompanha em tudo:

- **As segmentações o mexem.** Clique em `Wholesale` na segmentação de `Channel` da aula 11 e o
  gráfico se redesenha com quatro barras, os produtos que os clientes de atacado compram.
- **O layout o mexe.** Arraste outro campo para **Linhas** e o gráfico ganha um nível de categorias;
  tire um e ele o perde.
- **Ele traz botões.** Os botões de campo cinza no gráfico o filtram como os menus da própria tabela
  dinâmica. **Análise do Gráfico Dinâmico › Botões de Campo** (*Field Buttons*) os esconde quando o
  gráfico é para ler, e não para comandar.

Um limite vale saber antes de escolher. Um gráfico dinâmico não pode ser de dispersão, de bolhas nem
de ações: a dispersão precisa de cada registro como um ponto, e a tabela dinâmica já somou os
registros.

## Qual usar

Um gráfico sobre um intervalo de fórmulas fica exatamente como você o montou: você decide cada linha,
e nada o reorganiza a não ser você. Um gráfico dinâmico se reorganiza a cada segmentação e a cada
mudança de layout, o que é um defeito num relatório impresso uma vez por mês e é todo o propósito de
um painel que alguém explora com segmentações, o assunto da aula 17.
