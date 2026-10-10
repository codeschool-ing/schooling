---
title: Seu laboratório, e três jeitos de ter um
version: 1
---

**Toda lição deste curso roda alguma coisa no seu próprio computador**: uma API, uma coleção de
requisições, uma suíte de testes em JavaScript ou Java e, a partir da lição 14, um app num emulador
Android. Nada fica hospedado para você. Esta seção diz do que a máquina precisa na primeira metade e
três jeitos de tê-la; a lição 14 acrescenta o que a segunda metade pede, e a seção depois da próxima
diz o que fazer quando a instalação falha.

Para as lições 1 a 6 o laboratório é pequeno:

- **um terminal** com bash, com `curl` para mandar requisições e `jq` para ler JSON;
- **Node.js 22**, o ambiente de execução de JavaScript. O boxoffice, a API que toda lição testa, é
  um arquivo de JavaScript sem pacotes para instalar, e o Newman da lição 6 também é um programa
  Node;
- **um editor de texto** com que você se sinta à vontade. O Visual Studio Code é gratuito e é o que o
  curso supõe quando diz "abra o arquivo", mas qualquer editor que salve texto puro serve.

A lição 4 instala o Postman, a lição 7 um kit de desenvolvimento Java e o Maven, e cada uma diz como.

## Três jeitos de ter um

| caminho | o que você tem | quanto custa | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | as ferramentas no computador que você já usa; no Windows, dentro do WSL | uns 200 MB para o Node, mais para o Java na lição 7 | batem como impressas no Ubuntu 24.04 e no WSL; parecidas num Mac |
| **uma máquina virtual** | Ubuntu Server 24.04, separado do seu sistema | alguns gigabytes de disco e 2 GB de memória enquanto roda | batem como impressas |
| **online** | uma máquina Linux no navegador, o GitHub Codespaces | nada no seu computador; horas de uma cota mensal | parecidas; a metade mobile não roda ali |

**Instalado é o caminho recomendado, e o motivo é a lição 14.** O emulador Android é ele mesmo uma
máquina virtual, e precisa do suporte de virtualização do seu processador diretamente. Dentro de
outra máquina virtual ele precisa de virtualização *aninhada*, que muitos notebooks e hipervisores
não oferecem, e um emulador sem ela se recusa a iniciar ou roda devagar demais para testar qualquer
coisa. Então a segunda metade do curso roda no seu próprio sistema seja qual for a escolha agora, e
fazer a primeira metade ali também significa um conjunto de ferramentas em vez de dois.

O que "instalado" quer dizer depende do seu sistema:

- **Linux.** Use o terminal como está. Os comandos abaixo são do Ubuntu 24.04; outra distribuição
  tem as mesmas ferramentas com os mesmos nomes no próprio gerenciador de pacotes.
- **Windows.** Instale o WSL, o Subsistema do Windows para Linux, com o Ubuntu 24.04 (`wsl --install
  -d Ubuntu-24.04` num PowerShell aberto como administrador, depois reinicie). O WSL é um Linux
  pequeno que compartilha seus arquivos e sua rede, e todo comando abaixo roda dentro dele sem
  mudança. O Postman e o Android Studio, que têm janelas, são instalados no próprio Windows.
- **macOS.** O app Terminal roda zsh, que aceita todo comando deste curso. O curl já vem. Instale o
  Node 22 com o instalador de nodejs.org e o jq com o Homebrew (`brew install jq`). Nenhum passo do
  macOS foi executado para este curso, então um número de versão pode diferir do seu.

**Uma máquina virtual** serve para as lições 1 a 13 se você preferir manter as ferramentas longe do
seu sistema: VirtualBox no Windows ou no Linux, UTM num Mac, com uma imagem do Ubuntu Server 24.04 de
ubuntu.com. A lição 4 de `virtualization` monta uma passo a passo. Conte com instalar o Android
Studio no seu próprio sistema quando a lição 14 chegar, de qualquer forma.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal no navegador, sem custo para o seu
computador. O GitHub dá às contas pessoais uma cota mensal de horas e cobra além dela, em termos que
ele define e pode mudar. Não foi executado para este curso. Basta para as lições 1 a 13, e não roda
um emulador Android, que precisa de um hardware que um codespace não expõe.

## Montando

Tudo abaixo é digitado num terminal do Ubuntu 24.04 ou do WSL. Primeiro as duas ferramentas
pequenas, dos pacotes do próprio Ubuntu:

```sh
sudo apt-get update
sudo apt-get install -y curl jq
```

O Node vem de nodejs.org e não do Ubuntu, porque o Ubuntu 24.04 traz o Node 18, que já saiu do
período de suporte e é velho demais para as ferramentas das lições 6 e 15. Estas quatro linhas
baixam a versão com que toda transcrição foi gravada, descompactam em `/opt/node` e dizem ao seu
shell onde encontrá-la:

```sh
curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
sudo mkdir -p /opt/node
sudo tar -xJf node-v22.22.0-linux-x64.tar.xz -C /opt/node --strip-components=1
echo 'export PATH=/opt/node/bin:$PATH' >> ~/.bashrc
```

Num computador ARM, que é o que uma máquina virtual num Mac com Apple silicon é, escreva `arm64` onde
a primeira e a terceira linha dizem `x64`. A última linha acrescenta uma frase ao `~/.bashrc`, que um
terminal lê quando abre, **então feche o terminal e abra outro** antes de continuar. No novo, as
quatro ferramentas respondem:

```
ana@laptop:~$ node --version
v22.22.0
ana@laptop:~$ npm --version
10.9.4
ana@laptop:~$ curl --version | head -1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
ana@laptop:~$ jq --version
jq-1.7
ana@laptop:~$ cd boxoffice
```

Um Node 22 mais novo se comporta igual para este curso. O Node 24 também deve, e não foi testado.

## O que as transcrições mostram

Toda transcrição do curso foi gravada no Ubuntu 24.04 e mostra o prompt `ana@laptop:~/boxoffice$`.
Ana é a testadora de cujo terminal elas vêm; o seu mostra o seu usuário e a sua máquina. Quase tudo
o que o boxoffice responde é igual em qualquer máquina, com duas exceções: o cabeçalho `Date`, que é
o instante em que a requisição foi feita, e os tokens da lição 3, que carregam a hora em que foram
emitidos.
