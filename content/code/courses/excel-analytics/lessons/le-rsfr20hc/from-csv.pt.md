---
title: Um arquivo CSV, e a localidade que o lê
version: 1
---

**Um arquivo CSV é texto puro, e cada número e cada data dentro dele precisa ser lido pelas regras
de alguém: qual caractere separa os campos, qual marca os decimais e se o dia vem antes do mês.**
Essas regras pertencem ao arquivo, não ao seu computador. A maioria dos erros de importação é um
arquivo escrito com um conjunto de regras e lido com outro, e quase nenhum deles dá erro.

## Dois arquivos para criar

A loja virtual da Café Serra mudou de plataforma em julho de 2026, e a plataforma nova manda uma
exportação por mês. A transportadora manda uma fatura por trimestre, de um sistema configurado no
Brasil. Você vai criar as duas a partir do texto abaixo.

Primeiro, duas pastas. Na sua pasta **Documentos**, crie uma pasta chamada `cafe-serra` e, dentro
dela, outra chamada `web`. Mantenha os nomes exatamente assim: as consultas desta aula e da próxima
apontam para eles.

Para criar um arquivo, abra um editor de texto puro: o **Bloco de Notas** no Windows, ou o
**TextEdit** no Mac seguido de **Formatar › Converter em Texto Simples**. Copie o bloco com o botão
de copiar no canto dele, cole e salve com o nome indicado. No Bloco de Notas, mude **Tipo** para
**Todos os arquivos** antes de salvar, senão o arquivo é salvo como `web-2026-07.csv.txt`.

A exportação de julho da loja virtual vai na pasta `web`. Salve-a como `web-2026-07.csv`:

```
.
```

A fatura da transportadora vai na própria `cafe-serra`, **não** na `web`; a seção 04 explica por
quê. Salve-a como `freight-2026-q3.csv`:

```
.
```

Ponha os dois lado a lado e o problema já aparece. A loja virtual separa os campos com vírgulas,
marca os decimais com ponto e escreve as datas com o ano primeiro. A transportadora separa os campos
com ponto e vírgula, porque a vírgula é a marca decimal dela, e escreve as datas com o dia primeiro.
**Nenhum dos dois arquivos está errado.** Cada um segue as convenções do sistema que o escreveu, e
quem lê precisa saber quais são.

## Abrindo um CSV pelo Power Query

Vá em **Dados › Obter Dados › De Arquivo › De Texto/CSV**, escolha `web-2026-07.csv`, e abre-se uma
prévia com três caixas acima dos dados:

| caixa | o que ela decide | para este arquivo |
|---|---|---|
| **Origem do Arquivo** (File Origin) | a codificação de caracteres, que decide como as letras acentuadas são lidas | deixe como está; este arquivo não tem nenhuma |
| **Delimitador** | o caractere entre os campos | **Vírgula**, que o Excel adivinha pelo arquivo |
| **Detecção de Tipo de Dados** | se o Excel adivinha o tipo de cada coluna pelas primeiras linhas | **Não detectar tipos de dados** |

A última escolha é a importante, e é o contrário do padrão. Um tipo adivinhado é lido com as regras
regionais do **seu** computador, que são as regras erradas para metade dos arquivos que você vai
importar na vida. Mandar o Excel não adivinhar significa que você define cada tipo, com as regras do
arquivo.

Clique em **Transformar Dados**. O editor abre com duas etapas em **Etapas Aplicadas**: `Source`
(Fonte, no Excel em português), que leu o texto e o dividiu nas vírgulas, e `Promoted Headers`
(Cabeçalhos Promovidos), que transformou a primeira linha em nomes de colunas. Toda coluna ainda é
texto.

## Definindo um tipo com a localidade do arquivo

Clique com o botão direito no cabeçalho `Unit price` e escolha **Alterar Tipo › Usando a
Localidade…** (Change Type › Using Locale…). A caixa pede duas coisas: o tipo, **Número Decimal**, e
a localidade em que o texto foi escrito, **Inglês (Estados Unidos)**. Faça o mesmo com `Qty` como
**Número Inteiro** e com `Date` como **Data**, ambos com Inglês (Estados Unidos).

Localidade aqui não quer dizer o idioma das palavras. Quer dizer as convenções de números e datas, e
nomeá-la coluna por coluna é o que faz a consulta dar a mesma resposta em qualquer computador que a
atualize. No arquivo de julho a consulta agora tem **7 linhas** e **18 sacos**, e os preços
multiplicados dão **R$ 924**.

Agora o arquivo da transportadora, pelo mesmo menu. O Excel adivinha **Ponto e vírgula** para o
delimitador, e você de novo escolhe **Não detectar tipos de dados**. No editor, defina `Shipped` como
Data e `Weight kg` e `Freight` como Número Decimal, cada um com **Usando a Localidade…** e
**Português (Brasil)**. A consulta tem **20 linhas**, e o frete soma **R$ 434,30**.

Eis o que cada leitura faz com os dois arquivos, calculado linha por linha:

| texto no arquivo | lido como Inglês (Estados Unidos) | lido como Português (Brasil) |
|---|---|---|
| `45.00` (loja virtual) | 45 | **4500**: lá o ponto é separador de milhar |
| `0,75` (transportadora) | **75**: lá a vírgula é separador de milhar | 0,75 |
| `03/07/2026` (transportadora) | **7 de março de 2026**, mês primeiro | 3 de julho de 2026 |
| `16/07/2026` (transportadora) | **um erro**: não existe mês 16 | 16 de julho de 2026 |

Lido com a localidade errada, o arquivo da transportadora tem **8 datas** que viram outra data,
válida, sem aviso nenhum, e **10** que viram erros. As outras 2, `07/07/2026` e `09/09/2026`, saem
certas por sorte, porque dia e mês são iguais. Os erros são a parte boa, porque você os vê. As datas
silenciosas poriam um envio de julho em março, e ninguém saberia até um total mensal parecer
estranho.

## A consulta, etapa por etapa

Esta é a consulta da transportadora em M, a linguagem que a barra de fórmulas mostra. Você não precisa
digitá-la, porque os cliques acima a escrevem, mas precisa saber lê-la. Os nomes das etapas aparecem
aqui em inglês; num Excel em português o editor os escreve traduzidos, e o resto do código é igual:

```schooling-example
{"language": "powerquery", "file": "Freight", "parts": [
 {"code": "", "note": "Uma consulta é um bloco `let`: uma lista de etapas com nome, cada uma calculada a partir da anterior."},
 {"code": "", "note": "Lê o arquivo e divide cada linha nos pontos e vírgulas. O caminho é onde você o salvou, então o seu vai ter o nome da sua pasta de usuário; `Encoding` é a caixa Origem do Arquivo, e pode mostrar outro número no seu computador."},
 {"code": "", "note": "A primeira linha vira os nomes das colunas. Um nome de etapa com espaço é escrito `#\"…\"`."},
 {"code": "", "note": "Os três tipos, lidos com as convenções brasileiras. O último argumento é o motivo desta seção inteira: sem ele, os tipos são lidos com as convenções de qualquer computador que atualize a consulta. A caixa escreve uma etapa a cada uso; aqui as três estão numa etapa só, que faz o mesmo."},
 {"code": "", "note": "O resultado da consulta é a etapa nomeada depois de `in`, que é a última."}
]}
```

Feche o editor com **Página Inicial › Fechar e Carregar**. Cada consulta vai para uma tabela numa
planilha nova com o nome dela, e a seção 08 desta aula diz o que mais **Carregar** sabe fazer.
Renomeie a consulta da transportadora para `Freight`: no painel **Consultas e Conexões**, à direita,
clique nela com o botão direito, escolha **Renomear** e digite o nome. A aula 14 se refere a ela por
esse nome.

A consulta de julho é treino. A seção 04 a substitui por uma que lê todos os meses de uma vez.

## O clique duplo, para comparar

Dê um clique duplo em `freight-2026-q3.csv` na pasta dele e o Excel o abre direto, sem o Power Query,
usando as configurações regionais do seu computador para tudo. Um Excel num computador configurado
com as convenções brasileiras divide cada linha nos pontos e vírgulas e lê todos os valores
corretamente. Um configurado em inglês divide nas vírgulas, e as vírgulas deste arquivo estão dentro
dos números:

```schooling-figure
{"svg": "<svg data-fig=\"l13-split\"></svg>", "caption": ""}
```

O mesmo arquivo, dois resultados, e nada na tela diz quais regras foram usadas. Esse é o motivo para
importar pelo Power Query e nomear a localidade.
