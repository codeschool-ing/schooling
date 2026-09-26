---
title: O VirtualBox, e a parte no kernel
version: 1
---

O VirtualBox é um hypervisor tipo 2, aula 2, e roda no Windows, no macOS e no Linux. É gratuito. A
Oracle o publica, com um *Extension Pack* opcional sob outra licença, que acrescenta alguns recursos,
como a tela remota, e pelo qual empresas podem ter de pagar.

Ele é um aplicativo, e também instala um **driver no kernel do host**, chamado `vboxdrv` no Linux, para
usar os recursos de virtualização do processador. Eis o VirtualBox 7.0.16 no host
deste curso:

```
ana@host:~$ VBoxManage --version
WARNING: The character device /dev/vboxdrv does not exist.
         Please install the virtualbox-dkms package and the appropriate
         headers, most likely linux-headers-v37.

         You will not be able to start VMs until this problem is fixed.
7.0.16_Ubuntur162802
```

O aviso vem do script do Ubuntu em volta do `VBoxManage`, que procura o driver antes de cada comando.
Tudo o que só muda a descrição de uma máquina funciona sem ele, e esta aula inteira faz só isso. **Ligar
um convidado não funciona**, e a seção 07 mostra a falha. Neste computador o driver nem pode ser
carregado, porque o processador não oferece nada para ele usar, como a aula 2 descobriu.

No computador Linux de um cliente, o mesmo aviso tem duas causas comuns, e vale conhecer as duas porque
nada mais na mensagem as nomeia:

- **O kernel foi atualizado** e o driver não foi recompilado para o novo. Reinstalar o pacote do módulo
  de kernel do VirtualBox, ou dar boot no kernel antigo, o traz de volta.
- **O Secure Boot está ligado**, e o firmware se recusa a carregar um driver que ninguém assinou. O
  conserto é assiná-lo e cadastrar a chave, o que o instalador costuma oferecer no próximo boot.

No Windows e no Mac, o instalador põe no lugar o que o VirtualBox precisa junto com o resto, e pede
permissão para isso.
