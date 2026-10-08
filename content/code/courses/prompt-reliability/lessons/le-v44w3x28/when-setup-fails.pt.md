---
title: Quando a instalação falha
version: 1
---

A maioria das instalações falha num de quatro lugares: a instalação, o servidor, o modelo ou a
espera. Cada um tem uma mensagem, e todas as mensagens abaixo foram impressas na máquina em que
este curso foi capturado.

## A instalação para: zstd

A primeira instalação naquela máquina parou antes de instalar qualquer coisa:

```
$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

O Ollama é publicado compactado com zstd, e um Linux mínimo pode não ter o programa que o
descompacta. **A mensagem diz exatamente o que fazer**, que é o caso pelo qual torcer:

```sh
sudo apt-get install -y zstd
curl -fsSL https://ollama.com/install.sh | sh
```

## Ninguém está escutando

O `pl` fala com o Ollama pela rede, em `127.0.0.1:11434`, mesmo com os dois no seu computador. Se o
servidor não está rodando, não há ninguém nesse endereço:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
pl: cannot reach Ollama at http://127.0.0.1:11434 ([Errno 111] Connection refused). Is it running?
```

`Connection refused` quer dizer que o endereço respondeu que nenhum programa está escutando ali. No
Linux, a instalação configurou o Ollama como um serviço, e isto o sobe:

```sh
sudo systemctl start ollama
```

Num sistema sem serviços, como o WSL em algumas versões do Windows, suba-o à mão num terminal só
dele e deixe esse terminal aberto:

```sh
ollama serve
```

No macOS e no Windows, o aplicativo do Ollama é o servidor: abra-o, e ele fica na barra de menus ou
na área de notificação enquanto roda.

## O modelo não está lá

Um modelo que você nunca baixou não pode responder, e o Ollama diz isso pelo nome:

```
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl --set model=llama3.2:1b
pl: Ollama answered 404: {"error":"model 'llama3.2:1b' not found"}
ana@lab:~/triage$ ollama list
NAME           ID              SIZE      MODIFIED               
llama3.2:1b    baf6a787fdff    1.3 GB    Less than a second ago    
llama3.2:3b    a80c4f17acd5    2.0 GB    57 minutes ago            
```

A correção é o `ollama pull` com o mesmo nome. O nome tem de bater letra por letra: `llama3.2:3b` e
`llama3.2` são nomes que o Ollama conhece, e não se escrevem do mesmo jeito.

**Um modelo que você baixou também pode sumir**, e esse é mais difícil de ver. O Ollama guarda os
modelos num diretório dentro da home de quem subiu o servidor. O serviço no Linux roda com um
usuário próprio, `ollama`, com os modelos em `/usr/share/ollama/.ollama`. Suba o `ollama serve`
você mesmo, com o seu usuário, e esse segundo servidor procura na sua home, não acha nada e
responde como se você nunca tivesse baixado coisa alguma:

```
ana@lab:~/triage$ ollama list
NAME    ID    SIZE    MODIFIED 
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
pl: Ollama answered 404: {"error":"model 'llama3.2:3b' not found"}
```

`ollama list` vazio, e o modelo que o `ollama list` mostrava um minuto antes "não encontrado".
**Dois servidores, dois diretórios de modelos**, e só um deles pode ocupar o endereço de cada vez.
Pare o que você subiu (Ctrl-C no terminal dele) e suba o serviço no lugar, ou baixe o modelo de
novo no servidor que você está usando, ao preço de uma segunda cópia no disco.

## A primeira resposta é lenta

A primeira chamada depois que o servidor sobe carrega o modelo na memória, e isso leva segundos
antes que uma única palavra volte. Na primeira execução desta aula, a primeira resposta levou 34,8
segundos e a seguinte, 12,7. Depois de cinco minutos parado, o Ollama descarrega o modelo para
devolver a memória, e a próxima chamada paga para carregá-lo de novo. O `ollama ps` mostra o que
está carregado, quanta memória ocupa e até quando.

Se **toda** chamada é lenta, mais de meio minuto para uma resposta de uma linha, falta memória ou
processador ao computador para este modelo. Use o `llama3.2:1b`, como a primeira seção descreveu:
ele ocupou 2,0 GB de memória onde o `llama3.2:3b` ocupou 2,9, e é um modelo mais fraco. Se nem ele
rodar, sobra o caminho online.
