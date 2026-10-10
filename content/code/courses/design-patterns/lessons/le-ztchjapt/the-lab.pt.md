---
title: Seu laboratório, e três jeitos de ter um
version: 1
---

**Este curso roda todo programa que mostra, e você roda também, numa máquina sua.** A plataforma não
dá máquina nenhuma. O que você precisa é pouco: Python 3.12 ou mais novo, um terminal e um editor de
texto. Nenhum banco de dados, nenhum servidor, nenhum pacote de fora da biblioteca padrão do Python,
em lição nenhuma. A lição 10 usa SQLite, e o SQLite vem dentro do Python, como o módulo `sqlite3`.

## Três jeitos de ter um

| caminho | o que você tem | quanto custa | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | Python no computador que você já usa | cerca de 100 MB de disco | iguais às impressas no Ubuntu 24.04; parecidas nos outros |
| **uma máquina virtual** | Ubuntu 24.04, separado do seu sistema | cerca de 25 GB de disco, e 2 GB de memória enquanto roda | iguais às impressas |
| **online** | uma máquina Linux com terminal no navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instalar é o caminho recomendado**, porque nada neste curso escuta numa porta, escreve fora de
`~/patterns` ou precisa de direitos de administrador depois que o Python está lá. Não há nada de que
uma máquina virtual precisasse proteger você.

- **Linux.** O Ubuntu 24.04 já traz o Python 3.12 como `python3`. O Fedora 40 em diante traz um mais
  novo. Numa distribuição cujo Python seja mais velho que 3.12, como o Debian 12 com o 3.11, use a
  máquina virtual ou a ferramenta `uv`, que instala um Python separado para o seu usuário com
  `uv python install 3.12` e deixa o do sistema em paz.
- **macOS.** Baixe o instalador do Python 3 mais recente em python.org, ou rode
  `brew install python@3.12` se usa Homebrew. O comando é `python3`.
- **Windows.** Baixe o instalador em python.org e marque *Add python.exe to PATH* na primeira tela,
  ou rode `winget install Python.Python.3.12` num terminal. O comando é `py` ou `python`; onde este
  curso digita `python3`, digite isso. Os caminhos das transcrições são caminhos Linux, então
  `~/patterns/oo` é `C:\Users\<você>\patterns\oo` na sua máquina.

**Uma máquina virtual** é a escolha certa quando o computador não é seu para instalar coisas, como um
notebook do trabalho com a conta de administrador travada. Qualquer hipervisor serve: VirtualBox no
Windows ou no Linux, UTM num Mac com Apple silicon, Hyper-V no Windows se estiver ligado, com a
imagem do Ubuntu Server 24.04 de ubuntu.com. A lição 4 de `virtualization` monta uma no VirtualBox
passo a passo. No Windows, o WSL rodando Ubuntu 24.04 também é uma máquina virtual e funciona do
mesmo jeito.

**Online**, um ambiente no navegador como o GitHub Codespaces dá um terminal Linux e um editor com
Python já instalado. Não custa nada ao seu computador; as horas saem de uma cota mensal, em termos
que a empresa define e pode mudar, então não deixe o curso depender de um plano gratuito. Ele não
foi testado para este curso; `python3 --version` diz, antes de começar, se o Python dele é novo o
bastante.

Só a primeira linha no Ubuntu 24.04 foi rodada para este curso. As instruções de macOS, Windows e
online seguem a documentação de cada fornecedor e não foram rodadas, então um caminho ou uma versão
numa transcrição pode diferir do que a sua máquina imprime.

## Um editor

Qualquer editor que salve texto puro serve. Se você já escreve código num, use-o. Se não, o Visual
Studio Code, que é gratuito, colore Python e tem um terminal embutido, então o programa e o comando
que o roda ficam na mesma janela. O que importa para este curso é que o editor indente com
**espaços, quatro de cada vez**, que é o que todo programa daqui usa e o que o guia de estilo do
Python pede.
