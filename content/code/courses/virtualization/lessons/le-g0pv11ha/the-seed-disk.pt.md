---
title: O disco seed, à mão
version: 1
---

Uma imagem de nuvem não tem usuário com que você possa entrar nem senha que alguém conheça, de
propósito. Ela roda um programa chamado **cloud-init** no primeiro boot, que procura as configurações num
disco extra pequeno, o **seed**, e faz o que elas dizem: dar um nome à máquina, criar um usuário, deixar
uma chave entrar.

A chave é sua. Uma **chave ssh** é um par de arquivos: a metade privada fica no host e a metade pública
vai para cada convidado, e então o `ssh` faz você entrar sem senha. Se o `~/.ssh/id_ed25519` já existe,
você tem uma; pule o primeiro comando, ou ele pergunta antes de sobrescrevê-la.

```
ana@host:~$ ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
Created directory '/home/ana/.ssh'.
Generating public/private ed25519 key pair.
Your identification has been saved in /home/ana/.ssh/id_ed25519
Your public key has been saved in /home/ana/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:iEeA/7cFXOXv44SyrgqUMV0hZZDVRCd0Zgy+2l/XIl8 ana@host
The key's randomart image is:
+--[ED25519 256]--+
|   .. o=***+*    |
|  .  o.+ .oB.    |
|   .o o. .. .    |
|    .* .o  . .   |
|    +.o S..   .  |
|   . .. .o.  o  .|
|    .  ..oo o * E|
|     .  .  + * = |
|      ...oo . o  |
+----[SHA256]-----+
```

O `-N ""` deixa a chave sem frase-senha, uma comodidade para um laboratório no seu próprio computador e
não um hábito para uma chave que abre qualquer outra coisa. Depois as configurações, num arquivo chamado
`user-data`:

```
ana@host:~$ cat > user-data <<EOF
> #cloud-config
> hostname: vm1
> users:
>   - name: $USER
>     sudo: ALL=(ALL) NOPASSWD:ALL
>     shell: /bin/bash
>     ssh_authorized_keys: [ "$(cat ~/.ssh/id_ed25519.pub)" ]
> EOF
ana@host:~$ cat user-data
#cloud-config
hostname: vm1
users:
  - name: ana
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys: [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxorodEdZ/92A9HlMVJICfxiPyvSd18CxzbYDlw1lYz ana@host" ]
```

A **primeira linha tem de ser `#cloud-config`** exatamente: é como o cloud-init sabe que tipo de arquivo
é este, e sem ela o arquivo é ignorado em silêncio, o que a seção 11 mostra. O resto dá o nome à máquina e
cria um usuário com `sudo` que não pede senha. O `$USER` e o `$(cat ...)` foram trocados quando o arquivo
foi escrito: pelo **seu próprio nome de usuário**, para o `ssh vm1` da sua conta entrar com o mesmo nome,
e pela própria chave pública.

O `cloud-localds` transforma o arquivo numa imagem de disco, com a etiqueta que o cloud-init procura:

```
ana@host:~$ sudo cloud-localds /var/lib/libvirt/images/vm1-seed.img user-data
```

Ele não imprime nada quando funciona. O seed vai para a mesma pasta do disco do convidado, porque o
libvirt lê discos como um usuário só dele, o `libvirt-qemu`, que não enxerga a sua pasta pessoal.
