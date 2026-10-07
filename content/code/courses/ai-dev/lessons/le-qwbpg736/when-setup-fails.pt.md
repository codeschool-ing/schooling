---
title: Quando a instalação falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, num erro sobre um programa
que acabou de instalar. Estas são as falhas que a máquina da gravação produziu de verdade enquanto
esta aula era escrita, na ordem em que você as encontraria, cada uma como ela imprimiu e com o que
quer dizer.

## O instalador para no zstd

```
ana@dev:~$ sh install-ollama.sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

O Ollama é baixado comprimido com `zstd`, e um Ubuntu mínimo não o tem. A mensagem diz a solução:
`sudo apt install zstd`, e rodar o instalador de novo. O primeiro comando da seção 03 o instala
antes de você chegar aqui.

## O Ollama está instalado e nada responde

```
ana@dev:~$ ollama --version
Warning: could not connect to a running Ollama instance
Warning: client version is 0.40.0
ana@dev:~$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
```

O `ollama` são dois programas num arquivo só: o comando que você digita, e um servidor que guarda
os modelos e responde em `127.0.0.1:11434`. O comando funciona e o servidor não está rodando. Num
Ubuntu normal o instalador registra o servidor como serviço e o inicia; **onde não há `systemd`
ele não consegue**, e o instalador avisa numa linha perto do fim, `WARNING: systemd is not
running`, que é fácil de passar batido. A máquina da gravação é um contêiner e não tem `systemd`.
Instalações mais antigas do WSL também não têm.

Onde existe `systemd`, `sudo systemctl start ollama` inicia o serviço. Onde não existe, abra um
segundo terminal, rode `ollama serve` nele e deixe-o aberto: ele é o servidor, e imprime uma linha
para cada pedido que responde. Fechar esse terminal o para.

## O `ollama serve` diz que o endereço está em uso

```
ana@dev:~$ ollama serve
Couldn't find '/home/ana/.ollama/id_ed25519'. Generating new private key.
Your new public key is: 

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5FdikhuprKVHnNlN/IapGlDx31L4TfGV8MEufa9YiK

Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

**Já há um servidor rodando**, o que é boa notícia: o serviço subiu afinal, ou outro terminal está
rodando um. Só um programa pode escutar numa porta. Feche este e use o que já está lá. A chave
acima é gerada na primeira vez que o Ollama roda como você, e identifica a sua instalação no site
do próprio Ollama se um dia você publicar um modelo; nada neste curso a usa.

## O pip se recusa a instalar

```
ana@dev:~$ python3 -m pip install anthropic==1.11.0
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

Esse é o pip fora do ambiente, se recusando a instalar no Python de que o próprio Ubuntu depende.
Ele está certo em recusar. **Não passe `--break-system-packages`**, que quer dizer o que diz. Ative
o ambiente com `source ~/aidev/bin/activate` e rode o mesmo comando.

## Um programa não encontra o `anthropic`

```
ana@dev:~$ python3 -c "import anthropic"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'anthropic'
```

As bibliotecas estão instaladas em `~/aidev`, e este terminal não o está usando: é um terminal
novo, e ninguém rodou `source ~/aidev/bin/activate` nele. O prompt não tem `(aidev)` na frente.
Rode a linha do `source`, e as quatro variáveis da seção 03 voltam junto. No Ubuntu, um `python`
puro só existe dentro do ambiente, então `python: command not found` é o mesmo engano.

## Um download é recusado

Duas bibliotecas buscam um arquivo cada na internet na primeira vez que são usadas: o `tiktoken`
a sua tabela de tokens, de um servidor da OpenAI, e o WordLlama as configurações do seu
tokenizador, do Hugging Face. Numa rede que bloqueia esses endereços, o primeiro uso falha, e a
última linha de cada erro diz para onde ia:

```
ana@dev:~$ python -c 'import tiktoken; tiktoken.get_encoding("o200k_base")' 2>&1 | tail -n 1
requests.exceptions.ProxyError: HTTPSConnectionPool(host='openaipublic.blob.core.windows.net', port=443): Max retries exceeded with url: /encodings/o200k_base.tiktoken (Caused by ProxyError('Unable to connect to proxy', OSError('Tunnel connection failed: 403 Forbidden')))
ana@dev:~$ python -c 'from wordllama import WordLlama; WordLlama.load()' 2>&1 | tail -n 1
FileNotFoundError: Failed to download tokenizer file 'l2_supercat_tokenizer_config.json' from 'https://huggingface.co/dleemiller/word-llama-l2-supercat/resolve/main/l2_supercat_tokenizer_config.json'.
```

**A própria rede da máquina da gravação recusou os dois**, e foi assim que eles entraram na aula;
os outros downloads dela, o Ollama e os modelos entre eles, passaram. Redes de escritório e de
escola muitas vezes bloqueiam alguns endereços como esses. Rode essas duas linhas uma vez em outra
rede, em casa ou pela conexão de um celular: cada biblioteca guarda o seu arquivo em `~/.cache` e
nunca mais pergunta. Ou peça a quem cuida da rede que libere `openaipublic.blob.core.windows.net`
e `huggingface.co`.

## O Ollama para enquanto um programa fala com ele

```
ana@dev:~/shop$ python -c 'import anthropic; anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=40, messages=[{"role": "user", "content": "Hello"}])' 2>&1 | tail -n 1
anthropic.APIConnectionError: Connection error.
```

`Connection error` sem mais nada quer dizer que nada respondeu no endereço de
`ANTHROPIC_BASE_URL`. O servidor parou, ou nunca subiu depois de um reboot, ou o terminal que
rodava o `ollama serve` foi fechado. O `ollama list` diz qual numa linha, como na segunda falha
acima. O SDK tentou mais duas vezes antes de desistir, e é por isso que o erro leva alguns
segundos para aparecer; a aula 10 é sobre essas novas tentativas.

## Lento não é quebrado

A primeira pergunta depois de um tempo demora mais que as seguintes, porque o Ollama primeiro
carrega o modelo na memória e o descarrega depois de cinco minutos sem ninguém perguntar. Na
máquina da gravação, uma resposta de cem palavras levou uns doze segundos. Se toda
resposta leva minutos, ou o computador inteiro trava enquanto o modelo escreve, o modelo é grande
demais para a memória que você tem: a seção 02 diz quanto o recomendado precisa, e que modelo
menor usar no lugar.
