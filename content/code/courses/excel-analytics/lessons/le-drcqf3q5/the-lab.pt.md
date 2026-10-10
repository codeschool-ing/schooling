---
title: O seu laboratório é o Excel no seu computador
version: 1
---

**Ninguém aprende planilha vendo alguém usar uma.** Toda aula aqui pede que você mesmo digite a
fórmula, monte a tabela dinâmica ou percorra a consulta, nos dados da seção 05, e depois compare o
seu número com o da página. Então, antes de tudo, você precisa de um Excel que faça tudo o que o
curso faz. Esta seção é sobre conseguir um, e a próxima é sobre o que fazer quando isso dá errado.

A plataforma não roda nenhum programa para você. O laboratório é o seu computador, ou uma máquina
virtual dentro dele, ou um navegador, e a escolha decide quanto do curso você consegue acompanhar.

## O que o curso precisa do Excel

| recurso | primeiro uso | exige |
|---|---|---|
| `PROCX` e matrizes dinâmicas | aula 4 | Excel 2021, Excel 2024 ou Microsoft 365 |
| tabelas dinâmicas, segmentações, linhas do tempo | aulas 10 e 11 | qualquer Excel recente |
| **Power Query** | aulas 13 e 14 | Excel para Windows; em parte no Mac |
| **Power Pivot e DAX** | aulas 15 e 16 | **só o Excel para Windows** |

A última linha é a que decide. O Power Pivot só existe no Excel para Windows: não no Mac, não no
navegador e em nenhuma alternativa gratuita. As aulas 15 e 16 se apoiam nele, e o painel da aula 17
é montado sobre o que elas constroem.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa para você | aulas |
|---|---|---|---|
| **instalado** (recomendado) | Excel para Windows, de uma assinatura do Microsoft 365 | a assinatura, a menos que uma escola ou empresa já lhe dê uma; alguns gigabytes de disco | todas as 18 |
| **uma máquina virtual** | Windows rodando dentro de um Mac ou de um computador com Linux, com o Excel para Windows instalado nele | uma licença do Windows além da assinatura; 64 GB de disco e 4 GB de memória para o próprio Windows | todas as 18 |
| **online** | Excel para a web, num navegador | nada além de uma conta Microsoft gratuita | 1 a 12, com lacunas |

**Instalado é o caminho recomendado** quando o seu computador roda Windows. É o único em que toda
aula funciona como está escrita, e é o que a maioria das empresas usa, então o que você aprende
aqui é o que vai encontrar no trabalho. Muitos alunos já têm sem saber: uma universidade ou empresa
que usa o Microsoft 365 costuma incluir os aplicativos de desktop, e entrar em office.com com essa
conta mostra um botão **Instalar aplicativos** se a sua incluir.

**Num Mac**, o Excel para Mac cobre as aulas 1 a 12 do mesmo jeito. O Power Query chegou ao Mac
aos poucos e cobre parte das aulas 13 e 14; o Power Pivot não existe lá. Para as aulas 15 e 16, o
caminho é a **máquina virtual**: o Windows 11 numa máquina virtual (Parallels Desktop ou UTM num Mac
com Apple silicon, VirtualBox num Mac com Intel ou num computador com Linux), com o Excel para
Windows instalado dentro dela. Custa uma licença do Windows e um computador com espaço para um
segundo sistema: a Microsoft pede 64 GB de armazenamento e 4 GB de memória para o Windows 11, e essa
memória sai do seu sistema enquanto a máquina roda, então 8 GB no computador é o mínimo na prática.

**Online**, o Excel para a web não pede instalação nem pagamento: uma conta Microsoft gratuita o
abre em office.com. Ele dá conta das fórmulas, tabelas, validação, formatação condicional, tabelas
dinâmicas e gráficos das aulas 1 a 12, com alguns comandos faltando ou em outro lugar. Ele não cria
um modelo do Power Pivot, e o Power Query dele é bem mais magro que o do desktop, então é um jeito
de começar hoje, não de terminar o curso. Planos gratuitos mudam quando o dono quer, e nada neste
curso depende deste.

Dois programas que não são o Excel merecem ser citados, porque talvez você já os tenha. O
**LibreOffice Calc** é gratuito e instalado; cobre as aulas 2 a 6 e as tabelas dinâmicas da aula 10,
e tem `PROCX` a partir da versão 24.8. O **Planilhas Google** é gratuito e online, com `PROCX`,
tabelas dinâmicas e segmentações. Nenhum dos dois tem Power Query nem Power Pivot, e os dois chamam
alguns menus por outros nomes, então servem para praticar as aulas de fórmulas, não para acompanhar
o curso.

## Conferindo o Excel que você tem

Três verificações, numa pasta de trabalho nova e em branco, levam um minuto e poupam uma noite
depois:

1. **A versão.** Vá em **Arquivo › Conta** e olhe em **Informações do Produto**. Microsoft 365,
   Excel 2021 ou Excel 2024 é o que você quer; **Sobre o Excel**, na mesma página, dá a compilação.
2. **Uma função nova.** Digite `=PROCX(1;{1};{1})` em qualquer célula. A resposta deve ser `1`. Se
   aparecer `#NOME?`, este Excel é anterior ao `PROCX`, e a próxima seção diz o que fazer.
3. **As ferramentas de dados.** Abra a guia **Dados**. Deve aparecer **Obter Dados** na ponta
   esquerda, que é o Power Query. No Windows, procure também uma guia **Power Pivot**; se ela não
   estiver lá, a próxima seção a liga.

Quando as três passarem, siga para a seção 05 e monte a pasta de trabalho.
