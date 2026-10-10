---
title: O seu laboratório, e três jeitos de ter um
version: 1
---

**Toda aula deste curso conduz um navegador com um programa**, e esse navegador precisa estar num
computador que você controla, apontado para uma aplicação que você consegue iniciar, quebrar e
reiniciar. A plataforma não fornece nada disso. Esta seção diz o que é o laboratório e três jeitos
de tê-lo; as duas seguintes montam a aplicação, e a que vem depois delas diz o que fazer quando a
montagem dá errado.

O laboratório é um computador com quatro coisas:

- **Node.js**, versão 22 ou 24. A aplicação testada é um programa Node, e os testes também. O Node
  vem com o **npm**, que instala as ferramentas de teste dentro da pasta do próprio projeto;
- **um editor de código**. Qualquer um serve; o Visual Studio Code é gratuito e é o que a maioria
  das pessoas que fazem este trabalho usa;
- **um navegador que você usa à mão**, com as ferramentas de desenvolvedor: Chrome, Edge ou
  Firefox. Esta aula é sobre essas ferramentas, e toda aula seguinte as abre quando um teste faz
  algo inesperado;
- **o projeto, `quitanda`**: uma pequena loja virtual e, ao lado dela, os testes que a conduzem. As
  duas próximas seções montam o projeto arquivo por arquivo, e o **Playwright**, a primeira
  ferramenta de teste que você conhece, entra nele com um comando.

É tudo de que o curso precisa até a aula 8, que acrescenta o Selenium à mesma pasta, e a aula 9,
que acrescenta o Cypress. Nada roda num servidor em outro lugar e nada exige conta.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node e o projeto no computador que você já usa | uns 13 MB de pacotes no projeto e uns 920 MB de navegadores numa pasta de cache | iguais no Ubuntu 24.04; parecidas nos outros |
| **uma máquina virtual** | Ubuntu Desktop 24.04, separado do seu sistema | uns 25 GB de disco e 4 GB de memória enquanto roda | iguais ao que está impresso |
| **online** | uma máquina Linux no navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instalar no seu próprio computador é o caminho recomendado**, o contrário do que a maioria dos
cursos deste catálogo diz, e o motivo é próprio deste assunto. Um teste de navegador é algo que
se assiste: na aula 10 você roda testes com o navegador na tela, avança passo a passo no inspetor
do Playwright e abre um rastro gravado numa janela. Tudo isso pede uma tela, e o computador que você
já usa tem uma. Tudo o que o curso instala fica em dois lugares, a pasta `quitanda` e o cache de
navegadores do Playwright, então desfazer o laboratório é apagar duas pastas. Funciona do mesmo
jeito no Windows, no macOS e no Linux.

**Uma máquina virtual** serve se você prefere não mexer no seu sistema, ou se o seu computador
roda algo que as ferramentas não suportam. Use uma imagem desktop, não de servidor: uma imagem de
servidor não tem tela onde o navegador possa abrir. O VirtualBox roda no Windows e no Linux, o UTM
num Mac com Apple silicon, e a aula 4 de `virtualization` monta uma máquina no VirtualBox passo a
passo. Dê a ela 4 GB de memória e 25 GB de disco; só os navegadores ocupam um gigabyte.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal e editor no navegador. Não custa
nada ao seu computador. O GitHub dá às contas pessoais uma cota mensal de horas e cobra o que
passar dela, em termos que ele define e pode mudar. Um codespace não tem tela própria, então todo
navegador nele roda sem janela, o modo de que trata a aula 17, e você abre a loja pela porta que
ele encaminha. Esse caminho não foi executado para este curso.

## Instalando o Node

Baixe em nodejs.org o instalador marcado **LTS** e rode-o; no Windows e no macOS é só isso, e ele
põe `node` e `npm` no seu caminho. No Linux, nodejs.org lista as formas de instalar em cada
distribuição. O pacote `nodejs` do próprio Ubuntu é a versão 18, velha demais para as ferramentas
deste curso, então não use esse.

A máquina em que estas transcrições foram gravadas já tinha o Node, por isso a instalação em si
não aparece. Abra um terminal novo e pergunte a versão aos dois programas:

```
ana@laptop:~$ node --version
v22.22.0
ana@laptop:~$ npm --version
10.9.4
```

**Qualquer Node a partir do 22 se comporta igual aqui.** Se o seu imprimir um número abaixo de 22,
o instalador que você rodou não era o LTS, ou um Node mais antigo, antes no seu caminho, está
respondendo primeiro; a seção sobre falhas diz como descobrir.

## O que as transcrições mostram

Todas as transcrições do curso foram gravadas no Ubuntu 24.04 com o Node 22.22.0 e mostram o
prompt `ana@laptop:~/quitanda$`: Ana é a testadora de cujo terminal elas vêm, e `~/quitanda` é a
pasta do projeto na casa dela. O seu mostra o seu usuário e a sua pasta, e no Windows, o
`PS C:\Users\voce\quitanda>` do PowerShell. Os **tempos** que um executor de testes imprime mudam
em cada máquina e em cada execução; nomes de testes, contagens, códigos de status e mensagens de
erro devem bater com o que você vê.
