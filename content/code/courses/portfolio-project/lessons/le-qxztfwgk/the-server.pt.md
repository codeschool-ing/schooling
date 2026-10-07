---
title: Montando o srv
version: 1
---

Um deploy precisa de uma segunda máquina: um servidor, que não é o computador onde você escreve. Nas
transcrições o servidor é o **srv** e o computador é o **laptop** da Ana. Você monta o seu próprio srv uma
vez, nesta seção, e a aula 16 volta a usá-lo.

## Três jeitos de ter um

| caminho | o que você ganha | quanto custa | as transcrições |
|---|---|---|---|
| **uma máquina virtual** (recomendado) | um Ubuntu Server 24.04 no seu computador, alcançável só por ele | 2 GB de memória enquanto roda, e 10 GB de disco | iguais ao impresso |
| **um computador sobrando** | um Ubuntu Server 24.04 numa máquina de verdade na sua rede de casa | um computador velho que você possa apagar | iguais; o endereço é o da sua rede |
| **online** | um servidor pequeno alugado, com endereço público | uma mensalidade, ou um plano gratuito nos termos do provedor | iguais, e a última seção vale desde já |

**A máquina virtual é o caminho recomendado.** Não custa nada, pode ser jogada fora e montada de novo em
minutos, e nada nela fica exposto à internet enquanto você ainda está aprendendo do que um servidor
precisa. O **Multipass**, da Canonical, a empresa por trás do Ubuntu, é gratuito e monta uma máquina
virtual com Ubuntu Server com um comando, usando o hipervisor que o seu sistema já tem: Hyper-V no Windows
Pro, Enterprise e Education, VirtualBox no Windows Home, QEMU no Mac e KVM no Linux. No Windows e no macOS
ele vem como instalador do site dele; no Ubuntu, `sudo snap install multipass`.

**Um computador sobrando** funciona igual depois de instalar nele o Ubuntu Server 24.04 a partir da imagem
oficial, marcando a opção *OpenSSH server* durante a instalação. **Online**, quase todo provedor de
hospedagem vende um servidor virtual pequeno, e alguns têm plano gratuito; nenhum é necessário para
terminar esta aula, e a última seção lista o que conferir antes de confiar num deles. Nos dois casos o
arquivo abaixo continua valendo: um provedor online costuma aceitá-lo como *user data* na criação do
servidor, e num computador sobrando você faz à mão o que ele pede.

## Uma chave, e um arquivo que descreve o srv

O ssh deixa você entrar no srv com uma **chave** em vez de uma senha: um par de arquivos, uma metade
privada que nunca sai do seu computador e uma metade pública que você entrega a toda máquina que deve
deixar você entrar. Crie uma, a não ser que `~/.ssh/id_ed25519.pub` já exista:

```
ana@laptop:~$ ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
Created directory '/home/ana/.ssh'.
Generating public/private ed25519 key pair.
Your identification has been saved in /home/ana/.ssh/id_ed25519
Your public key has been saved in /home/ana/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:eRQ1yT6V3oGJwy9kUSMTxZ1flTAPIrspTkvLK+/8lTQ ana@laptop
The key's randomart image is:
+--[ED25519 256]--+
|         .oOXO=.=|
|          oB*=B=.|
|         .+.oo o+|
|         oo.o.. o|
|       +So.E..   |
|      = +.. o    |
|       =   o     |
|     .. . .      |
|      +=..       |
+----[SHA256]-----+
ana@laptop:~$ cat ~/.ssh/id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLnYX4B+/TJmCeRjHgeZURWQ3gFJ2X9iQWSKbb/LOs7 ana@laptop
```

`-N ""` deixa a metade privada sem senha. Para uma chave que abre uma única máquina, alcançável só pelo
seu computador, é uma troca justa; para uma chave que abre qualquer coisa pública, dê uma senha a ela. A
linha que o `cat` mostrou é a metade pública, e ela vai para o arquivo que descreve o srv:

```yaml
#cloud-config
# srv, the server this course deploys to. cloud-init reads this file the
# first time the machine boots, and never again.
hostname: srv
users:
  - name: ana
    shell: /bin/bash
    groups: [sudo]
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    ssh_authorized_keys:
      - paste the line from ~/.ssh/id_ed25519.pub here
ssh_pwauth: false
package_update: true
packages:
  - podman
  - caddy
  - git
  - python3
  - curl
```

Este é um arquivo do **cloud-init**. O cloud-init roda no primeiro boot de uma máquina Ubuntu Server, lê um
arquivo como este e faz o que ele diz: dá à máquina o nome `srv`, cria a conta `ana` com a sua chave pública
nela, desliga o login por senha e instala Podman, Caddy, git, Python e curl dos pacotes do próprio Ubuntu.
Salve-o como `srv.yaml`, ponha a **sua** chave pública na linha que pede por ela e escreva o seu nome de
usuário onde está `ana`. A linha `sudo` deixa essa conta usar `sudo` sem senha, já que o srv.yaml nunca
define uma; isso é aceitável numa máquina que só o seu computador alcança, e errado numa pública.

Depois, a máquina em si, que leva alguns minutos da primeira vez:

```sh
multipass launch 24.04 --name srv --cpus 2 --memory 2G --disk 10G --cloud-init srv.yaml
multipass info srv
```

Esses dois **não foram rodados neste curso**: o computador que o gravou não tem virtualização por
hardware, então o srv dele é um container que o cloud-init montou a partir deste mesmo arquivo. O
`multipass info` mostra, entre outras coisas, o endereço **IPv4** do srv, que é o que o próximo passo
precisa.

## Chegando nele pelo nome

Digitar um endereço toda vez é como os erros acontecem, então dê um nome a ele no `~/.ssh/config`, com o
endereço do `multipass info` e o seu nome de usuário:

```
ana@laptop:~$ printf 'Host srv\n    HostName 10.20.0.20\n    User ana\n' >> ~/.ssh/config
ana@laptop:~$ cat ~/.ssh/config
Host srv
    HostName 10.20.0.20
    User ana
```

Daqui em diante `ssh srv` quer dizer *aquele endereço, como aquele usuário*, e o mesmo vale para todo
comando `git` que cita `srv:`. A primeira conexão faz uma pergunta:

```
ana@laptop:~$ ssh srv hostname
The authenticity of host '10.20.0.20 (10.20.0.20)' can't be established.
ED25519 key fingerprint is SHA256:oIhKjQaT+HpopLWEVJTAyWCGN3xEs9te+VCtDIKW25c.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.20.0.20' (ED25519) to the list of known hosts.
srv
```

O ssh nunca viu essa máquina, então mostra a impressão digital da chave do próprio srv e pergunta se deve
confiar nela. Numa rede que você controla, *yes* é a resposta certa; o ssh anota a chave e, daí em diante,
se recusa a falar com qualquer outra máquina que diga ser o srv. Se quiser ter certeza,
`multipass exec srv -- ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` mostra a mesma impressão
digital do lado do srv.

O srv respondeu com o nome dele, mas o cloud-init pode ainda estar instalando. Espere por ele, e depois
peça as ferramentas:

```
ana@laptop:~$ ssh srv cloud-init status --wait
............................................................................status: done
ana@laptop:~$ ssh srv "podman --version; caddy version; git --version; python3 --version"
podman version 4.9.3
2.6.2
git version 2.43.0
Python 3.12.3
```

Cada ponto é um segundo de espera, e `done` quer dizer que cada linha do srv.yaml foi cumprida. O srv agora
tem tudo o que o resto desta aula usa. Se algum passo aqui saiu diferente, a próxima seção é exatamente
sobre isso.
