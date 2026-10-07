---
title: Montando a sua planilha
version: 1
---

A partir desta aula o curso calcula coisas — um tempo de ciclo, uma estimativa, uma faixa de velocidade, o valor de um risco — e você deveria calculá-las também, no seu próprio computador. Você precisa de duas coisas: **um quadro** e **uma planilha**. Nada neste curso fica hospedado para você, e nada precisa ficar.

## O quadro

Qualquer superfície com colunas serve. Post-its numa parede ou uma folha A3 funcionam tão bem quanto uma ferramenta, e para aprender funcionam melhor, porque mover um cartão de papel é uma decisão que você percebe. Se preferir software, o plano gratuito de qualquer ferramenta de quadro basta. O que importa é conseguir desenhar colunas, escrever um limite em cada uma e mover cartões entre elas.

## A planilha: três caminhos

| caminho | o que custa ao seu computador | o que observar |
|---|---|---|
| **LibreOffice Calc**, instalado — recomendado | uma instalação de algumas centenas de megabytes; funciona offline | os nomes das funções seguem o idioma em que o programa roda |
| **Google Planilhas**, no navegador | nada instalado; exige conta Google e conexão | os nomes das funções e o separador seguem a localidade da planilha |
| **Microsoft Excel**, instalado ou no navegador | a versão instalada é paga; o Excel para a web é gratuito com uma conta Microsoft | os nomes das funções seguem o idioma da instalação |

**O LibreOffice Calc é o caminho recomendado**, por três motivos. É livre e gratuito no Windows, no macOS e no Linux. Funciona sem conta e sem conexão. E é a planilha que calculou todo valor que este curso cita: o arquivo `workbook.py`, ao lado do curso, monta os dados, pede ao LibreOffice 24.2 que os recalcule e imprime o que cada fórmula devolveu.

Para instalar, baixe de libreoffice.org ou use o gerenciador de pacotes do seu sistema — no Debian ou no Ubuntu, `sudo apt install libreoffice-calc` instala só o Calc. Qualquer um dos outros dois caminhos dá os mesmos números; as fórmulas deste curso usam só funções que os três têm.

## A primeira folha

Abra uma planilha nova e digite a linha de cabeçalho: **Item**, **Início**, **Fim**, **Dias**. Embaixo, uma linha por item terminado, com as datas escritas como ano-mês-dia — `2026-03-02` —, que toda planilha em todo idioma lê como data. Na coluna Dias, o tempo de ciclo do primeiro item é:

```localised
=C2-B2+1
```

O `+1` é uma convenção, e importa: o time Agenda conta o dia em que um item começou e o dia em que terminou, então um item começado e terminado no mesmo dia levou um dia, não zero. Qualquer que seja a convenção escolhida, use a mesma para todos os itens e diga qual é quando citar um número.

Copie a fórmula coluna abaixo e a planilha ajusta os números das linhas sozinha. A próxima seção trata do que fazer quando isso não funciona.
