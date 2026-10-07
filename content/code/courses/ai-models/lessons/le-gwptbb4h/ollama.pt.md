---
title: O Ollama e o modelo do curso
version: 1
---

O **Ollama** é duas coisas: um servidor que mantém modelos na memória e responde requisições na
porta 11434, e um comando, `ollama`, que conversa com ele. A aula 14 trata dele em detalhe. Aqui ele
só precisa estar instalado e respondendo.

## Instalando

**Windows e macOS:** o instalador de ollama.com/download. Ele deixa o servidor rodando em segundo
plano, liga-o junto com o computador e acrescenta o comando `ollama` ao terminal. Nenhum dos dois
foi usado neste curso, que foi gravado em Linux.

**Linux**, e os caminhos da máquina virtual e online: o script do próprio Ollama. Ele precisa do
`zstd` para descompactar o que baixa, e um Ubuntu mínimo pode não ter, então instale-o antes; numa
máquina que já tem, a linha não muda nada:

```
ana@desk:~$ sudo apt-get install -y -q zstd > /dev/null && zstd --version
debconf: delaying package configuration, since apt-utils is not installed
*** Zstandard CLI (64-bit) v1.5.5, by Yann Collet ***
ana@desk:~$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
>>> Downloading ollama-linux-amd64.tar.zst
######################################################################## 100.0%
>>> Adding ollama user to video group...
>>> Adding current user to ollama group...
>>> Creating ollama systemd service...
WARNING: systemd is not running
WARNING: Unable to detect NVIDIA/AMD GPU. Install lspci or lshw to automatically detect and install GPU dependencies.
>>> The Ollama API is now available at 127.0.0.1:11434.
>>> Install complete. Run "ollama" from the command line.
ana@desk:~$ ollama --version
ollama version is 0.40.0
```

Os dois avisos são sobre esta máquina, não sobre a instalação. *systemd is not running* quer dizer
que o script não conseguiu registrar o servidor como um serviço que sobe com o computador; num
Ubuntu comum, numa máquina virtual ou numa alugada, o systemd está rodando e a linha não aparece. Se
ela aparecer, suba o servidor você mesmo, num terminal só para ele, com `ollama serve`, e deixe esse
terminal aberto. *Unable to detect NVIDIA/AMD GPU* quer dizer que não há placa de vídeo para usar,
então o modelo roda no processador.

## O modelo

O `ollama pull` baixa um modelo pelo nome e pela tag. A tag depois dos dois-pontos é o tamanho, e
escrevê-la importa: a aula 14 mostra que um nome sem tag quer dizer o que a biblioteca do Ollama
chama de `latest` naquele dia.

```
ana@desk:~$ ollama pull llama3.2:3b
pulling manifest
pulling dde5aa3fc5ff: 100% ▕█████████████████████████████████████ ▏ 2.0 GB/2.0 GB  208 MB/s      0s
pulling 34bb5ab01051: 100% ▕██████████████████████████████████████▏  561 B
verifying sha256 digest
writing manifest
success
```

Na primeira pergunta, o servidor carrega o modelo do disco para a memória, o que leva alguns
segundos, e então responde:

```
ana@desk:~$ ollama run llama3.2:3b 'In one sentence: what does an online bookshop do?'
An online bookshop allows customers to browse, purchase, and have books shipped to their
homes, often with features such as personalized recommendations, customer reviews, and e-books
available for digital download.
```

**A sua resposta vai vir com outras palavras.** Um modelo escolhe cada palavra com alguma
aleatoriedade, que a aula 5 seção 08 mede, então a mesma pergunta dá uma frase diferente em cada
máquina e em cada execução. O que deve bater é o tipo de resposta: uma frase sobre vender livros
pela internet.

Dois comandos dizem quanto o modelo custa ao seu computador. O `ollama list` é o disco, e o
`ollama ps` é a memória, enquanto o modelo continuar carregado:

```
ana@desk:~$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:3b    a80c4f17acd5    2.0 GB    23 seconds ago    
ana@desk:~$ ollama ps
NAME           ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:3b    a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
```

**2,0 GB em disco e 2,6 GB em memória.** A memória é maior porque o servidor reserva espaço para a
conversa além dos pesos, conta que a aula 3 faz. *4 minutes from now* é quando o Ollama vai
descarregá-lo se ninguém perguntar nada, e a aula 14 muda isso. `100% CPU` quer dizer que ele está
rodando no processador.

## O menor

Num computador com 4 GB de memória, baixe também o `llama3.2:1b`, e use-o onde uma aula disser
`llama3.2:3b`:

```
ana@desk:~$ ollama pull llama3.2:1b
pulling manifest
pulling 74701a8c35f6: 100% ▕██████████████████████████████████████▏ 1.3 GB
pulling 966de95ca8a6: 100% ▕██████████████████████████████████████▏ 1.4 KB
pulling fcc5a6bec9da: 100% ▕██████████████████████████████████████▏ 7.7 KB
pulling a70ff7e570d9: 100% ▕██████████████████████████████████████▏ 6.0 KB
pulling 4f659a1e86d7: 100% ▕██████████████████████████████████████▏  485 B
verifying sha256 digest
writing manifest
success
ana@desk:~$ ollama list
NAME           ID              SIZE      MODIFIED       
llama3.2:1b    baf6a787fdff    1.3 GB    10 seconds ago    
llama3.2:3b    a80c4f17acd5    2.0 GB    54 seconds ago    
ana@desk:~$ ollama ps
NAME           ID              SIZE      PROCESSOR    CONTEXT    RUNNER      UNTIL              
llama3.2:1b    baf6a787fdff    1.5 GB    100% CPU     4096       llamacpp    4 minutes from now    
llama3.2:3b    a80c4f17acd5    2.6 GB    100% CPU     4096       llamacpp    4 minutes from now    
```

1,3 GB em disco e 1,5 GB em memória, e dois modelos podem ficar carregados ao mesmo tempo se a
memória der.
