---
title: Editar um arquivo que está em outra máquina
version: 1
---

A razão inteira desta aula é que o arquivo está em outro lugar. Há quatro jeitos
de lidar com isso e só um deles é "aprender vim".

## Um: editar lá

```sh
ssh web01
vim /etc/nginx/nginx.conf
```

**É isto que esta aula vem ensinando**, e é a resposta certa quando a mudança é
pequena, quando você já está na máquina, e quando o que está instalado lá é o que
você tem.

O custo é que a sua configuração de editor não está lá, que é o argumento da
seção 09 para aprender o editor simples.

## Dois: copiar, editar, copiar de volta

```sh
scp web01:/etc/nginx/nginx.conf .
vim nginx.conf
scp nginx.conf web01:/etc/nginx/nginx.conf
```

**Três passos, e dois deles perdem coisas.** O `scp` escreve o arquivo como você,
com a sua umask, então o dono e o modo são os da sua máquina e não os de que o
serviço precisa. O `chown` da aula 4 seção 07 e a `umask` da aula 4 seção 09 se
aplicam, e nenhum dos dois é óbvio depois.

Tudo bem para um arquivo que é seu e errado para qualquer coisa sob o `/etc`.

## Três: montar o sistema de arquivos remoto

```sh
sshfs web01:/etc/nginx /mnt/nginx      # needs sshfs installed locally
vim /mnt/nginx/nginx.conf
fusermount -u /mnt/nginx
```

O `sshfs` apresenta um diretório remoto como um local, pela conexão ssh que você
já tem. O seu editor, a sua configuração, o arquivo remoto — e as permissões são
as da máquina remota, porque é lá que a escrita acontece.

**Ele é lento num link de alta latência** — cada salvamento é uma ida e volta, e
alguns editores consultam o arquivo o tempo todo — e precisa de um pacote na sua
máquina.

## Quatro: deixar o editor fazer

Os dois editores grandes conseguem abrir um caminho remoto diretamente:

```vim
:e scp://web01//etc/nginx/nginx.conf      " vim, via netrw
```

```
C-x C-f /ssh:web01:/etc/nginx/nginx.conf   ; emacs, via tramp
```

**O `tramp` do emacs é o que é genuinamente bom nisso.** Ele mantém uma conexão
aberta, lida com `sudo` do lado de lá
(`/ssh:web01|sudo:root@web01:/etc/…`), e o buffer se comporta como qualquer
outro. É o argumento prático mais forte a favor do emacs nesta aula, e é por isso
que ele é mencionado duas vezes.

O `netrw` do vim funciona e é menos agradável: cada salvamento é um `scp`
separado, e qualquer coisa que dependa do diretório em volta do arquivo —
navegação de arquivos, plugins de projeto — não vai junto.

A extensão remota do Visual Studio Code é um quinto jeito e está fora do escopo
deste curso; ela faz mais ou menos o que o `sshfs` faz, com um auxiliar que
instala do lado de lá.

## Qual usar

| | |
|---|---|
| uma linha num arquivo de configuração, num servidor | **ssh e edite lá** |
| um arquivo que é seu, numa máquina que você controla | qualquer um deles |
| uma sessão longa na base de código de outra pessoa | `sshfs`, ou o do próprio editor |
| sob o `/etc`, sempre | edite lá, com `sudoedit` |

## A pergunta melhor

**Por que você está editando um arquivo num servidor à mão, afinal?**

Os arquivos de unidade da aula 5 seção 11, as crontabs da aula 13, e todo arquivo
do `/etc` que você está prestes a mudar têm o mesmo problema: a mudança vive numa
máquina, ninguém mais sabe dela, e a próxima reconstrução a perde.

| | |
|---|---|
| um gerenciador de configuração | Ansible, Puppet, Salt — o arquivo vem de um repositório |
| uma imagem de contêiner | a configuração está na imagem, e a máquina é descartável |
| um pacote | o arquivo vem com o software |
| à mão, no vim | **uma emergência, ou uma máquina que não tem dono** |

Isso não é um argumento contra esta aula. **Cada um desses sistemas falha de um
jeito que te deixa na máquina com um editor**, e o incidente é exatamente quando
você precisa mudar uma linha e ter certeza de que não mudou mais nada.

Aprenda o editor. Depois arranje as coisas para não precisar dele.
