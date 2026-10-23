---
title: O seu laboratório é o que o curso de python construiu
version: 1
---

Toda aula deste curso roda um servidor, um banco ou um worker, e a plataforma não roda nenhum deles
por você. **Você trabalha numa máquina Linux sua, e é a mesma máquina que o curso `python` fez você
montar**: Ubuntu 24.04 com o próprio Python 3.12, e o uv para cuidar dos pacotes de cada projeto. Se
você fez aquele curso, já tem tudo, e esta seção só confere. Se não fez, os passos estão abaixo em
resumo, e a aula 1 e a aula 19 de `python` explicam em detalhe.

## Três lugares para ter isso

| caminho | o que você ganha | quanto custa ao seu computador |
|---|---|---|
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04, separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda |
| **instalado** | as mesmas ferramentas no computador que você já usa | o disco das ferramentas, mais cada serviço que as aulas 4, 13 e 16 acrescentam |
| **online** | uma máquina Linux com terminal, no navegador | nada no seu computador; horas de uma cota mensal que outra pessoa define |

**A máquina virtual é a escolha para este curso**, com mais firmeza do que em `python`. A partir da
aula 4, o curso instala o PostgreSQL, depois o Redis na aula 13, o nginx na aula 16 e o Docker na
aula 17, e roda todos como serviços do sistema que sobem quando a máquina liga. Num computador onde
você também trabalha, eles colidem com o que já roda ali; numa máquina virtual, são seus para
quebrar, e um snapshot tirado quando uma aula funciona dá um recomeço limpo quando um experimento dá
errado. Use o VirtualBox no Windows ou no Linux, o UTM num Mac com Apple silicon, ou o WSL rodando o
Ubuntu 24.04 no Windows, com 2 GB de memória e um disco de 20 GB, como a aula 1 de `python` montou.

**Instalado** funciona como está impresso num computador que já roda Ubuntu 24.04. No macOS ou no
Windows, o Python e o uv se instalam pelos próprios sites e o código Python de toda aula roda igual,
mas os serviços das aulas 4 a 17 se instalam de outro jeito, e as transcrições daqui não vão bater com
as suas. Nada disso foi rodado para este curso.

**Online**, o GitHub Codespaces dá uma máquina Linux com terminal no navegador. Ele não custa nada ao
seu computador, e o GitHub dá às contas pessoais uma cota mensal de horas e cobra além dela, em termos
que ele define e pode mudar. Ele não foi rodado para este curso. Qualquer máquina que rode Ubuntu
24.04 e deixe você instalar pacotes com `sudo` serve, de qualquer empresa; nada aqui depende de uma
delas.

## A preparação, em resumo

Na máquina, num terminal:

```sh
sudo apt update
sudo apt install -y python3 python3-venv python3-pip pipx git curl
pipx install uv
pipx ensurepath
```

A linha do `apt` é a da aula 1 de `python`, com `pipx`, `git` e `curl` ao lado. O `pipx` instala um
programa Python num diretório próprio, e é assim que o uv entra sem mexer no Python em que o próprio
Ubuntu roda. O `pipx ensurepath` acrescenta `~/.local/bin` ao seu `PATH`, que um terminal lê quando
abre, **então feche o terminal e abra outro** antes do passo seguinte.

## Confira que cada ferramenta responde

```
ana@vm:~$ python3 --version
Python 3.12.3
ana@vm:~$ uv --version
uv 0.13.1 (x86_64-unknown-linux-gnu)
ana@vm:~$ git --version
git version 2.43.0
ana@vm:~$ curl --version | head -1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.7
```

**O Python 3.12 é a versão com que este curso foi gravado**, e o Django 6.1, a versão que o uv
instala hoje, recusa qualquer uma mais antiga. O seu uv pode ser mais novo que o 0.13.1, e qualquer
0.13 em diante se comporta igual para este curso. O `curl` é como toda aula conversa com um servidor
que acabou de subir, e o `git` é o que as aulas 15 e 17 usam para versionar um projeto.

## O que as transcrições mostram

Toda transcrição do curso foi gravada no Ubuntu 24.04 por uma desenvolvedora chamada Ana, numa
máquina chamada `vm`, então o prompt é `ana@vm:~$`. O seu mostra o seu usuário e a sua máquina.
Datas, horas, números de processo e os milissegundos que o uv informa mudam a cada execução; todo o
resto, versões, códigos de status, nomes de arquivo e mensagens de erro, deve bater com o que você
vê. Cada biblioteca é a que o PyPI entregou no dia da gravação, e as aulas mostram a versão onde ela
importa.
