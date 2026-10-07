---
title: O seu servidor, montado por você
version: 1
---

Nada neste curso roda numa máquina nossa. **Você monta o servidor, e todo comando de toda aula é
digitado lá.** É uma máquina Ubuntu 24.04 com os servidores web, os caches e uma pequena livraria
instalados. Você pode jogá-la fora e montá-la de novo em cerca de meia hora, e essa é a propriedade
que mais importa: uma aula que quebra alguma coisa é uma aula que você pode repetir.

Há três jeitos de ter essa máquina. Escolha a máquina virtual, a não ser que tenha um motivo para não
escolher.

| | o que é | quanto custa |
|---|---|---|
| instalado | o Ubuntu 24.04 num computador só para isso, ou como sistema do computador que você usa | nada a comprar, e três servidores web, dois caches e uma autoridade certificadora de teste instalados nesse computador de vez |
| **uma máquina virtual com o Multipass** (recomendado) | a ferramenta da Canonical que cria uma VM Ubuntu com um comando, no Windows, no macOS e no Linux | 2 processadores, 2 GB de memória e 10 GB de disco enquanto ela roda |
| online | uma pequena máquina virtual alugada por hora num provedor de nuvem | dinheiro, e uma máquina na internet desde o primeiro minuto |

**Instalado** é a escolha certa se você tem um computador sobrando que pode apagar. No computador que
você usa todo dia é a escolha errada: tudo o que este curso instala é um servidor que sobe com a
máquina, e deixá-la como estava é mais difícil do que apagar uma máquina virtual. Qualquer outro
hipervisor também serve no lugar do Multipass, VirtualBox, UTM num Mac com Apple silicon, Hyper-V ou
GNOME Boxes, ao preço de meia hora de telas de instalação. **Online** está aqui para você saber que
existe, não como recomendação. Um servidor web num endereço público é encontrado por varredores em
minutos, e este curso só o protege na aula 4; se escolher assim mesmo, leia a aula 4 primeiro. Um
contêiner Linux, como o WSL2 ou um contêiner Docker, também é possível, mas as aulas se apoiam no
`systemctl` e em serviços que sobem com a máquina, coisa que um contêiner simples não tem.

## Com o Multipass

Instale o Multipass pelo site dele e depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name web --cpus 2 --memory 2G --disk 10G
multipass shell web
```

**Esses dois comandos não foram rodados para este curso**, porque o computador em que ele foi gravado
não roda um hipervisor. O primeiro cria a máquina virtual e o segundo abre um shell dentro dela, como
o usuário `ubuntu`. Tudo daqui em diante acontece nesse shell.

## Os pacotes

Todo programa que o curso usa vem do próprio repositório do Ubuntu, então um `apt-get` instala todos:
Nginx, Apache e Caddy, Redis e Memcached, Varnish, o certbot com o **Pebble**, uma autoridade
certificadora de teste que a aula 3 usa, e as ferramentas e bibliotecas Python em volta deles.

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends nginx apache2 caddy redis-server redis-tools \
    memcached libmemcached-tools varnish apache2-utils certbot python3-certbot-nginx pebble \
    python3-redis python3-pymemcache
sudo systemctl disable --now nginx apache2 caddy redis-server memcached varnish varnishncsa
printf '127.0.0.1\tipelivros.example www.ipelivros.example static.ipelivros.example\n' | sudo tee -a /etc/hosts
```

**O terceiro comando para todo servidor que acabou de ser instalado.** O Ubuntu sobe cada um no
momento em que é instalado, e três deles não podem ficar todos com a porta 80; esta aula os sobe um
de cada vez, e cada aula depois dela sobe o que precisar. A seção sobre o Apache mostra o que acontece
quando dois tentam.

O último comando acrescenta três nomes ao `/etc/hosts`, todos sob `.example`, um domínio de topo
reservado para nunca existir na internet. Eles apontam para a própria máquina, então
`http://ipelivros.example/` digitado dentro dela chega ao próprio servidor web. No navegador do seu
computador o nome não resolve, e não precisa: toda aula funciona a partir do shell da máquina, com
`curl`.

A próxima seção põe a livraria na máquina.
