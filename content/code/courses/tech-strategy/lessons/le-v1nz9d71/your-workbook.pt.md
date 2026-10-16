---
title: Suas ferramentas: uma planilha e um editor de texto
version: 1
---

Metade deste curso é dinheiro. Uma dívida precificada como juro por sprint, uma comparação de três
anos, um custo total de propriedade, um custo de atraso — cada um é aritmética com resposta certa,
e você aprende mais rápido calculando do que lendo a tabela de outra pessoa. A outra metade é
escrita: uma estratégia de uma página na aula 3 e registros de decisão na aula 17.

**Nenhuma máquina é fornecida para este curso, e nenhuma é necessária.** Tudo acontece no seu
próprio computador, com duas ferramentas comuns e uma terceira opcional:

- uma planilha, para todo número a partir da aula 5;
- um editor de texto simples, para as páginas que você escreve — qualquer um que salve um arquivo
  `.txt` ou `.md` puro: o Bloco de Notas no Windows, o TextEdit em modo de texto simples no macOS,
  o gedit ou o Kate no Linux, ou um editor de programador que você já use;
- uma ferramenta de diagramas, se você gosta de desenhar na tela. Papel funciona igual. O
  diagrams.net é gratuito, roda no navegador ou como aplicativo de desktop, e não pede conta.

## A planilha: três caminhos

| caminho | o que custa ao seu computador | no que prestar atenção |
|---|---|---|
| **LibreOffice Calc**, instalado — recomendado | uma instalação de algumas centenas de megabytes; funciona sem internet | os nomes das funções seguem o idioma em que o programa roda |
| **LibreOffice Calc numa máquina virtual** | o disco e a memória da própria máquina virtual, além do Calc | só vale a pena se você já trabalha dentro de uma máquina virtual Linux; instale o Calc lá exatamente como abaixo |
| **online**: Google Planilhas, ou Excel para a web | nada instalado; pede uma conta (Google ou Microsoft) e conexão | os nomes das funções e os separadores seguem a localidade da planilha |

**O LibreOffice Calc é o caminho recomendado.** É gratuito e de código aberto no Windows, no macOS
e no Linux, funciona sem conta e sem conexão, e é a planilha que calculou todo valor que este curso
mostra ao lado de uma fórmula: cada um é o que o LibreOffice 24.2 devolveu. Baixe em
libreoffice.org, ou use o gerenciador de pacotes do seu sistema — no Debian ou no Ubuntu,
`sudo apt install libreoffice-calc` instala só o Calc.

Os outros caminhos dão os mesmos números, e o Microsoft Excel instalado também, que é pago. As
fórmulas deste curso usam só funções que todos eles têm: em português, `SOMA`, `ARRED`, `ÍNDICE`,
`CORRESP`, `MÍNIMO`, `MAIOR` e `SE`.

## Confira antes de seguir

Digite `=1+1` numa célula vazia e aperte Enter. Um **2** quer dizer que a planilha calcula. Se a
célula mostrar a própria fórmula, ela está formatada como texto; limpe a formatação (no
LibreOffice, **Formatar → Limpar formatação direta**) e digite de novo.

## A primeira planilha: quanto custa uma reunião

Todo argumento de estratégia neste curso termina em horas multiplicadas por uma taxa, então comece
por aí. A Coreto conta a hora de engenharia a **R$ 150**, o custo carregado: salário, encargos,
benefícios e equipamento divididos pelas horas efetivamente trabalhadas. Digite este cabeçalho e
uma linha:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Pessoas | Horas | Taxa | Custo |
| 2 | 8 | 1 | 150 | |

Em D2, o custo de uma reunião de oito engenheiros por uma hora:

```localised
=A2*B2*C2      1200
```

E numa célula vazia, a mesma reunião toda semana — quatro por mês, doze meses:

```localised
=D2*4*12      57600
```

**Uma reunião semanal de uma hora com oito engenheiros custa à Coreto R$ 57.600 por ano.** Ninguém
aprova esse número, porque ninguém nunca o vê escrito; ele é gasto uma hora de cada vez. Boa parte
deste curso é o hábito de escrever números assim antes de decidir, e a planilha é onde eles são
escritos.

Salve o arquivo num lugar onde você vá achá-lo de novo. Cada aula que calcula acrescenta uma aba a
ele. A próxima seção é o que fazer quando uma fórmula responde com um erro em vez de um número.
