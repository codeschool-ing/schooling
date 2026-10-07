---
title: Numa planilha
version: 1
---

**Nada nesta seção foi executado.** O laboratório não tem Excel, e este curso não mostra saída que
não capturou. O que vem a seguir descreve como a mesma tarefa fica numa planilha e no Power Query,
a ferramenta do Excel para importar e moldar dados, e o comportamento que mais importa para a
limpeza.

**Uma planilha adivinha no momento em que o arquivo é aberto.** Dê dois cliques num CSV e o Excel
decide o tipo de cada célula sozinho, sem nenhum passo que você veja ou desfaça. O pandas faz o
mesmo quando não se diz o contrário, e isso dá para mostrar aqui:

```
ana@lab:~/clean$ python -c "import pandas as pd; text = pd.read_csv('raw/order_items.csv', dtype=str); guess = pd.read_csv('raw/order_items.csv'); five = text['product_code'].str.len() == 5; print(text.loc[five, 'product_code'].head(3).tolist(), guess.loc[five, 'product_code'].head(3).tolist(), guess['product_code'].dtype)"
['00833', '00126', '00713'] [833, 126, 713] int64
```

Lidos como texto, os códigos de produto do site são `00833`, `00126`, `00713`. Lidos com o palpite
padrão, viram os números 833, 126 e 713, a mesma perda que a exportação do aplicativo sofreu na
aula 7. Abrir o arquivo direto numa planilha convida o mesmo palpite em todas as colunas de uma vez:
códigos perdem os zeros, CEPs perdem os deles, e datas com dia primeiro ou mês primeiro são lidas
pelas configurações regionais do computador e não pelas do arquivo. Num computador configurado
para o Brasil, onde o separador de listas é o ponto e vírgula, um arquivo separado por vírgulas
também pode abrir com tudo numa coluna só.

O Power Query é a resposta para a maior parte disso, porque transforma os cliques em passos
registrados:

- **Importe pelo Power Query, não abrindo o arquivo**, e defina o tipo de cada coluna você mesmo,
  como texto onde for um código. "Usando a localidade" é a opção que lê datas `dd/mm/aaaa` e
  vírgulas decimais como o Brasil escreve.
- **Cada passo fica guardado** na lista de etapas aplicadas da consulta, pode ser revisado e é
  repetido quando o arquivo é atualizado. Isso é uma receita, o que uma planilha editada à mão não
  é.
- **Remover Duplicatas, Filtrar, Substituir Valores e Agrupar Por** cobrem esta tarefa, e
  **Transformar Outras Colunas em Linhas** é o melt da aula 13.

O fuso é a cláusula difícil. O Power Query tem um tipo para data e hora com fuso, e o `Z` precisa
ser lido para dentro dele de propósito; uma célula comum de planilha não tem fuso nenhum, e ali as
três horas do site precisam ser subtraídas por alguém que sabe que elas são necessárias.

::: track bi
As aulas 13 e 14 de `excel-analytics` montaram exatamente esse tipo de consulta, e para uma equipe
que vive no Excel ele muitas vezes é o lugar certo para um passo de limpeza: quem lê o resultado
consegue abrir os passos. A regra deste curso continua valendo: mantenha o arquivo bruto intacto,
faça toda mudança na consulta, e nunca digite por cima de um valor na planilha que a consulta
produziu.
:::

::: track data-science
Para os dados de treino de um modelo, uma planilha é lugar de olhar, não de limpar: o que quer que
tenha sido feito aos dados precisa ser repetível no arquivo do mês que vem sem uma pessoa clicando,
e isso quer dizer código.
:::

::: track *
Seja qual for a ferramenta que limpa os dados, a planilha continua sendo onde muitos resultados são
lidos. Exportar do pandas ou do SQL com os códigos como texto, e dizer a quem lê para importar em
vez de abrir, poupa a próxima pessoa dos palpites descritos acima.
:::
