---
title: Criando o pendrive de instalação e iniciando por ele
version: 1
---

O Windows é instalado a partir de um *pendrive* feito com a **Ferramenta de Criação de Mídia**
(*Media Creation Tool*) da Microsoft, que baixa a versão atual e a grava no pendrive. Ela precisa de
um pendrive de pelo menos **8 GB**, e apaga tudo o que houver nele. A mesma ferramenta pode, em vez
disso, salvar um arquivo **ISO**, uma imagem de disco, que é de onde uma máquina virtual (o curso de
virtualização) inicia.

## Iniciando o computador pelo pendrive

Um computador normalmente inicia pelo disco interno. Para iniciar pelo pendrive, você avisa o
firmware, e há dois jeitos:

- *O menu de boot*: uma tecla apertada logo depois de ligar, que mostra uma lista de uma vez só com
  os dispositivos de onde iniciar. A tecla depende do fabricante, muitas vezes *F12*, *F11*, *F9*
  ou *Esc*, e a primeira tela em geral diz qual.
- *As configurações do firmware*, onde fica a ordem de boot permanente. Útil quando a tecla do menu
  está desativada, e um lugar para ter cuidado: mudar a ordem e esquecer faz o computador tentar o
  pendrive toda manhã.

Se o pendrive não aparece na lista, os motivos de costume são ele ter sido feito para o tipo errado de
firmware, ou o firmware estar configurado para iniciar só por discos internos. Deixe o **Secure Boot
ligado**: o instalador da Microsoft é assinado, e desligá-lo para instalar o Windows nunca é
necessário.

## O que acontece em seguida

O pendrive inicia uma versão pequena do Windows, o **Windows PE** (*Preinstallation Environment*),
cujo único trabalho é rodar o instalador. Ele pede o idioma e o teclado, a chave do produto (dá para
pular quando a máquina tem licença digital) e a edição quando a chave não a define. Depois vem a pergunta
de que trata a próxima seção: **onde você quer instalar o Windows?**

O mesmo pendrive tem outro uso que vale lembrar. A primeira tela dele tem um link **Reparar o
computador**, que abre as ferramentas de recuperação da aula 17 numa máquina cuja recuperação própria
não inicia mais.
