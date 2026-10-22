---
title: Um motor de containers na sua máquina
version: 1
---

Esta aula termina com o boxoffice rodando num container, e isso precisa de um motor de containers: o
programa que constrói imagens e roda containers a partir delas. **O Docker Engine** é o que todas as
transcrições daqui usaram, e o curso `docker` o explica nas aulas 1 a 4 e o instala nas aulas 5 e 6; se você fez
esse curso, confira os dois comandos no fim desta seção e siga em frente. Esta seção é a preparação em
resumo.

## Três lugares para rodar

| caminho | o que custa ao seu computador | para esta aula |
|---|---|---|
| **instalado**, o Docker Engine no Ubuntu que você usa desde a aula 1 (recomendado) | cinco pacotes do repositório do Docker, um daemon rodando como root, e disco para cada imagem que você baixar ou construir | todo comando roda como impresso |
| **uma máquina virtual**: o Docker Desktop no macOS ou no Windows, ou o Docker Engine dentro da VM da aula 1 | o Desktop roda a sua própria VM Linux, alguns gigabytes de disco e a memória que você lhe der; a licença do Desktop pede assinatura paga a empresas maiores | os mesmos comandos; no macOS com chips da Apple o host é `arm64`, que é o assunto da seção 08 |
| **online**, um servidor Ubuntu alugado por hora de qualquer provedor | dinheiro por cada hora em que ele roda, e nada no seu computador | os mesmos comandos, digitados por `ssh` |

**Instale no Linux se puder.** No macOS e no Windows, um container é um processo Linux e precisa de um
kernel Linux, então todo caminho ali é uma máquina virtual; o Docker Desktop a esconde, e a VM Ubuntu da
aula 1 a deixa à vista. **O Podman** é o outro motor que vale conhecer: o Ubuntu o empacota como `podman`,
ele não tem daemon, roda rootless por padrão, e o `podman build` e o `podman run` aceitam o mesmo
Dockerfile e quase as mesmas flags. Este curso não o rodou.

## Instalando o Docker Engine no Ubuntu

Pelo repositório do próprio Docker, não pelo pacote `docker.io` do Ubuntu, que fica para trás. Estes são os
comandos das instruções de instalação do Docker que o curso `docker` dá nas aulas 5 e 6; eles não foram
rodados de novo para este curso, porque a máquina do laboratório já tinha o resultado, e a documentação do
Docker é o lugar para conferi-los antes, já que os detalhes mudam:

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

O resultado, na máquina do laboratório:

```
ana@vm:~$ dpkg-query -W -f '${Package} ${Version}\n' docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
containerd.io 2.3.6-1~ubuntu.24.04~noble
docker-buildx-plugin 0.37.1-1~ubuntu.24.04~noble
docker-ce 5:29.8.2-1~ubuntu.24.04~noble
docker-ce-cli 5:29.8.2-1~ubuntu.24.04~noble
docker-compose-plugin 5.6.0-1~ubuntu.24.04~noble
```

O motor, o seu comando, o containerd por baixo deles, e os dois plugins que dão o `docker buildx` e o
`docker compose`. Numa máquina que inicia com systemd, que é quase toda máquina Linux, o pacote inicia o
daemon e o habilita na inicialização. A próxima seção é a conferência, e o que fazer quando ela falha.
