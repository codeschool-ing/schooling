---
title: Lendo um arquivo de configuração
version: 1
---

A maioria dos arquivos de configuração é **quase toda comentário**. O do journal é um bom exemplo:

```
ana@server:~$ wc -l /etc/systemd/journald.conf
49 /etc/systemd/journald.conf
ana@server:~$ grep -Ev '^(#|$)' /etc/systemd/journald.conf
[Journal]
ana@server:~$ grep -n 'Storage' /etc/systemd/journald.conf
20:#Storage=auto
ana@server:~$ ls /etc/apt/apt.conf.d
01-vendor-ubuntu
01autoremove
70debconf
90proxy
99capture-plain
```

**49 linhas, e uma delas é configuração**: `[Journal]`, um título de seção, sem nada embaixo. Todo o
resto começa com `#`. O arquivo lista cada opção **comentada, com o valor padrão**: o `#Storage=auto` diz
que o armazenamento é automático a não ser que alguém tire o `#` e mude.

Essa convenção responde duas perguntas de uma vez. **O que pode ser configurado** é o arquivo inteiro.
**O que está configurado** são as linhas sem `#`, e o `grep -Ev '^(#|$)'` mostra exatamente essas: ele
esconde comentários e linhas vazias. Num servidor que outra pessoa configurou, esse comando em cada
arquivo do `/etc` é o jeito mais rápido de ver o que ela mudou.

## As pastas `.d`

O `/etc/apt/apt.conf.d` é uma **pasta de arquivos pequenos** que o apt lê em ordem de nome, em vez de um
arquivo grande. Cada pacote ou administrador acrescenta o próprio arquivo em vez de editar um
compartilhado, e remover a configuração é apagar um arquivo. Os números na frente definem a ordem.

O `99capture-plain` nessa lista é deste curso: o arquivo que faz o apt imprimir linhas de progresso
simples na aula 11. O `90proxy` é o caminho da máquina de captura para a internet. Uma instalação de
verdade não tem nenhum dos dois.
