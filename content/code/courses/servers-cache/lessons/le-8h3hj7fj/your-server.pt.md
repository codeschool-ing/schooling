---
title: O seu servidor, montado por você
version: 1
---

Nada neste curso roda numa máquina nossa. **Você monta o servidor, no seu próprio computador, e todo
comando de toda aula é digitado lá.** É uma máquina Ubuntu 24.04 com os servidores web, os caches e
uma pequena livraria instalados, e você pode jogá-la fora e montá-la de novo em uns dez minutos. Essa
é a propriedade que mais importa: uma aula que quebra alguma coisa é uma aula que você pode repetir.

Há três jeitos de ter essa máquina. Escolha o primeiro, a não ser que tenha um motivo para não
escolher.

| | o que é | quanto custa ao seu computador |
|---|---|---|
| **uma máquina virtual com o Multipass** (recomendado) | a ferramenta da Canonical que cria uma VM Ubuntu com um comando, no Windows, no macOS e no Linux | 2 processadores, 2 GB de memória e 10 GB de disco enquanto ela roda |
| uma máquina virtual em qualquer hipervisor | VirtualBox, UTM num Mac com Apple silicon, Hyper-V ou GNOME Boxes, instalando você mesmo a imagem do Ubuntu Server 24.04 | o mesmo, mais meia hora de telas de instalação |
| um pequeno servidor na nuvem | uma máquina virtual alugada por hora num provedor | dinheiro, e uma máquina na internet desde o primeiro minuto |

A opção da nuvem está aqui para você saber que existe, não como recomendação. Um servidor web num
endereço público é achado por varreduras em minutos, e este curso só o endurece na aula 4. Se mesmo
assim escolher essa opção, leia a aula 4 antes. Um contêiner Linux, como o WSL2 ou um contêiner
Docker, também é possível, mas as aulas se apoiam no `systemctl` e em serviços que sobem com a
máquina, coisa que um contêiner comum não tem.

## Com o Multipass

Instale o Multipass pelo site dele e, no terminal do seu próprio computador:

```
multipass launch 24.04 --name web --cpus 2 --memory 2G --disk 10G
multipass shell web
```

**Esses dois comandos não foram rodados para este curso**, porque o computador em que ele foi
gravado não roda hipervisor. O primeiro cria a máquina virtual e o segundo abre um shell dentro dela,
como o usuário `ubuntu`. Tudo daqui em diante acontece nesse shell.

## Dentro da máquina

Os arquivos e pacotes do curso são instalados por um script, `lab.sh`, publicado com o código-fonte
do curso. Copie-o para a máquina (`multipass transfer lab.sh web:` faz isso, e também não foi rodado
aqui) e rode:

```
sudo bash lab.sh install
```

Ele faz o que você digitaria à mão. Roda `apt-get install` para todo pacote que o curso usa, todos
do próprio repositório do Ubuntu: Nginx, Apache, Caddy, Redis, Memcached, Varnish, o certbot e as
pequenas ferramentas em volta deles. Escreve a livraria, `/opt/shop/shop.py`, e sobe duas cópias
dela. Escreve a vitrine estática em `/var/www/ipe`, acrescenta três nomes ao `/etc/hosts` e põe um
módulo Python em `~/work` para as aulas 8 a 11. Leia o script antes de rodar; ele é curto, e rodar
como root um script que você não leu é um hábito que vale não ter.

As transcrições deste curso foram gravadas numa máquina chamada `web`, por uma usuária chamada `ana`.
Na sua aparece `ubuntu@web` se você usou o Multipass, e essa deve ser a única diferença:

```
ana@web:~$ grep PRETTY /etc/os-release; nproc; free -h | head -2
PRETTY_NAME="Ubuntu 24.04 LTS"
4
               total        used        free      shared  buff/cache   available
Mem:            15Gi       646Mi        12Gi        13Mi       2.7Gi        15Gi
ana@web:~$ apt-cache policy nginx apache2 caddy | grep -E '^[a-z]|Installed'
nginx:
  Installed: 1.24.0-2ubuntu7.18
apache2:
  Installed: 2.4.58-1ubuntu8.15
caddy:
  Installed: 2.6.2-6ubuntu0.24.04.3
ana@web:~$ systemctl is-active shop@1 shop@2 nginx apache2 caddy
active
active
inactive
inactive
inactive
ana@web:~$ grep ipelivros /etc/hosts
127.0.0.1	ipelivros.example www.ipelivros.example static.ipelivros.example
ana@web:~$ ls -l ~/work
total 4
-rw-r--r-- 1 ana ana 885 Sep  1 10:00 catalogue.py
```

A memória e o número de processadores são os da máquina de gravação; a sua mostra o que você deu à
máquina virtual. O resto deve bater. **As duas cópias da loja estão rodando e todos os servidores web
estão parados**, porque o Ubuntu sobe cada servidor no momento em que ele é instalado, e três deles
não podem ficar todos com a porta 80. O script os para para que esta aula os suba um de cada vez, e
a seção sobre o Apache mostra o que acontece quando dois tentam.

Os três nomes do `/etc/hosts` ficam sob `.example`, um domínio de topo reservado para nunca existir
na internet. Eles apontam para a própria máquina, então `http://ipelivros.example/` digitado dentro
dela chega ao próprio servidor web. No navegador do seu computador o nome não resolve, e não precisa:
toda aula funciona a partir do shell da máquina, com `curl`.

**O que a máquina de gravação fez de diferente**, para nada surpreender você. Ela era um contêiner
inicializado com o próprio systemd em vez de uma máquina virtual, o que se comporta igual para tudo
o que este curso faz. Não tinha IPv6, então a única linha do site padrão do Nginx que escuta em
`[::]:80` foi removida; a sua mantém essa linha. E a `ana` podia usar `sudo` sem digitar senha, o que
deixa as transcrições livres de pedidos de senha.
