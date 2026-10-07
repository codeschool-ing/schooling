---
title: A sua bancada
version: 1
---

Este curso não tem software próprio para instalar, e a plataforma não te dá máquina nenhuma. O que você
precisa é pouco, e **você monta sozinho, no seu computador, agora**, porque todo exercício daqui em diante
pede que você faça algo: um slide, um sumário, um gráfico com o título certo.

## O que vai nela

1. **Uma pasta** para o curso, chamada `storytelling` ou qualquer nome que você vá achar de novo. Tudo o
   que você fizer vai nela, um arquivo por aula.
2. **Uma planilha**, para refazer qualquer número antes de colocá-lo num slide.
3. **Uma ferramenta de slides**, para desenhar os slides que as aulas pedem.
4. **A tabela da Faro**, salva como `faro.csv` na pasta. Copie o bloco da seção anterior com o botão de
   copiar, cole num editor de texto simples e salve com esse nome. Salve como texto puro, com codificação
   UTF-8, se o editor perguntar.
5. **Uma análise sua**, que é o assunto de verdade do curso a partir da aula 4.

## Três jeitos de ter planilha e ferramenta de slides

- **Instalado, e recomendado: LibreOffice.** Gratuito, de código aberto, e igual no Windows, no macOS e no
  Linux. Baixe em libreoffice.org e instale como qualquer programa; o Calc é a planilha e o Impress é a
  ferramenta de slides. Funciona sem internet, nada do que você faz sai do seu computador, e toda
  fórmula deste curso foi conferida nele.
- **Online: Planilhas Google e Apresentações Google.** Nada para instalar, e roda num computador fraco ou
  num Chromebook. Exige conta Google e conexão, e os seus arquivos ficam nos servidores do Google, o que
  importa quando a análise é com dados do seu empregador.
- **Com licença: Microsoft Excel e PowerPoint.** Se a sua empresa ou faculdade te dá o Microsoft 365, use.
  Toda fórmula daqui tem o mesmo nome no Excel.

Seja qual for a escolha, as aulas descrevem o que fazer, e não qual menu abrir, porque os menus mudam e as
ideias não.

## A primeira conta

Abra o `faro.csv` na planilha. As colunas caem de A a E, com o cabeçalho na linha 1 e as vinte e quatro
linhas abaixo. Numa célula vazia, digite a taxa de cancelamento dos clientes cuja primeira entrega
atrasou:

```localised
=SOMASES(E2:E25;C2:C25;"late")/SOMASES(D2:D25;C2:C25;"late")
```

Ela soma os cancelamentos das linhas marcadas `late` e divide pelos assinantes dessas mesmas linhas.
Formate a célula como porcentagem e ela mostra **41,5%**. Troque `"late"` por `"on time"` nos dois
lugares e ela mostra **17,4%**. Esses são os dois números sobre os quais o curso inteiro é construído, e
você acabou de calculá-los em vez de aceitá-los de confiança, o que é um hábito que a aula 12 transforma
em método.

## Quando não funciona

- **Tudo cai na coluna A.** A planilha adivinhou o separador errado. Abra o arquivo de novo e, na janela
  de importação, escolha vírgula como separador e mais nada. Em português, o palpite padrão costuma ser
  ponto e vírgula.
- **A fórmula é recusada.** Em português a função tem outro nome e o separador é ponto e vírgula. O bloco
  da aula mostra a grafia do seu idioma; digite essa.
- **A fórmula aparece como texto.** A célula estava formatada como texto antes de você digitar. Limpe a
  formatação e digite de novo.
- **Os acentos aparecem errados** num arquivo que você fez depois. Salve CSV como UTF-8.

## A sua análise

A partir da aula 4, todo exercício é feito duas vezes: uma sobre a Faro, onde as respostas são
conhecidas, e outra sobre uma análise sua, onde não são. Escolha agora.

::: track bi
Use a análise que você construiu na trilha de BI: o painel e as perguntas por trás dele, de
`analytics-bi`, ou o modelo que você desenhou em `warehouse-modeling`. Escolha um achado dele sobre o qual
alguém deveria agir.
:::

::: track data-science
Use um modelo da trilha de ciência de dados, o classificador ou a regressão que você treinou em
`machine-learning`. A sua história não é a acurácia do modelo; é o que o modelo permite alguém decidir.
:::

::: track *
Use qualquer análise que você já tenha feito, no trabalho ou no estudo. Se não tiver nenhuma, pegue um
conjunto de dados público da sua cidade ou do instituto de estatística do seu país e faça a ele uma
pergunta com que alguém se importaria.
:::

Escreva a pergunta no alto de um arquivo chamado `my-analysis.txt` na pasta. Ela vai mudar ao longo do
curso, e é para mudar.
