---
title: A sua máquina é o laboratório
version: 1
---

**Tudo o que este curso mostra, você roda sozinho, num computador seu.** Ninguém entrega um cluster
pronto: da aula 2 em diante, toda aula começa montando um novo em poucos segundos, com os mesmos três
programas com que todas as transcrições foram gravadas. O Docker roda os nós, o `kind` monta o cluster
com eles, e o `kubectl` conversa com ele. Esta seção os instala, a próxima monta a aplicação que as
aulas implantam, e o fim desta aula monta o cluster.

## Três caminhos

| caminho | o que é | quanto custa ao seu computador |
|---|---|---|
| instalado | Docker, `kind` e `kubectl` num computador que já roda Linux | cerca de 1 GiB de memória enquanto um cluster roda, e 3 GiB de disco para as imagens |
| **uma máquina virtual com Multipass** (recomendado) | Ubuntu Server 24.04 numa VM criada com um comando, no Windows, no macOS ou no Linux, e os mesmos três programas dentro dela | 4 processadores, 6 GiB de memória e 30 GiB de disco enquanto ela roda |
| online | um playground de Kubernetes no navegador, como o Killercoda, ou uma VM Linux alugada por hora | nada no seu computador; o playground esquece tudo depois de uma sessão, e a VM alugada custa dinheiro |

**A máquina virtual é a recomendação**, porque as aulas foram escritas para Linux e algumas delas vão
além do `kubectl`, até a máquina por baixo: a aula 1 mata o processo de um container pelo número dele,
e a aula 15 chama endereços da própria rede do Docker. Dentro de uma VM Ubuntu tudo isso funciona igual
em qualquer computador. O Multipass, a ferramenta da Canonical, cria a VM com um comando e usa o
hipervisor que o seu sistema tiver: Hyper-V no Windows (VirtualBox no Windows Home), o framework de
virtualização embutido no macOS, e KVM no Linux. Qualquer outro hipervisor também serve, VirtualBox,
UTM num Mac com Apple silicon ou GNOME Boxes, ao preço de um instalador para clicar até o fim.

**Instalado** é a mesma coisa sem a VM, e é a escolha melhor se o seu computador já roda Ubuntu ou
outro Linux: nada abaixo muda, exceto que você pula os próximos dois comandos. O Docker Desktop no
Windows ou no macOS também roda o `kind`, e a maioria das aulas funciona lá, mas os endereços da aula
15 ficam dentro da VM do próprio Docker Desktop e não são alcançáveis do computador. **Online** está
aqui para você saber que existe. Um playground é um bom jeito de experimentar um comando e um jeito
ruim de acompanhar um curso, porque cada sessão começa vazia e toda aula aqui remonta o seu cluster de
qualquer jeito; nenhuma aula depende do plano gratuito de empresa nenhuma.

## A máquina virtual

Instale o Multipass a partir do site dele e depois, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name k8s --cpus 4 --memory 6G --disk 30G
multipass shell k8s
```

**Esses dois comandos não foram rodados para este curso**, porque o computador em que ele foi gravado
não roda um hipervisor. O primeiro cria a VM e o segundo abre um shell dentro dela, como o usuário
`ubuntu`. Tudo daqui em diante acontece nesse shell. Com menos memória, 4 GiB servem para todas as
aulas, menos as poucas que enchem um nó de propósito, que então o enchem mais cedo.

## Docker

O curso `docker` instala o Docker Engine na aula 6, a partir do repositório de pacotes do próprio
Docker. Se você fez esse curso nesta máquina, pule adiante. A versão curta, das instruções de
instalação do Docker para Ubuntu, é:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

A última linha deixa você usar o `docker` sem `sudo`, e vale a partir do próximo login: saia do shell
com `exit` e abra-o de novo com `multipass shell k8s`. Esses comandos também não foram rodados aqui,
porque a máquina de gravação já tinha o Docker; é isto que ela tem:

```
ana@laptop:~/shop$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
```

## kind e kubectl

As transcrições deste curso foram gravadas como `ana`, numa máquina chamada `laptop`, num diretório
`~/shop`. Crie o seu agora com `mkdir ~/shop && cd ~/shop`. O seu prompt vai dizer `ubuntu@k8s` se você
escolheu a VM, e essa é a única diferença que você deve ver.

Os dois programas são arquivos únicos, baixados dos seus projetos e conferidos contra o checksum que
cada projeto publica ao lado do arquivo. `ARCH` é `amd64` na maioria dos computadores e `arm64` num Mac
com Apple silicon, e o `dpkg` sabe qual:

```
ana@laptop:~/shop$ ARCH=$(dpkg --print-architecture); echo $ARCH
amd64
ana@laptop:~/shop$ curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH
ana@laptop:~/shop$ curl -fsSL https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH.sha256sum | sed "s/kind-linux-$ARCH/kind/" | sha256sum --check
kind: OK
ana@laptop:~/shop$ curl -fsSLo kubectl https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl
ana@laptop:~/shop$ echo "$(curl -fsSL https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl.sha256)  kubectl" | sha256sum --check
kubectl: OK
ana@laptop:~/shop$ sudo install -m 0755 kind kubectl /usr/local/bin/ && rm kind kubectl
ana@laptop:~/shop$ kind version
kind v0.33.0 go1.26.7 linux/amd64
ana@laptop:~/shop$ kubectl version --client
Client Version: v1.37.1
Kustomize Version: v5.8.1
```

**Os dois `OK` são o objetivo das linhas do meio**: o arquivo que você baixou é o arquivo que o projeto
publicou. Uma conferência que falha imprime `FAILED` e sai com erro, e a resposta certa é apagar o
arquivo e baixá-lo de novo, nunca instalá-lo mesmo assim.
