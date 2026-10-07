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
| **LibreOffice Calc numa máquina virtual** | o disco e a memória da própria máquina virtual, além do Calc | só vale a pena se você já trabalha dentro de uma máquina virtual Linux; instale o Calc nela exatamente como abaixo |
| **online**: Google Planilhas, ou o Excel para a web | nada instalado; exige uma conta (Google ou Microsoft) e conexão | os nomes das funções e o separador seguem a localidade da planilha |

**O LibreOffice Calc é o caminho recomendado**, por três motivos. É livre e gratuito no Windows, no macOS e no Linux. Funciona sem conta e sem conexão. E é a planilha que calculou todo valor que este curso cita: cada valor mostrado ao lado de uma fórmula é o que o LibreOffice 24.2 devolveu para ela.

Para instalar, baixe de libreoffice.org ou use o gerenciador de pacotes do seu sistema — no Debian ou no Ubuntu, `sudo apt install libreoffice-calc` instala só o Calc. Os outros caminhos dão os mesmos números, e o Microsoft Excel instalado, que é pago, também; as fórmulas deste curso usam só funções que todos eles têm.

## Quando a instalação falha

Se o instalador não roda — sem permissão de administrador num computador do trabalho, um sistema operacional mais antigo do que o LibreOffice atual aceita, ou sem espaço no disco —, não brigue com ele. Siga o caminho online, que só precisa de um navegador, e volte ao instalado depois; os números são os mesmos.

No Debian ou no Ubuntu, se o `apt` responder que não encontra o pacote, a lista de pacotes dele está desatualizada. `sudo apt update` atualiza a lista, e aí o comando de instalação funciona.

Qualquer que seja o caminho, confira antes de seguir: digite `=1+1` numa célula vazia e tecle Enter. Um **2** quer dizer que a planilha calcula. Se a célula mostrar a própria fórmula, ela está formatada como texto; limpe a formatação (no LibreOffice, **Formatar → Limpar formatação direta**) e digite de novo.

## A primeira folha

Abra uma planilha nova e digite a linha de cabeçalho: **Item**, **Início**, **Fim**, **Dias**. Embaixo, uma linha por item terminado, com as datas escritas como ano-mês-dia — `2026-03-02` —, que toda planilha em todo idioma lê como data. Estes são os vinte itens que o time Agenda terminou em março de 2026, e o resto desta aula calcula a partir deles:

| Item | Início | Fim |
|---|---|---|
| AG-101 | 2026-03-02 | 2026-03-03 |
| AG-104 | 2026-02-26 | 2026-03-04 |
| AG-097 | 2026-02-27 | 2026-03-05 |
| AG-108 | 2026-03-04 | 2026-03-06 |
| AG-110 | 2026-03-07 | 2026-03-09 |
| AG-095 | 2026-02-21 | 2026-03-10 |
| AG-112 | 2026-03-09 | 2026-03-11 |
| AG-106 | 2026-03-03 | 2026-03-12 |
| AG-099 | 2026-02-22 | 2026-03-12 |
| AG-109 | 2026-03-05 | 2026-03-13 |
| AG-115 | 2026-03-13 | 2026-03-17 |
| AG-113 | 2026-03-12 | 2026-03-18 |
| AG-102 | 2026-03-05 | 2026-03-19 |
| AG-117 | 2026-03-16 | 2026-03-20 |
| AG-111 | 2026-03-10 | 2026-03-20 |
| AG-119 | 2026-03-19 | 2026-03-23 |
| AG-114 | 2026-03-18 | 2026-03-24 |
| AG-118 | 2026-03-20 | 2026-03-25 |
| AG-116 | 2026-03-17 | 2026-03-26 |
| AG-120 | 2026-03-25 | 2026-03-27 |

 Na coluna Dias, o tempo de ciclo do primeiro item é:

```localised
=C2-B2+1
```

O `+1` é uma convenção, e importa: o time Agenda conta o dia em que um item começou e o dia em que terminou, então um item começado e terminado no mesmo dia levou um dia, não zero. Qualquer que seja a convenção escolhida, use a mesma para todos os itens e diga qual é quando citar um número.

Copie a fórmula coluna abaixo e a planilha ajusta os números das linhas sozinha. A próxima seção trata do que fazer quando isso não funciona.
