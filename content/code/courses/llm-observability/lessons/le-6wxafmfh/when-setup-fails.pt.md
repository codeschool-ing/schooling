---
title: Quando a preparação falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, num erro sobre um programa
que acabou de instalar. Estas são as falhas que a máquina da gravação produziu de verdade enquanto
esta aula era escrita, na ordem em que você as encontraria, cada uma como apareceu e com o que ela
quer dizer.

## O instalador para no zstd

```
ana@dev:~$ curl -fsSL https://ollama.com/install.sh -o install-ollama.sh
ana@dev:~$ sh install-ollama.sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

O Ollama vem compactado com `zstd`, e um Ubuntu mínimo não o tem. A mensagem diz a correção:
`sudo apt install zstd`, e rodar o instalador de novo. O primeiro comando da seção 03 o instala
antes que você chegue aqui.

## O Ollama está instalado e nada responde

```
ana@dev:~$ ollama --version
Warning: could not connect to a running Ollama instance
Warning: client version is 0.40.0
ana@dev:~$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
```

O `ollama` são dois programas num arquivo só: o comando que você digita, e um servidor que guarda os
modelos e responde em `127.0.0.1:11434`. O comando funciona e o servidor não está rodando. Num Ubuntu
normal o instalador registra o servidor como serviço e o inicia; **onde não há `systemd` ele não
consegue**, e o instalador diz isso numa linha perto do fim, `WARNING: systemd is not running`, fácil
de passar batido. A máquina da gravação é um contêiner e não tem `systemd`. Instalações mais antigas
do WSL também não têm.

Onde há `systemd`, `sudo systemctl start ollama` inicia o serviço. Onde não há, abra um segundo
terminal, rode `ollama serve` nele e deixe-o aberto: ele é o servidor, e imprime uma linha para cada
pedido que responde. Fechar esse terminal o encerra.

## O `ollama serve` diz que o endereço está em uso

```
ana@dev:~$ timeout 5 ollama serve
Couldn't find '/home/ana/.ollama/id_ed25519'. Generating new private key.
Your new public key is: 

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQcQrwd08NN5DSOjJVWaJBpieMmy5keDn875YkH3BmE

Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

O `timeout 5` na frente pararia este segundo servidor depois de cinco segundos; ele não chegou lá.
**Já há um servidor rodando**, o que é boa notícia: o serviço subiu afinal, ou outro terminal está
rodando um. Só um programa pode escutar numa porta. Feche este e use o que já está lá. A chave acima
é gerada na primeira vez que o Ollama roda como você, e identifica a sua instalação no próprio site
do Ollama se você algum dia publicar um modelo; nada neste curso a usa.

## O pip se recusa a instalar

```
ana@dev:~$ python3 -m pip install openai==3.24.0
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
    
    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.
    
    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.
    
    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

É o pip fora do ambiente, recusando-se a instalar no Python de que o próprio Ubuntu depende. Ele faz
bem em recusar. **Não passe `--break-system-packages`**, que quer dizer o que diz. Ative o ambiente
com `source ~/llmobs/bin/activate` e rode o mesmo comando.

## Um programa não encontra o `openai`

```
ana@dev:~$ python3 -c "import openai"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'openai'
```

As bibliotecas estão instaladas em `~/llmobs`, e este terminal não o está usando: é um terminal novo,
e ninguém rodou `source ~/llmobs/bin/activate` nele. O prompt não tem `(llmobs)` na frente. Rode a
linha do `source`, e as três variáveis da seção 03 voltam junto. No Ubuntu, um `python` simples só
existe dentro do ambiente, então `python: command not found` é o mesmo engano.

## O Ollama para enquanto um programa conversa com ele

```
ana@dev:~/obs$ python -c 'from openai import OpenAI; OpenAI().chat.completions.create(model="llama3.2:3b", messages=[{"role": "user", "content": "Hello"}])' 2>&1 | tail -n 1
openai.APIConnectionError: Connection error.
```

`Connection error` sem mais nada quer dizer que nada respondeu no endereço de `OPENAI_BASE_URL`. O
servidor parou, ou não subiu depois de um reboot, ou o terminal que rodava `ollama serve` foi
fechado. `ollama list` diz qual numa linha, como na segunda falha acima. O SDK tentou mais duas
vezes antes de desistir, por isso o erro leva alguns segundos para aparecer; a aula 4 trata dessas
novas tentativas.

## Lento não é quebrado

A primeira pergunta depois de um tempo demora mais que as seguintes, porque o Ollama primeiro carrega
o modelo na memória e o descarrega depois de cinco minutos sem ninguém perguntar. A aula 4 mede essa
espera. Se toda resposta leva minutos, ou o computador inteiro trava enquanto o modelo escreve, o
modelo é grande demais para a memória que você tem: a seção 02 diz quanto o recomendado precisa, e
qual modelo menor usar no lugar.
