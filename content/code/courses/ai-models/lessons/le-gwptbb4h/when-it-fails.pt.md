---
title: Quando a montagem falha
version: 1
---

Cada falha abaixo que tem transcrição aconteceu enquanto este curso era gravado, no Ubuntu Server
24.04 que o caminho da máquina virtual instala, e cada uma diz a própria causa se você ler a última
linha primeiro.

## O instalador para antes de começar

```
ana@desk:~$ curl -fsSL https://ollama.com/install.sh | sh
>>> Installing ollama to /usr/local
ERROR: This version requires zstd for extraction. Please install zstd and try again:
  - Debian/Ubuntu: sudo apt-get install zstd
  - RHEL/CentOS/Fedora: sudo dnf install zstd
  - Arch: sudo pacman -S zstd
```

O script baixa o Ollama como um arquivo `.tar.zst` e precisa do `zstd` para descompactá-lo. A
mensagem diz o que instalar, para três famílias de Linux. Instale, rode a mesma linha de novo, e o
instalador termina como a seção 03 mostra.

## Ninguém está escutando

```
ana@desk:~$ ollama run llama3.2:3b "Hello"
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@desk:~/desk$ python check.py 2>&1 | tail -1
openai.APIConnectionError: Connection error.
```

As duas mensagens querem dizer a mesma coisa: **o servidor não está rodando.** O comando `ollama` e
as bibliotecas de Python são só clientes; o modelo está no servidor, e aqui não havia servidor na
porta 11434 para responder. No Windows e no macOS, abra o aplicativo do Ollama, que o sobe. No Linux
com systemd, `sudo systemctl start ollama`. Numa máquina sem systemd, o caso que o aviso da seção 03
descreveu, rode `ollama serve` num terminal só para ele e deixe-o aberto enquanto trabalha.

A mensagem do Python é a linha mais curta de um traceback longo, e o `tail -1` é o jeito de vê-la: a
última linha de um erro de Python é a causa, e tudo acima dela é o caminho que ele fez.

## O servidor não sobe uma segunda vez

```
ana@desk:~$ ollama serve
Couldn't find '/home/ana/.ollama/id_ed25519'. Generating new private key.
Your new public key is: 

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEamexygLwNBCOIi+pUp0VVMDB07m/s03OagWMQnp5r

Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

Na primeira vez que roda, o Ollama cria para si um par de chaves em `~/.ollama`, que ele só usa se
você entrar numa conta em ollama.com; nada neste curso precisa disso. A linha que importa é a
última: **a porta 11434 já tem um servidor**, o que é boa notícia. Havia um rodando o tempo todo,
subido pelo instalador ou pelo aplicativo, e o `ollama run` vai alcançá-lo.

## Um modelo que não existe

```
ana@desk:~$ ollama pull llama3.2:4b
pulling manifest
Error: pull model manifest: file does not exist
```

Não existe `llama3.2:4b`. **A tag tem de ser uma que a biblioteca do Ollama publica**, e a página
dela em ollama.com lista quais: o `llama3.2` vem em `1b` e `3b`. A mensagem diz *file does not
exist* porque o servidor pediu à biblioteca a lista de arquivos daquela tag e não recebeu nada.

## O Python não acha a biblioteca

```
ana@desk:~/desk$ python3 check.py
Traceback (most recent call last):
  File "/home/ana/desk/check.py", line 3, in <module>
    from openai import OpenAI
ModuleNotFoundError: No module named 'openai'
```

O `python3` rodou o Python do sistema, que não tem nenhuma das seis bibliotecas; elas estão dentro
do `.venv`. **Ative o ambiente virtual** em todo terminal novo antes de trabalhar na mesa, com
`. .venv/bin/activate`, e o prompt então costuma começar com `(.venv)`.

## A biblioteca não tem chave

```
ana@desk:~/desk$ python check.py
Traceback (most recent call last):
  File "/home/ana/desk/check.py", line 5, in <module>
    client = OpenAI()  # the address and the key come from desk.env
  File "/home/ana/desk/.venv/lib/python3.13/site-packages/openai/_client.py", line 274, in __init__
    raise OpenAIError(
        "Missing credentials. Please pass an `api_key`, `workload_identity`, `admin_api_key`, or set the `OPENAI_API_KEY` or `OPENAI_ADMIN_KEY` environment variable."
    )
openai.OpenAIError: Missing credentials. Please pass an `api_key`, `workload_identity`, `admin_api_key`, or set the `OPENAI_API_KEY` or `OPENAI_ADMIN_KEY` environment variable.
```

O ambiente virtual está ativo, e o `desk.env` não foi carregado, então a biblioteca não tem chave
nem endereço. Ela reclama da chave primeiro porque teria mandado a requisição para a própria OpenAI.
Rode `. ./desk.env` no mesmo terminal, e confira com `echo $OPENAI_BASE_URL`, que deve imprimir o
endereço do Ollama.

## O computador é pequeno demais

Numa máquina com menos memória do que o modelo precisa, o Ollama se recusa a carregá-lo ou responde
muito devagar, usando o disco como memória. Isso não foi gravado: a máquina em que o curso foi
gravado tem 16 GB. **Baixe o `llama3.2:1b`**, que precisa de 1,5 GB carregado, e use-o em todo
programa trocando o nome do modelo. A aula 5 mostra quanto ele custa em qualidade, medido.

## Qualquer outra coisa

**Leia a última linha do que foi impresso antes de pesquisar.** Um instalador que falha imprime uma
página, e o Python imprime um traceback; a causa é a linha que diz `ERROR`, `Error` ou o nome da
exceção, e as linhas em volta são onde aconteceu. Uma mensagem que cita um pacote ou um comando para
rodar, como a primeira daqui, quer dizer exatamente isso.
