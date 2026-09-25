---
title: Modo de segurança e recuperação, nos três
version: 1
---

## Windows

- **Modo de segurança**: segure **Shift** ao escolher *Reiniciar*, depois *Solução de problemas > Opções
  avançadas > Configurações de Inicialização > Reiniciar*, e aperte **4**. Só drivers e serviços básicos
  carregam. Se o problema some, é um driver, um serviço ou um programa de inicialização, as listas da
  aula 14.
- O **WinRE**, o Ambiente de Recuperação do Windows, é o menu por onde esse caminho passa, e ele também
  inicia sozinho depois de duas inicializações seguidas que falharam. Ele oferece **Reparo de
  Inicialização**, **Restauração do Sistema** (os pontos de restauração da aula 15), **Desinstalar
  Atualizações**, um **Prompt de Comando** e o **Restaurar o PC** da aula 2. O pendrive de instalação da
  aula 2 inicia o mesmo ambiente quando a cópia do disco está danificada.

## macOS

- **Modo de segurança**: no Apple silicon, entre nas opções de inicialização (aula 4), selecione o disco,
  segure **Shift** e escolha *Continuar no Modo de Segurança*; no Intel, segure **Shift** ao iniciar. Ele
  confere o disco e carrega só o necessário.
- **Recuperação**, aula 4: o *Utilitário de Disco > Primeiros Socorros* confere e repara o disco, e o
  *Reinstalar o macOS* mantém os dados.
- O **Console**, em *Aplicativos > Utilitários*, é o visualizador de logs, e o `log` é o comando:

```sh
log show --last 1h --predicate 'eventMessage CONTAINS "error"' | tail
log stream --process Finder                      # like tail -f, for one process
```

**Não foi rodado para esta aula.**

## Linux

- **Modo de recuperação**: nas *Opções avançadas* do GRUB, cada kernel tem uma entrada de recuperação que
  inicia com quase nada e oferece um shell de root. Manter **o kernel anterior** nesse menu é o que faz
  uma atualização de kernel ruim ficar a um reinício de resolvida.
- O **`rescue.target`** e o **`emergency.target`**, os modos mínimos do systemd, são o que o modo de
  recuperação usa: o primeiro monta os discos e inicia quase nenhum serviço, o segundo nem isso.
- O **pendrive live da aula 3** inicia um Linux inteiro pelo pendrive, a partir do qual o disco de uma
  instalação quebrada pode ser montado, conferido com o **`fsck`**, e ter os arquivos copiados.

## A regra para os três

**Antes de reparar qualquer coisa na recuperação, copie o que importa**, se o disco ainda ler. Um reparo
que falha pode deixar menos do que havia antes de começar.
