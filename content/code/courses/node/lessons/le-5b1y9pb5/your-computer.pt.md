---
title: O seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e se você fez o `javascript` ele já está
preparado.** Aquele curso instalou o Node.js 22 na primeira aula, e este usa o mesmo Node, na mesma
versão, instalado do mesmo jeito, para que ninguém instale duas vezes nem acabe com dois. Esta
seção repete os passos em resumo, para quem chega sem eles, e depois confere se cada ferramenta
responde.

## Três jeitos de ter isso

| caminho | o que você ganha | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node.js em uma pasta no seu diretório home | cerca de 200 MB de disco, mais o que os projetos instalarem | batem como impressas no Linux |
| uma máquina virtual | o Ubuntu Server 24.04 separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | batem como impressas |
| online | uma máquina Linux em uma aba do navegador | nada no seu computador; horas de uma cota mensal | parecidas, não idênticas |

**Instale no computador que você usa.** O Node vai para `~/.local/node` e não mexe em mais nada, e
todo servidor deste curso escuta em um endereço que só o seu computador alcança. No **Linux** os
comandos abaixo funcionam como estão. No **Windows**, instale o WSL primeiro — `wsl --install -d
Ubuntu-24.04` em um PowerShell aberto como administrador, reinicie, abra o Ubuntu pelo menu Iniciar —
e digite tudo dentro dele. No **Mac**, o instalador do Node.js 22 do nodejs.org lhe dá o mesmo
`node`, embora esse caminho não tenha sido rodado para este curso e um caminho numa transcrição possa
ser diferente.

**Uma máquina virtual** é o VirtualBox no Windows ou no Linux, ou o UTM num Mac com chip da Apple,
com o Ubuntu Server 24.04 LTS como convidado, e os passos do Linux dentro dela. **Online**, o GitHub
Codespaces e serviços parecidos dão um terminal Linux numa aba do navegador, com uma cota mensal cujas
condições a empresa define e pode mudar; isso não foi rodado para este curso. Seja qual for a
escolha, `cat /etc/os-release` diz em que sistema você está.

## Node.js, em resumo

Esta é a seção "Node.js" da aula 1 do javascript, sem a explicação; leia lá se algum passo for novo
para você. `uname -m` diz qual arquivo pegar: `x86_64` pega o que termina em `linux-x64`, e
`aarch64` o que termina em `linux-arm64`.

```
ana@dev:~$ uname -m
x86_64
ana@dev:~$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
ana@dev:~$ mkdir -p ~/.local/node ~/.local/bin
ana@dev:~$ tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1
ana@dev:~$ ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/
ana@dev:~$ node --version
bash: line 13: node: command not found
```

A última linha falha, e isso é esperado. `~/.local/bin` entra no seu `PATH`, a lista de pastas onde
o shell procura um comando, só num terminal aberto depois que a pasta existe. Feche este e abra um
novo.

## Conferindo se cada ferramenta responde

Três programas, cada um perguntado pela versão, no terminal novo:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ curl --version | head -1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
ana@dev:~$ npm config set update-notifier false
ana@dev:~$ mkdir ~/server
```

**O `node` precisa dizer `v22.22.0`**, ou um 22 posterior, e o `npm` veio na mesma pasta. O `curl` é
o programa que pergunta coisas aos seus servidores desde a aula 1; o Ubuntu já o traz, e se ele
disser `command not found`, `sudo apt install curl` o acrescenta.

As duas últimas linhas são para este curso. `npm config set update-notifier false` impede o npm de
imprimir a oferta de um npm mais novo embaixo de toda instalação: o npm que veio com o Node 22 é o
que este curso usa, e a oferta seria ruído em todas as transcrições. E **`~/server` é onde o seu
trabalho fica**, uma pasta por aula dentro dela.

Para ter certeza de que o `node` que responde é o que você acabou de instalar, pergunte onde ele
está:

```
ana@dev:~$ which node npm
/home/ana/.local/bin/node
/home/ana/.local/bin/npm
ana@dev:~$ ls ~/.local/node
CHANGELOG.md
LICENSE
README.md
bin
include
lib
share
```

Os dois moram no seu diretório home. Um `node` que responde de `/usr/bin` é um segundo Node, e a
próxima seção diz o que fazer com ele.
