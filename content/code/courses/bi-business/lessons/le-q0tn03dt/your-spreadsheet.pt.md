---
title: Suas ferramentas: uma planilha, e nada mais para instalar
version: 1
---

Este curso é sobre julgamento — que pergunta, que número, que comparação — e julgamento sobre números
se aprende calculando alguns deles você mesmo. A partir da aula 2, toda aula que tem números traz uma
tabela pequena para digitar e as fórmulas para escrever, com o valor que cada fórmula deve devolver ao
lado. **Nenhuma máquina é fornecida para o curso, e nenhuma é necessária: tudo acontece no seu próprio
computador, numa planilha.**

Não há banco de dados, linguagem de programação nem ferramenta de BI para instalar. Eles vêm nos
cursos depois deste na trilha `bi`, cada um com a sua instalação. Além da planilha, você precisa de um
lugar para escrever alguns parágrafos — qualquer editor de texto ou processador de texto que já tenha
— e papel para um rascunho de vez em quando, que funciona melhor que qualquer programa de desenho numa
primeira tentativa.

## A planilha: três caminhos

| caminho | o que custa ao seu computador | o que observar |
|---|---|---|
| **LibreOffice Calc**, instalado — recomendado | uma instalação de algumas centenas de megabytes; funciona sem internet | os nomes das funções seguem o idioma em que o programa roda |
| **LibreOffice Calc numa máquina virtual** | a memória e o disco da própria máquina virtual, além do Calc | só vale se você já trabalha dentro de uma; instale o Calc nela exatamente como abaixo |
| **online**: Google Planilhas, ou Excel para a web | nada instalado; precisa de uma conta (Google ou Microsoft) e de conexão | os nomes das funções e os separadores seguem a configuração de idioma do arquivo |

**O LibreOffice Calc é o caminho recomendado.** É livre e de código aberto, roda no Windows, no macOS
e no Linux, e funciona sem conta e sem conexão. Também é a planilha que calculou todo valor que este
curso mostra ao lado de uma fórmula: cada um é o que o LibreOffice Calc 24.2 devolveu. Baixe em
libreoffice.org, ou use o gerenciador de pacotes do seu sistema; no Debian ou no Ubuntu,
`sudo apt install libreoffice-calc` instala só o Calc.

Os outros caminhos dão os mesmos números, e o Microsoft Excel instalado também, que é pago. As
fórmulas deste curso usam só funções que todos eles têm — em português, `SOMA`, `MÉDIA`, `MED`,
`ARRED`, `MÍNIMO`, `MÁXIMO` e `SE` — e aritmética. Se você fez a aula 12 de `computing-essentials`, já
usou a maioria delas.

## Confira antes de seguir

Digite `=1+1` numa célula vazia e aperte Enter. Um **2** quer dizer que a planilha calcula. Se a
célula mostrar a própria fórmula, ela está formatada como texto: limpe a formatação (no LibreOffice,
**Formatar → Limpar formatação direta**) e digite de novo.

## A primeira planilha: quem vende o quê

As vendas da Varanda em 2025, em milhares de reais, por loja e da loja online. Digite as duas colunas
numa planilha nova, a partir de A1:

| | A | B |
|---|---|---|
| 1 | Loja | Vendas |
| 2 | Savassi | 11880 |
| 3 | Pampulha | 10560 |
| 4 | Contagem | 12480 |
| 5 | Betim | 8840 |
| 6 | Nova Lima | 9450 |
| 7 | Sete Lagoas | 6720 |
| 8 | Divinópolis | 6460 |
| 9 | Ipatinga | 7040 |
| 10 | Juiz de Fora | 8960 |
| 11 | Online | 15610 |

Digite os números puros, sem separador de milhar e sem símbolo de moeda; a próxima seção diz por quê.
Em A12 digite `Total` e em B12 a soma da coluna:

```localised
=SOMA(B2:B11)      98000
```

**R$ 98,0 milhões**, as vendas do ano. Agora a parcela de cada linha, em porcentagem arredondada a uma
casa decimal. Em C1 digite `Parcela`, e em C2:

```localised
=ARRED(B2/B$12*100;1)      12,1
```

Copie C2 até C11. O `$` antes do 12 mantém a fórmula apontando para o total enquanto ela desce; sem
ele, C3 dividiria por B13, que está vazia. Sua coluna deve mostrar **12,7** para Contagem e **15,9**
para a loja online: a loja online vende mais que qualquer loja física sozinha.

Some as parcelas para conferir:

```localised
=SOMA(C2:C11)      99,9
```

Não dá 100, porque cada parcela foi arredondada sozinha, e os dez arredondamentos não se anularam.
Isso não é erro, e um relatório que mostra parcelas arredondadas somando 99,9 é honesto; um em que
alguém empurrou uma parcela para a coluna dar 100 não é. Salve o arquivo num lugar onde vá achá-lo de
novo — cada aula que calcula acrescenta uma aba a ele.
