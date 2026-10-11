---
title: Para onde vai o resultado de uma consulta, e quando ele atualiza
version: 1
---

**Para onde vai o resultado de uma consulta é uma decisão separada do que a consulta faz, e pode ser
mudada a qualquer momento sem tocar em uma única etapa.** Até aqui esta aula usou duas respostas: uma
tabela numa planilha nova e uma conexão sem tabela nenhuma. Existe uma terceira, e a escolha entre as
três depende de quem lê o resultado.

## Os três destinos

**Página Inicial › Fechar e Carregar** manda o resultado para o padrão, uma tabela numa planilha nova.
**Página Inicial › Fechar e Carregar Para…** abre a caixa **Importar Dados**, que oferece as escolhas:

| escolha | o que você recebe | quando é a certa |
|---|---|---|
| **Tabela** | as linhas numa planilha, como uma tabela do Excel com o nome da consulta | uma pessoa precisa ler ou filtrar as linhas, ou uma fórmula precisa delas |
| **Relatório de Tabela Dinâmica** ou **Gráfico Dinâmico** | uma tabela dinâmica montada direto sobre a consulta, sem linhas em planilha nenhuma | as linhas só são lidas resumidas |
| **Apenas Criar Conexão** (Only Create Connection) | nada em planilha nenhuma; a consulta existe e outras consultas podem usá-la | uma etapa intermediária, como `Sales` e `Products` na seção 05 |

Abaixo delas, uma caixa chamada **Adicionar estes dados ao Modelo de Dados** carrega as linhas no
modelo que a aula 15 monta, em que as tabelas se relacionam em vez de serem consultadas por busca.
Deixe-a desmarcada por enquanto; a aula 15 volta a ela.

Para mudar o destino de uma consulta que já existe, abra **Dados › Consultas e Conexões**, clique na
consulta com o botão direito e escolha **Carregar Para…**. A mesma caixa se abre. Trocar uma tabela
por uma conexão tira a tabela da planilha, e o Excel avisa antes de fazer isso.

## O que o painel lhe diz

O painel **Consultas e Conexões** lista cada consulta com uma linha embaixo do nome. Para `WebOrders`
ela diz **24 linhas carregadas**, que é a mesma conferência que a seção 05 da aula 1 fez com
`CONT.VALORES` (`COUNTA` no Excel em inglês), só que feita pelo Excel: se o número não for o esperado, algo
antes está errado. Para `Sales` ela diz *Somente conexão*.

Quando algumas células não puderam ser convertidas, como as datas da transportadora lidas com a
localidade errada na seção 03, a linha também diz quantos **erros** houve, e clicar nela abre uma
consulta que lista as linhas com erro. Um erro numa tabela carregada chega como célula vazia, então
essa linha muitas vezes é o único lugar onde o problema aparece.

## Atualizando

Uma consulta roda quando mandam:

- **Dados › Atualizar Tudo** roda todas as consultas da pasta de trabalho, na ordem em que dependem
  umas das outras;
- clicar com o botão direito numa consulta do painel e escolher **Atualizar** roda aquela, e as que
  ela lê;
- no painel, botão direito › **Propriedades…** abre as configurações da consulta, onde **Atualizar
  dados ao abrir o arquivo** faz a pasta de trabalho se atualizar ao ser aberta, e **Atualizar a cada
  … minutos** faz isso num cronômetro enquanto o arquivo está aberto.

Atualizar ao abrir serve para um arquivo que outras pessoas abrem, como o painel da aula 17, porque
elas veem números atuais sem saber que existe uma consulta. Também quer dizer que o arquivo lê as
fontes toda vez que alguém o abre, e quem não alcança esses arquivos recebe um erro em vez dos números
que você viu. A aula 17 volta a isso quando o painel é compartilhado.

## Não digite numa tabela carregada

Uma tabela carregada é a saída da consulta, e a consulta manda nela. Digite uma correção numa célula
de `WebOrders` e ela fica lá só até a próxima atualização, que escreve o resultado da consulta por
cima. Se um valor está errado na origem, corrija no arquivo de origem ou com uma etapa, e a correção
sobrevive a todas as atualizações seguintes. Uma correção digitada na saída é uma correção que alguém
refaz todo mês.

## O que você tem agora

No fim desta aula a pasta de trabalho deve ter estas consultas, e a aula 14 começa delas:

| consulta | de onde | carregada em |
|---|---|---|
| `WebOrders` | a pasta `web`, três arquivos | uma tabela numa planilha própria, 24 linhas |
| `Freight` | `freight-2026-q3.csv` | uma tabela numa planilha própria, 20 linhas |
| `Sales` | a tabela `Sales` desta pasta de trabalho | somente conexão |
| `Products` | a tabela `Products` desta pasta de trabalho | somente conexão |

Salve a pasta de trabalho. As planilhas e fórmulas das aulas 1 a 12 continuam intactas: toda consulta
lê delas ou dos seus arquivos, e nenhuma escreve em nada além da própria tabela.
