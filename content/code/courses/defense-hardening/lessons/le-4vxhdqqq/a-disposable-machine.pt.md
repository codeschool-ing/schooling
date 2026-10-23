---
title: Firejail, uma sandbox para um comando
version: 1
---

**O Firejail é uma sandbox pronta para programas de desktop e scripts.** Ele monta o mesmo tipo de
parede que o `systemd-run`, com os mesmos recursos do kernel, mas com opções escritas para uma pessoa
no teclado em vez de para um serviço, e com perfis para centenas de programas comuns já no pacote.
Ele está instalado em todas as máquinas do laboratório.

As três paredes de que o script precisa são uma opção cada: nenhuma rede, um diretório home onde só o
próprio script é visível, e `/etc` somente leitura.

```
ana@web:~$ firejail --quiet --net=none --whitelist=~/relatorio.sh --read-only=/etc bash relatorio.sh
formatting the report...
ls: cannot access '/home/ana/.ssh': No such file or directory
relatorio.sh: line 5: /etc/relatorio-was-here: Read-only file system
could not write to /etc
could not reach 192.168.60.66
done
```

O resultado é o mesmo de antes: nenhum diretório SSH para listar, nada gravado em `/etc`, nenhuma
rede. O `--whitelist` transforma o diretório home numa visão dos caminhos citados e de mais nada, que
é o primo mais gentil do `ProtectHome`: o programa vê o que recebeu.

## Descartável, não só confinado

Um processo confinado ainda roda na máquina que o confina. **Para um arquivo que você preferiria nem
ter na máquina, o passo seguinte é uma máquina que você joga fora depois.** O laboratório já é uma:
`sudo bash hostlab.sh up trap` dá um `trap` novo em segundos, e o que um arquivo fizer ali some no
próximo `up`. Fora do laboratório a mesma ideia é uma máquina virtual restaurada de um snapshot depois
de cada uso, ou o Windows Sandbox, um Windows descartável que a Microsoft traz nas edições Pro e
Enterprise, que fecha e esquece tudo quando a janela é fechada. O Windows Sandbox não foi executado
para este curso.

A ordem de preferência para um arquivo desconhecido fica então simples: um serviço que o analisa em
outro lugar, a aula 19; uma máquina descartável; um processo confinado, como aqui, quando o arquivo
precisa ser aberto nesta máquina e nada melhor está disponível.
