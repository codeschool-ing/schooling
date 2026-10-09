---
title: Autopsy
version: 1
---

O **Autopsy** é um programa gráfico gratuito e de código aberto construído sobre o The Sleuth Kit. Tudo o que esta
aula fez na linha de comando, ele faz por janelas, com um arquivo de caso em volta. **Ele não foi rodado nesta
aula**: é uma aplicação de desktop grande, e no Linux é instalado por um download separado, não por um pacote do
Ubuntu. O que ele acrescenta aos comandos vale conhecer, porque a maioria dos relatórios forenses o cita:

| ele faz | o equivalente de linha de comando nesta aula |
|---|---|
| abre uma imagem, bruta ou E01, num **caso** com o nome do perito | `fsstat`, e o registro de custódia da aula 16 |
| uma árvore de arquivos, com os apagados marcados | `fls -r`, o asterisco |
| conteúdo de arquivo em visão de texto, hexadecimal e imagem | `icat`, e `blkcat` com `xxd` |
| uma visão de **linha do tempo**, filtrável por data e tipo | `fls -m` e `mactime` |
| **busca por palavra-chave** na imagem inteira, espaço livre incluído | `blkls` e `grep`, feito à mão |
| **conjuntos de hash**: marca arquivos sabidamente inofensivos, ou sabidamente ruins | `sha256sum` e uma lista |
| marcações e um **relatório** de tudo que foi marcado | o registro do incidente, escrito à mão |

A relação é a parte importante. O Autopsy deixa o trabalho mais rápido e mais fácil de mostrar a outra pessoa; não
acha nada que as ferramentas por baixo não achem. Quando um achado importa, um perito que conhece os comandos
consegue conferi-lo sem a interface, e dizer exatamente de qual inode e de qual bloco ele veio.
