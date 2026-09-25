---
title: O pendrive, a sessão ao vivo e o instalador
version: 1
---

A ISO vai para um pendrive com uma ferramenta que a grava inteira: *Rufus* ou *balenaEtcher* no
Windows, *balenaEtcher* no macOS, e no Linux o *Criador de Discos de Inicialização* ou o `dd`:

```sh
lsblk                                         # find the stick: its size tells you which it is
sudo dd if=ubuntu-24.04-desktop-amd64.iso of=/dev/sdX bs=4M status=progress
#                                             ^ the WHOLE stick, not a partition like sdX1
```

**Esse `dd` não foi rodado para esta aula**, e ele é o único comando deste curso para digitar devagar. O
`of=` é o dispositivo sobre o qual ele grava, inteiro e sem perguntar. Apontado para a letra errada, ele
apaga um disco em vez de um pendrive; `lsblk` antes, e leia os tamanhos.

Você inicia o computador pelo pendrive exatamente como na aula 2: a tecla do menu de boot. Deixe o
**Secure Boot ligado**. O carregador de boot do Ubuntu é assinado com uma chave em que o firmware já
confia, então ele inicia normalmente.

## Experimente antes de instalar

O pendrive inicia uma **sessão ao vivo** completa: o Ubuntu rodando a partir do pendrive, sem tocar no
disco. Vale dez minutos antes de instalar, porque responde às perguntas que importam num hardware de
verdade: o Wi-Fi funciona, a resolução da tela, o som, a impressora? Se não funcionam aqui, também não
vão funcionar depois de instalar, e é melhor saber agora.

## Escolhas que o instalador pede

- *Idioma, teclado e fuso horário.* Para o escritório: teclado Português (Brasil) e horário de São
  Paulo.
- *Tipo de instalação*, a que merece cuidado:
  - *Apagar o disco e instalar o Ubuntu*: o disco inteiro, como a instalação limpa da aula 2.
  - *Instalar ao lado do Windows*: divide o disco, a próxima seção.
  - *Instalação manual*: você mesmo desenha as partições.
- *Criptografia.* O instalador pode criptografar o disco inteiro (**LUKS**) com uma frase secreta
  pedida a cada inicialização. É a resposta do Linux ao BitLocker, e para um notebook que sai do
  escritório não é opcional.
- *Drivers proprietários.* Uma opção para instalar drivers que não são de código aberto, sobretudo
  de vídeo e Wi-Fi. Com o Secure Boot ligado, instalá-los pode pedir para você criar uma senha e
  confirmá-la uma vez, numa tela azul na próxima inicialização, chamada de cadastro **MOK**. Parece
  alarmante e é esperado.
- *Sua conta.* Nome, nome do computador e senha. Esta primeira conta pode rodar comandos de
  administrador com `sudo` (seção 05).
