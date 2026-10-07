---
title: A máquina em que você vai digitar
version: 1
---

Nada neste curso roda numa máquina hospedada por nós. **Você monta uma máquina Linux com o Docker
Engine, e a partir desta aula todo comando é digitado nela.** Toda transcrição do curso foi gravada
numa dessas, que as aulas chamam de laboratório: Ubuntu 24.04 com o Docker Engine 29 dos pacotes do
próprio Docker, uma usuária chamada `ana` e uma máquina chamada `vm`. O seu prompt vai trazer o seu
nome. As respostas são as mesmas, tirando os ids que o Docker inventa e os tempos, que mudam a cada
execução de todo jeito.

Há três jeitos de ter essa máquina. Escolha a máquina virtual, a menos que tenha um motivo para não
escolher.

| | o que é | quanto custa |
| --- | --- | --- |
| **uma máquina virtual com o Multipass** (recomendado) | a ferramenta da Canonical que cria uma VM Ubuntu 24.04 com um comando, no Windows, no macOS ou no Linux, com o Docker Engine instalado dentro | 2 processadores, 4 GB de memória e 30 GB de disco enquanto roda; no seu sistema, só o próprio Multipass |
| instalado | o Docker Desktop no Windows ou no macOS, o resto desta aula; ou o Docker Engine direto num computador que já roda Ubuntu, a aula 6 | o Desktop roda uma VM Linux própria, dimensionada nos ajustes dele, e exige licença paga numa empresa grande; o Engine no computador que você usa todo dia torna root nele todo mundo do grupo `docker`, como a aula 6 mostra |
| online | o Play with Docker, o playground do próprio Docker, ou um GitHub Codespace, no navegador | nada no seu computador; uma sessão apagada depois de algumas horas, ou uma cota mensal de horas grátis que a empresa que oferece decide |

**A máquina virtual tem o mesmo formato daquela de onde vieram as transcrições**, então, quando a sua
saída difere da da aula, a diferença merece ser lida, em vez de ser um efeito colateral da
instalação. E perdê-la não custa nada. Uma aula que quebra o daemon é uma aula que você repete numa
máquina nova, e nela só há o Ubuntu, o Docker e as ferramentas.

**Instalado serve para quase todas as aulas.** Com o Docker Desktop, o daemon, o arquivo de
configuração dele e o `/var/lib/docker` ficam dentro da VM do próprio Desktop, em que você nunca
entra, então os trechos das aulas 3, 4, 6 e 28 que olham para eles a partir do host são para ler, e
não para repetir. O Engine no seu próprio computador Ubuntu é exatamente o laboratório, menos a
liberdade de jogá-lo fora.

**O online aparece para você saber que existe, não como recomendação.** Da aula 11 em diante você
monta um projeto, o `shelf`, e continua mexendo nele por dezesseis aulas. Uma sessão apagada leva o
projeto junto, e nenhuma aula aqui depende de uma cota grátis que outra pessoa pode mudar.

Num Mac com Apple silicon, o Multipass cria uma máquina `arm64`. Toda imagem que este curso usa é
publicada para `arm64`, então os comandos funcionam sem mudança. As duas aulas sobre o processador,
a 2 e a 13, se leem ao contrário nela: o que falha no `amd64` do laboratório roda na sua, e
vice-versa.

## Com o Multipass

Instale o Multipass a partir do site da Canonical. Ele comanda um hipervisor que o sistema já tem: o
Hyper-V no Windows, ou o VirtualBox nas edições sem Hyper-V; o QEMU sobre o hipervisor da própria
Apple no macOS; e o QEMU com KVM no Linux. Depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name vm --cpus 2 --memory 4G --disk 30G
multipass shell vm
```

**Esses dois comandos não foram rodados para este curso**, porque a máquina em que ele foi gravado
já é uma máquina virtual e não consegue iniciar outra. O primeiro cria a VM e o segundo abre um shell
dentro dela, como o usuário `ubuntu`. Tudo daqui em diante acontece nesse shell.

Qualquer outro hipervisor serve no lugar do Multipass: VirtualBox, UTM num Mac com Apple silicon,
Hyper-V ou GNOME Boxes, com um instalador do Ubuntu Server 24.04 LTS e os mesmos tamanhos. Custa meia
hora de telas de instalação em vez de um comando.

## O Docker Engine, e as ferramentas em volta

Dentro da VM, o Docker Engine vem do repositório de pacotes do próprio Docker. A aula 6 explica
estas linhas uma a uma; são os comandos das instruções de instalação do Docker para o Ubuntu, e a
documentação do Docker é o lugar para conferi-los antes, porque os detalhes mudam:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Mais duas linhas. A primeira deixa o seu usuário rodar `docker` sem `sudo`, o que a aula 6 pesa
antes de você contar com isso. A segunda instala o que as aulas usam ao lado do Docker: o `jq`, que lê
JSON, e o `psql`, o cliente de linha de comando do PostgreSQL. O Ubuntu já tem `git` e `curl`.

```sh
sudo usermod -aG docker $USER
sudo apt-get install jq postgresql-client
```

**Um grupo novo vale a partir do próximo login**, então saia do shell com `exit` e abra de novo com
`multipass shell vm`. A máquina do laboratório já tinha tudo isso antes de o curso começar, então
nenhum dos comandos acima foi rodado nela. O que ela mostra é como conferir o resultado:

```
ana@vm:~$ jq --version && psql --version && git --version
jq-1.7
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
git version 2.43.0
ana@vm:~$ id -nG
ana docker
```

`docker` na lista de grupos quer dizer que o novo login valeu. Depois vêm as quatro verificações duas
seções abaixo, e são elas que decidem se o motor funciona.
